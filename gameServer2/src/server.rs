use slab;
use mio::tcp::*;
use mio::*;
use std::io::Write;
use std::io;
use netbuf;

use utils;

type Slab<T> = slab::Slab<T, Token>;

pub struct HWServer {
    listener: TcpListener,
    clients: Slab<HWClient>,
    rooms: Slab<HWRoom>
}

impl HWServer {
    pub fn new(listener: TcpListener, clients_limit: usize, rooms_limit: usize) -> HWServer {
        HWServer {
            listener: listener,
            clients: Slab::with_capacity(clients_limit),
            rooms: Slab::with_capacity(rooms_limit),
        }
    }

    pub fn register(&self, poll: &Poll) -> io::Result<()> {
        poll.register(&self.listener, utils::SERVER, Ready::readable(),
                      PollOpt::edge())
    }

    pub fn accept(&mut self, poll: &Poll) -> io::Result<()> {
        let (sock, addr) = self.listener.accept().unwrap();
        println!("Connected: {}", addr);

        let client = HWClient::new(sock);
        let token = self.clients.insert(client)
            .ok().expect("could not add connection to slab");

        self.clients[token].send_raw_msg(
            format!("CONNECTED\nHedgewars server http://www.hedgewars.org/\n{}\n\n"
            , utils::PROTOCOL_VERSION).as_bytes());
        self.clients[token].register(poll, token);

        Ok(())
    }

    pub fn client_readable(&mut self, poll: &Poll,
                           token: Token) -> io::Result<()> {
        self.clients[token].readable(poll)
    }

    pub fn client_writable(&mut self, poll: &Poll,
                           token: Token) -> io::Result<()> {
        self.clients[token].writable(poll)
    }
}


struct HWClient {
    sock: TcpStream,
    buf_in: netbuf::Buf,
    buf_out: netbuf::Buf
}

impl HWClient {
    fn new(sock: TcpStream) -> HWClient {
        HWClient {
            sock: sock,
            buf_in: netbuf::Buf::new(),
            buf_out: netbuf::Buf::new(),
        }
    }

    fn register(&self, poll: &Poll, token: Token) {
        poll.register(&self.sock, token, Ready::readable(),
                      PollOpt::edge())
            .ok().expect("could not register socket with event loop");
    }

    fn send_raw_msg(&mut self, msg: &[u8]) {
        self.buf_out.write(msg).unwrap();
        self.flush();
    }

    fn flush(&mut self) {
        self.buf_out.write_to(&mut self.sock).unwrap();
        self.sock.flush();
    }

    fn readable(&mut self, poll: &Poll) -> io::Result<()> {
        self.buf_in.read_from(&mut self.sock)?;
        println!("Incoming buffer size: {}", self.buf_in.len());
        Ok(())
    }

    fn writable(&mut self, poll: &Poll) -> io::Result<()> {
        self.buf_out.write_to(&mut self.sock)?;
        Ok(())
    }
}

struct HWRoom {
    name: String
}
