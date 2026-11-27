use std::iter::Iterator;

use self::{
    actions::{Destination, DestinationGroup, PendingMessage},
    inanteroom::LoginResult,
    strings::*,
};
use crate::handlers::actions::ToPendingMessage;
use crate::{
    core::{
        anteroom::HwAnteroom,
        config::ServerConfig,
        server::{HwRoomOrServer, HwServer},
        types::{ClientId, Replay, RoomId},
    },
    utils::{self, loc},
};
use hedgewars_network_protocol::messages::{
    global_chat, server_chat, HwProtocolMessage, HwServerMessage, HwServerMessage::*,
};

use crate::core::digest::Sha1Digest;
use base64::encode;
use log::*;
use rand::{thread_rng, RngCore};

mod actions;
mod checker;
mod common;
mod help;
mod inanteroom;
mod inlobby;
mod inroom;
mod strings;

pub struct ServerState {
    pub server: HwServer,
    pub anteroom: HwAnteroom,
    pub config: Option<ServerConfig>,
}

impl ServerState {
    pub fn new(clients_limit: usize, rooms_limit: usize) -> Self {
        let mut server = HwServer::new(clients_limit, rooms_limit);
        let mut anteroom = HwAnteroom::new(clients_limit);
        let config = ServerConfig::load(&mut server, &mut anteroom);
        Self {
            server,
            anteroom,
            config,
        }
    }

    pub fn flush_config(&mut self) {
        let bans_dirty = self.anteroom.bans.take_dirty();
        let srv_dirty = self.server.take_config_dirty();
        if bans_dirty || srv_dirty {
            if let Some(ref mut cfg) = self.config {
                cfg.save(&self.server, &self.anteroom);
            }
        }
    }

    pub fn has_client(&self, client_id: ClientId) -> bool {
        self.anteroom.has_client(client_id)
            || self.server.has_client(client_id)
            || self.server.is_checker(client_id)
    }

    pub fn assert_invariants(&self) {
        #[cfg(debug_assertions)]
        {
            for id in self.anteroom.iter_client_ids() {
                debug_assert!(
                    !self.server.has_client(id) && !self.server.is_checker(id),
                    "Client {} is in both anteroom and server",
                    id
                );
            }
            for id in self.server.iter_client_ids() {
                debug_assert!(
                    !self.anteroom.has_client(id),
                    "Client {} is in both server and anteroom",
                    id
                );
            }
            self.server.assert_invariants();
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
    StoreAchievements {
        protocol: u16,
        filename: String,
        teams: Vec<(String, String)>,
        game_details: crate::server::demo::GameDetails,
        info: Vec<String>,
    },
}

#[derive(Debug)]
pub enum IoResult {
    AccountRegistered(bool),
    Account(Option<AccountInfo>),
    CheckerAccount { is_registered: bool, is_admin: bool },
    Replay(Option<Box<Replay>>),
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
                DestinationGroup::LobbyWithProtocol(proto) => server
                    .lobby_client_ids()
                    .filter(|id| server.client(*id).protocol_number == proto)
                    .collect(),
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

fn generate_reconnection_token() -> String {
    let mut bytes = [0u8; 16];
    thread_rng().fill_bytes(&mut bytes);
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    format!(
        "{:02x}{:02x}{:02x}{:02x}-{:02x}{:02x}-{:02x}{:02x}-{:02x}{:02x}-{:02x}{:02x}{:02x}{:02x}{:02x}{:02x}",
        bytes[0], bytes[1], bytes[2], bytes[3],
        bytes[4], bytes[5], bytes[6], bytes[7],
        bytes[8], bytes[9], bytes[10], bytes[11],
        bytes[12], bytes[13], bytes[14], bytes[15],
    )
}

fn finish_client_login(
    state: &mut ServerState,
    client_id: ClientId,
    mut client: crate::core::anteroom::HwAnteroomClient,
    response: &mut Response,
) {
    let is_checker = client.is_checker;
    let proto = client.protocol_number.map_or(0, |p| p.get());
    let nick = client.nick.clone().unwrap_or_default();
    let host = client.host_string();

    if is_checker {
        state.server.add_client(client_id, client);
        info!(
            "Checker '{}' (id: {}, proto: {}) joined the server",
            nick, client_id, proto
        );
        return;
    }

    if proto < 60 {
        client.token = None;
    } else if let Some(ref token) = client.token {
        if let Some(existing_id) = state.server.find_client_by_nick_and_token(&nick, token) {
            info!(
                "Client '{}' (id: {}) reconnected with matching token, kicking existing client (id: {})",
                nick, client_id, existing_id
            );
            let mut kick_response = Response::new(existing_id);
            common::remove_client_by_id(
                &mut state.server,
                &mut state.anteroom,
                existing_id,
                &mut kick_response,
                loc("Reconnected from another client").to_string(),
            );
            for (ids, msg) in kick_response.extract_messages(&state.server) {
                response.add(msg.send_many(ids));
            }
            for removed_id in kick_response.extract_removed_clients() {
                response.remove_client(removed_id);
            }
        }
    } else {
        let token = generate_reconnection_token();
        client.token = Some(token.clone());
        response.add(Token(token).send_self());
    }

    state.server.add_client(client_id, client);
    info!(
        "Client '{}' (id: {}, host: {}) joined the server",
        nick, client_id, host
    );
    common::get_lobby_join_data(&state.server, response);

    if proto >= 60 {
        if let Some(rejoin_room_id) = state.server.find_rejoin_room_id(client_id) {
            let protocols = state.server.all_client_protocols();
            if let Ok((client, master, room, room_clients)) =
                state.server.rejoin_room(client_id, rejoin_room_id)
            {
                info!(
                    "Client '{}' automatically rejoined room '{}' (id: {})",
                    client.nick, room.name, room.id
                );
                response.add(Joining(room.name.clone()).send_self());
                common::get_room_join_data(
                    &mut protocols.into_iter(),
                    client,
                    master,
                    room,
                    room_clients,
                    response,
                );
            }
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
        HwProtocolMessage::Pong => {
            if state.anteroom.has_client(client_id) {
                let client = state.anteroom.get_client_mut(client_id);
                if client.pings_queue == 0 {
                    response.error(loc("Protocol violation"));
                } else {
                    client.pings_queue -= 1;
                }
            } else if state.server.has_client(client_id) && !state.server.is_checker(client_id) {
                let client = state.server.client_mut(client_id);
                if client.pings_queue == 0 {
                    response.error(loc("Protocol violation"));
                } else {
                    client.pings_queue -= 1;
                }
            }
        }
        _ => {
            if state.anteroom.has_client(client_id) {
                match inanteroom::handle(
                    &state.server,
                    &mut state.anteroom,
                    client_id,
                    response,
                    message,
                ) {
                    LoginResult::Unchanged => (),
                    LoginResult::Complete(client) => {
                        finish_client_login(state, client_id, client, response);
                    }
                    LoginResult::Exit => {
                        state.anteroom.remove_client(client_id);
                        response.remove_client(client_id);
                    }
                }
            } else if state.server.has_client(client_id) || state.server.is_checker(client_id) {
                if state.server.is_checker(client_id) {
                    match message {
                        HwProtocolMessage::Quit(Some(msg)) => {
                            common::remove_client(
                                &mut state.server,
                                &mut state.anteroom,
                                response,
                                msg,
                            );
                        }
                        HwProtocolMessage::Quit(None) => {
                            common::remove_client(
                                &mut state.server,
                                &mut state.anteroom,
                                response,
                                loc("bye").to_string(),
                            );
                        }
                        _ => checker::handle(&mut state.server, client_id, response, message),
                    }
                } else {
                    match message {
                        HwProtocolMessage::Quit(Some(msg)) => {
                            common::remove_client(
                                &mut state.server,
                                &mut state.anteroom,
                                response,
                                msg,
                            );
                        }
                        HwProtocolMessage::Quit(None) => {
                            common::remove_client(
                                &mut state.server,
                                &mut state.anteroom,
                                response,
                                loc("bye").to_string(),
                            );
                        }
                        HwProtocolMessage::Info(nick) => {
                            let is_admin_asking = state.server.is_admin(client_id);
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

                                let host_str = if is_admin_asking {
                                    format!("[{}]", client.host)
                                } else {
                                    "[]".to_string()
                                };

                                let info = vec![
                                    client.nick.clone(),
                                    host_str,
                                    utils::protocol_version_string(client.protocol_number)
                                        .to_string(),
                                    room_info,
                                ];
                                response.add(Info(info).send_self())
                            } else {
                                response.add(server_chat(USER_OFFLINE.to_string()).send_self())
                            }
                        }
                        HwProtocolMessage::Help => {
                            let client = state.server.client(client_id);
                            help::send_help(client.room_id.is_some(), client.is_admin(), response);
                        }
                        HwProtocolMessage::ToggleServerRegisteredOnly => {
                            if state.server.is_admin(client_id) {
                                let admin_nick = state.server.client(client_id).nick.clone();
                                state
                                    .server
                                    .set_is_registered_only(!state.server.is_registered_only());
                                info!(
                                    "Admin '{}' updated server variable registered_only to {}",
                                    admin_nick,
                                    state.server.is_registered_only()
                                );
                                let msg = if state.server.is_registered_only() {
                                    REGISTERED_ONLY_ENABLED
                                } else {
                                    REGISTERED_ONLY_DISABLED
                                };
                                response.add(server_chat(msg.to_string()).send_all());
                            }
                        }
                        HwProtocolMessage::Global(msg) => {
                            if state.server.is_admin(client_id) {
                                let admin_nick = state.server.client(client_id).nick.clone();
                                info!("Global announcement from '{}': {}", admin_nick, msg);
                                response.add(global_chat(msg).send_all())
                            }
                        }
                        HwProtocolMessage::SuperPower => {
                            if state.server.enable_super_power(client_id) {
                                response.add(server_chat(SUPER_POWER.to_string()).send_self())
                            }
                        }
                        HwProtocolMessage::ClearAccountsCache => {
                            // No-op (or only for admin)
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
                            HwRoomOrServer::Room(control) => {
                                inroom::handle(control, &mut state.anteroom, response, message)
                            }
                            HwRoomOrServer::Server(server) => inlobby::handle(
                                server,
                                &mut state.anteroom,
                                client_id,
                                response,
                                message,
                            ),
                        },
                    }
                }
            }
        }
    }
    state.assert_invariants();
    state.flush_config();
}

pub fn handle_client_accept(
    state: &mut ServerState,
    client_id: ClientId,
    response: &mut Response,
    addr: std::net::IpAddr,
    is_local: bool,
) -> bool {
    let ip_str = addr.to_string();
    let accepted = if let Err(reason) = state.anteroom.try_accept(Some(addr)) {
        warn!("Failed server connect from {}: {}", ip_str, reason);
        response.add(Bye(reason).send_self());
        response.remove_client(client_id);
        false
    } else {
        info!("Client connected from {} (id: {})", ip_str, client_id);
        let mut salt = [0u8; 18];
        thread_rng().fill_bytes(&mut salt);

        state
            .anteroom
            .add_client_with_ip(client_id, encode(salt), is_local, Some(addr));

        response
            .add(Connected(utils::SERVER_MESSAGE.to_owned(), utils::SERVER_VERSION).send_self());
        true
    };
    state.assert_invariants();
    state.flush_config();
    accepted
}

pub fn handle_ping_sent(state: &mut ServerState, client_id: ClientId) {
    if state.anteroom.has_client(client_id) {
        state.anteroom.get_client_mut(client_id).pings_queue += 1;
    } else if state.server.has_client(client_id) && !state.server.is_checker(client_id) {
        state.server.client_mut(client_id).pings_queue += 1;
    }
}

pub fn handle_client_loss(state: &mut ServerState, client_id: ClientId, response: &mut Response) {
    if let Some(c) = state.anteroom.remove_client(client_id) {
        let nick_str = c.nick.as_deref().unwrap_or("<unnamed>");
        info!(
            "Client '{}' (id: {}) disconnected from anteroom",
            nick_str, client_id
        );
    } else {
        common::remove_client(
            &mut state.server,
            &mut state.anteroom,
            response,
            loc("Connection closed").to_string(),
        );
    }
    state.assert_invariants();
}

pub fn handle_client_timed_out(
    state: &mut ServerState,
    client_id: ClientId,
    response: &mut Response,
) {
    if let Some(c) = state.anteroom.remove_client(client_id) {
        let nick_str = c.nick.as_deref().unwrap_or("<unnamed>");
        info!(
            "Client '{}' (id: {}) timed out in anteroom",
            nick_str, client_id
        );
        response.add(Bye(loc("Ping timeout").to_string()).send_self());
        response.remove_client(client_id);
    } else {
        common::remove_client(
            &mut state.server,
            &mut state.anteroom,
            response,
            loc("Ping timeout").to_string(),
        );
    }
    state.assert_invariants();
}

pub fn handle_io_result(
    state: &mut ServerState,
    client_id: ClientId,
    response: &mut Response,
    io_result: IoResult,
) {
    match io_result {
        IoResult::AccountRegistered(is_registered) => {
            if !state.anteroom.has_client(client_id) {
                return;
            }
            let is_no_anon = state
                .anteroom
                .no_anon
                .matches_opt(state.anteroom.get_client(client_id).ip_addr);
            if !is_registered && is_no_anon {
                let nick = state
                    .anteroom
                    .get_client(client_id)
                    .nick
                    .clone()
                    .unwrap_or_default();
                warn!("Client '{}' (id: {}) failed to join server: registered account required from this IP", nick, client_id);
                state.anteroom.remove_client(client_id);
                response.error(loc(
                    "Registered account is required when logging in from this IP address",
                ));
                response.remove_client(client_id);
            } else if !is_registered && state.server.is_registered_only() {
                let nick = state
                    .anteroom
                    .get_client(client_id)
                    .nick
                    .clone()
                    .unwrap_or_default();
                warn!(
                    "Client '{}' (id: {}) failed to join server: registration required",
                    nick, client_id
                );
                state.anteroom.remove_client(client_id);
                response.add(Bye(REGISTRATION_REQUIRED.to_string()).send_self());
                response.remove_client(client_id);
            } else if is_registered {
                let client = state.anteroom.get_client_mut(client_id);
                client.has_password_challenge = true;
                let proto = client.protocol_number.map_or(0, |p| p.get());
                let salt = if proto < 48 {
                    String::new()
                } else {
                    client.server_salt.clone()
                };
                response.add(AskPassword(salt).send_self());
            } else if let Some(client) = state.anteroom.remove_client(client_id) {
                finish_client_login(state, client_id, client, response);
            }
        }
        IoResult::Account(None) => {
            if !state.anteroom.has_client(client_id) {
                return;
            }
            let nick = state
                .anteroom
                .get_client(client_id)
                .nick
                .clone()
                .unwrap_or_default();
            warn!(
                "Client '{}' (id: {}) failed to join server: authentication failed",
                nick, client_id
            );
            state.anteroom.remove_client(client_id);
            response.add(Bye(AUTHENTICATION_FAILED.to_string()).send_self());
            response.remove_client(client_id);
        }
        IoResult::Account(Some(info)) => {
            if !state.anteroom.has_client(client_id) {
                return;
            }
            if let Some(mut client) = state.anteroom.remove_client(client_id) {
                let proto = client.protocol_number.map_or(0, |p| p.get());
                if proto >= 48 {
                    response.add(ServerAuth(format!("{:x}", info.server_hash)).send_self());
                }
                client.is_registered = info.is_registered;
                client.is_admin = info.is_admin;
                client.is_contributor = info.is_contributor;
                finish_client_login(state, client_id, client, response);
                if proto < 48 && info.is_admin {
                    response.add(AdminAccess.send_self());
                }
            }
        }
        IoResult::CheckerAccount {
            is_registered,
            is_admin,
        } => {
            if !state.anteroom.has_client(client_id) {
                return;
            }
            let nick = state
                .anteroom
                .get_client(client_id)
                .nick
                .clone()
                .unwrap_or_default();
            if !is_registered {
                warn!(
                    "Checker '{}' (id: {}) failed to join server: authentication failed",
                    nick, client_id
                );
                state.anteroom.remove_client(client_id);
                response.add(Bye(AUTHENTICATION_FAILED.to_string()).send_self());
                response.remove_client(client_id);
            } else if !is_admin {
                warn!(
                    "Checker '{}' (id: {}) failed to join server: no checker rights",
                    nick, client_id
                );
                state.anteroom.remove_client(client_id);
                response.add(Bye(NO_CHECKER_RIGHTS.to_string()).send_self());
                response.remove_client(client_id);
            } else if let Some(client) = state.anteroom.remove_client(client_id) {
                let proto = client.protocol_number.map_or(0, |p| p.get());
                info!(
                    "Checker '{}' (id: {}, proto: {}) joined the server",
                    nick, client_id, proto
                );
                state.server.add_client(client_id, client);
                response.add(LogonPassed.send_self());
            }
        }
        IoResult::Replay(Some(replay)) => {
            if !state.server.has_client(client_id) {
                return;
            }
            let client = state.server.client(client_id);
            let protocol = client.protocol_number;
            let start_msg = if protocol < 58 {
                RoomJoined(vec![client.nick.clone()])
            } else {
                ReplayStart
            };
            response.add(start_msg.send_self());

            common::get_room_config_impl(&replay.config, Destination::ToSelf, response);
            common::get_teams(
                replay.teams.iter().map(|t| &t.info),
                Destination::ToSelf,
                response,
            );
            response.add(RunGame.send_self());
            response.add(ForwardEngineMessage(replay.message_log).send_self());

            if protocol < 58 {
                response.add(Kicked.send_self());
            }
        }
        IoResult::Replay(None) => {}
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
    state.assert_invariants();
}

#[cfg(test)]
mod test {
    use super::*;
    use crate::core::digest::Sha1Digest;
    use std::net::IpAddr;

    #[test]
    fn hash_cmp_test() {
        let hash = Sha1Digest([
            0x37, 0xC4, 0x9F, 0x5C, 0xC3, 0xC9, 0xDB, 0xFC, 0x54, 0xAC, 0x22, 0x04, 0xF6, 0x12,
            0x9A, 0xED, 0x69, 0xB1, 0xC4, 0x5C,
        ]);

        assert_eq!(hash, &format!("{:x}", hash)[..]);
    }

    #[test]
    fn ipv6_accept_normalization_and_bans_test() {
        // IPv4-mapped IPv6 addresses normalize to plain IPv4
        let mapped: IpAddr = "::ffff:127.0.0.1".parse().unwrap();
        let norm_mapped = crate::utils::normalize_ip(mapped);
        assert_eq!(norm_mapped, "127.0.0.1".parse::<IpAddr>().unwrap());
        assert!(norm_mapped.is_loopback());

        let mut state = ServerState::new(16, 16);
        let v6_ip: IpAddr = "2001:db8::42".parse().unwrap();
        let mut resp = Response::new(1);
        assert!(handle_client_accept(
            &mut state,
            1,
            &mut resp,
            v6_ip,
            v6_ip.is_loopback()
        ));
        assert_eq!(state.anteroom.get_client(1).host_string(), "2001:db8::42");
        assert!(!state.anteroom.get_client(1).is_local_admin);

        // IPv6 subnet ban rejects subsequent connect from matching subnet
        state.anteroom.bans.add_ip_ban(
            "2001:db8::/32".to_string(),
            "v6 subnet ban".to_string(),
            60,
        );
        let v6_ip2: IpAddr = "2001:db8::99".parse().unwrap();
        let mut resp2 = Response::new(2);
        assert!(!handle_client_accept(
            &mut state, 2, &mut resp2, v6_ip2, false
        ));
    }

    fn test_login(
        state: &mut ServerState,
        client_id: ClientId,
        nick: &str,
        token: Option<&str>,
        proto: u16,
    ) -> Vec<(Vec<ClientId>, HwServerMessage)> {
        let ip = format!("10.0.0.{}", client_id).parse::<IpAddr>().unwrap();
        let mut resp = Response::new(client_id);
        assert!(handle_client_accept(state, client_id, &mut resp, ip, false));
        handle(
            state,
            client_id,
            &mut resp,
            HwProtocolMessage::Nick(nick.to_string(), token.map(str::to_string)),
        );
        handle(state, client_id, &mut resp, HwProtocolMessage::Proto(proto));
        #[cfg(feature = "official-server")]
        {
            let tasks: Vec<_> = resp.extract_io_tasks().collect();
            if tasks
                .iter()
                .any(|t| matches!(t, IoTask::CheckRegistered { .. }))
            {
                handle_io_result(
                    state,
                    client_id,
                    &mut resp,
                    IoResult::AccountRegistered(false),
                );
            }
        }
        resp.extract_messages(&state.server).collect()
    }

    fn make_team(name: &str, color: u8) -> Box<hedgewars_network_protocol::types::TeamInfo> {
        use hedgewars_network_protocol::types::{HedgehogInfo, TeamInfo};
        Box::new(TeamInfo {
            owner: String::new(),
            name: name.to_string(),
            color,
            grave: "Statue".to_string(),
            fort: "Plane".to_string(),
            voice_pack: "Default".to_string(),
            flag: "hedgewars".to_string(),
            difficulty: 0,
            hedgehogs: std::array::from_fn(|i| HedgehogInfo {
                name: format!("h{}", i + 1),
                hat: "NoHat".to_string(),
            }),
            hedgehogs_number: 4,
        })
    }

    #[test]
    fn token_assigned_for_proto_60_and_skipped_for_old_proto_or_checker() {
        let mut state = ServerState::new(16, 16);

        // Compatible client without token gets a random token assigned
        let msgs = test_login(&mut state, 1, "Alice", None, 60);
        let assigned_token = msgs
            .iter()
            .find_map(|(ids, m)| match m {
                Token(t) if ids == &vec![1] => Some(t.clone()),
                _ => None,
            })
            .expect("Expected server to assign a token");
        assert!(!assigned_token.is_empty());
        assert_eq!(
            state.server.client(1).token.as_deref(),
            Some(assigned_token.as_str())
        );

        // Incompatible client (proto < 60) does not get or keep a token
        let old_msgs = test_login(&mut state, 2, "Bob", Some("client-tok"), 59);
        assert!(!old_msgs.iter().any(|(_, m)| matches!(m, Token(_))));
        assert_eq!(state.server.client(2).token, None);

        // Checker does not get a token
        let ip = "10.0.0.2".parse::<IpAddr>().unwrap();
        let mut checker_resp = Response::new(3);
        assert!(handle_client_accept(
            &mut state,
            3,
            &mut checker_resp,
            ip,
            false
        ));
        handle(
            &mut state,
            3,
            &mut checker_resp,
            HwProtocolMessage::Checker(60, "checker".to_string(), "pw".to_string()),
        );
        #[cfg(feature = "official-server")]
        handle_io_result(
            &mut state,
            3,
            &mut checker_resp,
            IoResult::CheckerAccount {
                is_registered: true,
                is_admin: true,
            },
        );
        let checker_msgs: Vec<_> = checker_resp.extract_messages(&state.server).collect();
        assert!(!checker_msgs.iter().any(|(_, m)| matches!(m, Token(_))));
    }

    #[test]
    fn duplicate_nick_with_same_token_kicks_existing_player() {
        let mut state = ServerState::new(16, 16);
        let _ = test_login(&mut state, 1, "Alice", Some("tok-a"), 60);
        assert!(state.server.has_client(1));

        // Different token cannot take the active nick
        let ip = "10.0.0.2".parse::<IpAddr>().unwrap();
        let mut bad_resp = Response::new(2);
        assert!(handle_client_accept(
            &mut state,
            2,
            &mut bad_resp,
            ip,
            false
        ));
        handle(
            &mut state,
            2,
            &mut bad_resp,
            HwProtocolMessage::Nick("Alice".to_string(), Some("tok-b".to_string())),
        );
        handle(&mut state, 2, &mut bad_resp, HwProtocolMessage::Proto(60));
        let bad_msgs: Vec<_> = bad_resp.extract_messages(&state.server).collect();
        assert!(bad_msgs
            .iter()
            .any(|(_, m)| matches!(m, Notice(n) if n == "0")));
        assert!(state.server.has_client(1));
        assert!(state.anteroom.has_client(2));

        // Matching nick and token kicks existing player 1 and lets player 3 in
        let mut ok_resp = Response::new(3);
        assert!(handle_client_accept(&mut state, 3, &mut ok_resp, ip, false));
        handle(
            &mut state,
            3,
            &mut ok_resp,
            HwProtocolMessage::Nick("Alice".to_string(), Some("tok-a".to_string())),
        );
        handle(&mut state, 3, &mut ok_resp, HwProtocolMessage::Proto(60));
        #[cfg(feature = "official-server")]
        handle_io_result(
            &mut state,
            3,
            &mut ok_resp,
            IoResult::AccountRegistered(false),
        );

        let removed: Vec<_> = ok_resp.extract_removed_clients().collect();
        let ok_msgs: Vec<_> = ok_resp.extract_messages(&state.server).collect();
        assert!(removed.contains(&1));
        assert!(!state.server.has_client(1));
        assert!(state.server.has_client(3));
        assert_eq!(state.server.client(3).token.as_deref(), Some("tok-a"));
        assert!(ok_msgs
            .iter()
            .any(|(ids, m)| ids == &vec![1] && matches!(m, Bye(_))));
        assert!(!ok_msgs
            .iter()
            .any(|(ids, m)| ids.contains(&3) && matches!(m, LobbyLeft(_, _))));
        assert!(!ok_msgs.iter().any(|(_, m)| matches!(m, Token(_))));
    }

    #[cfg(feature = "official-server")]
    #[test]
    fn token_does_not_bypass_password_validation() {
        let mut state = ServerState::new(16, 16);
        let ip = "10.0.0.1".parse::<IpAddr>().unwrap();

        // Registered user logs in with token
        let mut resp1 = Response::new(1);
        assert!(handle_client_accept(&mut state, 1, &mut resp1, ip, false));
        handle(
            &mut state,
            1,
            &mut resp1,
            HwProtocolMessage::Nick("RegUser".to_string(), Some("tok-reg".to_string())),
        );
        handle(&mut state, 1, &mut resp1, HwProtocolMessage::Proto(60));
        handle_io_result(&mut state, 1, &mut resp1, IoResult::AccountRegistered(true));
        handle_io_result(
            &mut state,
            1,
            &mut resp1,
            IoResult::Account(Some(AccountInfo {
                is_registered: true,
                is_admin: false,
                is_contributor: false,
                server_hash: Sha1Digest([0; 20]),
            })),
        );
        assert!(state.server.has_client(1));

        // Second client with same nick + token must still pass password check
        let mut resp2 = Response::new(2);
        assert!(handle_client_accept(&mut state, 2, &mut resp2, ip, false));
        handle(
            &mut state,
            2,
            &mut resp2,
            HwProtocolMessage::Nick("RegUser".to_string(), Some("tok-reg".to_string())),
        );
        handle(&mut state, 2, &mut resp2, HwProtocolMessage::Proto(60));
        handle_io_result(&mut state, 2, &mut resp2, IoResult::AccountRegistered(true));
        let ask_msgs: Vec<_> = resp2.extract_messages(&state.server).collect();
        assert!(ask_msgs.iter().any(|(_, m)| matches!(m, AskPassword(_))));
        assert!(state.server.has_client(1));

        // Wrong password fails and does not kick existing user
        handle_io_result(&mut state, 2, &mut resp2, IoResult::Account(None));
        assert!(state.server.has_client(1));
        assert!(!state.server.has_client(2));
    }

    #[test]
    fn unregistered_player_auto_rejoins_running_game_with_matching_token() {
        let mut state = ServerState::new(16, 16);
        let _ = test_login(&mut state, 1, "Master", Some("tok-m"), 60);
        let _ = test_login(&mut state, 2, "Guest", Some("tok-g"), 60);

        let mut resp = Response::new(1);
        handle(
            &mut state,
            1,
            &mut resp,
            HwProtocolMessage::CreateRoom("SecretRoom".to_string(), Some("pw123".to_string())),
        );
        handle(
            &mut state,
            1,
            &mut resp,
            HwProtocolMessage::AddTeam(make_team("TeamM", 0)),
        );

        let mut resp2 = Response::new(2);
        handle(
            &mut state,
            2,
            &mut resp2,
            HwProtocolMessage::JoinRoom("SecretRoom".to_string(), Some("pw123".to_string())),
        );
        handle(
            &mut state,
            2,
            &mut resp2,
            HwProtocolMessage::AddTeam(make_team("TeamG", 1)),
        );
        handle(&mut state, 2, &mut resp2, HwProtocolMessage::ToggleReady);

        handle(
            &mut state,
            1,
            &mut resp,
            HwProtocolMessage::ToggleRestrictJoin,
        );
        handle(
            &mut state,
            1,
            &mut resp,
            HwProtocolMessage::ToggleRegisteredOnly,
        );
        handle(&mut state, 1, &mut resp, HwProtocolMessage::StartGame);

        // Guest disconnects mid-game
        let mut loss_resp = Response::new(2);
        handle_client_loss(&mut state, 2, &mut loss_resp);
        assert!(!state.server.has_client(2));

        // Wrong token with same nick does NOT auto-rejoin
        let wrong_msgs = test_login(&mut state, 3, "Guest", Some("wrong-tok"), 60);
        assert_eq!(state.server.client(3).room_id, None);
        assert!(!wrong_msgs.iter().any(|(_, m)| matches!(m, Joining(_))));

        // Disconnect wrong-token client so nick is free
        let mut loss_resp3 = Response::new(3);
        handle_client_loss(&mut state, 3, &mut loss_resp3);

        // Real Guest reconnects with matching nick and token -> auto-joins running game
        let rejoin_msgs = test_login(&mut state, 4, "Guest", Some("tok-g"), 60);
        let room_id = state
            .server
            .find_room("SecretRoom")
            .expect("room exists")
            .id;
        assert_eq!(state.server.client(4).room_id, Some(room_id));
        assert_eq!(state.server.client(4).teams_in_game, 1);
        assert!(state.server.client(4).is_in_game());
        assert!(rejoin_msgs.iter().any(|(ids, m)| {
            ids == &vec![4] && matches!(m, Joining(name) if name == "SecretRoom")
        }));
        assert!(rejoin_msgs
            .iter()
            .any(|(ids, m)| ids == &vec![4] && matches!(m, RunGame)));
        let expected_g = crate::utils::to_engine_msg(std::iter::once(b'G').chain("TeamG".bytes()));
        assert!(rejoin_msgs.iter().any(|(_, m)| matches!(
            m,
            ForwardEngineMessage(ems) if ems.contains(&expected_g)
        )));
    }
}
