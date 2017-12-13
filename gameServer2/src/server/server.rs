use slab;
use mio::tcp::*;
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
    pub lobby_id: Token,
}

impl HWServer {
    pub fn new(listener: TcpListener, clients_limit: usize, rooms_limit: usize) -> HWServer {
        let mut rooms = Slab::with_capacity(rooms_limit);
        let token = rooms.insert(HWRoom::new());
        HWServer {
            listener: listener,
            clients: Slab::with_capacity(clients_limit),
            rooms: rooms,
            lobby_id: Token(token),
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
        let token = Token(self.clients.insert(client));

        self.clients[token.0].id = token;
        self.clients[token.0].register(poll, token);

        Ok(())
    }

    pub fn client_readable(&mut self, poll: &Poll,
                           token: Token) -> io::Result<()> {
        let actions;
        {
            actions = self.clients[token.0].readable(poll);
        }

        self.react(token, poll, actions);

        Ok(())
    }

    pub fn client_writable(&mut self, poll: &Poll,
                           token: Token) -> io::Result<()> {
        self.clients[token.0].writable(poll)?;

        Ok(())
    }

    pub fn client_error(&mut self, poll: &Poll,
                           token: Token) -> io::Result<()> {
        let actions;
        {
            actions = self.clients[token.0].error(poll);
        }

        self.react(token, poll, actions);

        Ok(())
    }

    pub fn send(&mut self, token: Token, msg: &String) {
        self.clients[token.0].send_string(msg);
    }

    pub fn react(&mut self, token: Token, poll: &Poll, actions: Vec<actions::Action>) {
        for action in actions {
            actions::run_action(self, token, poll, action);
        }
    }
}


pub struct HWRoom {
    pub id: Token,
    pub name: String,
    pub password: Option<String>,
    pub protocol_number: u32,
    pub ready_players_number: u8,
}

impl HWRoom {
    pub fn new() -> HWRoom {
        HWRoom {
            id: Token(0),
            name: String::new(),
            password: None,
            protocol_number: 0,
            ready_players_number: 0,
        }
    }
}
