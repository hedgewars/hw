use slab;
use mio::tcp::*;
use mio::*;
use std::io::Write;
use std::io;

use utils;
use server::client::HWClient;
use server::actions::Action;
use server::actions::Action::*;
use protocol::messages::HWProtocolMessage::*;
use protocol::messages::HWServerMessage;

type Slab<T> = slab::Slab<T, Token>;

pub struct HWServer {
    listener: TcpListener,
    clients: Slab<HWClient>,
    rooms: Slab<HWRoom>,
    lobbyId: Token,
}

impl HWServer {
    pub fn new(listener: TcpListener, clients_limit: usize, rooms_limit: usize) -> HWServer {
        let mut rooms = Slab::with_capacity(rooms_limit);
        let token = rooms.insert(HWRoom::new()).ok().expect("Cannot create lobby");
        HWServer {
            listener: listener,
            clients: Slab::with_capacity(clients_limit),
            rooms: rooms,
            lobbyId: token,
        }
    }

    pub fn register(&self, poll: &Poll) -> io::Result<()> {
        poll.register(&self.listener, utils::SERVER, Ready::readable(),
                      PollOpt::edge())
    }

    pub fn accept(&mut self, poll: &Poll) -> io::Result<()> {
        let (sock, addr) = self.listener.accept()?;
        info!("Connected: {}", addr);

        let client = HWClient::new(sock, &self.lobbyId);
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

    fn send(&mut self, token: Token, msg: &String) {
        self.clients[token].send_string(msg);
    }

    fn react(&mut self, token: Token, poll: &Poll, actions: Vec<Action>) {
        for action in actions {
            match action {
                SendMe(msg) => self.send(token, &msg),
                ByeClient(msg) => {
                    self.react(token, poll, vec![
                        SendMe(HWServerMessage::Bye(&msg).to_raw_protocol()),
                        RemoveClient,
                    ]);
                },
                RemoveClient => {
                    self.clients[token].deregister(poll);
                    self.clients.remove(token);
                },
                ReactProtocolMessage(msg) => match msg {
                    Ping => self.react(token, poll, vec![SendMe(HWServerMessage::Pong.to_raw_protocol())]),
                    Quit(Some(msg)) => self.react(token, poll, vec![ByeClient("User quit: ".to_string() + &msg)]),
                    Quit(None) => self.react(token, poll, vec![ByeClient("User quit".to_string())]),
                    Nick(nick) => if self.clients[token].nick.len() == 0 {
                        self.send(token, &HWServerMessage::Nick(&nick).to_raw_protocol());
                        self.clients[token].nick = nick;
                    },
                    Malformed => warn!("Malformed/unknown message"),
                    Empty => warn!("Empty message"),
                    _ => unimplemented!(),
                }
                //_ => unimplemented!(),
            }
        }
    }
}


struct HWRoom {
    name: String
}

impl HWRoom {
    pub fn new() -> HWRoom {
        HWRoom {
            name: String::new(),
        }
    }
}
