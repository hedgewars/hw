use bytes::{Buf, Bytes};
use log::*;
use slab::Slab;
use std::io::Error;
use std::pin::Pin;
use std::task::{Context, Poll};
use std::{
    iter::Iterator,
    net::{IpAddr, SocketAddr},
    time::Duration,
};
use tokio::{
    io::{AsyncRead, AsyncReadExt, AsyncWrite, AsyncWriteExt, ReadBuf},
    net::{TcpListener, TcpStream},
    sync::mpsc::{channel, Receiver, Sender},
};
#[cfg(feature = "tls-connections")]
use tokio_native_tls::{TlsAcceptor, TlsStream};

use crate::{
    core::types::ClientId,
    handlers,
    handlers::{IoResult, IoTask, ServerState},
    protocol::{self, ProtocolDecoder, ProtocolError},
    utils,
};
use hedgewars_network_protocol::{
    messages::HwServerMessage::Redirect, messages::*, parser::server_message,
};

const PING_TIMEOUT: Duration = Duration::from_secs(15);

#[derive(Debug)]
enum ClientUpdateData {
    Message(HwProtocolMessage),
    Error(String),
}

#[derive(Debug)]
struct ClientUpdate {
    client_id: ClientId,
    data: ClientUpdateData,
}

struct ClientUpdateSender {
    client_id: ClientId,
    sender: Sender<ClientUpdate>,
}

impl ClientUpdateSender {
    async fn send(&mut self, data: ClientUpdateData) -> bool {
        self.sender
            .send(ClientUpdate {
                client_id: self.client_id,
                data,
            })
            .await
            .is_ok()
    }
}

enum ClientStream {
    Tcp(TcpStream),
    #[cfg(feature = "tls-connections")]
    Tls(TlsStream<TcpStream>),
}

impl Unpin for ClientStream {}

impl AsyncRead for ClientStream {
    fn poll_read(
        self: Pin<&mut Self>,
        cx: &mut Context<'_>,
        buf: &mut ReadBuf<'_>,
    ) -> Poll<std::io::Result<()>> {
        use ClientStream::*;
        match Pin::into_inner(self) {
            Tcp(stream) => Pin::new(stream).poll_read(cx, buf),
            #[cfg(feature = "tls-connections")]
            Tls(stream) => Pin::new(stream).poll_read(cx, buf),
        }
    }
}

impl AsyncWrite for ClientStream {
    fn poll_write(
        self: Pin<&mut Self>,
        cx: &mut Context<'_>,
        buf: &[u8],
    ) -> Poll<Result<usize, Error>> {
        use ClientStream::*;
        match Pin::into_inner(self) {
            Tcp(stream) => Pin::new(stream).poll_write(cx, buf),
            #[cfg(feature = "tls-connections")]
            Tls(stream) => Pin::new(stream).poll_write(cx, buf),
        }
    }

    fn poll_flush(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Result<(), Error>> {
        use ClientStream::*;
        match Pin::into_inner(self) {
            Tcp(stream) => Pin::new(stream).poll_flush(cx),
            #[cfg(feature = "tls-connections")]
            Tls(stream) => Pin::new(stream).poll_flush(cx),
        }
    }

    fn poll_shutdown(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Result<(), Error>> {
        use ClientStream::*;
        match Pin::into_inner(self) {
            Tcp(stream) => Pin::new(stream).poll_shutdown(cx),
            #[cfg(feature = "tls-connections")]
            Tls(stream) => Pin::new(stream).poll_shutdown(cx),
        }
    }
}

struct NetworkClient {
    id: ClientId,
    stream: ClientStream,
    receiver: Receiver<Bytes>,
    peer_addr: SocketAddr,
    decoder: ProtocolDecoder,
}

impl NetworkClient {
    fn new(
        id: ClientId,
        stream: ClientStream,
        peer_addr: SocketAddr,
        receiver: Receiver<Bytes>,
    ) -> Self {
        Self {
            id,
            stream,
            peer_addr,
            receiver,
            decoder: ProtocolDecoder::new(PING_TIMEOUT),
        }
    }

    async fn read<T: AsyncRead + AsyncWrite + Unpin>(
        stream: &mut T,
        decoder: &mut ProtocolDecoder,
    ) -> protocol::Result<HwProtocolMessage> {
        let result = decoder.read_from(stream).await;
        if matches!(result, Err(ProtocolError::Timeout)) {
            if Self::write(stream, Bytes::from(HwServerMessage::Ping.to_raw_protocol())).await {
                decoder.read_from(stream).await
            } else {
                Err(ProtocolError::Eof)
            }
        } else {
            result
        }
    }

    async fn write<T: AsyncWrite + Unpin>(stream: &mut T, mut data: Bytes) -> bool {
        !data.has_remaining() || matches!(stream.write_buf(&mut data).await, Ok(n) if n > 0)
    }

    async fn run(mut self, sender: Sender<ClientUpdate>) {
        use ClientUpdateData::*;
        let mut sender = ClientUpdateSender {
            client_id: self.id,
            sender,
        };

        loop {
            tokio::select! {
                server_message = self.receiver.recv() => {
                    match server_message {
                        Some(message) => if !Self::write(&mut self.stream, message).await {
                            sender.send(Error("Connection reset by peer".to_string())).await;
                            break;
                        }
                        None => {
                            break;
                        }
                    }
                }
                client_message = Self::read(&mut self.stream, &mut self.decoder) => {
                     match client_message {
                        Ok(message) => {
                            //todo!("add flood stats");
                            if !sender.send(Message(message)).await {
                                break;
                            }
                        }
                        Err(e) => {
                            //todo!("send cmdline errors");
                            //todo!("more graceful shutdown to prevent errors from explicitly closed clients")
                            sender.send(Error(format!("{}", e))).await;
                            if matches!(e, ProtocolError::Timeout) {
                                Self::write(&mut self.stream, Bytes::from(HwServerMessage::Bye("Ping timeout".to_string()).to_raw_protocol())).await;
                            }
                            break;
                        }
                    }
                }
            }
        }
    }
}

#[cfg(feature = "tls-connections")]
struct TlsListener {
    listener: TcpListener,
    acceptor: TlsAcceptor,
}

pub struct NetworkLayer {
    listener: TcpListener,
    #[cfg(feature = "tls-connections")]
    tls: TlsListener,
    server_state: ServerState,
    clients: Slab<Sender<Bytes>>,
    update_tx: Sender<ClientUpdate>,
    update_rx: Receiver<ClientUpdate>,
}

impl NetworkLayer {
    pub async fn run(&mut self) {
        async fn accept_plain_branch(
            layer: &mut NetworkLayer,
            value: (TcpStream, SocketAddr),
            update_tx: Sender<ClientUpdate>,
        ) {
            let (stream, addr) = value;
            if let Some(client) = layer.create_client(ClientStream::Tcp(stream), addr).await {
                tokio::spawn(client.run(update_tx));
            }
        }

        #[cfg(feature = "tls-connections")]
        async fn accept_tls_branch(
            layer: &mut NetworkLayer,
            value: (TcpStream, SocketAddr),
            update_tx: Sender<ClientUpdate>,
        ) {
            let (stream, addr) = value;
            match layer.tls.acceptor.accept(stream).await {
                Ok(stream) => {
                    if let Some(client) = layer.create_client(ClientStream::Tls(stream), addr).await
                    {
                        tokio::spawn(client.run(update_tx));
                    }
                }
                Err(e) => {
                    warn!("Unable to establish TLS connection: {}", e);
                }
            }
        }

        async fn client_message_branch(
            layer: &mut NetworkLayer,
            client_message: Option<ClientUpdate>,
        ) {
            use ClientUpdateData::*;
            match client_message {
                Some(ClientUpdate {
                    client_id,
                    data: Message(message),
                }) => {
                    layer.handle_message(client_id, message).await;
                }
                Some(ClientUpdate {
                    client_id,
                    data: Error(e),
                }) => {
                    let mut response = handlers::Response::new(client_id);
                    info!("Client {} error: {:?}", client_id, e);
                    response.remove_client(client_id);
                    handlers::handle_client_loss(&mut layer.server_state, client_id, &mut response);
                    layer.handle_response(response).await;
                }
                None => unreachable!(),
            }
        }

        //todo!("add the DB task");
        //todo!("add certfile watcher task");
        loop {
            #[cfg(not(feature = "tls-connections"))]
            tokio::select! {
                Ok(value) = self.listener.accept() => accept_plain_branch(self, value, self.update_tx.clone()).await,
                client_message = self.update_rx.recv(), if !self.clients.is_empty() => client_message_branch(self, client_message).await
            }

            #[cfg(feature = "tls-connections")]
            tokio::select! {
                Ok(value) = self.listener.accept() => accept_plain_branch(self, value, self.update_tx.clone()).await,
                Ok(value) = self.tls.listener.accept() => accept_tls_branch(self, value, self.update_tx.clone()).await,
                client_message = self.update_rx.recv(), if !self.clients.is_empty() => client_message_branch(self, client_message).await
            }
        }
    }

    async fn create_client(
        &mut self,
        stream: ClientStream,
        addr: SocketAddr,
    ) -> Option<NetworkClient> {
        let entry = self.clients.vacant_entry();
        let client_id = entry.key();
        let (tx, rx) = channel(16);
        entry.insert(tx);

        let client = NetworkClient::new(client_id, stream, addr, rx);

        info!("client {} ({}) added", client.id, client.peer_addr);

        let mut response = handlers::Response::new(client_id);

        let added = if let IpAddr::V4(addr) = client.peer_addr.ip() {
            handlers::handle_client_accept(
                &mut self.server_state,
                client_id,
                &mut response,
                addr.octets(),
                addr.is_loopback(),
            )
        } else {
            todo!("implement something")
        };

        self.handle_response(response).await;

        if added {
            Some(client)
        } else {
            None
        }
    }

    async fn handle_message(&mut self, client_id: ClientId, message: HwProtocolMessage) {
        debug!("Handling message {:?} for client {}", message, client_id);
        let mut response = handlers::Response::new(client_id);
        handlers::handle(&mut self.server_state, client_id, &mut response, message);
        self.handle_response(response).await;
    }

    async fn handle_response(&mut self, mut response: handlers::Response) {
        if response.is_empty() {
            return;
        }

        for client_id in response.extract_removed_clients() {
            if self.clients.contains(client_id) {
                self.clients.remove(client_id);
                if self.clients.is_empty() {
                    let (update_tx, update_rx) = channel(128);
                    self.update_rx = update_rx;
                    self.update_tx = update_tx;
                }
            }
            info!("Client {} removed", client_id);
        }

        debug!("{} pending server messages", response.len());
        let output = response.extract_messages(&mut self.server_state.server);
        for (clients, message) in output {
            debug!("Message {:?} to {:?}", message, clients);
            Self::send_message(&mut self.clients, message, clients.iter().cloned()).await;
        }
    }

    async fn send_message<I>(
        clients: &mut Slab<Sender<Bytes>>,
        message: HwServerMessage,
        to_clients: I,
    ) where
        I: Iterator<Item = ClientId>,
    {
        let msg_string = message.to_raw_protocol();
        let bytes = Bytes::copy_from_slice(msg_string.as_bytes());
        for client_id in to_clients {
            if let Some(client) = clients.get_mut(client_id) {
                if !client.send(bytes.clone()).await.is_ok() {
                    clients.remove(client_id);
                }
            }
        }
    }
}

pub struct NetworkLayerBuilder {
    listener: Option<TcpListener>,
    #[cfg(feature = "tls-connections")]
    tls_listener: Option<TcpListener>,
    #[cfg(feature = "tls-connections")]
    tls_acceptor: Option<TlsAcceptor>,
    clients_capacity: usize,
    rooms_capacity: usize,
}

impl Default for NetworkLayerBuilder {
    fn default() -> Self {
        Self {
            clients_capacity: 1024,
            rooms_capacity: 512,
            listener: None,
            #[cfg(feature = "tls-connections")]
            tls_listener: None,
            #[cfg(feature = "tls-connections")]
            tls_acceptor: None,
        }
    }
}

impl NetworkLayerBuilder {
    pub fn with_listener(self, listener: TcpListener) -> Self {
        Self {
            listener: Some(listener),
            ..self
        }
    }

    #[cfg(feature = "tls-connections")]
    pub fn with_tls_acceptor(self, listener: TlsAcceptor) -> Self {
        Self {
            tls_acceptor: Option::from(listener),
            ..self
        }
    }

    #[cfg(feature = "tls-connections")]
    pub fn with_tls_listener(self, listener: TlsAcceptor) -> Self {
        Self {
            tls_acceptor: Option::from(listener),
            ..self
        }
    }

    pub fn build(self) -> NetworkLayer {
        let server_state = ServerState::new(self.clients_capacity, self.rooms_capacity);

        let clients = Slab::with_capacity(self.clients_capacity);
        let (update_tx, update_rx) = channel(128);

        NetworkLayer {
            listener: self.listener.expect("No listener provided"),
            #[cfg(feature = "tls-connections")]
            tls: TlsListener {
                listener: self.tls_listener.expect("No TLS listener provided"),
                acceptor: self.tls_acceptor.expect("No TLS acceptor provided"),
            },
            server_state,
            clients,
            update_tx,
            update_rx,
        }
    }
}
