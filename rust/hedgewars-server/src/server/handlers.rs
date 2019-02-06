use mio;
use std::{io, io::Write};

use super::{actions::Destination, core::HWServer, coretypes::ClientId};
use crate::{
    protocol::messages::{HWProtocolMessage, HWServerMessage, HWServerMessage::*},
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

    #[inline]
    pub fn is_empty(&self) -> bool {
        self.messages.is_empty()
    }

    #[inline]
    pub fn len(&self) -> usize {
        self.messages.len()
    }

    #[inline]
    pub fn client_id(&self) -> ClientId {
        self.client_id
    }

    #[inline]
    pub fn add(&mut self, message: PendingMessage) {
        self.messages.push(message)
    }

    pub fn extract_messages<'a, 'b: 'a>(
        &'b mut self,
        server: &'a HWServer,
    ) -> impl Iterator<Item = (Vec<ClientId>, HWServerMessage)> + 'a {
        let client_id = self.client_id;
        self.messages.drain(..).map(move |m| {
            let ids = get_recipients(server, client_id, &m.destination);
            (ids, m.message)
        })
    }
}

impl Extend<PendingMessage> for Response {
    fn extend<T: IntoIterator<Item = PendingMessage>>(&mut self, iter: T) {
        for msg in iter {
            self.add(msg)
        }
    }
}

fn get_recipients(
    server: &HWServer,
    client_id: ClientId,
    destination: &Destination,
) -> Vec<ClientId> {
    let mut ids = match *destination {
        Destination::ToSelf => vec![client_id],
        Destination::ToId(id) => vec![id],
        Destination::ToAll {
            room_id: Some(id), ..
        } => server.room_clients(id),
        Destination::ToAll {
            protocol: Some(proto),
            ..
        } => server.protocol_clients(proto),
        Destination::ToAll { .. } => server.clients.iter().map(|(id, _)| id).collect::<Vec<_>>(),
    };
    if let Destination::ToAll {
        skip_self: true, ..
    } = destination
    {
        if let Some(index) = ids.iter().position(|id| *id == client_id) {
            ids.remove(index);
        }
    }
    ids
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
        }
        HWProtocolMessage::Quit(Some(msg)) => {
            common::remove_client(server, response, "User quit: ".to_string() + &msg);
        }
        HWProtocolMessage::Quit(None) => {
            common::remove_client(server, response, "User quit".to_string());
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

pub fn handle_client_loss(server: &mut HWServer, client_id: ClientId, response: &mut Response) {
    common::remove_client(server, response, "Connection reset".to_string());
}
