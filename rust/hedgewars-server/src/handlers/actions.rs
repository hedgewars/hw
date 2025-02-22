use crate::core::types::{ClientId, RoomId};
use hedgewars_network_protocol::messages::{HwServerMessage, HwServerMessage::*};

#[derive(Clone)]
pub enum DestinationGroup {
    All,
    Lobby,
    Room(RoomId),
    Protocol(u16),
}

#[derive(Clone)]
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

pub trait ToPendingMessage {
    fn send(self, client_id: ClientId) -> PendingMessage;
    fn send_many(self, client_ids: Vec<ClientId>) -> PendingMessage;
    fn send_self(self) -> PendingMessage;
    fn send_all(self) -> PendingMessage;
    fn send_to_destination(self, destination: Destination) -> PendingMessage;
}

impl ToPendingMessage for HwServerMessage {
    fn send(self, client_id: ClientId) -> PendingMessage {
        PendingMessage::send(self, client_id)
    }
    fn send_many(self, client_ids: Vec<ClientId>) -> PendingMessage {
        PendingMessage::send_many(self, client_ids)
    }
    fn send_self(self) -> PendingMessage {
        PendingMessage::send_self(self)
    }
    fn send_all(self) -> PendingMessage {
        PendingMessage::send_all(self)
    }
    fn send_to_destination(self, destination: Destination) -> PendingMessage {
        PendingMessage {
            destination,
            message: self,
        }
    }
}
