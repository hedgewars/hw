extern crate slab;

use std::io::ErrorKind;
use mio::net::*;
use super::server::{HWServer, PendingMessage, Destination};
use super::client::ClientId;
use slab::Slab;

use mio::net::TcpStream;
use mio::*;
use std::io::Write;
use std::io;
use netbuf;

use utils;
use protocol::ProtocolDecoder;
use protocol::messages::*;
use std::net::SocketAddr;

pub struct NetworkClient {
    id: ClientId,
    socket: TcpStream,
    peer_addr: SocketAddr,
    decoder: ProtocolDecoder,
    buf_out: netbuf::Buf,
    closed: bool
}

impl NetworkClient {
    pub fn new(id: ClientId, socket: TcpStream, peer_addr: SocketAddr) -> NetworkClient {
        NetworkClient {
            id, socket, peer_addr,
            decoder: ProtocolDecoder::new(),
            buf_out: netbuf::Buf::new(),
            closed: false
        }
    }

    pub fn send_raw_msg(&mut self, msg: &[u8]) {
        self.buf_out.write(msg).unwrap();
        self.flush();
    }

    pub fn send_string(&mut self, msg: &String) {
        self.send_raw_msg(&msg.as_bytes());
    }

    pub fn send_msg(&mut self, msg: HWServerMessage) {
        self.send_string(&msg.to_raw_protocol());
    }

    fn flush(&mut self) {
        self.buf_out.write_to(&mut self.socket).unwrap();
        self.socket.flush().unwrap();
    }

    pub fn read_messages(&mut self) -> io::Result<Vec<HWProtocolMessage>> {
        let bytes_read = self.decoder.read_from(&mut self.socket)?;
        debug!("Read {} bytes", bytes_read);

        if bytes_read == 0 {
            self.closed = true;
            info!("EOF for client {} ({})", self.id, self.peer_addr);
        }

        Ok(self.decoder.extract_messages())
    }

    pub fn write_messages(&mut self) -> io::Result<()> {
        self.buf_out.write_to(&mut self.socket)?;
        Ok(())
    }
}

pub struct NetworkLayer {
    listener: TcpListener,
    server: HWServer,

    clients: Slab<NetworkClient>
}

impl NetworkLayer {
    pub fn new(listener: TcpListener, clients_limit: usize, rooms_limit: usize) -> NetworkLayer {
        let server = HWServer::new(clients_limit, rooms_limit);
        let clients = Slab::with_capacity(clients_limit);
        NetworkLayer {listener, server, clients}
    }

    pub fn register_server(&self, poll: &Poll) -> io::Result<()> {
        poll.register(&self.listener, utils::SERVER, Ready::readable(),
                      PollOpt::edge())
    }

    fn deregister_client(&mut self, poll: &Poll, id: ClientId) {
        let mut client_exists = false;
        if let Some(ref client) = self.clients.get_mut(id) {
            poll.deregister(&client.socket)
                .ok().expect("could not deregister socket");
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
            .ok().expect("could not register socket with event loop");

        let entry = self.clients.vacant_entry();
        let client = NetworkClient::new(id, client_socket, addr);
        info!("client {} ({}) added", client.id, client.peer_addr);
        entry.insert(client);
    }

    pub fn accept_client(&mut self, poll: &Poll) -> io::Result<()> {
        let (client_socket, addr) = self.listener.accept()?;
        info!("Connected: {}", addr);

        let client_id = self.server.add_client();
        self.register_client(poll, client_id, client_socket, addr);
        self.flush_server_messages();

        Ok(())
    }

    fn flush_server_messages(&mut self) {
        for PendingMessage(destination, msg) in self.server.output.drain(..) {
            match destination {
                Destination::ToSelf(id)  => {
                    if let Some(ref mut client) = self.clients.get_mut(id) {
                        client.send_msg(msg)
                    }
                }
                Destination::ToOthers(id) => {
                    let msg_string = msg.to_raw_protocol();
                    for item in self.clients.iter_mut() {
                        if item.0 != id {
                            item.1.send_string(&msg_string)
                        }
                    }
                }
            }
        }
    }

    pub fn client_readable(&mut self, poll: &Poll,
                           client_id: ClientId) -> io::Result<()> {
        let mut client_lost = false;
        let messages;
        if let Some(ref mut client) = self.clients.get_mut(client_id) {
            messages = match client.read_messages() {
                Ok(messages) => Some(messages),
                Err(ref error) if error.kind() == ErrorKind::WouldBlock => None,
                Err(error) => return Err(error)
            };
            if client.closed {
                client_lost = true;
            }
        } else {
            warn!("invalid readable client: {}", client_id);
            messages = None;
        };

        if client_lost {
            self.client_error(&poll, client_id)?;
        } else if let Some(msg) = messages {
            for message in msg {
                self.server.handle_msg(client_id, message);
            }
            self.flush_server_messages();
        }

        if !self.server.removed_clients.is_empty() {
            let ids = self.server.removed_clients.to_vec();
            self.server.removed_clients.clear();
            for client_id in ids {
                self.deregister_client(poll, client_id);
            }
        }

        Ok(())
    }

    pub fn client_writable(&mut self, poll: &Poll,
                           client_id: ClientId) -> io::Result<()> {
        if let Some(ref mut client) = self.clients.get_mut(client_id) {
            match client.write_messages() {
                Ok(_) => (),
                Err(ref error) if error.kind() == ErrorKind::WouldBlock => (),
                Err(error) => return Err(error)
            }
        } else {
            warn!("invalid writable client: {}", client_id);
        }

        Ok(())
    }

    pub fn client_error(&mut self, poll: &Poll,
                        client_id: ClientId) -> io::Result<()> {
        self.deregister_client(poll, client_id);
        self.server.client_lost(client_id);

        Ok(())
    }
}

