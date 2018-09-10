extern crate slab;

use std::{
    io, io::{Error, ErrorKind, Read, Write},
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

use crate::{
    utils,
    protocol::{ProtocolDecoder, messages::*}
};
use super::{
    server::{HWServer},
    coretypes::ClientId
};
#[cfg(feature = "tls-connections")]
use openssl::{
    ssl::{
        SslMethod, SslContext, Ssl, SslContextBuilder,
        SslVerifyMode, SslFiletype, SslOptions,
        SslStreamBuilder, HandshakeError, MidHandshakeSslStream, SslStream
    },
    error::ErrorStack
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

#[cfg(not(feature = "tls-connections"))]
pub enum ClientSocket {
    Plain(TcpStream)
}

#[cfg(feature = "tls-connections")]
pub enum ClientSocket {
    SslHandshake(Option<MidHandshakeSslStream<TcpStream>>),
    SslStream(SslStream<TcpStream>)
}

impl ClientSocket {
    fn inner(&self) -> &TcpStream {
        #[cfg(not(feature = "tls-connections"))]
        match self {
            ClientSocket::Plain(stream) => stream,
        }

        #[cfg(feature = "tls-connections")]
        match self {
            ClientSocket::SslHandshake(Some(builder)) => builder.get_ref(),
            ClientSocket::SslHandshake(None) => unreachable!(),
            ClientSocket::SslStream(ssl_stream) => ssl_stream.get_ref()
        }
    }
}

pub struct NetworkClient {
    id: ClientId,
    socket: ClientSocket,
    peer_addr: SocketAddr,
    decoder: ProtocolDecoder,
    buf_out: netbuf::Buf
}

impl NetworkClient {
    pub fn new(id: ClientId, socket: ClientSocket, peer_addr: SocketAddr) -> NetworkClient {
        NetworkClient {
            id, socket, peer_addr,
            decoder: ProtocolDecoder::new(),
            buf_out: netbuf::Buf::new()
        }
    }

    #[cfg(feature = "tls-connections")]
    fn handshake_impl(&mut self, handshake: MidHandshakeSslStream<TcpStream>) -> io::Result<NetworkClientState> {
        match handshake.handshake() {
            Ok(stream) => {
                self.socket = ClientSocket::SslStream(stream);
                debug!("TLS handshake with {} ({}) completed", self.id, self.peer_addr);
                Ok(NetworkClientState::Idle)
            }
            Err(HandshakeError::WouldBlock(new_handshake)) => {
                self.socket = ClientSocket::SslHandshake(Some(new_handshake));
                Ok(NetworkClientState::Idle)
            }
            Err(HandshakeError::Failure(new_handshake)) => {
                self.socket = ClientSocket::SslHandshake(Some(new_handshake));
                debug!("TLS handshake with {} ({}) failed", self.id, self.peer_addr);
                Err(Error::new(ErrorKind::Other, "Connection failure"))
            }
            Err(HandshakeError::SetupFailure(_)) => unreachable!()
        }
    }

    fn read_impl<R: Read>(decoder: &mut ProtocolDecoder, source: &mut R,
                          id: ClientId, addr: &SocketAddr) -> NetworkResult<Vec<HWProtocolMessage>> {
        let mut bytes_read = 0;
        let result = loop {
            match decoder.read_from(source) {
                Ok(bytes) => {
                    debug!("Client {}: read {} bytes", id, bytes);
                    bytes_read += bytes;
                    if bytes == 0 {
                        let result = if bytes_read == 0 {
                            info!("EOF for client {} ({})", id, addr);
                            (Vec::new(), NetworkClientState::Closed)
                        } else {
                            (decoder.extract_messages(), NetworkClientState::NeedsRead)
                        };
                        break Ok(result);
                    }
                    else if bytes_read >= MAX_BYTES_PER_READ {
                        break Ok((decoder.extract_messages(), NetworkClientState::NeedsRead))
                    }
                }
                Err(ref error) if error.kind() == ErrorKind::WouldBlock => {
                    let messages =  if bytes_read == 0 {
                        Vec::new()
                    } else {
                        decoder.extract_messages()
                    };
                    break Ok((messages, NetworkClientState::Idle));
                }
                Err(error) =>
                    break Err(error)
            }
        };
        decoder.sweep();
        result
    }

    pub fn read(&mut self) -> NetworkResult<Vec<HWProtocolMessage>> {
        #[cfg(not(feature = "tls-connections"))]
        match self.socket {
            ClientSocket::Plain(ref mut stream) =>
                NetworkClient::read_impl(&mut self.decoder, stream, self.id, &self.peer_addr),
        }

        #[cfg(feature = "tls-connections")]
        match self.socket {
            ClientSocket::SslHandshake(ref mut handshake_opt) => {
                let handshake = std::mem::replace(handshake_opt, None).unwrap();
                Ok((Vec::new(), self.handshake_impl(handshake)?))
            },
            ClientSocket::SslStream(ref mut stream) =>
                NetworkClient::read_impl(&mut self.decoder, stream, self.id, &self.peer_addr)
        }
    }

    fn write_impl<W: Write>(buf_out: &mut netbuf::Buf, destination: &mut W) -> NetworkResult<()> {
        let result = loop {
            match buf_out.write_to(destination) {
                Ok(bytes) if buf_out.is_empty() || bytes == 0 =>
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
        result
    }

    pub fn write(&mut self) -> NetworkResult<()> {
        let result = {
            #[cfg(not(feature = "tls-connections"))]
            match self.socket {
                ClientSocket::Plain(ref mut stream) =>
                    NetworkClient::write_impl(&mut self.buf_out, stream)
            }

            #[cfg(feature = "tls-connections")] {
                match self.socket {
                    ClientSocket::SslHandshake(ref mut handshake_opt) => {
                        let handshake = std::mem::replace(handshake_opt, None).unwrap();
                        Ok(((), self.handshake_impl(handshake)?))
                    }
                    ClientSocket::SslStream(ref mut stream) =>
                        NetworkClient::write_impl(&mut self.buf_out, stream)
                }
            }
        };

        self.socket.inner().flush()?;
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

#[cfg(feature = "tls-connections")]
struct ServerSsl {
    context: SslContext
}

pub struct NetworkLayer {
    listener: TcpListener,
    server: HWServer,
    clients: Slab<NetworkClient>,
    pending: HashSet<(ClientId, NetworkClientState)>,
    pending_cache: Vec<(ClientId, NetworkClientState)>,
    #[cfg(feature = "tls-connections")]
    ssl: ServerSsl
}

impl NetworkLayer {
    pub fn new(listener: TcpListener, clients_limit: usize, rooms_limit: usize) -> NetworkLayer {
        let server = HWServer::new(clients_limit, rooms_limit);
        let clients = Slab::with_capacity(clients_limit);
        let pending = HashSet::with_capacity(2 * clients_limit);
        let pending_cache = Vec::with_capacity(2 * clients_limit);

        NetworkLayer {
            listener, server, clients, pending, pending_cache,
            #[cfg(feature = "tls-connections")]
            ssl: NetworkLayer::create_ssl_context()
        }
    }

    #[cfg(feature = "tls-connections")]
    fn create_ssl_context() -> ServerSsl {
        let mut builder = SslContextBuilder::new(SslMethod::tls()).unwrap();
        builder.set_verify(SslVerifyMode::NONE);
        builder.set_read_ahead(true);
        builder.set_certificate_file("ssl/cert.pem", SslFiletype::PEM).unwrap();
        builder.set_private_key_file("ssl/key.pem", SslFiletype::PEM).unwrap();
        builder.set_options(SslOptions::NO_COMPRESSION);
        builder.set_cipher_list("DEFAULT:!LOW:!RC4:!EXP").unwrap();
        ServerSsl { context: builder.build() }
    }

    pub fn register_server(&self, poll: &Poll) -> io::Result<()> {
        poll.register(&self.listener, utils::SERVER, Ready::readable(),
                      PollOpt::edge())
    }

    fn deregister_client(&mut self, poll: &Poll, id: ClientId) {
        let mut client_exists = false;
        if let Some(ref client) = self.clients.get(id) {
            poll.deregister(client.socket.inner())
                .expect("could not deregister socket");
            info!("client {} ({}) removed", client.id, client.peer_addr);
            client_exists = true;
        }
        if client_exists {
            self.clients.remove(id);
        }
    }

    fn register_client(&mut self, poll: &Poll, id: ClientId, client_socket: ClientSocket, addr: SocketAddr) {
        poll.register(client_socket.inner(), Token(id),
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

    fn create_client_socket(&self, socket: TcpStream) -> io::Result<ClientSocket> {
        #[cfg(not(feature = "tls-connections"))] {
            Ok(ClientSocket::Plain(socket))
        }

        #[cfg(feature = "tls-connections")] {
            let ssl = Ssl::new(&self.ssl.context).unwrap();
            let mut builder = SslStreamBuilder::new(ssl, socket);
            builder.set_accept_state();
            match builder.handshake() {
                Ok(stream) =>
                    Ok(ClientSocket::SslStream(stream)),
                Err(HandshakeError::WouldBlock(stream)) =>
                    Ok(ClientSocket::SslHandshake(Some(stream))),
                Err(e) => {
                    debug!("OpenSSL handshake failed: {}", e);
                    Err(Error::new(ErrorKind::Other, "Connection failure"))
                }
            }
        }
    }

    pub fn accept_client(&mut self, poll: &Poll) -> io::Result<()> {
        let (client_socket, addr) = self.listener.accept()?;
        info!("Connected: {}", addr);

        let client_id = self.server.add_client();
        self.register_client(poll, client_id, self.create_client_socket(client_socket)?, addr);
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
                client.read()
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
                client.write()
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
