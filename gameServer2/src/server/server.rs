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
        info!("Connected: {}", addr);

        let client = HWClient::new(sock);
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

    fn react(&mut self, token: Token, poll: &Poll, actions: Vec<Action>) {
        for action in actions {
            match action {
                SendMe(msg) => self.clients[token].send_string(&msg),
                ByeClient(msg) => {
                    self.react(token, poll, vec![
                        SendMe(Bye(&msg).to_raw_protocol()),
                        RemoveClient,
                    ]);
                },
                RemoveClient => {
                    self.clients[token].deregister(poll);
                    self.clients.remove(token);
                },
                //_ => unimplemented!(),
            }
        }
    }
}


struct HWRoom {
    name: String
}
