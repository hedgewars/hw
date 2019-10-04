use mio;
use std::{
    cmp::PartialEq,
    collections::HashMap,
    fmt::{Formatter, LowerHex},
    iter::Iterator,
};

use self::{
    actions::{Destination, DestinationGroup, PendingMessage},
    inanteroom::LoginResult,
    strings::*,
};
use crate::{
    core::{
        room::RoomSave,
        server::HwServer,
        types::{ClientId, GameCfg, Replay, RoomId, TeamInfo},
    },
    protocol::messages::{
        global_chat, server_chat, HwProtocolMessage, HwProtocolMessage::EngineMessage,
        HwServerMessage, HwServerMessage::*,
    },
    utils,
};
use base64::encode;
use log::*;
use rand::{thread_rng, RngCore};

mod actions;
mod checker;
mod common;
mod inanteroom;
mod inlobby;
mod inroom;
mod strings;

#[derive(PartialEq, Debug)]
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

impl PartialEq<&str> for Sha1Digest {
    fn eq(&self, other: &&str) -> bool {
        if other.len() != self.0.len() * 2 {
            false
        } else {
            #[inline]
            fn convert(c: u8) -> u8 {
                if c > b'9' {
                    c.wrapping_sub(b'a').saturating_add(10)
                } else {
                    c.wrapping_sub(b'0')
                }
            }

            other
                .as_bytes()
                .chunks_exact(2)
                .zip(&self.0)
                .all(|(chars, byte)| {
                    if let [hi, lo] = chars {
                        convert(*lo) == byte & 0x0f && convert(*hi) == (byte & 0xf0) >> 4
                    } else {
                        unreachable!()
                    }
                })
        }
    }
}

#[derive(Debug)]
pub struct AccountInfo {
    pub is_registered: bool,
    pub is_admin: bool,
    pub is_contributor: bool,
    pub server_hash: Sha1Digest,
}

pub enum IoTask {
    CheckRegistered {
        nick: String,
    },
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

#[derive(Debug)]
pub enum IoResult {
    AccountRegistered(bool),
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
    pub fn warn(&mut self, message: &str) {
        self.add(Warning(message.to_string()).send_self());
    }

    #[inline]
    pub fn error(&mut self, message: &str) {
        self.add(Error(message.to_string()).send_self());
    }

    #[inline]
    pub fn request_io(&mut self, task: IoTask) {
        self.io_tasks.push(task)
    }

    pub fn extract_messages<'a, 'b: 'a>(
        &'b mut self,
        server: &'a HwServer,
    ) -> impl Iterator<Item = (Vec<ClientId>, HwServerMessage)> + 'a {
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
    server: &HwServer,
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
    server: &mut HwServer,
    client_id: ClientId,
    response: &mut Response,
    message: HwProtocolMessage,
) {
    match message {
        HwProtocolMessage::Ping => response.add(Pong.send_self()),
        HwProtocolMessage::Pong => (),
        _ => {
            if server.anteroom.clients.contains(client_id) {
                match inanteroom::handle(server, client_id, response, message) {
                    LoginResult::Unchanged => (),
                    LoginResult::Complete => {
                        if let Some(client) = server.anteroom.remove_client(client_id) {
                            server.add_client(client_id, client);
                            common::get_lobby_join_data(server, response);
                        }
                    }
                    LoginResult::Exit => {
                        server.anteroom.remove_client(client_id);
                        response.remove_client(client_id);
                    }
                }
            } else if server.clients.contains(client_id) {
                match message {
                    HwProtocolMessage::Quit(Some(msg)) => {
                        common::remove_client(server, response, "User quit: ".to_string() + &msg);
                    }
                    HwProtocolMessage::Quit(None) => {
                        common::remove_client(server, response, "User quit".to_string());
                    }
                    HwProtocolMessage::Info(nick) => {
                        if let Some(client) = server.find_client(&nick) {
                            let admin_sign = if client.is_admin() { "@" } else { "" };
                            let master_sign = if client.is_master() { "+" } else { "" };
                            let room_info = match client.room_id {
                                Some(room_id) => {
                                    let room = server.room(room_id);
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
                                "[]".to_string(),
                                utils::protocol_version_string(client.protocol_number).to_string(),
                                room_info,
                            ];
                            response.add(Info(info).send_self())
                        } else {
                            response.add(server_chat(USER_OFFLINE.to_string()).send_self())
                        }
                    }
                    HwProtocolMessage::ToggleServerRegisteredOnly => {
                        if !server.is_admin(client_id) {
                            response.warn(ACCESS_DENIED);
                        } else {
                            server.set_is_registered_only(!server.is_registered_only());
                            let msg = if server.is_registered_only() {
                                REGISTERED_ONLY_ENABLED
                            } else {
                                REGISTERED_ONLY_DISABLED
                            };
                            response.add(server_chat(msg.to_string()).send_all());
                        }
                    }
                    HwProtocolMessage::Global(msg) => {
                        if !server.is_admin(client_id) {
                            response.warn(ACCESS_DENIED);
                        } else {
                            response.add(global_chat(msg).send_all())
                        }
                    }
                    HwProtocolMessage::SuperPower => {
                        let client = server.client_mut(client_id);
                        if !client.is_admin() {
                            response.warn(ACCESS_DENIED);
                        } else {
                            client.set_has_super_power(true);
                            response.add(server_chat(SUPER_POWER.to_string()).send_self())
                        }
                    }
                    HwProtocolMessage::Watch(id) => {
                        #[cfg(feature = "official-server")]
                        {
                            response.request_io(IoTask::GetReplay { id })
                        }

                        #[cfg(not(feature = "official-server"))]
                        {
                            response.warn(REPLAY_NOT_SUPPORTED);
                        }
                    }
                    _ => match server.client(client_id).room_id {
                        None => inlobby::handle(server, client_id, response, message),
                        Some(room_id) => {
                            inroom::handle(server, client_id, response, room_id, message)
                        }
                    },
                }
            }
        }
    }
}

pub fn handle_client_accept(
    server: &mut HwServer,
    client_id: ClientId,
    response: &mut Response,
    is_local: bool,
) {
    let mut salt = [0u8; 18];
    thread_rng().fill_bytes(&mut salt);

    server
        .anteroom
        .add_client(client_id, encode(&salt), is_local);

    response.add(HwServerMessage::Connected(utils::SERVER_VERSION).send_self());
}

pub fn handle_client_loss(server: &mut HwServer, client_id: ClientId, response: &mut Response) {
    if server.anteroom.remove_client(client_id).is_none() {
        common::remove_client(server, response, "Connection reset".to_string());
    }
}

pub fn handle_io_result(
    server: &mut HwServer,
    client_id: ClientId,
    response: &mut Response,
    io_result: IoResult,
) {
    match io_result {
        IoResult::AccountRegistered(is_registered) => {
            if !is_registered && server.is_registered_only() {
                response.add(Bye(REGISTRATION_REQUIRED.to_string()).send_self());
                response.remove_client(client_id);
            } else if is_registered {
                let salt = server.anteroom.clients[client_id].server_salt.clone();
                response.add(AskPassword(salt).send_self());
            } else if let Some(client) = server.anteroom.remove_client(client_id) {
                server.add_client(client_id, client);
                common::get_lobby_join_data(server, response);
            }
        }
        IoResult::Account(Some(info)) => {
            response.add(ServerAuth(format!("{:x}", info.server_hash)).send_self());
            if let Some(mut client) = server.anteroom.remove_client(client_id) {
                client.is_registered = info.is_registered;
                client.is_admin = info.is_admin;
                client.is_contributor = info.is_contributor;
                server.add_client(client_id, client);
                common::get_lobby_join_data(server, response);
            }
        }
        IoResult::Account(None) => {
            response.error(AUTHENTICATION_FAILED);
            response.remove_client(client_id);
        }
        IoResult::Replay(Some(replay)) => {
            let client = server.client(client_id);
            let protocol = client.protocol_number;
            let start_msg = if protocol < 58 {
                RoomJoined(vec![client.nick.clone()])
            } else {
                ReplayStart
            };
            response.add(start_msg.send_self());

            common::get_room_config_impl(&replay.config, client_id, response);
            common::get_teams(replay.teams.iter(), client_id, response);
            response.add(RunGame.send_self());
            response.add(ForwardEngineMessage(replay.message_log).send_self());

            if protocol < 58 {
                response.add(Kicked.send_self());
            }
        }
        IoResult::Replay(None) => {
            response.warn(REPLAY_LOAD_FAILED);
        }
        IoResult::SaveRoom(_, true) => {
            response.add(server_chat(ROOM_CONFIG_SAVED.to_string()).send_self());
        }
        IoResult::SaveRoom(_, false) => {
            response.warn(ROOM_CONFIG_SAVE_FAILED);
        }
        IoResult::LoadRoom(room_id, Some(contents)) => {
            if let Some(ref mut room) = server.rooms.get_mut(room_id) {
                match room.set_saves(&contents) {
                    Ok(_) => response.add(server_chat(ROOM_CONFIG_LOADED.to_string()).send_self()),
                    Err(e) => {
                        warn!("Error while deserializing the room configs: {}", e);
                        response.warn(ROOM_CONFIG_DESERIALIZE_FAILED);
                    }
                }
            }
        }
        IoResult::LoadRoom(_, None) => {
            response.warn(ROOM_CONFIG_LOAD_FAILED);
        }
    }
}

#[cfg(test)]
mod test {
    use super::Sha1Digest;

    #[test]
    fn hash_cmp_test() {
        let hash = Sha1Digest([
            0x37, 0xC4, 0x9F, 0x5C, 0xC3, 0xC9, 0xDB, 0xFC, 0x54, 0xAC, 0x22, 0x04, 0xF6, 0x12,
            0x9A, 0xED, 0x69, 0xB1, 0xC4, 0x5C,
        ]);

        assert_eq!(hash, &format!("{:x}", hash)[..]);
    }
}
