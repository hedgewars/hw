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
use crate::handlers::actions::ToPendingMessage;
use crate::{
    core::{
        anteroom::HwAnteroom,
        room::RoomSave,
        server::{HwRoomOrServer, HwServer},
        types::{ClientId, Replay, RoomId},
    },
    utils,
};
use hedgewars_network_protocol::{
    messages::{
        global_chat, server_chat, HwProtocolMessage, HwProtocolMessage::EngineMessage,
        HwServerMessage, HwServerMessage::*,
    },
    types::{GameCfg, TeamInfo},
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

pub struct ServerState {
    pub server: HwServer,
    pub anteroom: HwAnteroom,
}

impl ServerState {
    pub fn new(clients_limit: usize, rooms_limit: usize) -> Self {
        Self {
            server: HwServer::new(clients_limit, rooms_limit),
            anteroom: HwAnteroom::new(clients_limit),
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
    GetCheckerAccount {
        nick: String,
        password: String,
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
    CheckerAccount { is_registered: bool },
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
                DestinationGroup::All => server.iter_client_ids().collect(),
                DestinationGroup::Lobby => server.lobby_client_ids().collect(),
                DestinationGroup::Protocol(proto) => server.protocol_client_ids(proto).collect(),
                DestinationGroup::Room(id) => server.room_client_ids(id).collect(),
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
    state: &mut ServerState,
    client_id: ClientId,
    response: &mut Response,
    message: HwProtocolMessage,
) {
    match message {
        HwProtocolMessage::Ping => response.add(Pong.send_self()),
        HwProtocolMessage::Pong => (),
        _ => {
            if state.anteroom.clients.contains(client_id) {
                match inanteroom::handle(state, client_id, response, message) {
                    LoginResult::Unchanged => (),
                    LoginResult::Complete => {
                        if let Some(client) = state.anteroom.remove_client(client_id) {
                            let is_checker = client.is_checker;
                            state.server.add_client(client_id, client);
                            if !is_checker {
                                common::get_lobby_join_data(&state.server, response);
                            }
                        }
                    }
                    LoginResult::Exit => {
                        state.anteroom.remove_client(client_id);
                        response.remove_client(client_id);
                    }
                }
            } else if state.server.has_client(client_id) {
                match message {
                    HwProtocolMessage::Quit(Some(msg)) => {
                        common::remove_client(
                            &mut state.server,
                            response,
                            "User quit: ".to_string() + &msg,
                        );
                    }
                    HwProtocolMessage::Quit(None) => {
                        common::remove_client(&mut state.server, response, "User quit".to_string());
                    }
                    HwProtocolMessage::Info(nick) => {
                        if let Some(client) = state.server.find_client(&nick) {
                            let admin_sign = if client.is_admin() { "@" } else { "" };
                            let master_sign = if client.is_master() { "+" } else { "" };
                            let room_info = match client.room_id {
                                Some(room_id) => {
                                    let room = state.server.room(room_id);
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
                        if !state.server.is_admin(client_id) {
                            response.warn(ACCESS_DENIED);
                        } else {
                            state
                                .server
                                .set_is_registered_only(!state.server.is_registered_only());
                            let msg = if state.server.is_registered_only() {
                                REGISTERED_ONLY_ENABLED
                            } else {
                                REGISTERED_ONLY_DISABLED
                            };
                            response.add(server_chat(msg.to_string()).send_all());
                        }
                    }
                    HwProtocolMessage::Global(msg) => {
                        if !state.server.is_admin(client_id) {
                            response.warn(ACCESS_DENIED);
                        } else {
                            response.add(global_chat(msg).send_all())
                        }
                    }
                    HwProtocolMessage::SuperPower => {
                        if state.server.enable_super_power(client_id) {
                            response.add(server_chat(SUPER_POWER.to_string()).send_self())
                        } else {
                            response.warn(ACCESS_DENIED);
                        }
                    }
                    #[allow(unused_variables)]
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
                    _ => match state.server.get_room_control(client_id) {
                        HwRoomOrServer::Room(control) => inroom::handle(control, response, message),
                        HwRoomOrServer::Server(server) => {
                            inlobby::handle(server, client_id, response, message)
                        }
                    },
                }
            }
        }
    }
}

pub fn handle_client_accept(
    state: &mut ServerState,
    client_id: ClientId,
    response: &mut Response,
    addr: [u8; 4],
    is_local: bool,
) -> bool {
    let ban_reason = Some(addr)
        .filter(|_| !is_local)
        .and_then(|a| state.anteroom.find_ip_ban(a));
    if let Some(reason) = ban_reason {
        response.add(HwServerMessage::Bye(reason).send_self());
        response.remove_client(client_id);
        false
    } else {
        let mut salt = [0u8; 18];
        thread_rng().fill_bytes(&mut salt);

        state
            .anteroom
            .add_client(client_id, encode(&salt), is_local);

        response.add(
            HwServerMessage::Connected(utils::SERVER_MESSAGE.to_owned(), utils::SERVER_VERSION)
                .send_self(),
        );
        true
    }
}

pub fn handle_client_loss(state: &mut ServerState, client_id: ClientId, response: &mut Response) {
    if state.anteroom.remove_client(client_id).is_none() {
        common::remove_client(&mut state.server, response, "Connection reset".to_string());
    }
}

pub fn handle_io_result(
    state: &mut ServerState,
    client_id: ClientId,
    response: &mut Response,
    io_result: IoResult,
) {
    match io_result {
        IoResult::AccountRegistered(is_registered) => {
            if !is_registered && state.server.is_registered_only() {
                response.add(Bye(REGISTRATION_REQUIRED.to_string()).send_self());
                response.remove_client(client_id);
            } else if is_registered {
                let client = &state.anteroom.clients[client_id];
                response.add(AskPassword(client.server_salt.clone()).send_self());
            } else if let Some(client) = state.anteroom.remove_client(client_id) {
                state.server.add_client(client_id, client);
                common::get_lobby_join_data(&state.server, response);
            }
        }
        IoResult::Account(None) => {
            response.add(Bye(AUTHENTICATION_FAILED.to_string()).send_self());
            response.remove_client(client_id);
        }
        IoResult::Account(Some(info)) => {
            response.add(ServerAuth(format!("{:x}", info.server_hash)).send_self());
            if let Some(mut client) = state.anteroom.remove_client(client_id) {
                client.is_registered = info.is_registered;
                client.is_admin = info.is_admin;
                client.is_contributor = info.is_contributor;
                state.server.add_client(client_id, client);
                common::get_lobby_join_data(&state.server, response);
            }
        }
        IoResult::CheckerAccount { is_registered } => {
            if is_registered {
                if let Some(client) = state.anteroom.remove_client(client_id) {
                    state.server.add_client(client_id, client);
                    response.add(LogonPassed.send_self());
                }
            } else {
                response.add(Bye(NO_CHECKER_RIGHTS.to_string()).send_self());
                response.remove_client(client_id);
            }
        }
        IoResult::Replay(Some(replay)) => {
            let client = state.server.client(client_id);
            let protocol = client.protocol_number;
            let start_msg = if protocol < 58 {
                RoomJoined(vec![client.nick.clone()])
            } else {
                ReplayStart
            };
            response.add(start_msg.send_self());

            common::get_room_config_impl(&replay.config, Destination::ToSelf, response);
            common::get_teams(replay.teams.iter(), Destination::ToSelf, response);
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
            match state.server.set_room_saves(room_id, &contents) {
                Ok(_) => response.add(server_chat(ROOM_CONFIG_LOADED.to_string()).send_self()),
                Err(e) => {
                    warn!("Error while deserializing the room configs: {}", e);
                    response.warn(ROOM_CONFIG_DESERIALIZE_FAILED);
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
