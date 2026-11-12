use super::{
    anteroom::HwAnteroomClient,
    client::HwClient,
    indexslab::IndexSlab,
    room::HwRoom,
    types::{CheckerId, ClientId, RoomId, Voting},
};
use crate::utils;
use hedgewars_network_protocol::types::{GameCfg, ServerVar, TeamInfo, Vote, VoteType};

use crate::server::replaystorage::{ReplayId, ReplayStorage};

use bitflags::*;
use rand::{self, thread_rng, Rng};
use slab::Slab;
use std::{cmp::min, collections::HashSet};

#[derive(Debug)]
pub enum CreateRoomError {
    InvalidName,
    AlreadyExists,
}

#[derive(Debug)]
pub enum JoinRoomError {
    DoesntExist,
    WrongProtocol,
    WrongPassword,
    Full,
    Restricted,
    RegistrationRequired,
    RoomBanned,
}

#[derive(Debug)]
pub enum LeaveRoomResult {
    RoomRemoved,
    RoomRemains {
        is_empty: bool,
        was_master: bool,
        was_in_game: bool,
        new_master: Option<ClientId>,
        removed_teams: Vec<String>,
        end_game_result: Option<EndGameResult>,
    },
}

#[derive(Debug)]
pub struct ChangeMasterResult {
    pub old_master_id: Option<ClientId>,
    pub new_master_id: ClientId,
}

#[derive(Debug)]
pub enum ChangeMasterError {
    NoAccess,
    AlreadyMaster,
    NoClient,
    ClientNotInRoom,
}

#[derive(Debug)]
pub enum AddTeamError {
    TooManyTeams,
    TooManyHedgehogs,
    TeamAlreadyExists,
    GameInProgress,
    Restricted,
}

#[derive(Debug)]
pub enum RemoveTeamError {
    NoTeam,
    TeamNotOwned,
}

#[derive(Debug)]
pub enum ModifyTeamError {
    NoTeam,
    NotMaster,
}

#[derive(Debug)]
pub enum SetTeamCountError {
    InvalidNumber,
    NotMaster,
}

#[derive(Debug)]
pub enum SetHedgehogsError {
    NoTeam,
    InvalidNumber(u8),
    NotMaster,
}

#[derive(Debug)]
pub enum SetConfigError {
    NotMaster,
    RoomFixed,
}

#[derive(Debug)]
pub enum ModifyRoomNameError {
    NotMaster,
    AccessDenied,
    InvalidName,
    DuplicateName,
}

#[derive(Debug)]
pub enum StartVoteError {
    VotingInProgress,
}

#[derive(Debug)]
pub enum VoteEffect {
    Kicked(ClientId, LeaveRoomResult),
    Map(String),
    Pause,
    NewSeed(GameCfg),
    HedgehogsPerTeam(u8, Vec<String>),
}

#[derive(Debug)]
pub enum VoteResult {
    Submitted,
    Succeeded(VoteEffect),
    Failed,
}

#[derive(Debug)]
pub enum VoteError {
    NoVoting,
    AlreadyVoted,
    NotEntitled,
}

#[derive(Debug)]
pub enum StartGameError {
    NotEnoughClans,
    NotReady,
    AlreadyInGame,
}

#[derive(Debug)]
pub struct EndGameResult {
    pub left_teams: Vec<String>,
    pub unreadied_nicks: Vec<String>,
    pub checker_replay: Option<(CheckerId, Vec<String>)>,
}

#[derive(Debug)]
pub struct UninitializedError();
#[derive(Debug)]
pub struct AccessError();

pub struct ServerGreetings {
    pub for_latest_protocol: String,
    pub for_old_protocols: String,
}

impl ServerGreetings {
    fn new() -> Self {
        Self {
            for_latest_protocol: "\u{1f994} is watching".to_string(),
            for_old_protocols: "\u{1f994} is watching".to_string(),
        }
    }
}

bitflags! {
    pub struct ServerFlags: u8 {
        const REGISTERED_ONLY = 0b0000_1000;
    }
}

pub struct HwChecker {
    pub id: ClientId,
    pub is_ready: bool,
    pub protocol_number: u16,
    pub current_replay: Option<ReplayId>,
    pub current_teams: Vec<(String, String)>,
    pub current_details: Option<crate::server::demo::GameDetails>,
}

impl HwChecker {
    pub fn new(id: ClientId, protocol_number: u16) -> Self {
        Self {
            id,
            is_ready: false,
            protocol_number,
            current_replay: None,
            current_teams: Vec::new(),
            current_details: None,
        }
    }

    pub fn set_is_ready(&mut self, ready: bool) {
        self.is_ready = ready
    }
}

pub struct HwServer {
    clients: IndexSlab<HwClient>,
    rooms: Slab<HwRoom>,
    checkers: IndexSlab<HwChecker>,
    latest_protocol: u16,
    flags: ServerFlags,
    greetings: ServerGreetings,
    config_dirty: bool,
    pub replay_storage: Option<ReplayStorage>,
}

impl HwServer {
    pub fn new(clients_limit: usize, rooms_limit: usize) -> Self {
        //todo!("add reconnection IDs");
        let rooms = Slab::with_capacity(rooms_limit);
        let clients = IndexSlab::with_capacity(clients_limit);
        let checkers = IndexSlab::new();
        Self {
            clients,
            rooms,
            checkers,
            greetings: ServerGreetings::new(),
            latest_protocol: 58,
            flags: ServerFlags::empty(),
            config_dirty: false,
            replay_storage: Some(ReplayStorage::new()),
        }
    }

    pub fn take_config_dirty(&mut self) -> bool {
        let dirty = self.config_dirty;
        self.config_dirty = false;
        dirty
    }

    pub fn latest_protocol(&self) -> u16 {
        self.latest_protocol
    }

    pub fn set_latest_protocol(&mut self, proto: u16) {
        self.latest_protocol = proto;
    }

    pub fn latest_greeting(&self) -> &str {
        &self.greetings.for_latest_protocol
    }

    pub fn set_latest_greeting(&mut self, msg: String) {
        self.greetings.for_latest_protocol = msg;
    }

    pub fn old_greeting(&self) -> &str {
        &self.greetings.for_old_protocols
    }

    pub fn set_old_greeting(&mut self, msg: String) {
        self.greetings.for_old_protocols = msg;
    }

    pub fn find_ready_checker(&self, protocol: u16) -> Option<CheckerId> {
        self.checkers
            .iter()
            .find(|(_, c)| c.is_ready && c.protocol_number == protocol)
            .map(|(id, _)| id)
    }

    pub fn assign_replay_to_checker(
        &mut self,
        checker_id: CheckerId,
    ) -> Option<(CheckerId, Vec<String>)> {
        let protocol = self.checkers.get(checker_id)?.protocol_number;
        let (id, replay) = self.replay_storage.as_mut()?.pick_replay(protocol)?;
        let (details, demo_msgs) = crate::server::demo::replay_to_demo(&replay);
        let teams = replay
            .teams
            .iter()
            .map(|t| (t.name.clone(), t.owner.clone()))
            .collect();
        if let Some(c) = self.checkers.get_mut(checker_id) {
            c.set_is_ready(false);
            c.current_replay = Some(id);
            c.current_teams = teams;
            c.current_details = details;
        }
        Some((checker_id, demo_msgs))
    }

    pub fn all_client_protocols(&self) -> HashSet<u16> {
        self.clients
            .iter()
            .map(|(_, c)| c.protocol_number)
            .collect()
    }

    #[inline]
    pub fn client(&self, client_id: ClientId) -> &HwClient {
        &self.clients[client_id]
    }

    #[inline]
    pub fn client_mut(&mut self, client_id: ClientId) -> &mut HwClient {
        &mut self.clients[client_id]
    }

    #[inline]
    pub fn get_checker_mut(&mut self, checker_id: CheckerId) -> Option<&mut HwChecker> {
        self.checkers.get_mut(checker_id)
    }

    #[inline]
    pub fn has_client(&self, client_id: ClientId) -> bool {
        self.clients.contains(client_id)
    }

    #[inline]
    pub fn iter_clients(&self) -> impl Iterator<Item = &HwClient> + Clone {
        self.clients.iter().map(|(_, c)| c)
    }

    #[inline]
    pub fn room(&self, room_id: RoomId) -> &HwRoom {
        &self.rooms[room_id]
    }

    #[inline]
    pub fn iter_rooms(&self) -> impl Iterator<Item = &HwRoom> {
        self.rooms.iter().map(|(_, r)| r)
    }

    #[inline]
    pub fn client_and_room(&self, client_id: ClientId, room_id: RoomId) -> (&HwClient, &HwRoom) {
        (&self.clients[client_id], &self.rooms[room_id])
    }

    #[inline]
    fn client_and_room_mut(&mut self, client_id: ClientId) -> Option<(&mut HwClient, &mut HwRoom)> {
        let client = &mut self.clients[client_id];
        if let Some(room_id) = client.room_id {
            Some((client, &mut self.rooms[room_id]))
        } else {
            None
        }
    }

    #[inline]
    pub fn get_room_control(&mut self, client_id: ClientId) -> HwRoomOrServer<'_> {
        HwRoomControl::new(self, client_id)
    }

    #[inline]
    pub fn is_admin(&self, client_id: ClientId) -> bool {
        self.clients
            .get(client_id)
            .map(|c| c.is_admin())
            .unwrap_or(false)
    }

    #[inline]
    pub fn is_checker(&self, client_id: ClientId) -> bool {
        self.checkers.contains(client_id)
    }

    pub fn add_client(&mut self, client_id: ClientId, data: HwAnteroomClient) {
        debug_assert!(!self.clients.contains(client_id) && !self.checkers.contains(client_id));
        if data.is_checker {
            self.checkers.insert(
                client_id,
                HwChecker::new(client_id, data.protocol_number.map_or(0, |p| p.get())),
            );
        } else if data.protocol_number.is_some() && data.nick.is_some() {
            let host = data.host_string();
            let protocol = data.protocol_number.unwrap();
            let nick = data.nick.unwrap();
            let mut client = HwClient::new(client_id, protocol.get(), nick);
            client.host = host;
            client.pings_queue = data.pings_queue;
            client.set_is_registered(data.is_registered);
            client.set_is_contributor(data.is_contributor);
            #[cfg(not(feature = "official-server"))]
            client.set_is_admin(data.is_local_admin || data.is_admin);

            #[cfg(feature = "official-server")]
            client.set_is_admin(data.is_admin);

            self.clients.insert(client_id, client);
        }
    }

    pub fn remove_client(&mut self, client_id: ClientId) {
        if self
            .clients
            .get(client_id)
            .and_then(|c| c.room_id)
            .is_some()
        {
            debug_assert!(
                false,
                "Client {} removed from server while still in a room",
                client_id
            );
            if let HwRoomOrServer::Room(mut control) = self.get_room_control(client_id) {
                control.leave_room();
            }
        }
        self.clients.remove(client_id);
        if let Some(c) = self.checkers.remove(client_id) {
            if let (Some(id), Some(ref mut storage)) =
                (c.current_replay, self.replay_storage.as_mut())
            {
                storage.requeue_replay(&id);
            }
        }
    }

    pub fn assert_invariants(&self) {
        #[cfg(debug_assertions)]
        {
            for (id, client) in self.clients.iter() {
                debug_assert_eq!(client.id, id);
                debug_assert!(!self.checkers.contains(id));
                if let Some(room_id) = client.room_id {
                    debug_assert!(
                        self.rooms.contains(room_id),
                        "Client {} has stale room_id {}",
                        id,
                        room_id
                    );
                    let room = &self.rooms[room_id];
                    if client.is_master() {
                        debug_assert_eq!(
                            room.master_id,
                            Some(id),
                            "Client {} has is_master=true but room {} master_id is {:?}",
                            id,
                            room_id,
                            room.master_id
                        );
                    } else {
                        debug_assert_ne!(
                            room.master_id,
                            Some(id),
                            "Client {} has is_master=false but room {} master_id is Some({})",
                            id,
                            room_id,
                            id
                        );
                    }
                } else {
                    debug_assert!(!client.is_master(), "Lobby client {} has is_master=true", id);
                    debug_assert!(!client.is_ready(), "Lobby client {} has is_ready=true", id);
                    debug_assert!(
                        !client.is_in_game(),
                        "Lobby client {} has is_in_game=true",
                        id
                    );
                    debug_assert!(
                        !client.is_rejoined(),
                        "Lobby client {} has is_rejoined=true",
                        id
                    );
                    debug_assert_eq!(client.teams_in_game, 0);
                    debug_assert!(client.team_indices.is_empty());
                    debug_assert!(client.clan.is_none());
                }
            }

            for (id, checker) in self.checkers.iter() {
                debug_assert_eq!(checker.id, id);
                debug_assert!(!self.clients.contains(id));
            }

            for (room_id, room) in self.rooms.iter() {
                debug_assert_eq!(room.id, room_id);
                let actual_players = self
                    .clients
                    .iter()
                    .filter(|(_, c)| c.room_id == Some(room_id))
                    .count();
                debug_assert_eq!(
                    room.players_number as usize,
                    actual_players,
                    "Room {} players_number ({}) != actual players ({})",
                    room_id,
                    room.players_number,
                    actual_players
                );
                if let Some(master_id) = room.master_id {
                    debug_assert!(
                        self.clients.contains(master_id),
                        "Room {} has stale master_id {}",
                        room_id,
                        master_id
                    );
                    let master = &self.clients[master_id];
                    debug_assert_eq!(
                        master.room_id,
                        Some(room_id),
                        "Room {} master {} is in room {:?}",
                        room_id,
                        master_id,
                        master.room_id
                    );
                    debug_assert!(
                        master.is_master(),
                        "Room {} master {} does not have is_master flag",
                        room_id,
                        master_id
                    );
                }
                for team in &room.teams {
                    debug_assert!(
                        self.clients.contains(team.owner_id),
                        "Room {} team '{}' has stale owner_id {}",
                        room_id,
                        team.info.name,
                        team.owner_id
                    );
                    debug_assert_eq!(
                        self.clients[team.owner_id].room_id,
                        Some(room_id),
                        "Room {} team '{}' owner {} is not in room",
                        room_id,
                        team.info.name,
                        team.owner_id
                    );
                }
                if let Some(ref voting) = room.voting {
                    for &voter_id in &voting.voters {
                        debug_assert!(
                            self.clients.contains(voter_id),
                            "Room {} voting has stale voter_id {}",
                            room_id,
                            voter_id
                        );
                        debug_assert_eq!(
                            self.clients[voter_id].room_id,
                            Some(room_id),
                            "Room {} voter {} is not in room",
                            room_id,
                            voter_id
                        );
                    }
                    for &(voter_id, _) in &voting.votes {
                        debug_assert!(
                            self.clients.contains(voter_id),
                            "Room {} voting has stale vote from {}",
                            room_id,
                            voter_id
                        );
                        debug_assert_eq!(
                            self.clients[voter_id].room_id,
                            Some(room_id),
                            "Room {} vote owner {} is not in room",
                            room_id,
                            voter_id
                        );
                    }
                }
            }
        }
    }

    pub fn get_greetings(&self, client: &HwClient) -> &str {
        if client.protocol_number < self.latest_protocol {
            &self.greetings.for_old_protocols
        } else {
            &self.greetings.for_latest_protocol
        }
    }

    #[inline]
    pub fn create_room(
        &mut self,
        creator_id: ClientId,
        name: String,
        password: Option<String>,
    ) -> Result<(&HwClient, &HwRoom), CreateRoomError> {
        use CreateRoomError::*;
        if utils::is_name_illegal(&name) {
            Err(InvalidName)
        } else if self.has_room(&name) {
            Err(AlreadyExists)
        } else {
            Ok(create_room(
                &mut self.clients[creator_id],
                &mut self.rooms,
                name,
                password,
            ))
        }
    }

    pub fn join_room(
        &mut self,
        client_id: ClientId,
        room_id: RoomId,
        room_password: Option<&str>,
    ) -> Result<
        (
            &HwClient,
            Option<&HwClient>,
            &HwRoom,
            impl Iterator<Item = &HwClient> + Clone,
        ),
        JoinRoomError,
    > {
        use JoinRoomError::*;
        let room = &mut self.rooms[room_id];
        let client = &mut self.clients[client_id];

        if client.protocol_number != room.protocol_number && !client.is_admin() {
            Err(WrongProtocol)
        } else if room.is_join_restricted() && !client.has_super_power() {
            Err(Restricted)
        } else if room.is_registration_required() && !client.is_registered() && !client.is_admin() {
            Err(RegistrationRequired)
        } else if !client.host.is_empty() && room.bans.contains(&client.host) {
            Err(RoomBanned)
        } else if room.password.is_some()
            && room_password != room.password.as_deref()
            && !client.has_super_power()
        {
            Err(WrongPassword)
        } else if room.players_number == u8::MAX {
            Err(Full)
        } else {
            move_to_room(client, room);
            let room_id = room.id;
            Ok((
                &self.clients[client_id],
                room.master_id.map(|id| &self.clients[id]),
                &self.rooms[room_id],
                self.iter_clients()
                    .filter(move |c| c.room_id == Some(room_id)),
            ))
        }
    }

    #[inline]
    pub fn join_room_by_name(
        &mut self,
        client_id: ClientId,
        room_name: &str,
        room_password: Option<&str>,
    ) -> Result<
        (
            &HwClient,
            Option<&HwClient>,
            &HwRoom,
            impl Iterator<Item = &HwClient> + Clone,
        ),
        JoinRoomError,
    > {
        use JoinRoomError::*;
        let room = self.rooms.iter().find(|(_, r)| r.name == room_name);
        if let Some((_, room)) = room {
            let room_id = room.id;
            self.join_room(client_id, room_id, room_password)
        } else if self.clients[client_id].protocol_number < 60 && room_name.starts_with("[v") {
            Err(WrongProtocol)
        } else {
            Err(DoesntExist)
        }
    }

    pub fn enable_super_power(&mut self, client_id: ClientId) -> bool {
        let client = &mut self.clients[client_id];
        if client.is_admin() {
            client.set_has_super_power(true);
        }
        client.is_admin()
    }

    #[inline]
    pub fn set_var(&mut self, client_id: ClientId, var: ServerVar) -> Result<(), AccessError> {
        if self.clients[client_id].is_admin() {
            match var {
                ServerVar::MOTDNew(msg) => self.greetings.for_latest_protocol = msg,
                ServerVar::MOTDOld(msg) => self.greetings.for_old_protocols = msg,
                ServerVar::LatestProto(n) => self.latest_protocol = n,
            }
            self.config_dirty = true;
            Ok(())
        } else {
            Err(AccessError())
        }
    }

    #[inline]
    pub fn get_vars(&self, client_id: ClientId) -> Result<[ServerVar; 3], AccessError> {
        if self.clients[client_id].is_admin() {
            Ok([
                ServerVar::MOTDNew(self.greetings.for_latest_protocol.clone()),
                ServerVar::MOTDOld(self.greetings.for_old_protocols.clone()),
                ServerVar::LatestProto(self.latest_protocol),
            ])
        } else {
            Err(AccessError())
        }
    }

    pub fn get_used_protocols(&self, client_id: ClientId) -> Result<Vec<u16>, AccessError> {
        if self.clients[client_id].is_admin() {
            let mut protocols: HashSet<_> = self
                .clients
                .iter()
                .map(|(_, c)| c.protocol_number)
                .chain(self.rooms.iter().map(|(_, r)| r.protocol_number))
                .collect();
            let mut protocols: Vec<_> = protocols.drain().collect();
            protocols.sort();
            Ok(protocols)
        } else {
            Err(AccessError())
        }
    }

    #[inline]
    pub fn has_room(&self, name: &str) -> bool {
        self.find_room(name).is_some()
    }

    #[inline]
    pub fn find_room(&self, name: &str) -> Option<&HwRoom> {
        self.rooms
            .iter()
            .find_map(|(_, r)| Some(r).filter(|r| r.name == name))
    }

    fn find_room_mut(&mut self, name: &str) -> Option<&mut HwRoom> {
        self.rooms
            .iter_mut()
            .find_map(|(_, r)| Some(r).filter(|r| r.name == name))
    }

    pub fn find_client(&self, nick: &str) -> Option<&HwClient> {
        self.clients
            .iter()
            .find_map(|(_, c)| Some(c).filter(|c| c.nick == nick))
    }

    fn find_client_mut(&mut self, nick: &str) -> Option<&mut HwClient> {
        self.clients
            .iter_mut()
            .find_map(|(_, c)| Some(c).filter(|c| c.nick == nick))
    }

    pub fn iter_client_ids(&self) -> impl Iterator<Item = ClientId> + '_ {
        self.clients.iter().map(|(id, _)| id)
    }

    pub fn filter_clients<'a, F>(&'a self, f: F) -> impl Iterator<Item = ClientId> + 'a
    where
        F: Fn(&(usize, &HwClient)) -> bool + 'a,
    {
        self.clients.iter().filter(f).map(|(_, c)| c.id)
    }

    pub fn filter_rooms<'a, F>(&'a self, f: F) -> impl Iterator<Item = RoomId> + 'a
    where
        F: Fn(&(usize, &HwRoom)) -> bool + 'a,
    {
        self.rooms.iter().filter(f).map(|(_, c)| c.id)
    }

    pub fn collect_client_ids<F>(&self, f: F) -> Vec<ClientId>
    where
        F: Fn(&(usize, &HwClient)) -> bool,
    {
        self.filter_clients(f).collect()
    }

    pub fn collect_nicks<F>(&self, f: F) -> Vec<String>
    where
        F: Fn(&(usize, &HwClient)) -> bool,
    {
        self.clients
            .iter()
            .filter(f)
            .map(|(_, c)| c.nick.clone())
            .collect()
    }

    pub fn lobby_client_ids(&self) -> impl Iterator<Item = ClientId> + '_ {
        self.filter_clients(|(_, c)| c.room_id.is_none())
    }

    pub fn room_client_ids(&self, room_id: RoomId) -> impl Iterator<Item = ClientId> + '_ {
        self.filter_clients(move |(_, c)| c.room_id == Some(room_id))
    }

    pub fn protocol_client_ids(&self, protocol: u16) -> impl Iterator<Item = ClientId> + '_ {
        self.filter_clients(move |(_, c)| c.protocol_number == protocol)
    }

    pub fn protocol_room_ids(&self, protocol: u16) -> impl Iterator<Item = RoomId> + '_ {
        self.filter_rooms(move |(_, r)| r.protocol_number == protocol)
    }

    pub fn other_client_ids_in_room(&self, self_id: ClientId) -> Vec<ClientId> {
        let room_id = self.clients[self_id].room_id;
        self.collect_client_ids(|(id, c)| *id != self_id && c.room_id == room_id)
    }

    pub fn is_registered_only(&self) -> bool {
        self.flags.contains(ServerFlags::REGISTERED_ONLY)
    }

    pub fn set_is_registered_only(&mut self, value: bool) {
        self.flags.set(ServerFlags::REGISTERED_ONLY, value);
        self.config_dirty = true;
    }

    pub fn set_room_saves(&mut self, room_id: RoomId, text: &str) -> Result<(), serde_yaml::Error> {
        if let Some(room) = self.rooms.get_mut(room_id) {
            room.set_saves(text)
        } else {
            Ok(())
        }
    }
}

pub enum HwRoomOrServer<'a> {
    Room(HwRoomControl<'a>),
    Server(&'a mut HwServer),
}

impl<'a> HwRoomOrServer<'a> {
    #[inline]
    pub fn into_room(self) -> Option<HwRoomControl<'a>> {
        match self {
            HwRoomOrServer::Room(control) => Some(control),
            HwRoomOrServer::Server(_) => None,
        }
    }
}

pub struct HwRoomControl<'a> {
    server: &'a mut HwServer,
    client_id: ClientId,
    room_id: RoomId,
    is_room_removed: bool,
}

impl<'a> HwRoomControl<'a> {
    #[inline]
    #[allow(clippy::new_ret_no_self)]
    pub fn new(server: &'a mut HwServer, client_id: ClientId) -> HwRoomOrServer<'a> {
        if let Some(room_id) = server.clients[client_id].room_id {
            HwRoomOrServer::Room(Self {
                server,
                client_id,
                room_id,
                is_room_removed: false,
            })
        } else {
            HwRoomOrServer::Server(server)
        }
    }

    #[inline]
    pub fn server(&self) -> &HwServer {
        self.server
    }

    #[inline]
    pub fn server_mut(&mut self) -> &mut HwServer {
        self.server
    }

    #[inline]
    pub fn client(&self) -> &HwClient {
        &self.server.clients[self.client_id]
    }

    #[inline]
    fn client_mut(&mut self) -> &mut HwClient {
        &mut self.server.clients[self.client_id]
    }

    #[inline]
    pub fn room(&self) -> &HwRoom {
        &self.server.rooms[self.room_id]
    }

    #[inline]
    pub fn room_mut(&mut self) -> &mut HwRoom {
        &mut self.server.rooms[self.room_id]
    }

    #[inline]
    pub fn get(&self) -> (&HwClient, &HwRoom) {
        (self.client(), self.room())
    }

    #[inline]
    fn get_mut(&mut self) -> (&mut HwClient, &mut HwRoom) {
        (
            &mut self.server.clients[self.client_id],
            &mut self.server.rooms[self.room_id],
        )
    }

    fn remove_from_room(&mut self, client_id: ClientId) -> LeaveRoomResult {
        let (client, room) = self
            .server
            .client_and_room_mut(client_id)
            .expect("Caller should have ensured the client is in this room");
        room.players_number -= 1;
        client.room_id = None;

        let is_empty = room.players_number == 0;
        let is_fixed = room.is_fixed();
        let was_master = room.master_id == Some(client.id);
        let was_in_game = client.is_in_game();
        let was_ready = client.is_ready();
        let is_kicked_from_server = client.is_kicked_from_server;
        let mut removed_teams = vec![];

        client.set_is_master(false);
        client.set_is_ready(false);
        client.set_is_in_game(false);
        client.set_is_rejoined(false);
        client.teams_in_game = 0;
        client.team_indices.clear();
        client.clan = None;

        if room.master_id == Some(client.id) {
            room.master_id = None;
        }

        if let Some(ref mut voting) = room.voting {
            voting.voters.retain(|id| *id != client.id);
            voting.votes.retain(|(id, _)| *id != client.id);
        }

        self.is_room_removed = is_empty && !is_fixed;

        if self.is_room_removed {
            room.teams.clear();
            room.voting = None;
            room.game_info = None;
        } else {
            if was_ready && room.ready_players_number > 0 {
                room.ready_players_number -= 1;
            }

            removed_teams = room
                .client_teams(client.id)
                .map(|t| t.name.clone())
                .collect();

            if let Some(ref mut info) = room.game_info {
                info.mark_left_teams(was_in_game, removed_teams.iter());
            }

            for team_name in &removed_teams {
                room.remove_team(team_name);
            }
        }

        if !self.is_room_removed && room.master_id.is_none() {
            let protocol_number = room.protocol_number;
            let new_master_id = if is_fixed {
                None
            } else {
                self.server.room_client_ids(self.room_id).next()
            };

            if let Some(new_master_id) = new_master_id {
                let room = self.room_mut();
                room.master_id = Some(new_master_id);
                let new_master = &mut self.server.clients[new_master_id];
                new_master.set_is_master(true);

                if protocol_number < 42 || is_kicked_from_server {
                    let nick = new_master.nick.clone();
                    self.room_mut().name = nick;
                }
            }

            let room = self.room_mut();
            room.set_join_restriction(false);
            room.set_team_add_restriction(false);
            room.set_unregistered_players_restriction(is_fixed);
        }

        if self.is_room_removed {
            LeaveRoomResult::RoomRemoved
        } else {
            let end_game_result = if was_in_game && self.room().teams_in_game() == Some(0) {
                self.end_game()
            } else {
                None
            };
            LeaveRoomResult::RoomRemains {
                is_empty,
                was_master,
                was_in_game,
                new_master: self.room().master_id,
                removed_teams,
                end_game_result,
            }
        }
    }

    pub fn leave_room(&mut self) -> LeaveRoomResult {
        self.remove_from_room(self.client_id)
    }

    pub fn kick_user(&mut self, client_id: ClientId) -> LeaveRoomResult {
        self.remove_from_room(client_id)
    }

    pub fn change_master(
        &mut self,
        new_master_nick: String,
    ) -> Result<ChangeMasterResult, ChangeMasterError> {
        use ChangeMasterError::*;
        let (client, room) = self.get_mut();

        if client.is_admin() || room.master_id == Some(client.id) {
            let new_master_id = self
                .server
                .clients
                .iter()
                .find(|(_, c)| c.nick == new_master_nick)
                .map(|(id, _)| id);

            match new_master_id {
                Some(new_master_id) if self.room().master_id == Some(new_master_id) => {
                    Err(AlreadyMaster)
                }
                Some(new_master_id) => {
                    let new_master = &mut self.server.clients[new_master_id];
                    if new_master.room_id == Some(self.room_id) {
                        let new_master_nick_str = new_master.nick.clone();
                        self.server.clients[new_master_id].set_is_master(true);
                        let old_master_id = self.room().master_id;

                        if let Some(master_id) = old_master_id {
                            self.server.clients[master_id].set_is_master(false);
                        }
                        let is_fixed = self.room().is_fixed();
                        let proto = self.room().protocol_number;
                        let room = self.room_mut();
                        room.master_id = Some(new_master_id);
                        if proto < 42 && !is_fixed {
                            room.name = new_master_nick_str;
                        }
                        room.set_join_restriction(false);
                        room.set_team_add_restriction(false);
                        room.set_unregistered_players_restriction(is_fixed);
                        Ok(ChangeMasterResult {
                            old_master_id,
                            new_master_id,
                        })
                    } else {
                        Err(ClientNotInRoom)
                    }
                }
                None => Err(NoClient),
            }
        } else {
            Err(NoAccess)
        }
    }

    pub fn start_vote(&mut self, kind: VoteType) -> Result<(), StartVoteError> {
        use StartVoteError::*;
        match self.room().voting {
            Some(_) => Err(VotingInProgress),
            None => {
                let voting = Voting::new(kind, self.server.room_client_ids(self.room_id).collect());
                self.room_mut().voting = Some(voting);
                Ok(())
            }
        }
    }

    fn apply_vote(&mut self, kind: VoteType) -> Option<VoteEffect> {
        match kind {
            VoteType::Kick(nick) => {
                let is_in_game = self.room().game_info.is_some();
                if let Some(kicked_id) = self
                    .server
                    .find_client(&nick)
                    .filter(|c| {
                        c.room_id == Some(self.room_id) && (!is_in_game || c.teams_in_game == 0)
                    })
                    .map(|c| c.id)
                {
                    let leave_result = self.remove_from_room(kicked_id);
                    Some(VoteEffect::Kicked(kicked_id, leave_result))
                } else {
                    None
                }
            }
            VoteType::Map(None) => None,
            VoteType::Map(Some(name)) => {
                if let Some(location) = self.load_config(&name).map(|s| s.to_string()) {
                    if self.room().protocol_number > 51 {
                        let points = super::ghosts::load_ghost_points(&location);
                        let new_dm = self
                            .room()
                            .config()
                            .drawn_map
                            .as_deref()
                            .map(|dm| super::ghosts::prepend_ghost_points(&points, dm));
                        if let Some(dm) = new_dm {
                            self.room_mut().set_config(GameCfg::DrawnMap(dm));
                        }
                    }
                    Some(VoteEffect::Map(location))
                } else {
                    None
                }
            }
            VoteType::Pause => Some(VoteEffect::Pause).filter(|_| self.toggle_pause()),
            VoteType::NewSeed => {
                let seed = thread_rng().gen_range(0..1_000_000_000).to_string();
                let cfg = GameCfg::Seed(seed);
                self.room_mut().set_config(cfg.clone());
                Some(VoteEffect::NewSeed(cfg))
            }
            VoteType::HedgehogsPerTeam(number) => {
                let nicks = self.set_hedgehogs_number(number);
                Some(VoteEffect::HedgehogsPerTeam(number, nicks))
            }
        }
    }

    pub fn vote(&mut self, vote: Vote) -> Result<VoteResult, VoteError> {
        use self::{VoteError::*, VoteResult::*};
        let client_id = self.client_id;
        let is_admin = self.server.clients[client_id].is_admin();
        if let Some(ref mut voting) = self.room_mut().voting {
            if (vote.is_forced && !is_admin) || (!vote.is_forced && !voting.voters.contains(&client_id)) {
                Err(NotEntitled)
            } else if vote.is_forced || voting.votes.iter().all(|(id, _)| client_id != *id) {
                voting.votes.push((client_id, vote.is_pro));
                let i = voting.votes.iter();
                let pro = i.clone().filter(|(_, v)| *v).count();
                let contra = i.filter(|(_, v)| !*v).count();
                let success_quota = voting.voters.len() / 2 + 1;

                if vote.is_forced && !vote.is_pro
                    || contra > voting.voters.len() - success_quota
                {
                    self.room_mut().voting = None;
                    Ok(Failed)
                } else if vote.is_forced && vote.is_pro || pro >= success_quota {
                    let voting = self.room_mut().voting.take().unwrap();
                    if let Some(effect) = self.apply_vote(voting.kind) {
                        Ok(Succeeded(effect))
                    } else {
                        Ok(Failed)
                    }
                } else {
                    Ok(Submitted)
                }
            } else {
                Err(AlreadyVoted)
            }
        } else {
            Err(NoVoting)
        }
    }

    pub fn toggle_flag(&mut self, flags: super::room::RoomFlags) -> bool {
        let (client, room) = self.get_mut();
        if client.is_master() {
            room.flags.toggle(flags);
        }
        client.is_master()
    }

    pub fn fix_room(&mut self) -> Result<(), AccessError> {
        let (client, room) = self.get_mut();
        if client.is_admin() {
            room.set_is_fixed(true);
            Ok(())
        } else {
            Err(AccessError())
        }
    }

    pub fn unfix_room(&mut self) -> Result<(), AccessError> {
        let (client, room) = self.get_mut();
        if client.is_admin() {
            room.set_is_fixed(false);
            Ok(())
        } else {
            Err(AccessError())
        }
    }

    pub fn set_room_name(&mut self, mut name: String) -> Result<String, ModifyRoomNameError> {
        use ModifyRoomNameError::*;
        let room_exists = self.server.has_room(&name);
        let (client, room) = self.get_mut();
        if !client.is_master() {
            Err(NotMaster)
        } else if utils::is_name_illegal(&name) {
            Err(InvalidName)
        } else if room.is_fixed() {
            Err(AccessDenied)
        } else if room_exists {
            Err(DuplicateName)
        } else {
            std::mem::swap(&mut room.name, &mut name);
            Ok(name)
        }
    }

    pub fn set_room_greeting(&mut self, greeting: Option<String>) -> Result<bool, AccessError> {
        let (client, room) = self.get_mut();
        if client.is_admin() || (client.is_master() && !room.is_fixed()) {
            let msg = greeting.unwrap_or_default();
            let is_empty = msg.is_empty();
            room.greeting = msg;
            Ok(is_empty)
        } else {
            Err(AccessError())
        }
    }

    pub fn set_room_max_teams(&mut self, count: u8) -> Result<(), SetTeamCountError> {
        use SetTeamCountError::*;
        let (client, room) = self.get_mut();
        if !client.is_master() {
            Err(NotMaster)
        } else if !(2..=super::room::MAX_TEAMS_IN_ROOM).contains(&count) {
            Err(InvalidNumber)
        } else {
            room.max_teams = count;
            Ok(())
        }
    }

    pub fn set_team_hedgehogs_number(
        &mut self,
        team_name: &str,
        number: u8,
    ) -> Result<(), SetHedgehogsError> {
        use SetHedgehogsError::*;
        let (client, room) = self.get_mut();
        let addable_hedgehogs = room.addable_hedgehogs();
        if let Some((_, team)) = room.find_team_and_owner_mut(|t| t.name == team_name) {
            let max_hedgehogs = min(
                hedgewars_network_protocol::types::MAX_HEDGEHOGS_PER_TEAM,
                addable_hedgehogs + team.hedgehogs_number,
            );
            if !client.is_master() {
                Err(NotMaster)
            } else if !(1..=max_hedgehogs).contains(&number) {
                Err(InvalidNumber(team.hedgehogs_number))
            } else {
                team.hedgehogs_number = number;
                Ok(())
            }
        } else {
            Err(NoTeam)
        }
    }

    pub fn set_hedgehogs_number(&mut self, number: u8) -> Vec<String> {
        self.room_mut().set_hedgehogs_number(number)
    }

    pub fn add_team(&mut self, mut info: Box<TeamInfo>) -> Result<&TeamInfo, AddTeamError> {
        use AddTeamError::*;
        let (client, room) = self.get_mut();
        if room.teams.len() >= room.max_teams as usize {
            Err(TooManyTeams)
        } else if room.addable_hedgehogs() == 0 {
            Err(TooManyHedgehogs)
        } else if room.find_team(|t| t.name == info.name).is_some() {
            Err(TeamAlreadyExists)
        } else if room.game_info.is_some() {
            Err(GameInProgress)
        } else if room.is_team_add_restricted() {
            Err(Restricted)
        } else {
            info.owner = client.nick.clone();
            let team = room.add_team(client, *info, client.protocol_number < 42);
            client.teams_in_game += 1;
            client.clan = Some(team.color);
            Ok(team)
        }
    }

    pub fn remove_team(&mut self, team_name: &str) -> Result<(), RemoveTeamError> {
        use RemoveTeamError::*;
        let (client, room) = self.get_mut();
        match room.find_team_owner(team_name) {
            None => Err(NoTeam),
            Some((id, _)) if id != client.id => Err(TeamNotOwned),
            Some(_) => {
                client.teams_in_game -= 1;
                room.remove_team(team_name);
                client.clan = room.find_team_color(client.id);
                if let Some(ref mut info) = room.game_info {
                    let names = [team_name.to_string()];
                    info.mark_left_teams(client.is_in_game(), names.iter());
                }
                Ok(())
            }
        }
    }

    pub fn set_team_color(&mut self, team_name: &str, color: u8) -> Result<(), ModifyTeamError> {
        use ModifyTeamError::*;
        let (client, room) = self.get_mut();
        if let Some((owner, team)) = room.find_team_and_owner_mut(|t| t.name == team_name) {
            if !client.is_master() {
                Err(NotMaster)
            } else {
                team.color = color;
                self.server.clients[owner].clan = Some(color);
                Ok(())
            }
        } else {
            Err(NoTeam)
        }
    }

    pub fn set_config(&mut self, cfg: GameCfg) -> Result<(), SetConfigError> {
        use SetConfigError::*;
        let (client, room) = self.get_mut();
        if room.is_fixed() {
            Err(RoomFixed)
        } else if !client.is_master() {
            Err(NotMaster)
        } else {
            let cfg = match cfg {
                GameCfg::Scheme(name, mut values) => {
                    if client.protocol_number == 49 && values.len() >= 2 {
                        let mut s = "X".repeat(50);
                        s.push_str(&values.pop().unwrap());
                        values.push(s);
                    }
                    GameCfg::Scheme(name, values)
                }
                cfg => cfg,
            };
            room.set_config(cfg);
            Ok(())
        }
    }

    pub fn save_config(&mut self, name: String, location: String) {
        self.room_mut().save_config(name, location);
    }

    pub fn load_config(&mut self, name: &str) -> Option<&str> {
        self.room_mut().load_config(name)
    }

    pub fn delete_config(&mut self, name: &str) -> bool {
        self.room_mut().delete_config(name)
    }

    pub fn toggle_ready(&mut self) -> bool {
        let (client, room) = self.get_mut();
        client.set_is_ready(!client.is_ready());
        if client.is_ready() {
            room.ready_players_number += 1;
        } else {
            room.ready_players_number -= 1;
        }
        client.is_ready()
    }

    pub fn start_game(&mut self) -> Result<Vec<String>, StartGameError> {
        use StartGameError::*;
        let room_id = self.room_id;
        let (room_clients, room_nicks): (Vec<_>, Vec<_>) = self
            .server
            .clients
            .iter()
            .filter(|(_, c)| c.room_id == Some(room_id))
            .map(|(id, c)| (id, c.nick.clone()))
            .unzip();

        let all_players_registered = {
            let room = &self.server.rooms[room_id];
            room.teams
                .iter()
                .all(|t| self.server.clients[t.owner_id].is_registered())
        };

        let room = self.room_mut();

        if !room.has_multiple_clans() {
            Err(NotEnoughClans)
        } else if room.protocol_number <= 43 && room.players_number != room.ready_players_number {
            Err(NotReady)
        } else if room.game_info.is_some() {
            Err(AlreadyInGame)
        } else {
            room.start_round(all_players_registered);
            for id in room_clients {
                let team_indices = self.room().client_team_indices(id);
                let c = &mut self.server.clients[id];
                c.set_is_in_game(true);
                c.team_indices = team_indices;
            }
            Ok(room_nicks)
        }
    }

    pub fn toggle_pause(&mut self) -> bool {
        if let Some(ref mut info) = self.room_mut().game_info {
            info.is_paused = !info.is_paused;
        }
        self.room_mut().game_info.is_some()
    }

    pub fn leave_game(&mut self) -> Option<Vec<String>> {
        let (client, room) = self.get_mut();
        let client_left = client.is_in_game();
        if client_left {
            client.set_is_in_game(false);

            let team_names: Vec<_> = room
                .client_teams(client.id)
                .map(|t| t.name.clone())
                .collect();

            if let Some(ref mut info) = room.game_info {
                info.log_team_removal(team_names.iter());
                Some(team_names)
            } else {
                None
            }
        } else {
            None
        }
    }

    pub fn end_game(&mut self) -> Option<EndGameResult> {
        let room = self.room_mut();
        room.ready_players_number = room.master_id.is_some() as u8;

        if let Some(info) = room.game_info.take() {
            let room_id = room.id;
            let room_proto = room.protocol_number;
            let mut left_teams = Vec::new();
            for team_name in &info.rejoined_teams {
                if room.find_team(|t| t.name == *team_name).is_some() {
                    room.remove_team(team_name);
                    left_teams.push(team_name.clone());
                }
            }

            #[cfg(feature = "official-server")]
            if info.all_players_registered {
                let replay = super::types::Replay {
                    config: room.config().clone(),
                    teams: info
                        .original_teams
                        .iter()
                        .map(|(_, info)| info.clone())
                        .collect(),
                    message_log: info.msg_log.clone(),
                };
                let uid: u32 = thread_rng().gen_range(10000..100000);
                let filename = format!(
                    "replays/{} UTC-{}.{}",
                    chrono::Utc::now().format("%Y-%m-%d %H:%M:%S%.f"),
                    uid,
                    room_proto
                );
                let _ = replay.save(filename);
            }

            let unreadied_nicks: Vec<_> = self
                .server
                .clients
                .iter_mut()
                .filter(|(_, c)| c.room_id == Some(room_id))
                .map(|(_, c)| {
                    c.set_is_ready(c.is_master());
                    c.set_is_in_game(false);
                    c.set_is_rejoined(false);
                    c.team_indices.clear();
                    c
                })
                .filter_map(|c| {
                    if !c.is_master() {
                        Some(c.nick.clone())
                    } else {
                        None
                    }
                })
                .collect();

            #[cfg(feature = "official-server")]
            let checker_replay = if info.all_players_registered {
                self.server
                    .find_ready_checker(room_proto)
                    .and_then(|cid| self.server.assign_replay_to_checker(cid))
            } else {
                None
            };

            #[cfg(not(feature = "official-server"))]
            let checker_replay = None;

            Some(EndGameResult {
                left_teams,
                unreadied_nicks,
                checker_replay,
            })
        } else {
            None
        }
    }

    pub fn log_engine_msg(&mut self, log_msg: String, sync_msg: Option<Option<String>>) {
        if let Some(ref mut info) = self.room_mut().game_info {
            if !log_msg.is_empty() {
                info.msg_log.push(log_msg);
            }
            if let Some(msg) = sync_msg {
                info.sync_msg = msg;
            }
        }
    }
}

impl<'a> Drop for HwRoomControl<'a> {
    #[inline]
    fn drop(&mut self) {
        if self.is_room_removed {
            debug_assert!(self.server.room_client_ids(self.room_id).next().is_none());
            self.server.rooms.remove(self.room_id);
        }
    }
}

fn allocate_room(rooms: &mut Slab<HwRoom>) -> &mut HwRoom {
    let entry = rooms.vacant_entry();
    let room = HwRoom::new(entry.key());
    entry.insert(room)
}

fn create_room<'a, 'b>(
    client: &'a mut HwClient,
    rooms: &'b mut Slab<HwRoom>,
    name: String,
    password: Option<String>,
) -> (&'a HwClient, &'b HwRoom) {
    debug_assert!(client.room_id.is_none());
    let room = allocate_room(rooms);

    room.master_id = Some(client.id);
    room.name = name;
    room.password = password;
    room.protocol_number = client.protocol_number;

    room.players_number = 1;
    room.ready_players_number = 1;

    client.room_id = Some(room.id);
    client.set_is_master(true);
    client.set_is_ready(true);
    client.set_is_in_game(false);
    client.clan = None;
    client.teams_in_game = 0;
    client.team_indices = vec![];

    (client, room)
}

fn move_to_room(client: &mut HwClient, room: &mut HwRoom) {
    debug_assert!(client.room_id.is_none());
    debug_assert!(room.master_id != Some(client.id));

    room.players_number += 1;

    client.room_id = Some(room.id);
    client.teams_in_game = 0;
    client.set_is_ready(false);
    client.set_is_master(false);
    client.set_is_in_game(room.game_info.is_some());
    client.set_is_rejoined(room.game_info.is_some());
    client.clan = None;
    client.team_indices = vec![];

    #[cfg(feature = "official-server")]
    let can_rejoin = client.protocol_number >= 48 && client.is_registered();

    #[cfg(not(feature = "official-server"))]
    let can_rejoin = client.protocol_number >= 48;

    if can_rejoin {
        if let Some(ref mut info) = room.game_info {
            let mut restored_teams = Vec::new();
            for (owner_nick, team_info) in &info.original_teams {
                if *owner_nick == client.nick {
                    restored_teams.push(super::room::OwnedTeam {
                        owner_id: client.id,
                        owner_nick: owner_nick.clone(),
                        info: team_info.clone(),
                    });
                }
            }

            client.teams_in_game = restored_teams.len() as u8;
            client.clan = restored_teams.first().map(|t| t.info.color);

            if !restored_teams.is_empty() {
                for owned in restored_teams {
                    let name = owned.info.name.clone();
                    info.left_teams.retain(|n| n != &name);
                    if !info.rejoined_teams.contains(&name) {
                        info.rejoined_teams.push(name.clone());
                    }
                    info.teams_in_game += 1;
                    if room.teams.iter().all(|t| t.info.name != name) {
                        room.teams.push(owned);
                    }
                }
            }
        }
        if room.game_info.is_some() {
            client.team_indices = room.client_team_indices(client.id);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use hedgewars_network_protocol::types::HedgehogInfo;
    use std::num::NonZeroU16;

    fn make_anteroom_client(nick: &str, is_admin: bool) -> HwAnteroomClient {
        HwAnteroomClient {
            nick: Some(nick.to_string()),
            protocol_number: NonZeroU16::new(58),
            server_salt: String::new(),
            is_local_admin: is_admin,
            is_registered: true,
            is_admin,
            is_contributor: false,
            is_checker: false,
            ip_addr: Some([127, 0, 0, 1]),
            web_password: String::new(),
            has_password_challenge: false,
            pings_queue: 0,
        }
    }

    fn dummy_team(name: &str, color: u8) -> Box<TeamInfo> {
        Box::new(TeamInfo {
            owner: String::new(),
            name: name.to_string(),
            color,
            grave: "Bone".to_string(),
            fort: "Castle".to_string(),
            voice_pack: "Default".to_string(),
            flag: "hedgewars".to_string(),
            difficulty: 0,
            hedgehogs_number: 4,
            hedgehogs: [
                HedgehogInfo { name: "h1".to_string(), hat: "NoHat".to_string() },
                HedgehogInfo { name: "h2".to_string(), hat: "NoHat".to_string() },
                HedgehogInfo { name: "h3".to_string(), hat: "NoHat".to_string() },
                HedgehogInfo { name: "h4".to_string(), hat: "NoHat".to_string() },
                HedgehogInfo { name: "h5".to_string(), hat: "NoHat".to_string() },
                HedgehogInfo { name: "h6".to_string(), hat: "NoHat".to_string() },
                HedgehogInfo { name: "h7".to_string(), hat: "NoHat".to_string() },
                HedgehogInfo { name: "h8".to_string(), hat: "NoHat".to_string() },
            ],
        })
    }

    #[test]
    fn test_no_stale_ids_on_room_leave_and_id_reuse() {
        let mut server = HwServer::new(16, 16);

        // 1. Client 0 creates a room and leaves it (room removed) -> client 0 must have is_master=false
        server.add_client(0, make_anteroom_client("alice", true));
        server.create_room(0, "room1".to_string(), None).unwrap();
        server.assert_invariants();

        if let HwRoomOrServer::Room(mut ctrl) = server.get_room_control(0) {
            ctrl.add_team(dummy_team("t1", 0)).unwrap();
            let res = ctrl.leave_room();
            assert!(matches!(res, LeaveRoomResult::RoomRemoved));
        }
        server.assert_invariants();
        assert!(!server.client(0).is_master());
        assert!(server.client(0).room_id.is_none());

        // 2. Fixed room: master sets restricted join, fixes room, leaves;
        // flag must be reset so new client can join fixed room without master
        let (_, room) = server.create_room(0, "fixed_room".to_string(), None).unwrap();
        let fixed_room_id = room.id;
        if let HwRoomOrServer::Room(mut ctrl) = server.get_room_control(0) {
            ctrl.toggle_flag(super::super::room::RoomFlags::RESTRICTED_JOIN);
            assert!(ctrl.room().is_join_restricted());
            ctrl.fix_room().unwrap();
            ctrl.leave_room();
        }
        server.remove_client(0);
        server.assert_invariants();
        assert_eq!(server.room(fixed_room_id).master_id, None);
        assert!(!server.room(fixed_room_id).is_join_restricted());

        // New client gets id 0 and joins fixed_room -> must NOT become master, and join must succeed
        server.add_client(0, make_anteroom_client("bob", false));
        let _ = server.join_room(0, fixed_room_id, None).unwrap();
        server.assert_invariants();
        assert!(!server.client(0).is_master());
        assert_eq!(server.room(fixed_room_id).master_id, None);
        if let HwRoomOrServer::Room(mut ctrl) = server.get_room_control(0) {
            ctrl.leave_room();
        }
        server.remove_client(0);
        server.assert_invariants();

        // 3. Voting & mid-game leave with ClientId reuse
        server.add_client(1, make_anteroom_client("p1", false));
        server.add_client(2, make_anteroom_client("p2", false));
        let (_, room) = server.create_room(1, "game_room".to_string(), None).unwrap();
        let game_room_id = room.id;
        let _ = server.join_room(2, game_room_id, None).unwrap();

        if let HwRoomOrServer::Room(mut ctrl) = server.get_room_control(1) {
            ctrl.add_team(dummy_team("team_p1", 0)).unwrap();
        }
        if let HwRoomOrServer::Room(mut ctrl) = server.get_room_control(2) {
            ctrl.add_team(dummy_team("team_p2", 1)).unwrap();
            ctrl.toggle_ready();
        }
        if let HwRoomOrServer::Room(mut ctrl) = server.get_room_control(1) {
            ctrl.start_game().unwrap();
            ctrl.start_vote(VoteType::Pause).unwrap();
            ctrl.vote(Vote { is_pro: true, is_forced: false }).unwrap();
        }
        server.assert_invariants();

        // Player 1 (master, voter, team owner) leaves and disconnects
        if let HwRoomOrServer::Room(mut ctrl) = server.get_room_control(1) {
            ctrl.leave_room();
        }
        server.remove_client(1);
        server.assert_invariants();

        // New client "stranger" reuses ClientId 1 and joins game_room
        server.add_client(1, make_anteroom_client("stranger", false));
        let _ = server.join_room(1, game_room_id, None).unwrap();
        server.assert_invariants();

        // "stranger" must NOT be master, must NOT own any teams, and must NOT be in voting.voters
        assert!(!server.client(1).is_master());
        assert_eq!(server.client(1).teams_in_game, 0);
        assert_eq!(server.room(game_room_id).client_teams(1).count(), 0);
        assert!(
            !server
                .room(game_room_id)
                .voting
                .as_ref()
                .unwrap()
                .voters
                .contains(&1)
        );
    }
}
