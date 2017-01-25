use mio;
use std::io::Write;
use std::io;

use super::server::HWServer;
use protocol::messages::HWProtocolMessage;
use protocol::messages::HWServerMessage::*;
use super::handlers;

pub enum Action {
    SendMe(String),
    RemoveClient,
    ByeClient(String),
    ReactProtocolMessage(HWProtocolMessage),
}

use self::Action::*;

pub fn run_action(server: &mut HWServer, token: mio::Token, poll: &mio::Poll, action: Action) {
    match action {
        SendMe(msg) =>
            server.send(token, &msg),
        ByeClient(msg) => {
            server.react(token, poll, vec![
                SendMe(Bye(&msg).to_raw_protocol()),
                RemoveClient,
                ]);
        },
        RemoveClient => {
            server.clients[token].deregister(poll);
            server.clients.remove(token);
        },
        ReactProtocolMessage(msg) =>
            handlers::handle(server, token, poll, msg),
        //_ => unimplemented!(),
    }
}
