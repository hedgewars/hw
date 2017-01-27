use mio;
use std::io::Write;
use std::io;

use super::server::HWServer;
use super::actions::Action;
use super::actions::Action::*;
use protocol::messages::HWProtocolMessage;
use protocol::messages::HWServerMessage::*;

pub fn handle(server: &mut HWServer, token: mio::Token, poll: &mio::Poll, message: HWProtocolMessage) {
    match message {
        HWProtocolMessage::Ping =>
            server.react(token, poll, vec![SendMe(Pong.to_raw_protocol())]),
        HWProtocolMessage::Quit(Some(msg)) =>
            server.react(token, poll, vec![ByeClient("User quit: ".to_string() + &msg)]),
        HWProtocolMessage::Quit(None) =>
            server.react(token, poll, vec![ByeClient("User quit".to_string())]),
        HWProtocolMessage::Nick(nick) =>
            if server.clients[token].room_id == None {
                server.react(token, poll, vec![SendMe(Nick(&nick).to_raw_protocol())]);
                server.clients[token].nick = nick;
                server.react(token, poll, vec![CheckRegistered]);
            },
        HWProtocolMessage::Proto(proto) => {
                server.clients[token].protocol_number = proto;
                server.react(token, poll, vec![CheckRegistered]);
        },
        HWProtocolMessage::List => warn!("Deprecated LIST message received"),
        HWProtocolMessage::Malformed => warn!("Malformed/unknown message"),
        HWProtocolMessage::Empty => warn!("Empty message"),
        _ => unimplemented!(),
    }
}
