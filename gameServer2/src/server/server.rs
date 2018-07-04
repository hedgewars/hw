use slab;
use utils;
use super::{
    client::*, room::*, actions, handlers,
    actions::{Destination, PendingMessage}
};
use protocol::messages::*;

type Slab<T> = slab::Slab<T>;


pub struct HWServer {
    pub clients: Slab<HWClient>,
    pub rooms: Slab<HWRoom>,
    pub lobby_id: RoomId,
    pub output: Vec<(Vec<ClientId>, HWServerMessage)>,
    pub removed_clients: Vec<ClientId>,
}

impl HWServer {
    pub fn new(clients_limit: usize, rooms_limit: usize) -> HWServer {
        let rooms = Slab::with_capacity(rooms_limit);
        let clients = Slab::with_capacity(clients_limit);
        let mut server = HWServer {
            clients, rooms,
            lobby_id: 0,
            output: vec![],
            removed_clients: vec![]
        };
        server.lobby_id = server.add_room();
        server
    }

    pub fn add_client(&mut self) -> ClientId {
        let key: ClientId;
        {
            let entry = self.clients.vacant_entry();
            key = entry.key();
            let client = HWClient::new(entry.key());
            entry.insert(client);
        }
        self.send(key, Destination::ToSelf, HWServerMessage::Connected(utils::PROTOCOL_VERSION));
        key
    }

    pub fn client_lost(&mut self, client_id: ClientId) {
        actions::run_action(self, client_id,
                            actions::Action::ByeClient("Connection reset".to_string()));
    }

    pub fn add_room(&mut self) -> RoomId {
        let entry = self.rooms.vacant_entry();
        let key = entry.key();
        let room = HWRoom::new(entry.key());
        entry.insert(room);
        key
    }

    pub fn handle_msg(&mut self, client_id: ClientId, msg: HWProtocolMessage) {
        debug!("Handling message {:?} for client {}", msg, client_id);
        if self.clients.contains(client_id) {
            handlers::handle(self, client_id, msg);
        }
    }

    fn get_recipients(&self, client_id: ClientId, destination: Destination) -> Vec<ClientId> {
        let mut ids = match destination {
            Destination::ToSelf => vec![client_id],
            Destination::ToId(id) => vec![id],
            Destination::ToAll {room_id: Some(id), ..} =>
                self.room_clients(id),
            Destination::ToAll {protocol: Some(proto), ..} =>
                self.protocol_clients(proto),
            Destination::ToAll {..} =>
                self.clients.iter().map(|(id, _)| id).collect::<Vec<_>>()
        };
        if let Destination::ToAll {skip_self: true, ..} = destination {
            if let Some(index) = ids.iter().position(|id| *id == client_id) {
                ids.remove(index);
            }
        }
        ids
    }

    pub fn send(&mut self, client_id: ClientId, destination: Destination, message: HWServerMessage) {
        let ids = self.get_recipients(client_id, destination);
        self.output.push((ids, message));
    }

    pub fn react(&mut self, client_id: ClientId, actions: Vec<actions::Action>) {
        for action in actions {
            actions::run_action(self, client_id, action);
        }
    }

    pub fn has_room(&self, name: &str) -> bool {
        self.rooms.iter().any(|(_, r)| r.name == name)
    }

    pub fn find_room(&self, name: &str) -> Option<&HWRoom> {
        self.rooms.iter().find(|(_, r)| r.name == name).map(|(_, r)| r)
    }

    pub fn find_room_mut(&mut self, name: &str) -> Option<&mut HWRoom> {
        self.rooms.iter_mut().find(|(_, r)| r.name == name).map(|(_, r)| r)
    }

    pub fn select_clients<F>(&self, f: F) -> Vec<ClientId>
        where F: Fn(&(usize, &HWClient)) -> bool {
        self.clients.iter().filter(f)
            .map(|(_, c)| c.id).collect()
    }

    pub fn room_clients(&self, room_id: RoomId) -> Vec<ClientId> {
        self.select_clients(|(_, c)| c.room_id == Some(room_id))
    }

    pub fn protocol_clients(&self, protocol: u32) -> Vec<ClientId> {
        self.select_clients(|(_, c)| c.protocol_number == protocol)
    }

    pub fn other_clients_in_room(&self, self_id: ClientId) -> Vec<ClientId> {
        let room_id = self.clients[self_id].room_id;
        self.select_clients(|(id, c)| *id != self_id && c.room_id == room_id )
    }

    pub fn client_and_room(&mut self, client_id: ClientId) -> (&mut HWClient, Option<&mut HWRoom>) {
        let c = &mut self.clients[client_id];
        if let Some(room_id) = c.room_id {
            (c, Some(&mut self.rooms[room_id]))
        } else {
            (c, None)
        }
    }
}