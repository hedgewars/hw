use crate::{
    core::{
        client::HwClient,
        room::HwRoom,
        room::{GameInfo, RoomFlags},
        server::HwServer,
        types::{ClientId, GameCfg, RoomId, VoteType},
    },
    protocol::messages::{server_chat, HwProtocolMessage, HwServerMessage, HwServerMessage::*},
    utils::to_engine_msg,
};
use rand::{distributions::Uniform, thread_rng, Rng};
use std::{io, io::Write, iter::once, mem::replace};

pub enum DestinationGroup {
    All,
    Lobby,
    Room(RoomId),
    Protocol(u16),
}

pub enum Destination {
    ToId(ClientId),
    ToIds(Vec<ClientId>),
    ToSelf,
    ToAll {
        group: DestinationGroup,
        skip_self: bool,
    },
}

pub struct PendingMessage {
    pub destination: Destination,
    pub message: HwServerMessage,
}

impl PendingMessage {
    pub fn send(message: HwServerMessage, client_id: ClientId) -> PendingMessage {
        PendingMessage {
            destination: Destination::ToId(client_id),
            message,
        }
    }

    pub fn send_many(message: HwServerMessage, client_ids: Vec<ClientId>) -> PendingMessage {
        PendingMessage {
            destination: Destination::ToIds(client_ids),
            message,
        }
    }

    pub fn send_self(message: HwServerMessage) -> PendingMessage {
        PendingMessage {
            destination: Destination::ToSelf,
            message,
        }
    }

    pub fn send_all(message: HwServerMessage) -> PendingMessage {
        let destination = Destination::ToAll {
            group: DestinationGroup::All,
            skip_self: false,
        };
        PendingMessage {
            destination,
            message,
        }
    }

    pub fn in_room(mut self, clients_room_id: RoomId) -> PendingMessage {
        if let Destination::ToAll { ref mut group, .. } = self.destination {
            *group = DestinationGroup::Room(clients_room_id)
        }
        self
    }

    pub fn in_lobby(mut self) -> PendingMessage {
        if let Destination::ToAll { ref mut group, .. } = self.destination {
            *group = DestinationGroup::Lobby
        }
        self
    }

    pub fn with_protocol(mut self, protocol_number: u16) -> PendingMessage {
        if let Destination::ToAll { ref mut group, .. } = self.destination {
            *group = DestinationGroup::Protocol(protocol_number)
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

impl HwServerMessage {
    pub fn send(self, client_id: ClientId) -> PendingMessage {
        PendingMessage::send(self, client_id)
    }
    pub fn send_many(self, client_ids: Vec<ClientId>) -> PendingMessage {
        PendingMessage::send_many(self, client_ids)
    }
    pub fn send_self(self) -> PendingMessage {
        PendingMessage::send_self(self)
    }
    pub fn send_all(self) -> PendingMessage {
        PendingMessage::send_all(self)
    }
}
