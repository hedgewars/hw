use slab;
use mio::tcp::*;
use mio::*;
use std::io::Write;
use std::io;
use netbuf;

use utils;
use server::client::HWClient;

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
        let (sock, addr) = self.listener.accept()?;
        println!("Connected: {}", addr);

        let client = HWClient::new(sock);
        let token = self.clients.insert(client)
            .ok().expect("could not add connection to slab");

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


struct HWRoom {
    name: String
}
