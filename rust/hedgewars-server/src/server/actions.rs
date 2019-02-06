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

pub enum Destination {
    ToId(ClientId),
    ToSelf,
    ToAll {
        room_id: Option<RoomId>,
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
            room_id: None,
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
            *room_id = Some(clients_room_id)
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

pub enum Action {
    ChangeMaster(RoomId, Option<ClientId>),
}

use self::Action::*;

pub fn run_action(server: &mut HWServer, client_id: usize, action: Action) {
    match action {
        ChangeMaster(room_id, new_id) => {
            let room_client_ids = server.room_clients(room_id);
            let new_id = if server
                .room(client_id)
                .map(|r| r.is_fixed())
                .unwrap_or(false)
            {
                new_id
            } else {
                new_id.or_else(|| room_client_ids.iter().find(|id| **id != client_id).cloned())
            };
            let new_nick = new_id.map(|id| server.clients[id].nick.clone());

            if let (c, Some(r)) = server.client_and_room(client_id) {
                match r.master_id {
                    Some(id) if id == c.id => {
                        c.set_is_master(false);
                        r.master_id = None;
                        /*actions.push(
                            ClientFlags("-h".to_string(), vec![c.nick.clone()])
                                .send_all()
                                .in_room(r.id)
                                .action(),
                        );*/
                    }
                    Some(_) => unreachable!(),
                    None => {}
                }
                r.master_id = new_id;
                if !r.is_fixed() && c.protocol_number < 42 {
                    r.name
                        .replace_range(.., new_nick.as_ref().map_or("[]", String::as_str));
                }
                r.set_join_restriction(false);
                r.set_team_add_restriction(false);
                let is_fixed = r.is_fixed();
                r.set_unregistered_players_restriction(is_fixed);
                if let Some(nick) = new_nick {
                    /*actions.push(
                        ClientFlags("+h".to_string(), vec![nick])
                            .send_all()
                            .in_room(r.id)
                            .action(),
                    );*/
                }
            }
            if let Some(id) = new_id {
                server.clients[id].set_is_master(true)
            }
        }
    }
}
