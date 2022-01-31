use bytes::{Buf, Bytes};
use log::*;
use slab::Slab;
use std::{
    collections::HashSet,
    io,
    io::{Error, ErrorKind, Read, Write},
    iter::Iterator,
    mem::{replace, swap},
    net::{IpAddr, Ipv4Addr, SocketAddr},
    num::NonZeroU32,
    time::Duration,
    time::Instant,
};
use tokio::{
    io::AsyncReadExt,
    net::{TcpListener, TcpStream},
    sync::mpsc::{channel, Receiver, Sender},
};

use crate::{
    core::{
        events::{TimedEvents, Timeout},
        types::ClientId,
    },
    handlers,
    handlers::{IoResult, IoTask, ServerState},
    protocol::ProtocolDecoder,
    utils,
};
use hedgewars_network_protocol::{
    messages::HwServerMessage::Redirect, messages::*, parser::server_message,
};
use tokio::io::AsyncWriteExt;

enum ClientUpdateData {
    Message(HwProtocolMessage),
    Error(String),
}

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

struct NetworkClient {
    id: ClientId,
    socket: TcpStream,
    receiver: Receiver<Bytes>,
    peer_addr: SocketAddr,
    decoder: ProtocolDecoder,
}

impl NetworkClient {
    fn new(
        id: ClientId,
        socket: TcpStream,
        peer_addr: SocketAddr,
        receiver: Receiver<Bytes>,
    ) -> Self {
        Self {
            id,
            socket,
            peer_addr,
            receiver,
            decoder: ProtocolDecoder::new(),
        }
    }

    async fn read(&mut self) -> Option<HwProtocolMessage> {
        self.decoder.read_from(&mut self.socket).await
    }

    async fn write(&mut self, mut data: Bytes) -> bool {
        !data.has_remaining() || matches!(self.socket.write_buf(&mut data).await, Ok(n) if n > 0)
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
                        Some(message) => if !self.write(message).await {
                            sender.send(Error("Connection reset by peer".to_string())).await;
                            break;
                        }
                        None => {
                            break;
                        }
                    }
                }
                client_message = self.decoder.read_from(&mut self.socket) => {
                     match client_message {
                        Some(message) => {
                            if !sender.send(Message(message)).await {
                                break;
                            }
                        }
                        None => {
                            sender.send(Error("Connection reset by peer".to_string())).await;
                            break;
                        }
                    }
                }
            }
        }
    }
}

pub struct NetworkLayer {
    listener: TcpListener,
    server_state: ServerState,
    clients: Slab<Sender<Bytes>>,
}

impl NetworkLayer {
    pub async fn run(&mut self) {
        let (update_tx, mut update_rx) = channel(128);

        loop {
            tokio::select! {
                Ok((stream, addr)) = self.listener.accept() => {
                    if let Some(client) = self.create_client(stream, addr).await {
                        tokio::spawn(client.run(update_tx.clone()));
                    }
                }
                client_message = update_rx.recv(), if !self.clients.is_empty() => {
                    use ClientUpdateData::*;
                    match client_message {
                        Some(ClientUpdate{ client_id, data: Message(message) } ) => {
                            self.handle_message(client_id, message).await;
                        }
                        Some(ClientUpdate{ client_id, .. } ) => {
                            let mut response = handlers::Response::new(client_id);
                            handlers::handle_client_loss(&mut self.server_state, client_id, &mut response);
                            self.handle_response(response).await;
                        }
                        None => unreachable!()
                    }
                }
            }
        }
    }

    async fn create_client(
        &mut self,
        stream: TcpStream,
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

        debug!("{} pending server messages", response.len());
        let output = response.extract_messages(&mut self.server_state.server);
        for (clients, message) in output {
            debug!("Message {:?} to {:?}", message, clients);
            Self::send_message(&mut self.clients, message, clients.iter().cloned()).await;
        }

        for client_id in response.extract_removed_clients() {
            if self.clients.contains(client_id) {
                self.clients.remove(client_id);
            }
            info!("Client {} removed", client_id);
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
    clients_capacity: usize,
    rooms_capacity: usize,
}

impl Default for NetworkLayerBuilder {
    fn default() -> Self {
        Self {
            clients_capacity: 1024,
            rooms_capacity: 512,
            listener: None,
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

    pub fn build(self) -> NetworkLayer {
        let server_state = ServerState::new(self.clients_capacity, self.rooms_capacity);

        let clients = Slab::with_capacity(self.clients_capacity);

        NetworkLayer {
            listener: self.listener.expect("No listener provided"),
            server_state,
            clients,
        }
    }
}
