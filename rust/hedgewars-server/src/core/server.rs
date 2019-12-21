use super::{
    client::HwClient,
    indexslab::IndexSlab,
    room::HwRoom,
    types::{ClientId, RoomId, ServerVar, TeamInfo},
};
use crate::{protocol::messages::HwProtocolMessage::Greeting, utils};

use bitflags::_core::hint::unreachable_unchecked;
use bitflags::*;
use chrono::{offset, DateTime};
use log::*;
use slab::Slab;
use std::{borrow::BorrowMut, collections::HashSet, iter, mem::replace, num::NonZeroU16};

#[derive(Debug)]
pub enum CreateRoomError {
    InvalidName,
    AlreadyExists,
}

#[derive(Debug)]
pub enum JoinRoomError {
    DoesntExist,
    WrongProtocol,
    Full,
    Restricted,
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
    },
}

#[derive(Debug)]
pub enum LeaveRoomError {
    NoRoom,
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
pub enum ModifyRoomNameError {
    AccessDenied,
    InvalidName,
    DuplicateName,
}

#[derive(Debug)]
pub enum StartGameError {
    NotEnoughClans,
    NotEnoughTeams,
    NotReady,
    AlreadyInGame,
}

#[derive(Debug)]
pub struct EndGameResult {
    pub joined_mid_game_clients: Vec<ClientId>,
    pub left_teams: Vec<String>,
    pub unreadied_nicks: Vec<String>,
}

#[derive(Debug)]
pub struct UninitializedError();
#[derive(Debug)]
pub struct AccessError();

pub struct HwAnteClient {
    pub nick: Option<String>,
    pub protocol_number: Option<NonZeroU16>,
    pub server_salt: String,
    pub is_checker: bool,
    pub is_local_admin: bool,
    pub is_registered: bool,
    pub is_admin: bool,
    pub is_contributor: bool,
}

struct Ipv4AddrRange {
    min: [u8; 4],
    max: [u8; 4],
}

impl Ipv4AddrRange {
    fn contains(&self, addr: [u8; 4]) -> bool {
        (0..4).all(|i| self.min[i] <= addr[i] && addr[i] <= self.max[i])
    }
}

struct BanCollection {
    ban_ips: Vec<Ipv4AddrRange>,
    ban_timeouts: Vec<DateTime<offset::Utc>>,
    ban_reasons: Vec<String>,
}

impl BanCollection {
    fn new() -> Self {
        Self {
            ban_ips: vec![],
            ban_timeouts: vec![],
            ban_reasons: vec![],
        }
    }

    fn find(&self, addr: [u8; 4]) -> Option<String> {
        let time = offset::Utc::now();
        self.ban_ips
            .iter()
            .enumerate()
            .find(|(i, r)| r.contains(addr) && time < self.ban_timeouts[*i])
            .map(|(i, _)| self.ban_reasons[i].clone())
    }
}

pub struct HwAnteroom {
    pub clients: IndexSlab<HwAnteClient>,
    bans: BanCollection,
}

impl HwAnteroom {
    pub fn new(clients_limit: usize) -> Self {
        let clients = IndexSlab::with_capacity(clients_limit);
        HwAnteroom {
            clients,
            bans: BanCollection::new(),
        }
    }

    pub fn find_ip_ban(&self, addr: [u8; 4]) -> Option<String> {
        self.bans.find(addr)
    }

    pub fn add_client(&mut self, client_id: ClientId, salt: String, is_local_admin: bool) {
        let client = HwAnteClient {
            nick: None,
            protocol_number: None,
            server_salt: salt,
            is_checker: false,
            is_local_admin,
            is_registered: false,
            is_admin: false,
            is_contributor: false,
        };
        self.clients.insert(client_id, client);
    }

    pub fn remove_client(&mut self, client_id: ClientId) -> Option<HwAnteClient> {
        let client = self.clients.remove(client_id);
        client
    }
}

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

pub struct HwServer {
    pub clients: IndexSlab<HwClient>,
    pub rooms: Slab<HwRoom>,
    pub anteroom: HwAnteroom,
    pub latest_protocol: u16,
    pub flags: ServerFlags,
    pub greetings: ServerGreetings,
}

impl HwServer {
    pub fn new(clients_limit: usize, rooms_limit: usize) -> Self {
        let rooms = Slab::with_capacity(rooms_limit);
        let clients = IndexSlab::with_capacity(clients_limit);
        Self {
            clients,
            rooms,
            anteroom: HwAnteroom::new(clients_limit),
            greetings: ServerGreetings::new(),
            latest_protocol: 58,
            flags: ServerFlags::empty(),
        }
    }

    #[inline]
    pub fn client(&self, client_id: ClientId) -> &HwClient {
        &self.clients[client_id]
    }

    #[inline]
    fn client_mut(&mut self, client_id: ClientId) -> &mut HwClient {
        &mut self.clients[client_id]
    }

    #[inline]
    pub fn has_client(&self, client_id: ClientId) -> bool {
        self.clients.contains(client_id)
    }

    #[inline]
    pub fn iter_clients(&self) -> impl Iterator<Item = &HwClient> {
        self.clients.iter().map(|(_, c)| c)
    }

    #[inline]
    pub fn room(&self, room_id: RoomId) -> &HwRoom {
        &self.rooms[room_id]
    }

    #[inline]
    pub fn room_mut(&mut self, room_id: RoomId) -> &mut HwRoom {
        &mut self.rooms[room_id]
    }

    #[inline]
    pub fn client_and_room(&self, client_id: ClientId, room_id: RoomId) -> (&HwClient, &HwRoom) {
        (&self.clients[client_id], &self.rooms[room_id])
    }

    #[inline]
    pub fn client_and_room_mut(
        &mut self,
        client_id: ClientId,
        room_id: RoomId,
    ) -> (&HwClient, &mut HwRoom) {
        (&self.clients[client_id], &mut self.rooms[room_id])
    }

    #[inline]
    pub fn is_admin(&self, client_id: ClientId) -> bool {
        self.clients
            .get(client_id)
            .map(|c| c.is_admin())
            .unwrap_or(false)
    }

    pub fn add_client(&mut self, client_id: ClientId, data: HwAnteClient) {
        if let (Some(protocol), Some(nick)) = (data.protocol_number, data.nick) {
            let mut client = HwClient::new(client_id, protocol.get(), nick);
            client.set_is_checker(data.is_checker);
            #[cfg(not(feature = "official-server"))]
            client.set_is_admin(data.is_local_admin);

            #[cfg(feature = "official-server")]
            {
                client.set_is_registered(info.is_registered);
                client.set_is_admin(info.is_admin);
                client.set_is_contributor(info.is_contributor);
            }

            self.clients.insert(client_id, client);
        }
    }

    pub fn remove_client(&mut self, client_id: ClientId) {
        self.clients.remove(client_id);
    }

    pub fn get_greetings(&self, client: &HwClient) -> &str {
        if client.protocol_number < self.latest_protocol {
            &self.greetings.for_old_protocols
        } else {
            &self.greetings.for_latest_protocol
        }
    }

    #[inline]
    pub fn get_client_nick(&self, client_id: ClientId) -> &str {
        &self.clients[client_id].nick
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
    ) -> Result<(&HwClient, &HwRoom, impl Iterator<Item = &HwClient> + Clone), JoinRoomError> {
        use JoinRoomError::*;
        let room = &mut self.rooms[room_id];
        let client = &mut self.clients[client_id];

        if client.protocol_number != room.protocol_number {
            Err(WrongProtocol)
        } else if room.is_join_restricted() {
            Err(Restricted)
        } else if room.players_number == u8::max_value() {
            Err(Full)
        } else {
            move_to_room(client, room);
            let room_id = room.id;
            Ok((
                &self.clients[client_id],
                &self.rooms[room_id],
                self.clients.iter().map(|(_, c)| c),
            ))
        }
    }

    #[inline]
    pub fn join_room_by_name(
        &mut self,
        client_id: ClientId,
        room_name: &str,
    ) -> Result<(&HwClient, &HwRoom, impl Iterator<Item = &HwClient> + Clone), JoinRoomError> {
        use JoinRoomError::*;
        let room = self.rooms.iter().find(|(_, r)| r.name == room_name);
        if let Some((_, room)) = room {
            let room_id = room.id;
            self.join_room(client_id, room_id)
        } else {
            Err(DoesntExist)
        }
    }

    pub fn leave_room(&mut self, client_id: ClientId) -> Result<LeaveRoomResult, LeaveRoomError> {
        let client = &mut self.clients[client_id];
        if let Some(room_id) = client.room_id {
            let room = &mut self.rooms[room_id];

            room.players_number -= 1;
            client.room_id = None;

            let is_empty = room.players_number == 0;
            let is_fixed = room.is_fixed();
            let was_master = room.master_id == Some(client_id);
            let was_in_game = client.is_in_game();
            let mut removed_teams = vec![];

            if is_empty && !is_fixed {
                if client.is_ready() && room.ready_players_number > 0 {
                    room.ready_players_number -= 1;
                }

                removed_teams = room
                    .client_teams(client.id)
                    .map(|t| t.name.clone())
                    .collect();

                for team_name in &removed_teams {
                    room.remove_team(team_name);
                }

                if client.is_master() && !is_fixed {
                    client.set_is_master(false);
                    room.master_id = None;
                }
            }

            client.set_is_ready(false);
            client.set_is_in_game(false);

            if !is_fixed {
                if room.players_number == 0 {
                    self.rooms.remove(room_id);
                } else if room.master_id == None {
                    let new_master_id = self.room_clients(room_id).next();
                    if let Some(new_master_id) = new_master_id {
                        let room = &mut self.rooms[room_id];
                        room.master_id = Some(new_master_id);
                        let new_master = &mut self.clients[new_master_id];
                        new_master.set_is_master(true);

                        if room.protocol_number < 42 {
                            room.name = new_master.nick.clone();
                        }

                        room.set_join_restriction(false);
                        room.set_team_add_restriction(false);
                        room.set_unregistered_players_restriction(true);
                    }
                }
            }

            if is_empty && !is_fixed {
                Ok(LeaveRoomResult::RoomRemoved)
            } else {
                Ok(LeaveRoomResult::RoomRemains {
                    is_empty,
                    was_master,
                    was_in_game,
                    new_master: self.rooms[room_id].master_id,
                    removed_teams,
                })
            }
        } else {
            Err(LeaveRoomError::NoRoom)
        }
    }

    pub fn change_master(
        &mut self,
        client_id: ClientId,
        room_id: RoomId,
        new_master_nick: String,
    ) -> Result<ChangeMasterResult, ChangeMasterError> {
        let client = &mut self.clients[client_id];
        let room = &mut self.rooms[room_id];

        if client.is_admin() || room.master_id == Some(client_id) {
            let new_master_id = self
                .clients
                .iter()
                .find(|(_, c)| c.nick == new_master_nick)
                .map(|(id, _)| id);

            match new_master_id {
                Some(new_master_id) if new_master_id == client_id => {
                    Err(ChangeMasterError::AlreadyMaster)
                }
                Some(new_master_id) => {
                    let new_master = &mut self.clients[new_master_id];
                    if new_master.room_id == Some(room_id) {
                        self.clients[new_master_id].set_is_master(true);
                        let old_master_id = room.master_id;
                        if let Some(master_id) = old_master_id {
                            self.clients[master_id].set_is_master(false);
                        }
                        room.master_id = Some(new_master_id);
                        Ok(ChangeMasterResult {
                            old_master_id,
                            new_master_id,
                        })
                    } else {
                        Err(ChangeMasterError::ClientNotInRoom)
                    }
                }
                None => Err(ChangeMasterError::NoClient),
            }
        } else {
            Err(ChangeMasterError::NoAccess)
        }
    }

    pub fn start_game(&mut self, room_id: RoomId) -> Result<Vec<String>, StartGameError> {
        let (room_clients, room_nicks): (Vec<_>, Vec<_>) = self
            .clients
            .iter()
            .map(|(id, c)| (id, c.nick.clone()))
            .unzip();

        let room = &mut self.rooms[room_id];

        if !room.has_multiple_clans() {
            Err(StartGameError::NotEnoughClans)
        } else if room.protocol_number <= 43 && room.players_number != room.ready_players_number {
            Err(StartGameError::NotReady)
        } else if room.game_info.is_some() {
            Err(StartGameError::AlreadyInGame)
        } else {
            room.start_round();
            for id in room_clients {
                let c = &mut self.clients[id];
                c.set_is_in_game(true);
                c.team_indices = room.client_team_indices(c.id);
            }
            Ok(room_nicks)
        }
    }

    pub fn leave_game(&mut self, client_id: ClientId) -> Option<Vec<String>> {
        let client = &mut self.clients[client_id];
        let client_left = client.is_in_game();
        if client_left {
            client.set_is_in_game(false);
            let room = &mut self.rooms[client.room_id.expect("Client should've been in the game")];

            let team_names: Vec<_> = room
                .client_teams(client_id)
                .map(|t| t.name.clone())
                .collect();

            if let Some(ref mut info) = room.game_info {
                info.teams_in_game -= team_names.len() as u8;

                for team_name in &team_names {
                    let remove_msg =
                        utils::to_engine_msg(std::iter::once(b'F').chain(team_name.bytes()));
                    if let Some(m) = &info.sync_msg {
                        info.msg_log.push(m.clone());
                    }
                    if info.sync_msg.is_some() {
                        info.sync_msg = None
                    }
                    info.msg_log.push(remove_msg);
                }
                Some(team_names)
            } else {
                unreachable!();
            }
        } else {
            None
        }
    }

    pub fn end_game(&mut self, room_id: RoomId) -> EndGameResult {
        let room = &mut self.rooms[room_id];
        room.ready_players_number = room.master_id.is_some() as u8;

        if let Some(info) = replace(&mut room.game_info, None) {
            let joined_mid_game_clients = self
                .clients
                .iter()
                .filter(|(_, c)| c.room_id == Some(room_id) && c.is_joined_mid_game())
                .map(|(_, c)| c.id)
                .collect();

            let unreadied_nicks: Vec<_> = self
                .clients
                .iter_mut()
                .filter(|(_, c)| c.room_id == Some(room_id))
                .map(|(_, c)| {
                    c.set_is_ready(c.is_master());
                    c.set_is_joined_mid_game(false);
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

            EndGameResult {
                joined_mid_game_clients,
                left_teams: info.left_teams.clone(),
                unreadied_nicks,
            }
        } else {
            unreachable!()
        }
    }

    pub fn enable_super_power(&mut self, client_id: ClientId) -> bool {
        let client = &mut self.clients[client_id];
        if client.is_admin() {
            client.set_has_super_power(true);
        }
        client.is_admin()
    }

    pub fn set_room_name(
        &mut self,
        client_id: ClientId,
        room_id: RoomId,
        mut name: String,
    ) -> Result<String, ModifyRoomNameError> {
        let room_exists = self.has_room(&name);
        let room = &mut self.rooms[room_id];
        if room.is_fixed() || room.master_id != Some(client_id) {
            Err(ModifyRoomNameError::AccessDenied)
        } else if utils::is_name_illegal(&name) {
            Err(ModifyRoomNameError::InvalidName)
        } else if room_exists {
            Err(ModifyRoomNameError::DuplicateName)
        } else {
            std::mem::swap(&mut room.name, &mut name);
            Ok(name)
        }
    }

    pub fn add_team(
        &mut self,
        client_id: ClientId,
        mut info: Box<TeamInfo>,
    ) -> Result<&TeamInfo, AddTeamError> {
        let client = &mut self.clients[client_id];
        if let Some(room_id) = client.room_id {
            let room = &mut self.rooms[room_id];
            if room.teams.len() >= room.max_teams as usize {
                Err(AddTeamError::TooManyTeams)
            } else if room.addable_hedgehogs() == 0 {
                Err(AddTeamError::TooManyHedgehogs)
            } else if room.find_team(|t| t.name == info.name) != None {
                Err(AddTeamError::TeamAlreadyExists)
            } else if room.game_info.is_some() {
                Err(AddTeamError::GameInProgress)
            } else if room.is_team_add_restricted() {
                Err(AddTeamError::Restricted)
            } else {
                info.owner = client.nick.clone();
                let team = room.add_team(client.id, *info, client.protocol_number < 42);
                client.teams_in_game += 1;
                client.clan = Some(team.color);
                Ok(team)
            }
        } else {
            unreachable!()
        }
    }

    pub fn remove_team(
        &mut self,
        client_id: ClientId,
        team_name: &str,
    ) -> Result<(), RemoveTeamError> {
        let client = &mut self.clients[client_id];
        if let Some(room_id) = client.room_id {
            let room = &mut self.rooms[room_id];
            match room.find_team_owner(team_name) {
                None => Err(RemoveTeamError::NoTeam),
                Some((id, _)) if id != client_id => Err(RemoveTeamError::TeamNotOwned),
                Some(_) => {
                    client.teams_in_game -= 1;
                    client.clan = room.find_team_color(client.id);
                    room.remove_team(team_name);
                    Ok(())
                }
            }
        } else {
            unreachable!();
        }
    }

    pub fn set_team_color(
        &mut self,
        client_id: ClientId,
        room_id: RoomId,
        team_name: &str,
        color: u8,
    ) -> Result<(), ModifyTeamError> {
        let client = &self.clients[client_id];
        let room = &mut self.rooms[room_id];
        if let Some((owner, team)) = room.find_team_and_owner_mut(|t| t.name == team_name) {
            if !client.is_master() {
                Err(ModifyTeamError::NotMaster)
            } else {
                team.color = color;
                self.clients[owner].clan = Some(color);
                Ok(())
            }
        } else {
            Err(ModifyTeamError::NoTeam)
        }
    }

    pub fn toggle_ready(&mut self, client_id: ClientId) -> bool {
        let client = &mut self.clients[client_id];
        if let Some(room_id) = client.room_id {
            let room = &mut self.rooms[room_id];

            client.set_is_ready(!client.is_ready());
            if client.is_ready() {
                room.ready_players_number += 1;
            } else {
                room.ready_players_number -= 1;
            }
        }
        client.is_ready()
    }

    #[inline]
    pub fn set_var(&mut self, client_id: ClientId, var: ServerVar) -> Result<(), AccessError> {
        if self.clients[client_id].is_admin() {
            match var {
                ServerVar::MOTDNew(msg) => self.greetings.for_latest_protocol = msg,
                ServerVar::MOTDOld(msg) => self.greetings.for_old_protocols = msg,
                ServerVar::LatestProto(n) => self.latest_protocol = n,
            }
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

    pub fn find_room_mut(&mut self, name: &str) -> Option<&mut HwRoom> {
        self.rooms
            .iter_mut()
            .find_map(|(_, r)| Some(r).filter(|r| r.name == name))
    }

    pub fn find_client(&self, nick: &str) -> Option<&HwClient> {
        self.clients
            .iter()
            .find_map(|(_, c)| Some(c).filter(|c| c.nick == nick))
    }

    pub fn find_client_mut(&mut self, nick: &str) -> Option<&mut HwClient> {
        self.clients
            .iter_mut()
            .find_map(|(_, c)| Some(c).filter(|c| c.nick == nick))
    }

    pub fn all_clients(&self) -> impl Iterator<Item = ClientId> + '_ {
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

    pub fn collect_clients<F>(&self, f: F) -> Vec<ClientId>
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

    pub fn lobby_clients(&self) -> impl Iterator<Item = ClientId> + '_ {
        self.filter_clients(|(_, c)| c.room_id == None)
    }

    pub fn room_clients(&self, room_id: RoomId) -> impl Iterator<Item = ClientId> + '_ {
        self.filter_clients(move |(_, c)| c.room_id == Some(room_id))
    }

    pub fn protocol_clients(&self, protocol: u16) -> impl Iterator<Item = ClientId> + '_ {
        self.filter_clients(move |(_, c)| c.protocol_number == protocol)
    }

    pub fn protocol_rooms(&self, protocol: u16) -> impl Iterator<Item = RoomId> + '_ {
        self.filter_rooms(move |(_, r)| r.protocol_number == protocol)
    }

    pub fn other_clients_in_room(&self, self_id: ClientId) -> Vec<ClientId> {
        let room_id = self.clients[self_id].room_id;
        self.collect_clients(|(id, c)| *id != self_id && c.room_id == room_id)
    }

    pub fn is_registered_only(&self) -> bool {
        self.flags.contains(ServerFlags::REGISTERED_ONLY)
    }

    pub fn set_is_registered_only(&mut self, value: bool) {
        self.flags.set(ServerFlags::REGISTERED_ONLY, value)
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
    client.set_is_joined_mid_game(false);

    (client, room)
}

fn move_to_room(client: &mut HwClient, room: &mut HwRoom) {
    debug_assert!(client.room_id != Some(room.id));

    room.players_number += 1;

    client.room_id = Some(room.id);
    client.set_is_joined_mid_game(room.game_info.is_some());
    client.set_is_in_game(room.game_info.is_some());

    if let Some(ref mut info) = room.game_info {
        let teams = info.client_teams(client.id);
        client.teams_in_game = teams.clone().count() as u8;
        client.clan = teams.clone().next().map(|t| t.color);
        let team_names: Vec<_> = teams.map(|t| t.name.clone()).collect();

        if !team_names.is_empty() {
            info.left_teams.retain(|name| !team_names.contains(&name));
            info.teams_in_game += team_names.len() as u8;
            room.teams = info
                .teams_at_start
                .iter()
                .filter(|(_, t)| !team_names.contains(&t.name))
                .cloned()
                .collect();
        }
    }
}
