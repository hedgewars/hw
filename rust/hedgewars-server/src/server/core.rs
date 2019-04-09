use super::{
    client::HWClient,
    coretypes::{ClientId, RoomId},
    indexslab::IndexSlab,
    room::HWRoom,
};
use crate::utils;

use log::*;
use slab;
use std::fs::{File, OpenOptions};
use std::io::{Read, Write};
use std::{borrow::BorrowMut, iter, num::NonZeroU16};

type Slab<T> = slab::Slab<T>;

pub struct HWAnteClient {
    pub nick: Option<String>,
    pub protocol_number: Option<NonZeroU16>,
    pub server_salt: String,
}

pub struct HWAnteroom {
    pub clients: IndexSlab<HWAnteClient>,
}

impl HWAnteroom {
    pub fn new(clients_limit: usize) -> Self {
        let clients = IndexSlab::with_capacity(clients_limit);
        HWAnteroom { clients }
    }

    pub fn add_client(&mut self, client_id: ClientId, salt: String) {
        let client = HWAnteClient {
            nick: None,
            protocol_number: None,
            server_salt: salt,
        };
        self.clients.insert(client_id, client);
    }

    pub fn remove_client(&mut self, client_id: ClientId) -> Option<HWAnteClient> {
        let mut client = self.clients.remove(client_id);
        client
    }
}

pub struct HWServer {
    pub clients: IndexSlab<HWClient>,
    pub rooms: Slab<HWRoom>,
    pub io: Box<dyn HWServerIO>,
    pub anteroom: HWAnteroom,
}

impl HWServer {
    pub fn new(clients_limit: usize, rooms_limit: usize, io: Box<dyn HWServerIO>) -> Self {
        let rooms = Slab::with_capacity(rooms_limit);
        let clients = IndexSlab::with_capacity(clients_limit);
        Self {
            clients,
            rooms,
            io,
            anteroom: HWAnteroom::new(clients_limit),
        }
    }

    pub fn add_client(&mut self, client_id: ClientId, data: HWAnteClient) {
        if let (Some(protocol), Some(nick)) = (data.protocol_number, data.nick) {
            let client = HWClient::new(client_id, protocol.get(), nick);
            self.clients.insert(client_id, client);
        }
    }

    pub fn remove_client(&mut self, client_id: ClientId) {
        self.clients.remove(client_id);
    }

    #[inline]
    pub fn create_room(
        &mut self,
        creator_id: ClientId,
        name: String,
        password: Option<String>,
    ) -> RoomId {
        create_room(
            &mut self.clients[creator_id],
            &mut self.rooms,
            name,
            password,
        )
    }

    #[inline]
    pub fn move_to_room(&mut self, client_id: ClientId, room_id: RoomId) {
        move_to_room(&mut self.clients[client_id], &mut self.rooms[room_id])
    }

    pub fn has_room(&self, name: &str) -> bool {
        self.find_room(name).is_some()
    }

    pub fn find_room(&self, name: &str) -> Option<&HWRoom> {
        self.rooms
            .iter()
            .find_map(|(_, r)| Some(r).filter(|r| r.name == name))
    }

    pub fn find_room_mut(&mut self, name: &str) -> Option<&mut HWRoom> {
        self.rooms
            .iter_mut()
            .find_map(|(_, r)| Some(r).filter(|r| r.name == name))
    }

    pub fn find_client(&self, nick: &str) -> Option<&HWClient> {
        self.clients
            .iter()
            .find_map(|(_, c)| Some(c).filter(|c| c.nick == nick))
    }

    pub fn find_client_mut(&mut self, nick: &str) -> Option<&mut HWClient> {
        self.clients
            .iter_mut()
            .find_map(|(_, c)| Some(c).filter(|c| c.nick == nick))
    }

    pub fn select_clients<F>(&self, f: F) -> Vec<ClientId>
    where
        F: Fn(&(usize, &HWClient)) -> bool,
    {
        self.clients.iter().filter(f).map(|(_, c)| c.id).collect()
    }

    pub fn lobby_clients(&self) -> Vec<ClientId> {
        self.select_clients(|(_, c)| c.room_id == None)
    }

    pub fn room_clients(&self, room_id: RoomId) -> Vec<ClientId> {
        self.select_clients(|(_, c)| c.room_id == Some(room_id))
    }

    pub fn protocol_clients(&self, protocol: u16) -> Vec<ClientId> {
        self.select_clients(|(_, c)| c.protocol_number == protocol)
    }

    pub fn other_clients_in_room(&self, self_id: ClientId) -> Vec<ClientId> {
        let room_id = self.clients[self_id].room_id;
        self.select_clients(|(id, c)| *id != self_id && c.room_id == room_id)
    }
}

fn allocate_room(rooms: &mut Slab<HWRoom>) -> &mut HWRoom {
    let entry = rooms.vacant_entry();
    let room = HWRoom::new(entry.key());
    entry.insert(room)
}

fn create_room(
    client: &mut HWClient,
    rooms: &mut Slab<HWRoom>,
    name: String,
    password: Option<String>,
) -> RoomId {
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

    room.id
}

fn move_to_room(client: &mut HWClient, room: &mut HWRoom) {
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

pub trait HWServerIO {
    fn write_file(&mut self, name: &str, content: &str) -> std::io::Result<()>;
    fn read_file(&mut self, name: &str) -> std::io::Result<String>;
}

pub struct EmptyServerIO {}

impl EmptyServerIO {
    pub fn new() -> Self {
        Self {}
    }
}

impl HWServerIO for EmptyServerIO {
    fn write_file(&mut self, _name: &str, _content: &str) -> std::io::Result<()> {
        Ok(())
    }

    fn read_file(&mut self, _name: &str) -> std::io::Result<String> {
        Ok("".to_string())
    }
}

pub struct FileServerIO {}

impl FileServerIO {
    pub fn new() -> Self {
        Self {}
    }
}

impl HWServerIO for FileServerIO {
    fn write_file(&mut self, name: &str, content: &str) -> std::io::Result<()> {
        let mut writer = OpenOptions::new().create(true).write(true).open(name)?;
        writer.write_all(content.as_bytes())
    }

    fn read_file(&mut self, name: &str) -> std::io::Result<String> {
        let mut reader = File::open(name)?;
        let mut result = String::new();
        reader.read_to_string(&mut result)?;
        Ok(result)
    }
}
