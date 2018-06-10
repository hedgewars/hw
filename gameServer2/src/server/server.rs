use slab;
use mio::net::*;
use mio::*;
use std::io;

use utils;
use super::client::*;
use super::room::*;
use super::actions;
use protocol::messages::*;
use super::handlers;

type Slab<T> = slab::Slab<T>;

pub enum Destination {
    ToSelf(ClientId),
    ToOthers(ClientId)
}

pub struct PendingMessage(pub Destination, pub HWServerMessage);

pub struct HWServer {
    pub clients: Slab<HWClient>,
    pub rooms: Slab<HWRoom>,
    pub lobby_id: RoomId,
    pub output: Vec<PendingMessage>,
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
        self.send_self(key, HWServerMessage::Connected(utils::PROTOCOL_VERSION));
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
        handlers::handle(self, client_id, msg);
    }

    pub fn send_self(&mut self, client_id: ClientId, msg: HWServerMessage) {
        self.output.push(PendingMessage(
            Destination::ToSelf(client_id), msg));
    }

    pub fn send_others(&mut self, client_id: ClientId, msg: HWServerMessage) {
        self.output.push(PendingMessage(
            Destination::ToOthers(client_id), msg));
    }

    pub fn react(&mut self, client_id: ClientId, actions: Vec<actions::Action>) {
        for action in actions {
            actions::run_action(self, client_id, action);
        }
    }
}
