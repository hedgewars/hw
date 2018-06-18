use std::{
    io, io::Write
};
use super::{
    server::HWServer,
    client::ClientId,
    room::HWRoom,
    handlers
};
use protocol::messages::{
    HWProtocolMessage,
    HWServerMessage,
    HWServerMessage::*
};

pub enum Action {
    SendAll(HWServerMessage),
    SendMe(HWServerMessage),
    SendAllButMe(HWServerMessage),
    SendToSelected(Vec<ClientId>, HWServerMessage),
    RemoveClient,
    ByeClient(String),
    ReactProtocolMessage(HWProtocolMessage),
    CheckRegistered,
    JoinLobby,
    AddRoom(String, Option<String>),
    RemoveRoom(RoomId),
    MoveToRoom(RoomId),
    MoveToLobby(String),
    ChangeMaster(RoomId, Option<ClientId>),
    SendRoomUpdate(Option<String>),
    Warn(String),
    ProtocolError(String)
}

use self::Action::*;
use server::room::RoomId;

pub fn run_action(server: &mut HWServer, token: usize, action: Action) {
    match action {
        SendAll(msg) =>
            server.send_all(msg),
        SendMe(msg) =>
            server.send_self(token, msg),
        SendAllButMe(msg) =>
            server.send_others(token, msg),
        SendToSelected(client_ids, msg) =>
            server.send_to_selected(client_ids, msg),
        ByeClient(msg) => {
            let room_id;
            let nick;
            {
                let c = &server.clients[token];
                room_id = c.room_id;
                nick = c.nick.clone();
            }

            let action = room_id.map (|id| {
                if id == server.lobby_id {
                    SendAll(LobbyLeft(nick, msg.clone()))
                } else {
                    MoveToLobby(format!("quit: {}", msg.clone()))
                }
            });

            if let Some(action) = action {
                server.react(token, vec![action]);
            }

            server.react(token, vec![
                SendMe(Bye(msg)),
                RemoveClient]);
        },
        RemoveClient => {
            server.removed_clients.push(token);
            if server.clients.contains(token) {
                server.clients.remove(token);
            }
        },
        ReactProtocolMessage(msg) =>
            handlers::handle(server, token, msg),
        CheckRegistered =>
            if server.clients[token].protocol_number > 0 && server.clients[token].nick != "" {
                server.react(token, vec![
                    JoinLobby,
                    ]);
            },
        JoinLobby => {
            server.clients[token].room_id = Some(server.lobby_id);

            let joined_msg;
            {
                let mut lobby_nicks = Vec::new();
                for (_, c) in server.clients.iter() {
                    if c.room_id.is_some() {
                        lobby_nicks.push(c.nick.clone());
                    }
                }
                joined_msg = LobbyJoined(lobby_nicks);
            }
            let everyone_msg = LobbyJoined(vec![server.clients[token].nick.clone()]);
            let flags_msg = ClientFlags(
                "+i".to_string(),
                server.clients.iter()
                    .filter(|(_, c)| c.room_id.is_some())
                    .map(|(_, c)| c.nick.clone())
                    .collect());
            let server_msg = ServerMessage("\u{1f994} is watching".to_string());
            let rooms_msg = Rooms(server.rooms.iter()
                .filter(|(id, _)| *id != server.lobby_id)
                .flat_map(|(_, r)|
                    r.info(r.master_id.map(|id| &server.clients[id])))
                .collect());
            server.react(token, vec![
                SendAllButMe(everyone_msg),
                SendMe(joined_msg),
                SendMe(flags_msg),
                SendMe(server_msg),
                SendMe(rooms_msg),
                ]);
        },
        AddRoom(name, password) => {
            let room_protocol;
            let room_info;
            let room_id = server.add_room();;
            {
                let r = &mut server.rooms[room_id];
                let c = &mut server.clients[token];
                r.master_id = Some(c.id);
                r.name = name;
                r.password = password;
                r.protocol_number = c.protocol_number;

                room_protocol = r.protocol_number;
                room_info = r.info(Some(&c));
            }
            let protocol_client_ids = server.protocol_clients(room_protocol);
            server.react(token, vec![
                SendToSelected(protocol_client_ids, RoomAdd(room_info)),
                MoveToRoom(room_id)]);
        },
        RemoveRoom(room_id) => {
            let room_protocol;
            let room_name;
            {
                let r = &mut server.rooms[room_id];
                room_protocol = r.protocol_number;
                room_name = r.name.clone();
            }
            server.rooms.remove(room_id);
            let protocol_client_ids = server.protocol_clients(room_protocol);
            server.react(token, vec![
                SendToSelected(protocol_client_ids, RoomRemove(room_name))]);
        }
        MoveToRoom(room_id) => {
            let flags_msg;
            let nick;
            {
                let r = &mut server.rooms[room_id];
                let c = &mut server.clients[token];
                r.players_number += 1;
                c.room_id = Some(room_id);
                c.is_joined_mid_game = false;
                if r.master_id == Some(c.id) {
                    r.ready_players_number += 1;
                    c.is_master = true;
                    c.is_ready = true;
                } else {
                    c.is_ready = false;
                    c.is_master = false;
                }
                flags_msg = ClientFlags("+i".to_string(), vec![c.nick.clone()]);
                nick = c.nick.clone();
            }
            let rooms_client_ids = server.room_clients(room_id);
            server.react(token, vec![
                SendToSelected(rooms_client_ids, RoomJoined(vec![nick])),
                SendAll(flags_msg),
                SendRoomUpdate(None)]);
        },
        MoveToLobby(msg) => {
            let mut actions = Vec::new();
            let other_client_ids = server.other_clients_in_room(token);
            let lobby_id = server.lobby_id;
            if let (c, Some(r)) = server.client_and_room(token) {
                r.players_number -= 1;
                if c.is_ready {
                    r.ready_players_number -= 1;
                }
                if r.players_number > 0 && c.is_master {
                    actions.push(ChangeMaster(r.id, None));
                }
                actions.push(SendToSelected(other_client_ids, RoomLeft(c.nick.clone(), msg)));
                actions.push(SendAll(ClientFlags("-i".to_string(), vec![c.nick.clone()])));
                actions.push(SendRoomUpdate(Some(r.name.clone())));
            }
            server.react(token, actions);
            actions = Vec::new();

            if let (c, Some(r)) = server.client_and_room(token) {
                c.room_id = Some(lobby_id);
                if r.players_number == 0 {
                    actions.push(RemoveRoom(r.id));
                }
            }
            server.react(token, actions)
        }
        ChangeMaster(room_id, new_id) => {
            let mut actions = Vec::new();
            let room_client_ids = server.room_clients(room_id);
            let new_id = new_id.or_else(||
                room_client_ids.iter().find(|id| **id != token).map(|id| *id));
            let new_nick = new_id.map(|id| server.clients[id].nick.clone());

            if let (c, Some(r)) = server.client_and_room(token) {
                if let Some(id) = r.master_id {
                    c.is_master = false;
                    r.master_id = None;
                    actions.push(SendToSelected(room_client_ids.clone(), ClientFlags("-h".to_string(), vec![c.nick.clone()])));
                }
                r.master_id = new_id;
                if let Some(nick) = new_nick {
                    actions.push(SendToSelected(room_client_ids, ClientFlags("+h".to_string(), vec![nick])));
                }
            }
            new_id.map(|id| server.clients[id].is_master = true);
            server.react(token, actions);
        }
        SendRoomUpdate(old_name) => {
            let room_data =
                if let (c, Some(r)) = server.client_and_room(token) {
                    let name = old_name.unwrap_or_else(|| r.name.clone());
                    Some((name, r.protocol_number, r.info(Some(&c))))
                } else {
                    None
                };

            if let Some((room_name, protocol, room_info)) = room_data {
                let protocol_clients = server.protocol_clients(protocol);
                server.react(token,
                             vec![SendToSelected(protocol_clients, RoomUpdated(room_name, room_info))]);
            }
        }

        Warn(msg) => {
            run_action(server, token,SendMe(Warning(msg)));
        }
        ProtocolError(msg) => {
            run_action(server, token, SendMe(Error(msg)))
        }
    }
}
