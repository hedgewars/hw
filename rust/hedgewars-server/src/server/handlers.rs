use mio;
use std::{collections::HashMap, io, io::Write};

use super::{
    actions::{Destination, DestinationGroup},
    core::HWServer,
    coretypes::{ClientId, Replay, RoomId},
    room::RoomSave,
};
use crate::{
    protocol::messages::{server_chat, HWProtocolMessage, HWServerMessage, HWServerMessage::*},
    server::actions::PendingMessage,
    utils,
};
use base64::encode;
use log::*;
use rand::{thread_rng, RngCore};

mod checker;
mod common;
mod inroom;
mod lobby;
mod loggingin;

use self::loggingin::LoginResult;
use crate::protocol::messages::global_chat;
use crate::protocol::messages::HWProtocolMessage::EngineMessage;
use crate::server::coretypes::{GameCfg, TeamInfo};
use std::fmt::{Formatter, LowerHex};

#[derive(PartialEq)]
pub struct Sha1Digest([u8; 20]);

impl Sha1Digest {
    pub fn new(digest: [u8; 20]) -> Self {
        Self(digest)
    }
}

impl LowerHex for Sha1Digest {
    fn fmt(&self, f: &mut Formatter) -> Result<(), std::fmt::Error> {
        for byte in &self.0 {
            write!(f, "{:02x}", byte)?;
        }
        Ok(())
    }
}

pub struct AccountInfo {
    pub is_registered: bool,
    pub is_admin: bool,
    pub is_contributor: bool,
    pub server_hash: Sha1Digest,
}

pub enum IoTask {
    GetAccount {
        nick: String,
        protocol: u16,
        password_hash: String,
        client_salt: String,
        server_salt: String,
    },
    GetReplay {
        id: u32,
    },
    SaveRoom {
        room_id: RoomId,
        filename: String,
        contents: String,
    },
    LoadRoom {
        room_id: RoomId,
        filename: String,
    },
}

pub enum IoResult {
    Account(Option<AccountInfo>),
    Replay(Option<Replay>),
    SaveRoom(RoomId, bool),
    LoadRoom(RoomId, Option<String>),
}

pub struct Response {
    client_id: ClientId,
    messages: Vec<PendingMessage>,
    io_tasks: Vec<IoTask>,
    removed_clients: Vec<ClientId>,
}

impl Response {
    pub fn new(client_id: ClientId) -> Self {
        Self {
            client_id,
            messages: vec![],
            io_tasks: vec![],
            removed_clients: vec![],
        }
    }

    #[inline]
    pub fn is_empty(&self) -> bool {
        self.messages.is_empty() && self.removed_clients.is_empty() && self.io_tasks.is_empty()
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

    #[inline]
    pub fn request_io(&mut self, task: IoTask) {
        self.io_tasks.push(task)
    }

    pub fn extract_messages<'a, 'b: 'a>(
        &'b mut self,
        server: &'a HWServer,
    ) -> impl Iterator<Item = (Vec<ClientId>, HWServerMessage)> + 'a {
        let client_id = self.client_id;
        self.messages.drain(..).map(move |m| {
            let ids = get_recipients(server, client_id, m.destination);
            (ids, m.message)
        })
    }

    pub fn remove_client(&mut self, client_id: ClientId) {
        self.removed_clients.push(client_id);
    }

    pub fn extract_removed_clients(&mut self) -> impl Iterator<Item = ClientId> + '_ {
        self.removed_clients.drain(..)
    }

    pub fn extract_io_tasks(&mut self) -> impl Iterator<Item = IoTask> + '_ {
        self.io_tasks.drain(..)
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
    destination: Destination,
) -> Vec<ClientId> {
    match destination {
        Destination::ToSelf => vec![client_id],
        Destination::ToId(id) => vec![id],
        Destination::ToIds(ids) => ids,
        Destination::ToAll { group, skip_self } => {
            let mut ids: Vec<_> = match group {
                DestinationGroup::All => server.all_clients().collect(),
                DestinationGroup::Lobby => server.lobby_clients().collect(),
                DestinationGroup::Protocol(proto) => server.protocol_clients(proto).collect(),
                DestinationGroup::Room(id) => server.room_clients(id).collect(),
            };

            if skip_self {
                if let Some(index) = ids.iter().position(|id| *id == client_id) {
                    ids.remove(index);
                }
            }

            ids
        }
    }
}

pub fn handle(
    server: &mut HWServer,
    client_id: ClientId,
    response: &mut Response,
    message: HWProtocolMessage,
) {
    match message {
        HWProtocolMessage::Ping => response.add(Pong.send_self()),
        _ => {
            if server.anteroom.clients.contains(client_id) {
                match loggingin::handle(server, client_id, response, message) {
                    LoginResult::Unchanged => (),
                    LoginResult::Complete => {
                        if let Some(client) = server.anteroom.remove_client(client_id) {
                            server.add_client(client_id, client);
                            common::join_lobby(server, response);
                        }
                    }
                    LoginResult::Exit => {
                        server.anteroom.remove_client(client_id);
                        response.remove_client(client_id);
                    }
                }
            } else if server.clients.contains(client_id) {
                match message {
                    HWProtocolMessage::Quit(Some(msg)) => {
                        common::remove_client(server, response, "User quit: ".to_string() + &msg);
                    }
                    HWProtocolMessage::Quit(None) => {
                        common::remove_client(server, response, "User quit".to_string());
                    }
                    HWProtocolMessage::Info(nick) => {
                        if let Some(client) = server.find_client(&nick) {
                            let admin_sign = if client.is_admin() { "@" } else { "" };
                            let master_sign = if client.is_master() { "+" } else { "" };
                            let room_info = match client.room_id {
                                Some(room_id) => {
                                    let room = &server.rooms[room_id];
                                    let status = match room.game_info {
                                        Some(_) if client.teams_in_game == 0 => "(spectating)",
                                        Some(_) => "(playing)",
                                        None => "",
                                    };
                                    format!(
                                        "[{}{}room {}]{}",
                                        admin_sign, master_sign, room.name, status
                                    )
                                }
                                None => format!("[{}lobby]", admin_sign),
                            };

                            let info = vec![
                                client.nick.clone(),
                                utils::protocol_version_string(client.protocol_number).to_string(),
                                room_info,
                            ];
                            Info(info);
                        } else {
                            response
                                .add(server_chat("Player is not online.".to_string()).send_self())
                        }
                    }
                    HWProtocolMessage::ToggleServerRegisteredOnly => {
                        if !server.clients[client_id].is_admin() {
                            response.add(Warning("Access denied.".to_string()).send_self());
                        } else {
                            server.set_is_registered_only(server.is_registered_only());
                            let msg = if server.is_registered_only() {
                                "This server no longer allows unregistered players to join."
                            } else {
                                "This server now allows unregistered players to join."
                            };
                            response.add(server_chat(msg.to_string()).send_all());
                        }
                    }
                    HWProtocolMessage::Global(msg) => {
                        if !server.clients[client_id].is_admin() {
                            response.add(Warning("Access denied.".to_string()).send_self());
                        } else {
                            response.add(global_chat(msg).send_all())
                        }
                    }
                    HWProtocolMessage::SuperPower => {
                        if !server.clients[client_id].is_admin() {
                            response.add(Warning("Access denied.".to_string()).send_self());
                        } else {
                            server.clients[client_id].set_has_super_power(true);
                            response
                                .add(server_chat("Super power activated.".to_string()).send_self())
                        }
                    }
                    HWProtocolMessage::Watch(id) => {
                        #[cfg(feature = "official-server")]
                        {
                            response.request_io(IoTask::GetReplay { id })
                        }

                        #[cfg(not(feature = "official-server"))]
                        {
                            response.add(
                                Warning("This server does not support replays!".to_string())
                                    .send_self(),
                            );
                        }
                    }
                    _ => match server.clients[client_id].room_id {
                        None => lobby::handle(server, client_id, response, message),
                        Some(room_id) => {
                            inroom::handle(server, client_id, response, room_id, message)
                        }
                    },
                }
            }
        }
    }
}

pub fn handle_client_accept(server: &mut HWServer, client_id: ClientId, response: &mut Response) {
    let mut salt = [0u8; 18];
    thread_rng().fill_bytes(&mut salt);

    server.anteroom.add_client(client_id, encode(&salt));

    response.add(HWServerMessage::Connected(utils::SERVER_VERSION).send_self());
}

pub fn handle_client_loss(server: &mut HWServer, client_id: ClientId, response: &mut Response) {
    if server.anteroom.remove_client(client_id).is_none() {
        common::remove_client(server, response, "Connection reset".to_string());
    }
}

pub fn handle_io_result(
    server: &mut HWServer,
    client_id: ClientId,
    response: &mut Response,
    io_result: IoResult,
) {
    match io_result {
        IoResult::Account(Some(info)) => {
            if !info.is_registered && server.is_registered_only() {
                response.add(
                    Bye("This server only allows registered users to join.".to_string())
                        .send_self(),
                );
                response.remove_client(client_id);
            } else {
                response.add(ServerAuth(format!("{:x}", info.server_hash)).send_self());
                if let Some(client) = server.anteroom.remove_client(client_id) {
                    server.add_client(client_id, client);
                    let client = &mut server.clients[client_id];
                    client.set_is_registered(info.is_registered);
                    client.set_is_admin(info.is_admin);
                    client.set_is_contributor(info.is_admin)
                }
            }
        }
        IoResult::Account(None) => {
            response.add(Error("Authentication failed.".to_string()).send_self());
            response.remove_client(client_id);
        }
        IoResult::Replay(Some(replay)) => {
            response.add(RoomJoined(vec![server.clients[client_id].nick.clone()]).send_self());
            common::get_room_config_impl(&replay.config, client_id, response);
            common::get_teams(replay.teams.iter(), client_id, response);
            response.add(RunGame.send_self());
            response.add(ForwardEngineMessage(replay.message_log).send_self());
            response.add(Kicked.send_self());
        }
        IoResult::Replay(None) => {
            response.add(Warning("Could't load the replay".to_string()).send_self())
        }
        IoResult::SaveRoom(_, true) => {
            response.add(server_chat("Room configs saved successfully.".to_string()).send_self());
        }
        IoResult::SaveRoom(_, false) => {
            response.add(Warning("Unable to save the room configs.".to_string()).send_self());
        }
        IoResult::LoadRoom(room_id, Some(contents)) => {
            if let Some(ref mut room) = server.rooms.get_mut(room_id) {
                match room.set_saves(&contents) {
                    Ok(_) => response.add(
                        server_chat("Room configs loaded successfully.".to_string()).send_self(),
                    ),
                    Err(e) => {
                        warn!("Error while deserializing the room configs: {}", e);
                        response.add(
                            Warning("Unable to deserialize the room configs.".to_string())
                                .send_self(),
                        );
                    }
                }
            }
        }
        IoResult::LoadRoom(_, None) => {
            response.add(Warning("Unable to load the room configs.".to_string()).send_self());
        }
    }
}
