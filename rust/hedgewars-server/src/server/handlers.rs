use mio;
use std::{io, io::Write};

use super::{
    actions::{Action, Action::*},
    core::HWServer,
    coretypes::ClientId,
};
use crate::{
    protocol::messages::{HWProtocolMessage, HWServerMessage::*},
    server::actions::PendingMessage,
};
use log::*;

mod checker;
mod common;
mod inroom;
mod lobby;
mod loggingin;

pub struct Response {
    client_id: ClientId,
    messages: Vec<PendingMessage>,
}

impl Response {
    pub fn new(client_id: ClientId) -> Self {
        Self {
            client_id,
            messages: vec![],
        }
    }

    pub fn client_id(&self) -> ClientId {
        self.client_id
    }

    pub fn add(&mut self, message: PendingMessage) {
        self.messages.push(message)
    }
}

pub fn handle(
    server: &mut HWServer,
    client_id: ClientId,
    response: &mut Response,
    message: HWProtocolMessage,
) {
    match message {
        HWProtocolMessage::Ping => {
            response.add(Pong.send_self());
            server.react(client_id, vec![Pong.send_self().action()])
        }
        HWProtocolMessage::Quit(Some(msg)) => {
            server.react(client_id, vec![ByeClient("User quit: ".to_string() + &msg)])
        }
        HWProtocolMessage::Quit(None) => {
            server.react(client_id, vec![ByeClient("User quit".to_string())])
        }
        HWProtocolMessage::Malformed => warn!("Malformed/unknown message"),
        HWProtocolMessage::Empty => warn!("Empty message"),
        _ => match server.clients[client_id].room_id {
            None => loggingin::handle(server, client_id, response, message),
            Some(id) if id == server.lobby_id => {
                lobby::handle(server, client_id, response, message)
            }
            Some(id) => inroom::handle(server, client_id, response, id, message),
        },
    }
}
