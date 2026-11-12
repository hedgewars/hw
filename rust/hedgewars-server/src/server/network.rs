use bytes::Bytes;
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
    io::{AsyncRead, AsyncWrite, AsyncWriteExt, ReadBuf},
    net::{TcpListener, TcpStream},
    sync::mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender},
    time::{Instant, timeout},
};
#[cfg(feature = "tls-connections")]
use tokio_native_tls::{TlsAcceptor, TlsStream};

use crate::{
    core::types::ClientId,
    handlers,
    handlers::{IoResult, IoTask, ServerState},
    protocol::ProtocolDecoder,
};
use hedgewars_network_protocol::messages::*;

const PING_TIMEOUT: Duration = Duration::from_secs(15);

#[derive(Debug)]
enum ClientUpdateData {
    Message(HwProtocolMessage),
    PingSent,
    PingTimeout,
    Error(String),
}

#[derive(Debug)]
struct ClientUpdate {
    client_id: ClientId,
    conn_id: u64,
    data: ClientUpdateData,
}

struct ClientUpdateSender {
    client_id: ClientId,
    conn_id: u64,
    sender: UnboundedSender<ClientUpdate>,
}

impl ClientUpdateSender {
    fn send(&mut self, data: ClientUpdateData) -> bool {
        self.sender
            .send(ClientUpdate {
                client_id: self.client_id,
                conn_id: self.conn_id,
                data,
            })
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

#[derive(PartialEq, Eq)]
enum WriteResult {
    Ok,
    IoError,
    TimedOut,
}

struct NetworkClient {
    id: ClientId,
    conn_id: u64,
    stream: ClientStream,
    receiver: UnboundedReceiver<Bytes>,
    peer_addr: SocketAddr,
    decoder: ProtocolDecoder,
    ping_timeout: Duration,
}

impl NetworkClient {
    fn new(
        id: ClientId,
        conn_id: u64,
        stream: ClientStream,
        peer_addr: SocketAddr,
        receiver: UnboundedReceiver<Bytes>,
    ) -> Self {
        Self::with_timeout(id, conn_id, stream, peer_addr, receiver, PING_TIMEOUT)
    }

    fn with_timeout(
        id: ClientId,
        conn_id: u64,
        stream: ClientStream,
        peer_addr: SocketAddr,
        receiver: UnboundedReceiver<Bytes>,
        ping_timeout: Duration,
    ) -> Self {
        Self {
            id,
            conn_id,
            stream,
            peer_addr,
            receiver,
            decoder: ProtocolDecoder::new(),
            ping_timeout,
        }
    }

    async fn write<T: AsyncWrite + Unpin>(
        stream: &mut T,
        data: Bytes,
        write_timeout: Duration,
    ) -> WriteResult {
        if data.is_empty() {
            return WriteResult::Ok;
        }
        match timeout(write_timeout, stream.write_all(&data)).await {
            Ok(Ok(())) => WriteResult::Ok,
            Ok(Err(_)) => WriteResult::IoError,
            Err(_) => WriteResult::TimedOut,
        }
    }

    async fn run(mut self, sender: UnboundedSender<ClientUpdate>) {
        use ClientUpdateData::*;
        let mut sender = ClientUpdateSender {
            client_id: self.id,
            conn_id: self.conn_id,
            sender,
        };
        let ping_timeout = self.ping_timeout;
        let ping_timer = tokio::time::sleep(ping_timeout);
        tokio::pin!(ping_timer);
        let mut ping_sent = false;

        loop {
            tokio::select! {
                client_message = self.decoder.read_from(&mut self.stream) => {
                    match client_message {
                        Ok(message) => {
                            if matches!(message, HwProtocolMessage::Pong) {
                                ping_sent = false;
                                ping_timer.as_mut().reset(Instant::now() + ping_timeout);
                            } else if !ping_sent {
                                ping_timer.as_mut().reset(Instant::now() + ping_timeout);
                            }
                            if !sender.send(Message(message)) {
                                break;
                            }
                        }
                        Err(e) => {
                            while let Ok(message) = self.receiver.try_recv() {
                                if Self::write(&mut self.stream, message, ping_timeout).await
                                    != WriteResult::Ok
                                {
                                    break;
                                }
                            }
                            sender.send(Error(format!("{}", e)));
                            break;
                        }
                    }
                }
                server_message = self.receiver.recv() => {
                    match server_message {
                        Some(message) => {
                            match Self::write(&mut self.stream, message, ping_timeout).await {
                                WriteResult::Ok => (),
                                WriteResult::IoError => {
                                    sender.send(Error("Connection reset by peer".to_string()));
                                    break;
                                }
                                WriteResult::TimedOut => {
                                    sender.send(PingTimeout);
                                    break;
                                }
                            }
                        }
                        None => {
                            let _ = timeout(ping_timeout, self.stream.shutdown()).await;
                            break;
                        }
                    }
                }
                () = &mut ping_timer => {
                    if ping_sent {
                        if sender.send(PingTimeout) {
                            while let Some(message) = self.receiver.recv().await {
                                if Self::write(&mut self.stream, message, ping_timeout).await
                                    != WriteResult::Ok
                                {
                                    break;
                                }
                            }
                            let _ = timeout(ping_timeout, self.stream.shutdown()).await;
                        }
                        break;
                    } else {
                        match Self::write(
                            &mut self.stream,
                            Bytes::from(HwServerMessage::Ping.to_raw_protocol()),
                            ping_timeout,
                        )
                        .await
                        {
                            WriteResult::Ok => {
                                if !sender.send(PingSent) {
                                    break;
                                }
                                ping_sent = true;
                                ping_timer.as_mut().reset(Instant::now() + ping_timeout);
                            }
                            WriteResult::IoError => {
                                sender.send(Error("Connection reset by peer".to_string()));
                                break;
                            }
                            WriteResult::TimedOut => {
                                sender.send(PingTimeout);
                                break;
                            }
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
    tls: Option<TlsListener>,
    #[cfg(feature = "official-server")]
    db: super::database::Database,
    server_state: ServerState,
    clients: Slab<(u64, UnboundedSender<Bytes>)>,
    next_conn_id: u64,
    update_tx: UnboundedSender<ClientUpdate>,
    update_rx: UnboundedReceiver<ClientUpdate>,
}

impl NetworkLayer {
    pub async fn run(&mut self) {
        async fn accept_plain_branch(
            layer: &mut NetworkLayer,
            value: (TcpStream, SocketAddr),
            update_tx: UnboundedSender<ClientUpdate>,
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
            update_tx: UnboundedSender<ClientUpdate>,
        ) {
            let (stream, addr) = value;
            let Some(ref tls) = layer.tls else {
                return;
            };
            match tls.acceptor.accept(stream).await {
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
            let Some(ClientUpdate {
                client_id,
                conn_id,
                data,
            }) = client_message
            else {
                return;
            };
            if layer.clients.get(client_id).map(|(cid, _)| *cid) != Some(conn_id) {
                return;
            }
            match data {
                Message(message) => {
                    layer.handle_message(client_id, message).await;
                }
                PingSent => {
                    handlers::handle_ping_sent(&mut layer.server_state, client_id);
                }
                PingTimeout => {
                    let mut response = handlers::Response::new(client_id);
                    info!("Client {} ping timeout", client_id);
                    response.remove_client(client_id);
                    handlers::handle_client_timed_out(
                        &mut layer.server_state,
                        client_id,
                        &mut response,
                    );
                    layer.handle_response(response).await;
                }
                Error(e) => {
                    let mut response = handlers::Response::new(client_id);
                    info!("Client {} error: {:?}", client_id, e);
                    response.remove_client(client_id);
                    handlers::handle_client_loss(&mut layer.server_state, client_id, &mut response);
                    layer.handle_response(response).await;
                }
            }
        }

        loop {
            #[cfg(not(feature = "tls-connections"))]
            tokio::select! {
                Ok(value) = self.listener.accept() => accept_plain_branch(self, value, self.update_tx.clone()).await,
                client_message = self.update_rx.recv(), if !self.clients.is_empty() => client_message_branch(self, client_message).await
            }

            #[cfg(feature = "tls-connections")]
            if self.tls.is_some() {
                tokio::select! {
                    Ok(value) = self.listener.accept() => accept_plain_branch(self, value, self.update_tx.clone()).await,
                    Ok(value) = self.tls.as_ref().unwrap().listener.accept() => accept_tls_branch(self, value, self.update_tx.clone()).await,
                    client_message = self.update_rx.recv(), if !self.clients.is_empty() => client_message_branch(self, client_message).await
                }
            } else {
                tokio::select! {
                    Ok(value) = self.listener.accept() => accept_plain_branch(self, value, self.update_tx.clone()).await,
                    client_message = self.update_rx.recv(), if !self.clients.is_empty() => client_message_branch(self, client_message).await
                }
            }
        }
    }

    async fn create_client(
        &mut self,
        stream: ClientStream,
        addr: SocketAddr,
    ) -> Option<NetworkClient> {
        self.next_conn_id += 1;
        let conn_id = self.next_conn_id;
        let entry = self.clients.vacant_entry();
        let client_id = entry.key();
        let (tx, rx) = unbounded_channel();
        entry.insert((conn_id, tx));

        let client = NetworkClient::new(client_id, conn_id, stream, addr, rx);

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
            tokio::spawn(async move {
                let mut client = client;
                while let Some(message) = client.receiver.recv().await {
                    if NetworkClient::write(&mut client.stream, message, PING_TIMEOUT).await
                        != WriteResult::Ok
                    {
                        break;
                    }
                }
                let _ = timeout(PING_TIMEOUT, client.stream.shutdown()).await;
            });
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
        while !response.is_empty() {
            debug!("{} pending server messages", response.len());
            let output = response.extract_messages(&self.server_state.server);
            for (clients, message) in output {
                debug!("Message {:?} to {:?}", message, clients);
                Self::send_message(&mut self.clients, message, clients.iter().cloned());
            }

            for client_id in response.extract_removed_clients() {
                if self.clients.contains(client_id) {
                    self.clients.remove(client_id);
                    info!("Client {} removed", client_id);
                }
            }

            let io_tasks: Vec<_> = response.extract_io_tasks().collect();
            let req_client_id = response.client_id();
            #[cfg(feature = "official-server")]
            for task in io_tasks {
                if let Some(io_result) = self.db.execute_task(task).await {
                    handlers::handle_io_result(
                        &mut self.server_state,
                        req_client_id,
                        &mut response,
                        io_result,
                    );
                }
            }
        }

        #[cfg(debug_assertions)]
        {
            for (client_id, _) in &self.clients {
                debug_assert!(
                    self.server_state.has_client(client_id),
                    "NetworkLayer client {} missing from ServerState",
                    client_id
                );
            }
            for client_id in self.server_state.anteroom.iter_client_ids() {
                debug_assert!(
                    self.clients.contains(client_id),
                    "Anteroom client {} missing from NetworkLayer",
                    client_id
                );
            }
            for client_id in self.server_state.server.iter_client_ids() {
                debug_assert!(
                    self.clients.contains(client_id),
                    "Server client {} missing from NetworkLayer",
                    client_id
                );
            }
            self.server_state.assert_invariants();
        }
    }

    fn send_message<I>(
        clients: &mut Slab<(u64, UnboundedSender<Bytes>)>,
        message: HwServerMessage,
        to_clients: I,
    ) where
        I: Iterator<Item = ClientId>,
    {
        let msg_string = message.to_raw_protocol();
        let bytes = Bytes::copy_from_slice(msg_string.as_bytes());
        for client_id in to_clients {
            if let Some((_, client)) = clients.get_mut(client_id) {
                let _ = client.send(bytes.clone());
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
        let (update_tx, update_rx) = unbounded_channel();

        #[cfg(feature = "official-server")]
        let db_url = std::env::var("HEDGEWARS_DB_URL")
            .ok()
            .or_else(|| server_state.config.as_ref().map(|c| c.database_url()))
            .unwrap_or_else(|| "mysql://hedgewars@127.0.0.1/hedgewars".to_string());

        NetworkLayer {
            listener: self.listener.expect("No listener provided"),
            #[cfg(feature = "tls-connections")]
            tls: match (self.tls_listener, self.tls_acceptor) {
                (Some(listener), Some(acceptor)) => Some(TlsListener { listener, acceptor }),
                _ => None,
            },
            #[cfg(feature = "official-server")]
            db: super::database::Database::new(&db_url),
            server_state,
            clients,
            next_conn_id: 0,
            update_tx,
            update_rx,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tokio::io::AsyncReadExt;

    #[tokio::test]
    async fn ping_timeout_deliver_bye_despite_server_broadcasts() {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();

        let connect_fut = TcpStream::connect(addr);
        let accept_fut = listener.accept();
        let (client_res, server_res) = tokio::join!(connect_fut, accept_fut);
        let mut peer_stream = client_res.unwrap();
        let (server_stream, peer_addr) = server_res.unwrap();

        let (tx, rx) = unbounded_channel();
        let (update_tx, mut update_rx) = unbounded_channel();

        let net_client = NetworkClient::with_timeout(
            1,
            1,
            ClientStream::Tcp(server_stream),
            peer_addr,
            rx,
            Duration::from_millis(80),
        );
        let client_task = tokio::spawn(net_client.run(update_tx));

        // Continuously send server messages faster than ping_timeout to verify
        // that server->client traffic does not reset the ping timer.
        let tx_spam = tx.clone();
        let spam_task = tokio::spawn(async move {
            for _ in 0..10 {
                tokio::time::sleep(Duration::from_millis(20)).await;
                let _ = tx_spam.send(Bytes::from("CHAT\n[server]\nhello\n\n"));
            }
        });

        // 1. Expect PingSent after ~80ms
        let first_update = timeout(Duration::from_millis(300), update_rx.recv())
            .await
            .expect("Timed out waiting for PingSent")
            .unwrap();
        assert!(matches!(first_update.data, ClientUpdateData::PingSent));

        // 2. Expect PingTimeout after another ~80ms
        let second_update = timeout(Duration::from_millis(300), update_rx.recv())
            .await
            .expect("Timed out waiting for PingTimeout")
            .unwrap();
        assert!(matches!(second_update.data, ClientUpdateData::PingTimeout));

        // Simulate NetworkLayer::handle_response sending BYE and removing the client (dropping tx)
        spam_task.abort();
        let _ = tx.send(Bytes::from(
            HwServerMessage::Bye("Ping timeout".to_string()).to_raw_protocol(),
        ));
        drop(tx);

        timeout(Duration::from_millis(300), client_task)
            .await
            .expect("Client task did not terminate")
            .unwrap();

        // Read all bytes received by the peer and verify PING and BYE\nPing timeout were delivered
        let mut received = String::new();
        peer_stream.read_to_string(&mut received).await.unwrap();
        assert!(
            received.contains("PING\n\n"),
            "Expected PING in stream, got: {:?}",
            received
        );
        assert!(
            received.ends_with("BYE\nPing timeout\n\n"),
            "Expected stream to end with BYE\\nPing timeout\\n\\n, got: {:?}",
            received
        );
    }

    #[tokio::test]
    async fn handle_client_timed_out_sends_ping_timeout_to_room_and_lobby() {
        let mut state = ServerState::new(16, 16);
        let mut response = handlers::Response::new(1);
        handlers::handle_client_accept(&mut state, 1, &mut response, [127, 0, 0, 1], true);
        handlers::handle(
            &mut state,
            1,
            &mut response,
            HwProtocolMessage::Nick("Alice".to_string(), None),
        );
        handlers::handle(&mut state, 1, &mut response, HwProtocolMessage::Proto(60));
        #[cfg(feature = "official-server")]
        handlers::handle_io_result(
            &mut state,
            1,
            &mut response,
            IoResult::AccountRegistered(false),
        );
        handlers::handle(
            &mut state,
            1,
            &mut response,
            HwProtocolMessage::CreateRoom("testroom".to_string(), None),
        );

        let mut response2 = handlers::Response::new(2);
        handlers::handle_client_accept(&mut state, 2, &mut response2, [127, 0, 0, 1], true);
        handlers::handle(
            &mut state,
            2,
            &mut response2,
            HwProtocolMessage::Nick("Bob".to_string(), None),
        );
        handlers::handle(&mut state, 2, &mut response2, HwProtocolMessage::Proto(60));
        #[cfg(feature = "official-server")]
        handlers::handle_io_result(
            &mut state,
            2,
            &mut response2,
            IoResult::AccountRegistered(false),
        );
        handlers::handle(
            &mut state,
            2,
            &mut response2,
            HwProtocolMessage::JoinRoom("testroom".to_string(), None),
        );

        let mut timeout_resp = handlers::Response::new(2);
        handlers::handle_client_timed_out(&mut state, 2, &mut timeout_resp);
        let messages: Vec<_> = timeout_resp.extract_messages(&state.server).collect();

        assert!(messages.iter().any(|(ids, msg)| {
            ids == &vec![1]
                && matches!(
                    msg,
                    HwServerMessage::RoomLeft(nick, reason)
                        if nick == "Bob" && reason == "Ping timeout"
                )
        }));
        assert!(messages.iter().any(|(ids, msg)| {
            ids == &vec![1]
                && matches!(
                    msg,
                    HwServerMessage::LobbyLeft(nick, reason)
                        if nick == "Bob" && reason == "Ping timeout"
                )
        }));
        assert!(messages.iter().any(|(ids, msg)| {
            ids == &vec![2]
                && matches!(
                    msg,
                    HwServerMessage::Bye(reason) if reason == "Ping timeout"
                )
        }));
    }
}
