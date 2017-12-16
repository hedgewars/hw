use mio;
use std::io::Write;
use std::io;

use super::server::HWServer;
use super::actions::Action;
use super::actions::Action::*;
use protocol::messages::HWProtocolMessage;
use protocol::messages::HWServerMessage::*;

mod loggingin;
mod lobby;
mod inroom;

pub fn handle(server: &mut HWServer, token: usize, poll: &mio::Poll, message: HWProtocolMessage) {
    match message {
        HWProtocolMessage::Ping =>
            server.react(token, poll, vec![SendMe(Pong.to_raw_protocol())]),
        HWProtocolMessage::Quit(Some(msg)) =>
            server.react(token, poll, vec![ByeClient("User quit: ".to_string() + &msg)]),
        HWProtocolMessage::Quit(None) =>
            server.react(token, poll, vec![ByeClient("User quit".to_string())]),
        HWProtocolMessage::Malformed => warn!("Malformed/unknown message"),
        HWProtocolMessage::Empty => warn!("Empty message"),
        _ => {
            if !server.clients[token].room_id.is_some() {
                loggingin::handle(server, token, poll, message);
            } else if server.clients[token].room_id == Some(server.lobby_id) {
                lobby::handle(server, token, poll, message);
            } else {
                inroom::handle(server, token, poll, message);
            }
        },
    }
}
