use super::{
    client::HWClient,
    core::HWServer,
    coretypes::{ClientId, GameCfg, RoomId, VoteType},
    handlers,
    room::HWRoom,
    room::{GameInfo, RoomFlags},
};
use crate::{
    protocol::messages::{server_chat, HWProtocolMessage, HWServerMessage, HWServerMessage::*},
    utils::to_engine_msg,
};
use rand::{distributions::Uniform, thread_rng, Rng};
use std::{io, io::Write, iter::once, mem::replace};

#[cfg(feature = "official-server")]
use super::database;

pub enum DestinationRoom {
    All,
    Lobby,
    Room(RoomId),
}

pub enum Destination {
    ToId(ClientId),
    ToSelf,
    ToAll {
        room_id: DestinationRoom,
        protocol: Option<u16>,
        skip_self: bool,
    },
}

pub struct PendingMessage {
    pub destination: Destination,
    pub message: HWServerMessage,
}

impl PendingMessage {
    pub fn send(message: HWServerMessage, client_id: ClientId) -> PendingMessage {
        PendingMessage {
            destination: Destination::ToId(client_id),
            message,
        }
    }

    pub fn send_self(message: HWServerMessage) -> PendingMessage {
        PendingMessage {
            destination: Destination::ToSelf,
            message,
        }
    }

    pub fn send_all(message: HWServerMessage) -> PendingMessage {
        let destination = Destination::ToAll {
            room_id: DestinationRoom::All,
            protocol: None,
            skip_self: false,
        };
        PendingMessage {
            destination,
            message,
        }
    }

    pub fn in_room(mut self, clients_room_id: RoomId) -> PendingMessage {
        if let Destination::ToAll {
            ref mut room_id, ..
        } = self.destination
        {
            *room_id = DestinationRoom::Room(clients_room_id)
        }
        self
    }

    pub fn in_lobby(mut self) -> PendingMessage {
        if let Destination::ToAll {
            ref mut room_id, ..
        } = self.destination
        {
            *room_id = DestinationRoom::Lobby
        }
        self
    }

    pub fn with_protocol(mut self, protocol_number: u16) -> PendingMessage {
        if let Destination::ToAll {
            ref mut protocol, ..
        } = self.destination
        {
            *protocol = Some(protocol_number)
        }
        self
    }

    pub fn but_self(mut self) -> PendingMessage {
        if let Destination::ToAll {
            ref mut skip_self, ..
        } = self.destination
        {
            *skip_self = true
        }
        self
    }
}

impl HWServerMessage {
    pub fn send(self, client_id: ClientId) -> PendingMessage {
        PendingMessage::send(self, client_id)
    }
    pub fn send_self(self) -> PendingMessage {
        PendingMessage::send_self(self)
    }
    pub fn send_all(self) -> PendingMessage {
        PendingMessage::send_all(self)
    }
}
