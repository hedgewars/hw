use slab::*;
use mio::tcp::*;
use mio::*;
use mio;
use std::io::Write;
use std::io;

use utils;

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

        self.clients[token].uid = Some(token);
        poll.register(&self.clients[token].sock, mio::Token(token), Ready::readable(),
                      PollOpt::edge() | PollOpt::oneshot())
            .ok().expect("could not register socket with event loop");

        Ok(())
    }
}

struct HWClient {
    sock: TcpStream,
    uid: Option<usize>
}

impl HWClient {
    fn new(sock: TcpStream) -> HWClient {
        HWClient {
            sock: sock,
            uid: None
        }
    }

    fn send_raw_msg(&mut self, msg: &[u8]) {
        self.sock.write_all(msg).unwrap();
    }
}

struct HWRoom {
    name: String
}
