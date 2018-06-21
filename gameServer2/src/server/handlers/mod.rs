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

pub fn handle(server: &mut HWServer, token: usize, message: HWProtocolMessage) {
    match message {
        HWProtocolMessage::Ping =>
            server.react(token, vec![Pong.send_self().action()]),
        HWProtocolMessage::Quit(Some(msg)) =>
            server.react(token, vec![ByeClient("User quit: ".to_string() + &msg)]),
        HWProtocolMessage::Quit(None) =>
            server.react(token, vec![ByeClient("User quit".to_string())]),
        HWProtocolMessage::Malformed => warn!("Malformed/unknown message"),
        HWProtocolMessage::Empty => warn!("Empty message"),
        _ => {
            match server.clients[token].room_id {
                None =>
                    loggingin::handle(server, token, message),
                Some(id) if id == server.lobby_id =>
                    lobby::handle(server, token, message),
                _ =>
                    inroom::handle(server, token, message)
            }
        },
    }
}
