use super::{
    anteroom::HwAnteroomClient,
    client::HwClient,
    indexslab::IndexSlab,
    room::HwRoom,
    types::{ClientId, GameCfg, RoomId, ServerVar, TeamInfo, Vote, VoteType, Voting},
};
use crate::{protocol::messages::HwProtocolMessage::Greeting, utils};

use bitflags::_core::hint::unreachable_unchecked;
use bitflags::*;
use log::*;
use slab::Slab;
use std::{borrow::BorrowMut, cmp::min, collections::HashSet, iter, mem::replace};

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
    AccessDenied,
    InvalidName,
    DuplicateName,
}

#[derive(Debug)]
pub enum StartVoteError {
    VotingInProgress,
}

#[derive(Debug)]
pub enum VoteResult {
    Submitted,
    Succeeded(VoteType),
    Failed,
}

#[derive(Debug)]
pub enum VoteError {
    NoVoting,
    AlreadyVoted,
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
    clients: IndexSlab<HwClient>,
    rooms: Slab<HwRoom>,
    latest_protocol: u16,
    flags: ServerFlags,
    greetings: ServerGreetings,
}

impl HwServer {
    pub fn new(clients_limit: usize, rooms_limit: usize) -> Self {
        let rooms = Slab::with_capacity(rooms_limit);
        let clients = IndexSlab::with_capacity(clients_limit);
        Self {
            clients,
            rooms,
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
    pub fn get_room(&self, room_id: RoomId) -> Option<&HwRoom> {
        self.rooms.get(room_id)
    }

    #[inline]
    fn get_room_mut(&mut self, room_id: RoomId) -> Option<&mut HwRoom> {
        self.rooms.get_mut(room_id)
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
    pub fn get_room_control(&mut self, client_id: ClientId) -> Option<HwRoomControl> {
        HwRoomControl::new(self, client_id)
    }

    #[inline]
    pub fn is_admin(&self, client_id: ClientId) -> bool {
        self.clients
            .get(client_id)
            .map(|c| c.is_admin())
            .unwrap_or(false)
    }

    pub fn add_client(&mut self, client_id: ClientId, data: HwAnteroomClient) {
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
        self.filter_clients(|(_, c)| c.room_id == None)
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
        self.flags.set(ServerFlags::REGISTERED_ONLY, value)
    }

    pub fn set_room_saves(&mut self, room_id: RoomId, text: &str) -> Result<(), serde_yaml::Error> {
        if let Some(room) = self.rooms.get_mut(room_id) {
            room.set_saves(text)
        } else {
            Ok(())
        }
    }
}

pub struct HwRoomControl<'a> {
    server: &'a mut HwServer,
    client_id: ClientId,
    room_id: RoomId,
}

impl<'a> HwRoomControl<'a> {
    #[inline]
    pub fn new(server: &'a mut HwServer, client_id: ClientId) -> Option<Self> {
        if let Some(room_id) = server.clients[client_id].room_id {
            Some(Self {
                server,
                client_id,
                room_id,
            })
        } else {
            None
        }
    }

    #[inline]
    pub fn server(&self) -> &HwServer {
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
    fn room_mut(&mut self) -> &mut HwRoom {
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

    pub fn change_client<'b: 'a>(self, client_id: ClientId) -> Option<HwRoomControl<'a>> {
        let room_id = self.room_id;
        HwRoomControl::new(self.server, client_id).filter(|c| c.room_id == room_id)
    }

    pub fn leave_room(&mut self) -> LeaveRoomResult {
        let (client, room) = self.get_mut();
        room.players_number -= 1;
        client.room_id = None;

        let is_empty = room.players_number == 0;
        let is_fixed = room.is_fixed();
        let was_master = room.master_id == Some(client.id);
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
                self.server.rooms.remove(self.room_id);
            } else if room.master_id == None {
                let protocol_number = room.protocol_number;
                let new_master_id = self.server.room_client_ids(self.room_id).next();

                if let Some(new_master_id) = new_master_id {
                    let room = self.room_mut();
                    room.master_id = Some(new_master_id);
                    let new_master = &mut self.server.clients[new_master_id];
                    new_master.set_is_master(true);

                    if protocol_number < 42 {
                        let nick = new_master.nick.clone();
                        self.room_mut().name = nick;
                    }

                    let room = self.room_mut();
                    room.set_join_restriction(false);
                    room.set_team_add_restriction(false);
                    room.set_unregistered_players_restriction(true);
                }
            }
        }

        if is_empty && !is_fixed {
            LeaveRoomResult::RoomRemoved
        } else {
            LeaveRoomResult::RoomRemains {
                is_empty,
                was_master,
                was_in_game,
                new_master: self.room().master_id,
                removed_teams,
            }
        }
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
                Some(new_master_id) if new_master_id == self.client_id => Err(AlreadyMaster),
                Some(new_master_id) => {
                    let new_master = &mut self.server.clients[new_master_id];
                    if new_master.room_id == Some(self.room_id) {
                        self.server.clients[new_master_id].set_is_master(true);
                        let room = self.room_mut();
                        let old_master_id = self.room().master_id;

                        if let Some(master_id) = old_master_id {
                            self.server.clients[master_id].set_is_master(false);
                        }
                        self.room_mut().master_id = Some(new_master_id);
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

    pub fn vote(&mut self, vote: Vote) -> Result<VoteResult, VoteError> {
        use self::{VoteError::*, VoteResult::*};
        let client_id = self.client_id;
        if let Some(ref mut voting) = self.room_mut().voting {
            if vote.is_forced || voting.votes.iter().all(|(id, _)| client_id != *id) {
                voting.votes.push((client_id, vote.is_pro));
                let i = voting.votes.iter();
                let pro = i.clone().filter(|(_, v)| *v).count();
                let contra = i.filter(|(_, v)| !*v).count();
                let success_quota = voting.voters.len() / 2 + 1;
                if vote.is_forced && vote.is_pro || pro >= success_quota {
                    let voting = self.room_mut().voting.take().unwrap();
                    Ok(Succeeded(voting.kind))
                } else if vote.is_forced && !vote.is_pro
                    || contra > voting.voters.len() - success_quota
                {
                    Ok(Failed)
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

    pub fn add_engine_message(&mut self) {
        todo!("port from the room handler")
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
            room.set_join_restriction(false);
            room.set_team_add_restriction(false);
            room.set_unregistered_players_restriction(true);
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
        if room.is_fixed() || room.master_id != Some(client.id) {
            Err(AccessDenied)
        } else if utils::is_name_illegal(&name) {
            Err(InvalidName)
        } else if room_exists {
            Err(DuplicateName)
        } else {
            std::mem::swap(&mut room.name, &mut name);
            Ok(name)
        }
    }

    pub fn set_room_greeting(&mut self, greeting: Option<String>) -> Result<(), AccessError> {
        let (client, room) = self.get_mut();
        if client.is_admin() {
            room.greeting = greeting.unwrap_or(String::new());
            Ok(())
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
                super::room::MAX_HEDGEHOGS_IN_ROOM,
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
        } else if room.find_team(|t| t.name == info.name) != None {
            Err(TeamAlreadyExists)
        } else if room.game_info.is_some() {
            Err(GameInProgress)
        } else if room.is_team_add_restricted() {
            Err(Restricted)
        } else {
            info.owner = client.nick.clone();
            let team = room.add_team(client.id, *info, client.protocol_number < 42);
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
            Some((id, _)) if id != client.id => Err(RemoveTeamError::TeamNotOwned),
            Some(_) => {
                client.teams_in_game -= 1;
                client.clan = room.find_team_color(client.id);
                room.remove_team(team_name);
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
        let (room_clients, room_nicks): (Vec<_>, Vec<_>) = self
            .server
            .clients
            .iter()
            .map(|(id, c)| (id, c.nick.clone()))
            .unzip();

        let room = self.room_mut();

        if !room.has_multiple_clans() {
            Err(NotEnoughClans)
        } else if room.protocol_number <= 43 && room.players_number != room.ready_players_number {
            Err(NotReady)
        } else if room.game_info.is_some() {
            Err(AlreadyInGame)
        } else {
            room.start_round();
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

    pub fn end_game(&mut self) -> Option<EndGameResult> {
        let room = self.room_mut();
        room.ready_players_number = room.master_id.is_some() as u8;

        if let Some(info) = replace(&mut room.game_info, None) {
            let room_id = room.id;
            let joined_mid_game_clients = self
                .server
                .clients
                .iter()
                .filter(|(_, c)| c.room_id == Some(self.room_id) && c.is_joined_mid_game())
                .map(|(_, c)| c.id)
                .collect();

            let unreadied_nicks: Vec<_> = self
                .server
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

            Some(EndGameResult {
                joined_mid_game_clients,
                left_teams: info.left_teams.clone(),
                unreadied_nicks,
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
