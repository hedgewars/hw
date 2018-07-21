extern crate slab;

use std::{
    io, io::{Error, ErrorKind, Write},
    net::{SocketAddr, IpAddr, Ipv4Addr},
    collections::HashSet,
    mem::{swap, replace}
};

use mio::{
    net::{TcpStream, TcpListener},
    Poll, PollOpt, Ready, Token
};
use netbuf;
use slab::Slab;

use utils;
use protocol::{ProtocolDecoder, messages::*};
use super::{
    server::{HWServer},
    coretypes::ClientId
};

const MAX_BYTES_PER_READ: usize = 2048;

#[derive(Hash, Eq, PartialEq, Copy, Clone)]
pub enum NetworkClientState {
    Idle,
    NeedsWrite,
    NeedsRead,
    Closed,
}

type NetworkResult<T> = io::Result<(T, NetworkClientState)>;

pub struct NetworkClient {
    id: ClientId,
    socket: TcpStream,
    peer_addr: SocketAddr,
    decoder: ProtocolDecoder,
    buf_out: netbuf::Buf
}

impl NetworkClient {
    pub fn new(id: ClientId, socket: TcpStream, peer_addr: SocketAddr) -> NetworkClient {
        NetworkClient {
            id, socket, peer_addr,
            decoder: ProtocolDecoder::new(),
            buf_out: netbuf::Buf::new()
        }
    }

    pub fn read_messages(&mut self) -> NetworkResult<Vec<HWProtocolMessage>> {
        let mut bytes_read = 0;
        let result = loop {
            match self.decoder.read_from(&mut self.socket) {
                Ok(bytes) => {
                    debug!("Client {}: read {} bytes", self.id, bytes);
                    bytes_read += bytes;
                    if bytes == 0 {
                        let result = if bytes_read == 0 {
                            info!("EOF for client {} ({})", self.id, self.peer_addr);
                            (Vec::new(), NetworkClientState::Closed)
                        } else {
                            (self.decoder.extract_messages(), NetworkClientState::NeedsRead)
                        };
                        break Ok(result);
                    }
                    else if bytes_read >= MAX_BYTES_PER_READ {
                        break Ok((self.decoder.extract_messages(), NetworkClientState::NeedsRead))
                    }
                }
                Err(ref error) if error.kind() == ErrorKind::WouldBlock => {
                    let messages =  if bytes_read == 0 {
                        Vec::new()
                    } else {
                        self.decoder.extract_messages()
                    };
                    break Ok((messages, NetworkClientState::Idle));
                }
                Err(error) =>
                    break Err(error)
            }
        };
        self.decoder.sweep();
        result
    }

    pub fn flush(&mut self) -> NetworkResult<()> {
        let result = loop {
            match self.buf_out.write_to(&mut self.socket) {
                Ok(bytes) if self.buf_out.is_empty() || bytes == 0 =>
                    break Ok(((), NetworkClientState::Idle)),
                Ok(_) => (),
                Err(ref error) if error.kind() == ErrorKind::Interrupted
                    || error.kind() == ErrorKind::WouldBlock => {
                    break Ok(((), NetworkClientState::NeedsWrite));
                },
                Err(error) =>
                    break Err(error)
            }
        };
        self.socket.flush()?;
        result
    }

    pub fn send_raw_msg(&mut self, msg: &[u8]) {
        self.buf_out.write_all(msg).unwrap();
    }

    pub fn send_string(&mut self, msg: &str) {
        self.send_raw_msg(&msg.as_bytes());
    }

    pub fn send_msg(&mut self, msg: &HWServerMessage) {
        self.send_string(&msg.to_raw_protocol());
    }
}

pub struct NetworkLayer {
    listener: TcpListener,
    server: HWServer,
    clients: Slab<NetworkClient>,
    pending: HashSet<(ClientId, NetworkClientState)>,
    pending_cache: Vec<(ClientId, NetworkClientState)>
}

impl NetworkLayer {
    pub fn new(listener: TcpListener, clients_limit: usize, rooms_limit: usize) -> NetworkLayer {
        let server = HWServer::new(clients_limit, rooms_limit);
        let clients = Slab::with_capacity(clients_limit);
        let pending = HashSet::with_capacity(2 * clients_limit);
        let pending_cache = Vec::with_capacity(2 * clients_limit);
        NetworkLayer {listener, server, clients, pending, pending_cache}
    }

    pub fn register_server(&self, poll: &Poll) -> io::Result<()> {
        poll.register(&self.listener, utils::SERVER, Ready::readable(),
                      PollOpt::edge())
    }

    fn deregister_client(&mut self, poll: &Poll, id: ClientId) {
        let mut client_exists = false;
        if let Some(ref client) = self.clients.get(id) {
            poll.deregister(&client.socket)
                .expect("could not deregister socket");
            info!("client {} ({}) removed", client.id, client.peer_addr);
            client_exists = true;
        }
        if client_exists {
            self.clients.remove(id);
        }
    }

    fn register_client(&mut self, poll: &Poll, id: ClientId, client_socket: TcpStream, addr: SocketAddr) {
        poll.register(&client_socket, Token(id),
                      Ready::readable() | Ready::writable(),
                      PollOpt::edge())
            .expect("could not register socket with event loop");

        let entry = self.clients.vacant_entry();
        let client = NetworkClient::new(id, client_socket, addr);
        info!("client {} ({}) added", client.id, client.peer_addr);
        entry.insert(client);
    }

    fn flush_server_messages(&mut self) {
        debug!("{} pending server messages", self.server.output.len());
        for (clients, message) in self.server.output.drain(..) {
            debug!("Message {:?} to {:?}", message, clients);
            let msg_string = message.to_raw_protocol();
            for client_id in clients {
                if let Some(client) = self.clients.get_mut(client_id) {
                    client.send_string(&msg_string);
                    self.pending.insert((client_id, NetworkClientState::NeedsWrite));
                }
            }
        }
    }

    pub fn accept_client(&mut self, poll: &Poll) -> io::Result<()> {
        let (client_socket, addr) = self.listener.accept()?;
        info!("Connected: {}", addr);

        let client_id = self.server.add_client();
        self.register_client(poll, client_id, client_socket, addr);
        self.flush_server_messages();

        Ok(())
    }

    fn operation_failed(&mut self, poll: &Poll, client_id: ClientId, error: &Error, msg: &str) -> io::Result<()> {
        let addr = if let Some(ref mut client) = self.clients.get_mut(client_id) {
            client.peer_addr
        } else {
            SocketAddr::new(IpAddr::V4(Ipv4Addr::new(0, 0, 0, 0)), 0)
        };
        debug!("{}({}): {}", msg, addr, error);
        self.client_error(poll, client_id)
    }

    pub fn client_readable(&mut self, poll: &Poll,
                           client_id: ClientId) -> io::Result<()> {
        let messages =
            if let Some(ref mut client) = self.clients.get_mut(client_id) {
                client.read_messages()
            } else {
                warn!("invalid readable client: {}", client_id);
                Ok((Vec::new(), NetworkClientState::Idle))
            };

        match messages {
            Ok((messages, state)) => {
                for message in messages {
                    self.server.handle_msg(client_id, message);
                }
                match state {
                    NetworkClientState::NeedsRead => {
                        self.pending.insert((client_id, state));
                    },
                    NetworkClientState::Closed =>
                        self.client_error(&poll, client_id)?,
                    _ => {}
                };
            }
            Err(e) => self.operation_failed(
                poll, client_id, &e,
                "Error while reading from client socket")?
        }

        self.flush_server_messages();

        if !self.server.removed_clients.is_empty() {
            let ids: Vec<_> = self.server.removed_clients.drain(..).collect();
            for client_id in ids {
                self.deregister_client(poll, client_id);
            }
        }

        Ok(())
    }

    pub fn client_writable(&mut self, poll: &Poll,
                           client_id: ClientId) -> io::Result<()> {
        let result =
            if let Some(ref mut client) = self.clients.get_mut(client_id) {
                client.flush()
            } else {
                warn!("invalid writable client: {}", client_id);
                Ok(((), NetworkClientState::Idle))
            };

        match result {
            Ok(((), state)) if state == NetworkClientState::NeedsWrite => {
                self.pending.insert((client_id, state));
            },
            Ok(_) => {}
            Err(e) => self.operation_failed(
                poll, client_id, &e,
                "Error while writing to client socket")?
        }

        Ok(())
    }

    pub fn client_error(&mut self, poll: &Poll,
                        client_id: ClientId) -> io::Result<()> {
        self.deregister_client(poll, client_id);
        self.server.client_lost(client_id);

        Ok(())
    }

    pub fn has_pending_operations(&self) -> bool {
        !self.pending.is_empty()
    }

    pub fn on_idle(&mut self, poll: &Poll) -> io::Result<()> {
        if self.has_pending_operations() {
            let mut cache = replace(&mut self.pending_cache, Vec::new());
            cache.extend(self.pending.drain());
            for (id, state) in cache.drain(..) {
                match state {
                    NetworkClientState::NeedsRead =>
                        self.client_readable(poll, id)?,
                    NetworkClientState::NeedsWrite =>
                        self.client_writable(poll, id)?,
                    _ => {}
                }
            }
            swap(&mut cache, &mut self.pending_cache);
        }
        Ok(())
    }
}
