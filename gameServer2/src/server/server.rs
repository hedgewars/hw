use slab;
use mio::net::*;
use mio::*;
use std::io;

use utils;
use super::client::HWClient;
use super::actions;

type Slab<T> = slab::Slab<T>;

pub struct HWServer {
    listener: TcpListener,
    pub clients: Slab<HWClient>,
    pub rooms: Slab<HWRoom>,
    pub lobby_id: usize,
}

impl HWServer {
    pub fn new(listener: TcpListener, clients_limit: usize, rooms_limit: usize) -> HWServer {
        let mut rooms = Slab::with_capacity(rooms_limit);
        let token = rooms.insert(HWRoom::new());
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

        let client = HWClient::new(sock);
        let token = self.clients.insert(client);

        self.clients[token].id = token;
        self.clients[token].register(poll, Token(token));

        Ok(())
    }

    pub fn client_readable(&mut self, poll: &Poll,
                           token: usize) -> io::Result<()> {
        let actions;
        {
            actions = self.clients[token].readable(poll);
        }

        self.react(token, poll, actions);

        Ok(())
    }

    pub fn client_writable(&mut self, poll: &Poll,
                           token: usize) -> io::Result<()> {
        self.clients[token].writable(poll)?;

        Ok(())
    }

    pub fn client_error(&mut self, poll: &Poll,
                           token: usize) -> io::Result<()> {
        let actions;
        {
            actions = self.clients[token].error(poll);
        }

        self.react(token, poll, actions);

        Ok(())
    }

    pub fn send(&mut self, token: usize, msg: &String) {
        self.clients[token].send_string(msg);
    }

    pub fn react(&mut self, token: usize, poll: &Poll, actions: Vec<actions::Action>) {
        for action in actions {
            actions::run_action(self, token, poll, action);
        }
    }
}


pub struct HWRoom {
    pub id: usize,
    pub name: String,
    pub password: Option<String>,
    pub protocol_number: u32,
    pub ready_players_number: u8,
}

impl HWRoom {
    pub fn new() -> HWRoom {
        HWRoom {
            id: 0,
            name: String::new(),
            password: None,
            protocol_number: 0,
            ready_players_number: 0,
        }
    }
}
