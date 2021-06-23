extern crate slab;

use std::{
    collections::HashSet,
    io,
    io::{Error, ErrorKind, Read, Write},
    mem::{replace, swap},
    net::{IpAddr, Ipv4Addr, SocketAddr},
    num::NonZeroU32,
    time::Duration,
    time::Instant,
};

use log::*;
use mio::{
    event::Source,
    net::{TcpListener, TcpStream},
    Interest, Poll, Token, Waker,
};
use netbuf;
use slab::Slab;

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
use hedgewars_network_protocol::{messages::HwServerMessage::Redirect, messages::*};

#[cfg(feature = "official-server")]
use super::io::{IoThread, RequestId};

#[cfg(feature = "tls-connections")]
use openssl::{
    error::ErrorStack,
    ssl::{
        HandshakeError, MidHandshakeSslStream, Ssl, SslContext, SslContextBuilder, SslFiletype,
        SslMethod, SslOptions, SslStream, SslStreamBuilder, SslVerifyMode,
    },
};

const MAX_BYTES_PER_READ: usize = 2048;
const SEND_PING_TIMEOUT: Duration = Duration::from_secs(5);
const DROP_CLIENT_TIMEOUT: Duration = Duration::from_secs(5);
const MAX_TIMEOUT: usize = DROP_CLIENT_TIMEOUT.as_secs() as usize;
const PING_PROBES_COUNT: u8 = 2;

#[derive(Hash, Eq, PartialEq, Copy, Clone)]
pub enum NetworkClientState {
    Idle,
    NeedsWrite,
    NeedsRead,
    Closed,
    #[cfg(feature = "tls-connections")]
    Connected,
}

type NetworkResult<T> = io::Result<(T, NetworkClientState)>;

pub enum ClientSocket {
    Plain(TcpStream),
    #[cfg(feature = "tls-connections")]
    SslHandshake(Option<MidHandshakeSslStream<TcpStream>>),
    #[cfg(feature = "tls-connections")]
    SslStream(SslStream<TcpStream>),
}

impl ClientSocket {
    fn inner_mut(&mut self) -> &mut TcpStream {
        match self {
            ClientSocket::Plain(stream) => stream,
            #[cfg(feature = "tls-connections")]
            ClientSocket::SslHandshake(Some(builder)) => builder.get_mut(),
            #[cfg(feature = "tls-connections")]
            ClientSocket::SslHandshake(None) => unreachable!(),
            #[cfg(feature = "tls-connections")]
            ClientSocket::SslStream(ssl_stream) => ssl_stream.get_mut(),
        }
    }
}

pub struct NetworkClient {
    id: ClientId,
    socket: ClientSocket,
    peer_addr: SocketAddr,
    decoder: ProtocolDecoder,
    buf_out: netbuf::Buf,
    pending_close: bool,
    timeout: Timeout,
    last_rx_time: Instant,
}

impl NetworkClient {
    pub fn new(
        id: ClientId,
        socket: ClientSocket,
        peer_addr: SocketAddr,
        timeout: Timeout,
    ) -> NetworkClient {
        NetworkClient {
            id,
            socket,
            peer_addr,
            decoder: ProtocolDecoder::new(),
            buf_out: netbuf::Buf::new(),
            pending_close: false,
            timeout,
            last_rx_time: Instant::now(),
        }
    }

    #[cfg(feature = "tls-connections")]
    fn handshake_impl(
        &mut self,
        handshake: MidHandshakeSslStream<TcpStream>,
    ) -> io::Result<NetworkClientState> {
        match handshake.handshake() {
            Ok(stream) => {
                self.socket = ClientSocket::SslStream(stream);
                debug!(
                    "TLS handshake with {} ({}) completed",
                    self.id, self.peer_addr
                );
                Ok(NetworkClientState::Connected)
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
            Err(HandshakeError::SetupFailure(_)) => unreachable!(),
        }
    }

    fn read_impl<R: Read>(
        decoder: &mut ProtocolDecoder,
        source: &mut R,
        id: ClientId,
        addr: &SocketAddr,
    ) -> NetworkResult<Vec<HwProtocolMessage>> {
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
                    } else if bytes_read >= MAX_BYTES_PER_READ {
                        break Ok((decoder.extract_messages(), NetworkClientState::NeedsRead));
                    }
                }
                Err(ref error) if error.kind() == ErrorKind::WouldBlock => {
                    let messages = if bytes_read == 0 {
                        Vec::new()
                    } else {
                        decoder.extract_messages()
                    };
                    break Ok((messages, NetworkClientState::Idle));
                }
                Err(error) => break Err(error),
            }
        };
        result
    }

    pub fn read(&mut self) -> NetworkResult<Vec<HwProtocolMessage>> {
        let result = match self.socket {
            ClientSocket::Plain(ref mut stream) => {
                NetworkClient::read_impl(&mut self.decoder, stream, self.id, &self.peer_addr)
            }
            #[cfg(feature = "tls-connections")]
            ClientSocket::SslHandshake(ref mut handshake_opt) => {
                let handshake = std::mem::replace(handshake_opt, None).unwrap();
                Ok((Vec::new(), self.handshake_impl(handshake)?))
            }
            #[cfg(feature = "tls-connections")]
            ClientSocket::SslStream(ref mut stream) => {
                NetworkClient::read_impl(&mut self.decoder, stream, self.id, &self.peer_addr)
            }
        };

        if let Ok(_) = result {
            self.last_rx_time = Instant::now();
        }

        result
    }

    fn write_impl<W: Write>(
        buf_out: &mut netbuf::Buf,
        destination: &mut W,
        close_on_empty: bool,
    ) -> NetworkResult<()> {
        let result = loop {
            match buf_out.write_to(destination) {
                Ok(bytes) if buf_out.is_empty() || bytes == 0 => {
                    let status = if buf_out.is_empty() && close_on_empty {
                        NetworkClientState::Closed
                    } else {
                        NetworkClientState::Idle
                    };
                    break Ok(((), status));
                }
                Ok(_) => (),
                Err(ref error)
                    if error.kind() == ErrorKind::Interrupted
                        || error.kind() == ErrorKind::WouldBlock =>
                {
                    break Ok(((), NetworkClientState::NeedsWrite));
                }
                Err(error) => break Err(error),
            }
        };
        result
    }

    pub fn write(&mut self) -> NetworkResult<()> {
        let result = match self.socket {
            ClientSocket::Plain(ref mut stream) => {
                NetworkClient::write_impl(&mut self.buf_out, stream, self.pending_close)
            }
            #[cfg(feature = "tls-connections")]
            ClientSocket::SslHandshake(ref mut handshake_opt) => {
                let handshake = std::mem::replace(handshake_opt, None).unwrap();
                Ok(((), self.handshake_impl(handshake)?))
            }
            #[cfg(feature = "tls-connections")]
            ClientSocket::SslStream(ref mut stream) => {
                NetworkClient::write_impl(&mut self.buf_out, stream, self.pending_close)
            }
        };

        self.socket.inner_mut().flush()?;
        result
    }

    pub fn send_raw_msg(&mut self, msg: &[u8]) {
        self.buf_out.write_all(msg).unwrap();
    }

    pub fn send_string(&mut self, msg: &str) {
        self.send_raw_msg(&msg.as_bytes());
    }

    pub fn replace_timeout(&mut self, timeout: Timeout) -> Timeout {
        replace(&mut self.timeout, timeout)
    }

    pub fn has_pending_sends(&self) -> bool {
        !self.buf_out.is_empty()
    }
}

#[cfg(feature = "tls-connections")]
struct ServerSsl {
    listener: TcpListener,
    context: SslContext,
}

#[cfg(feature = "official-server")]
pub struct IoLayer {
    next_request_id: RequestId,
    request_queue: Vec<(RequestId, ClientId)>,
    io_thread: IoThread,
}

#[cfg(feature = "official-server")]
impl IoLayer {
    fn new(waker: Waker) -> Self {
        Self {
            next_request_id: 0,
            request_queue: vec![],
            io_thread: IoThread::new(waker),
        }
    }

    fn send(&mut self, client_id: ClientId, task: IoTask) {
        let request_id = self.next_request_id;
        self.next_request_id += 1;
        self.request_queue.push((request_id, client_id));
        self.io_thread.send(request_id, task);
    }

    fn try_recv(&mut self) -> Option<(ClientId, IoResult)> {
        let (request_id, result) = self.io_thread.try_recv()?;
        if let Some(index) = self
            .request_queue
            .iter()
            .position(|(id, _)| *id == request_id)
        {
            let (_, client_id) = self.request_queue.swap_remove(index);
            Some((client_id, result))
        } else {
            None
        }
    }

    fn cancel(&mut self, client_id: ClientId) {
        let mut index = 0;
        while index < self.request_queue.len() {
            if self.request_queue[index].1 == client_id {
                self.request_queue.swap_remove(index);
            } else {
                index += 1;
            }
        }
    }
}

enum TimeoutEvent {
    SendPing { probes_count: u8 },
    DropClient,
}

struct TimerData(TimeoutEvent, ClientId);
type NetworkTimeoutEvents = TimedEvents<TimerData, MAX_TIMEOUT>;

pub struct NetworkLayer {
    listener: TcpListener,
    server_state: ServerState,
    clients: Slab<NetworkClient>,
    pending: HashSet<(ClientId, NetworkClientState)>,
    pending_cache: Vec<(ClientId, NetworkClientState)>,
    #[cfg(feature = "tls-connections")]
    ssl: ServerSsl,
    #[cfg(feature = "official-server")]
    io: IoLayer,
    timeout_events: NetworkTimeoutEvents,
}

fn register_read<S: Source>(poll: &Poll, source: &mut S, token: mio::Token) -> io::Result<()> {
    poll.registry().register(source, token, Interest::READABLE)
}

fn create_ping_timeout(
    timeout_events: &mut NetworkTimeoutEvents,
    probes_count: u8,
    client_id: ClientId,
) -> Timeout {
    timeout_events.set_timeout(
        NonZeroU32::new(SEND_PING_TIMEOUT.as_secs() as u32).unwrap(),
        TimerData(TimeoutEvent::SendPing { probes_count }, client_id),
    )
}

fn create_drop_timeout(timeout_events: &mut NetworkTimeoutEvents, client_id: ClientId) -> Timeout {
    timeout_events.set_timeout(
        NonZeroU32::new(DROP_CLIENT_TIMEOUT.as_secs() as u32).unwrap(),
        TimerData(TimeoutEvent::DropClient, client_id),
    )
}

impl NetworkLayer {
    pub fn register(&mut self, poll: &Poll) -> io::Result<()> {
        register_read(poll, &mut self.listener, utils::SERVER_TOKEN)?;
        #[cfg(feature = "tls-connections")]
        register_read(poll, &mut self.ssl.listener, utils::SECURE_SERVER_TOKEN)?;

        Ok(())
    }

    fn deregister_client(&mut self, poll: &Poll, id: ClientId, is_error: bool) {
        if let Some(ref mut client) = self.clients.get_mut(id) {
            poll.registry()
                .deregister(client.socket.inner_mut())
                .expect("could not deregister socket");
            if client.has_pending_sends() && !is_error {
                info!(
                    "client {} ({}) pending removal",
                    client.id, client.peer_addr
                );
                client.pending_close = true;
                poll.registry()
                    .register(client.socket.inner_mut(), Token(id), Interest::WRITABLE)
                    .unwrap_or_else(|_| {
                        self.clients.remove(id);
                    });
            } else {
                info!("client {} ({}) removed", client.id, client.peer_addr);
                self.clients.remove(id);
            }
            #[cfg(feature = "official-server")]
            self.io.cancel(id);
        }
    }

    fn register_client(
        &mut self,
        poll: &Poll,
        mut client_socket: ClientSocket,
        addr: SocketAddr,
    ) -> io::Result<ClientId> {
        let entry = self.clients.vacant_entry();
        let client_id = entry.key();

        poll.registry().register(
            client_socket.inner_mut(),
            Token(client_id),
            Interest::READABLE | Interest::WRITABLE,
        )?;

        let client = NetworkClient::new(
            client_id,
            client_socket,
            addr,
            create_ping_timeout(&mut self.timeout_events, PING_PROBES_COUNT - 1, client_id),
        );
        info!("client {} ({}) added", client.id, client.peer_addr);
        entry.insert(client);

        Ok(client_id)
    }

    fn handle_response(&mut self, mut response: handlers::Response, poll: &Poll) {
        if response.is_empty() {
            return;
        }

        debug!("{} pending server messages", response.len());
        let output = response.extract_messages(&mut self.server_state.server);
        for (clients, message) in output {
            debug!("Message {:?} to {:?}", message, clients);
            let msg_string = message.to_raw_protocol();
            for client_id in clients {
                if let Some(client) = self.clients.get_mut(client_id) {
                    client.send_string(&msg_string);
                    self.pending
                        .insert((client_id, NetworkClientState::NeedsWrite));
                }
            }
        }

        for client_id in response.extract_removed_clients() {
            self.deregister_client(poll, client_id, false);
        }

        #[cfg(feature = "official-server")]
        {
            let client_id = response.client_id();
            for task in response.extract_io_tasks() {
                self.io.send(client_id, task);
            }
        }
    }

    pub fn handle_timeout(&mut self, poll: &mut Poll) -> io::Result<()> {
        for TimerData(event, client_id) in self.timeout_events.poll(Instant::now()) {
            if let Some(client) = self.clients.get_mut(client_id) {
                if client.last_rx_time.elapsed() > SEND_PING_TIMEOUT {
                    match event {
                        TimeoutEvent::SendPing { probes_count } => {
                            client.send_string(&HwServerMessage::Ping.to_raw_protocol());
                            client.write()?;
                            let timeout = if probes_count != 0 {
                                create_ping_timeout(
                                    &mut self.timeout_events,
                                    probes_count - 1,
                                    client_id,
                                )
                            } else {
                                create_drop_timeout(&mut self.timeout_events, client_id)
                            };
                            client.replace_timeout(timeout);
                        }
                        TimeoutEvent::DropClient => {
                            client.send_string(
                                &HwServerMessage::Bye("Ping timeout".to_string()).to_raw_protocol(),
                            );
                            let _res = client.write();

                            self.operation_failed(
                                poll,
                                client_id,
                                &ErrorKind::TimedOut.into(),
                                "No ping response",
                            )?;
                        }
                    }
                } else {
                    client.replace_timeout(create_ping_timeout(
                        &mut self.timeout_events,
                        PING_PROBES_COUNT - 1,
                        client_id,
                    ));
                }
            }
        }
        Ok(())
    }

    #[cfg(feature = "official-server")]
    pub fn handle_io_result(&mut self, poll: &Poll) -> io::Result<()> {
        while let Some((client_id, result)) = self.io.try_recv() {
            debug!("Handling io result {:?} for client {}", result, client_id);
            let mut response = handlers::Response::new(client_id);
            handlers::handle_io_result(&mut self.server_state, client_id, &mut response, result);
            self.handle_response(response, poll);
        }
        Ok(())
    }

    fn create_client_socket(&self, socket: TcpStream) -> io::Result<ClientSocket> {
        Ok(ClientSocket::Plain(socket))
    }

    #[cfg(feature = "tls-connections")]
    fn create_client_secure_socket(&self, socket: TcpStream) -> io::Result<ClientSocket> {
        let ssl = Ssl::new(&self.ssl.context).unwrap();
        let mut builder = SslStreamBuilder::new(ssl, socket);
        builder.set_accept_state();
        match builder.handshake() {
            Ok(stream) => Ok(ClientSocket::SslStream(stream)),
            Err(HandshakeError::WouldBlock(stream)) => Ok(ClientSocket::SslHandshake(Some(stream))),
            Err(e) => {
                debug!("OpenSSL handshake failed: {}", e);
                Err(Error::new(ErrorKind::Other, "Connection failure"))
            }
        }
    }

    fn init_client(&mut self, poll: &Poll, client_id: ClientId) {
        let mut response = handlers::Response::new(client_id);

        if let ClientSocket::Plain(_) = self.clients[client_id].socket {
            #[cfg(feature = "tls-connections")]
            response.add(Redirect(self.ssl.listener.local_addr().unwrap().port()).send_self())
        }

        if let IpAddr::V4(addr) = self.clients[client_id].peer_addr.ip() {
            handlers::handle_client_accept(
                &mut self.server_state,
                client_id,
                &mut response,
                addr.octets(),
                addr.is_loopback(),
            );
            self.handle_response(response, poll);
        } else {
            todo!("implement something")
        }
    }

    pub fn accept_client(&mut self, poll: &Poll, server_token: mio::Token) -> io::Result<()> {
        match server_token {
            utils::SERVER_TOKEN => {
                let (client_socket, addr) = self.listener.accept()?;
                info!("Connected(plaintext): {}", addr);
                let client_id =
                    self.register_client(poll, self.create_client_socket(client_socket)?, addr)?;
                self.init_client(poll, client_id);
            }
            #[cfg(feature = "tls-connections")]
            utils::SECURE_SERVER_TOKEN => {
                let (client_socket, addr) = self.ssl.listener.accept()?;
                info!("Connected(TLS): {}", addr);
                self.register_client(poll, self.create_client_secure_socket(client_socket)?, addr)?;
            }
            _ => unreachable!(),
        }

        Ok(())
    }

    fn operation_failed(
        &mut self,
        poll: &Poll,
        client_id: ClientId,
        error: &Error,
        msg: &str,
    ) -> io::Result<()> {
        let addr = if let Some(ref mut client) = self.clients.get_mut(client_id) {
            client.peer_addr
        } else {
            SocketAddr::new(IpAddr::V4(Ipv4Addr::new(0, 0, 0, 0)), 0)
        };
        debug!("{}({}): {}", msg, addr, error);
        self.client_error(poll, client_id)
    }

    pub fn client_readable(&mut self, poll: &Poll, client_id: ClientId) -> io::Result<()> {
        let messages = if let Some(ref mut client) = self.clients.get_mut(client_id) {
            client.read()
        } else {
            warn!("invalid readable client: {}", client_id);
            Ok((Vec::new(), NetworkClientState::Idle))
        };

        let mut response = handlers::Response::new(client_id);

        match messages {
            Ok((messages, state)) => {
                for message in messages {
                    debug!("Handling message {:?} for client {}", message, client_id);
                    handlers::handle(&mut self.server_state, client_id, &mut response, message);
                }
                match state {
                    NetworkClientState::NeedsRead => {
                        self.pending.insert((client_id, state));
                    }
                    NetworkClientState::Closed => self.client_error(&poll, client_id)?,
                    #[cfg(feature = "tls-connections")]
                    NetworkClientState::Connected => self.init_client(poll, client_id),
                    _ => {}
                };
            }
            Err(e) => self.operation_failed(
                poll,
                client_id,
                &e,
                "Error while reading from client socket",
            )?,
        }

        self.handle_response(response, poll);

        Ok(())
    }

    pub fn client_writable(&mut self, poll: &Poll, client_id: ClientId) -> io::Result<()> {
        let result = if let Some(ref mut client) = self.clients.get_mut(client_id) {
            client.write()
        } else {
            warn!("invalid writable client: {}", client_id);
            Ok(((), NetworkClientState::Idle))
        };

        match result {
            Ok(((), state)) if state == NetworkClientState::NeedsWrite => {
                self.pending.insert((client_id, state));
            }
            Ok(((), state)) if state == NetworkClientState::Closed => {
                self.deregister_client(poll, client_id, false);
            }
            Ok(_) => (),
            Err(e) => {
                self.operation_failed(poll, client_id, &e, "Error while writing to client socket")?
            }
        }

        Ok(())
    }

    pub fn client_error(&mut self, poll: &Poll, client_id: ClientId) -> io::Result<()> {
        let pending_close = self.clients[client_id].pending_close;
        self.deregister_client(poll, client_id, true);

        if !pending_close {
            let mut response = handlers::Response::new(client_id);
            handlers::handle_client_loss(&mut self.server_state, client_id, &mut response);
            self.handle_response(response, poll);
        }

        Ok(())
    }

    pub fn has_pending_operations(&self) -> bool {
        !self.pending.is_empty() || !self.timeout_events.is_empty()
    }

    pub fn on_idle(&mut self, poll: &Poll) -> io::Result<()> {
        if self.has_pending_operations() {
            let mut cache = replace(&mut self.pending_cache, Vec::new());
            cache.extend(self.pending.drain());
            for (id, state) in cache.drain(..) {
                match state {
                    NetworkClientState::NeedsRead => self.client_readable(poll, id)?,
                    NetworkClientState::NeedsWrite => self.client_writable(poll, id)?,
                    _ => {}
                }
            }
            swap(&mut cache, &mut self.pending_cache);
        }
        Ok(())
    }
}

pub struct NetworkLayerBuilder {
    listener: Option<TcpListener>,
    secure_listener: Option<TcpListener>,
    clients_capacity: usize,
    rooms_capacity: usize,
}

impl Default for NetworkLayerBuilder {
    fn default() -> Self {
        Self {
            clients_capacity: 1024,
            rooms_capacity: 512,
            listener: None,
            secure_listener: None,
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

    pub fn with_secure_listener(self, listener: TcpListener) -> Self {
        Self {
            secure_listener: Some(listener),
            ..self
        }
    }

    #[cfg(feature = "tls-connections")]
    fn create_ssl_context(listener: TcpListener) -> ServerSsl {
        let mut builder = SslContextBuilder::new(SslMethod::tls()).unwrap();
        builder.set_verify(SslVerifyMode::NONE);
        builder.set_read_ahead(true);
        builder
            .set_certificate_file("ssl/cert.pem", SslFiletype::PEM)
            .expect("Cannot find certificate file");
        builder
            .set_private_key_file("ssl/key.pem", SslFiletype::PEM)
            .expect("Cannot find private key file");
        builder.set_options(SslOptions::NO_COMPRESSION);
        builder.set_options(SslOptions::NO_TLSV1);
        builder.set_options(SslOptions::NO_TLSV1_1);
        builder.set_cipher_list("ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384").unwrap();
        ServerSsl {
            listener,
            context: builder.build(),
        }
    }

    pub fn build(self, poll: &Poll) -> NetworkLayer {
        let server_state = ServerState::new(self.clients_capacity, self.rooms_capacity);

        let clients = Slab::with_capacity(self.clients_capacity);
        let pending = HashSet::with_capacity(2 * self.clients_capacity);
        let pending_cache = Vec::with_capacity(2 * self.clients_capacity);
        let timeout_events = NetworkTimeoutEvents::new();

        #[cfg(feature = "official-server")]
        let waker = Waker::new(poll.registry(), utils::IO_TOKEN)
            .expect("Unable to create a waker for the IO thread");

        NetworkLayer {
            listener: self.listener.expect("No listener provided"),
            server_state,
            clients,
            pending,
            pending_cache,
            #[cfg(feature = "tls-connections")]
            ssl: Self::create_ssl_context(
                self.secure_listener.expect("No secure listener provided"),
            ),
            #[cfg(feature = "official-server")]
            io: IoLayer::new(waker),
            timeout_events,
        }
    }
}
