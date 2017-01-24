use mio;
use std::io::Write;
use std::io;

use super::server::HWServer;
use super::actions::Action;
use super::actions::Action::*;
use protocol::messages::HWProtocolMessage;
use protocol::messages::HWServerMessage::*;

pub fn handle(server: &mut HWServer, token: mio::Token, poll: &mio::Poll, action: Action) {
    match action {
        SendMe(msg) => server.send(token, &msg),
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
        ReactProtocolMessage(msg) => match msg {
            HWProtocolMessage::Ping =>
                server.react(token, poll, vec![SendMe(Pong.to_raw_protocol())]),
            HWProtocolMessage::Quit(Some(msg)) =>
                server.react(token, poll, vec![ByeClient("User quit: ".to_string() + &msg)]),
            HWProtocolMessage::Quit(None) =>
                server.react(token, poll, vec![ByeClient("User quit".to_string())]),
            HWProtocolMessage::Nick(nick) =>
                if server.clients[token].nick.len() == 0 {
                server.react(token, poll, vec![SendMe(Nick(&nick).to_raw_protocol())]);
                server.clients[token].nick = nick;
            },
            HWProtocolMessage::Malformed => warn!("Malformed/unknown message"),
            HWProtocolMessage::Empty => warn!("Empty message"),
            _ => unimplemented!(),
        }
        //_ => unimplemented!(),
    }
}
