use super::{
    client::HwClient,
    indexslab::IndexSlab,
    room::HwRoom,
    types::{ClientId, RoomId, ServerVar},
};
use crate::{protocol::messages::HwProtocolMessage::Greeting, utils};

use crate::core::server::JoinRoomError::WrongProtocol;
use bitflags::*;
use log::*;
use slab;
use std::{borrow::BorrowMut, collections::HashSet, iter, num::NonZeroU16};

type Slab<T> = slab::Slab<T>;

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

pub struct HwAnteroom {
    pub clients: IndexSlab<HwAnteClient>,
}

impl HwAnteroom {
    pub fn new(clients_limit: usize) -> Self {
        let clients = IndexSlab::with_capacity(clients_limit);
        HwAnteroom { clients }
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
    pub fn client_mut(&mut self, client_id: ClientId) -> &mut HwClient {
        &mut self.clients[client_id]
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
    ) -> (&mut HwClient, &mut HwRoom) {
        (&mut self.clients[client_id], &mut self.rooms[room_id])
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
