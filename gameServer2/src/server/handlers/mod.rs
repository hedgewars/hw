use mio;
use std::{io, io::Write};

use super::{
    server::HWServer,
    actions::{Action, Action::*},
    coretypes::ClientId
};
use crate::{
    protocol::messages::{
        HWProtocolMessage,
        HWServerMessage::*
    }
};

mod loggingin;
mod lobby;
mod inroom;
mod common;
mod checker;

pub fn handle(server: &mut HWServer, client_id: ClientId, message: HWProtocolMessage) {
    match message {
        HWProtocolMessage::Ping =>
            server.react(client_id, vec![Pong.send_self().action()]),
        HWProtocolMessage::Quit(Some(msg)) =>
            server.react(client_id, vec![ByeClient("User quit: ".to_string() + &msg)]),
        HWProtocolMessage::Quit(None) =>
            server.react(client_id, vec![ByeClient("User quit".to_string())]),
        HWProtocolMessage::Malformed => warn!("Malformed/unknown message"),
        HWProtocolMessage::Empty => warn!("Empty message"),
        _ => {
            match server.clients[client_id].room_id {
                None =>
                    loggingin::handle(server, client_id, message),
                Some(id) if id == server.lobby_id =>
                    lobby::handle(server, client_id, message),
                Some(id) =>
                    inroom::handle(server, client_id, id, message)
            }
        },
    }
}
