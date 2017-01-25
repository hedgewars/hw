use slab;
use mio::tcp::*;
use mio::*;
use std::io;

use utils;
use super::client::HWClient;
use super::actions;

type Slab<T> = slab::Slab<T, Token>;

pub struct HWServer {
    listener: TcpListener,
    pub clients: Slab<HWClient>,
    pub rooms: Slab<HWRoom>,
    pub lobby_id: Token,
}

impl HWServer {
    pub fn new(listener: TcpListener, clients_limit: usize, rooms_limit: usize) -> HWServer {
        let mut rooms = Slab::with_capacity(rooms_limit);
        let token = rooms.insert(HWRoom::new()).ok().expect("Cannot create lobby");
        HWServer {
            listener: listener,
            clients: Slab::with_capacity(clients_limit),
            rooms: rooms,
            lobby_id: token,
        }
    }

    pub fn register(&self, poll: &Poll) -> io::Result<()> {
        poll.register(&self.listener, utils::SERVER, Ready::readable(),
                      PollOpt::edge())
    }

    pub fn accept(&mut self, poll: &Poll) -> io::Result<()> {
        let (sock, addr) = self.listener.accept()?;
        info!("Connected: {}", addr);

        let client = HWClient::new(sock, &self.lobby_id);
        let token = self.clients.insert(client)
            .ok().expect("could not add connection to slab");

        self.clients[token].register(poll, token);

        Ok(())
    }

    pub fn client_readable(&mut self, poll: &Poll,
                           token: Token) -> io::Result<()> {
        let actions;
        {
            actions = self.clients[token].readable(poll);
        }

        self.react(token, poll, actions);

        Ok(())
    }

    pub fn client_writable(&mut self, poll: &Poll,
                           token: Token) -> io::Result<()> {
        self.clients[token].writable(poll)?;

        Ok(())
    }

    pub fn client_error(&mut self, poll: &Poll,
                           token: Token) -> io::Result<()> {
        let actions;
        {
            actions = self.clients[token].error(poll);
        }

        self.react(token, poll, actions);

        Ok(())
    }

    pub fn send(&mut self, token: Token, msg: &String) {
        self.clients[token].send_string(msg);
    }

    pub fn react(&mut self, token: Token, poll: &Poll, actions: Vec<actions::Action>) {
        for action in actions {
            actions::run_action(self, token, poll, action);
        }
    }
}


pub struct HWRoom {
    pub name: String,
}

impl HWRoom {
    pub fn new() -> HWRoom {
        HWRoom {
            name: String::new(),
        }
    }
}
