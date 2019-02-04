use super::{
    actions,
    actions::{Destination, PendingMessage},
    client::HWClient,
    coretypes::{ClientId, RoomId},
    handlers,
    io::HWServerIO,
    room::HWRoom,
};
use crate::protocol::messages::*;
use crate::utils;
use base64::encode;
use log::*;
use rand::{thread_rng, RngCore};
use slab;
use std::borrow::BorrowMut;

type Slab<T> = slab::Slab<T>;

pub struct HWServer {
    pub clients: Slab<HWClient>,
    pub rooms: Slab<HWRoom>,
    pub lobby_id: RoomId,
    pub output: Vec<(Vec<ClientId>, HWServerMessage)>,
    pub removed_clients: Vec<ClientId>,
    pub io: Box<dyn HWServerIO>,
}

impl HWServer {
    pub fn new(clients_limit: usize, rooms_limit: usize, io: Box<dyn HWServerIO>) -> HWServer {
        let rooms = Slab::with_capacity(rooms_limit);
        let clients = Slab::with_capacity(clients_limit);
        let mut server = HWServer {
            clients,
            rooms,
            lobby_id: 0,
            output: vec![],
            removed_clients: vec![],
            io,
        };
        server.lobby_id = server.add_room().id;
        server
    }

    pub fn add_client(&mut self) -> ClientId {
        let key: ClientId;
        {
            let entry = self.clients.vacant_entry();
            key = entry.key();
            let mut salt = [0u8; 18];
            thread_rng().fill_bytes(&mut salt);

            let client = HWClient::new(entry.key(), encode(&salt));
            entry.insert(client);
        }
        self.send(
            key,
            &Destination::ToSelf,
            HWServerMessage::Connected(utils::PROTOCOL_VERSION),
        );
        key
    }

    pub fn client_lost(&mut self, client_id: ClientId) {
        actions::run_action(
            self,
            client_id,
            actions::Action::ByeClient("Connection reset".to_string()),
        );
    }

    pub fn add_room(&mut self) -> &mut HWRoom {
        allocate_room(&mut self.rooms)
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

    pub fn send(
        &mut self,
        client_id: ClientId,
        destination: &Destination,
        message: HWServerMessage,
    ) {

    }

    pub fn send_msg(&mut self, client_id: ClientId, message: PendingMessage) {
        self.send(client_id, &message.destination, message.message)
    }

    pub fn react(&mut self, client_id: ClientId, actions: Vec<actions::Action>) {
        for action in actions {
            actions::run_action(self, client_id, action);
        }
    }

    pub fn lobby(&self) -> &HWRoom {
        &self.rooms[self.lobby_id]
    }

    pub fn has_room(&self, name: &str) -> bool {
        self.rooms.iter().any(|(_, r)| r.name == name)
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

    pub fn client_and_room(&mut self, client_id: ClientId) -> (&mut HWClient, Option<&mut HWRoom>) {
        let c = &mut self.clients[client_id];
        if let Some(room_id) = c.room_id {
            (c, Some(&mut self.rooms[room_id]))
        } else {
            (c, None)
        }
    }

    pub fn room(&mut self, client_id: ClientId) -> Option<&mut HWRoom> {
        self.client_and_room(client_id).1
    }
}

fn allocate_room(rooms: &mut Slab<HWRoom>) -> &mut HWRoom {
    let entry = rooms.vacant_entry();
    let key = entry.key();
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
