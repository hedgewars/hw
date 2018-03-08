use mio;
use std::io::Write;
use std::io;

use super::server::HWServer;
use super::room::HWRoom;
use protocol::messages::HWProtocolMessage;
use protocol::messages::HWServerMessage;
use protocol::messages::HWServerMessage::*;
use super::handlers;

pub enum Action {
    SendMe(HWServerMessage),
    SendAllButMe(HWServerMessage),
    RemoveClient,
    ByeClient(String),
    ReactProtocolMessage(HWProtocolMessage),
    CheckRegistered,
    JoinLobby,
    AddRoom(String, Option<String>),
    Warn(String),
}

use self::Action::*;

pub fn run_action(server: &mut HWServer, token: usize, action: Action) {
    match action {
        SendMe(msg) =>
            server.send_self(token, msg),
        SendAllButMe(msg) => {
            server.send_others(token, msg)
        },
        ByeClient(msg) => {
            server.react(token, vec![
                SendMe(Bye(msg)),
                RemoveClient,
                ]);
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
            server.react(token, vec![
                SendAllButMe(everyone_msg),
                SendMe(joined_msg),
                ]);
        },
        AddRoom(name, password) => {
            let room_id = server.add_room();;
            {
                let r = &mut server.rooms[room_id];
                let c = &mut server.clients[token];
                r.name = name;
                r.password = password;
                r.ready_players_number = 1;
                r.protocol_number = c.protocol_number;
                c.room_id = Some(room_id);
            }
        },
        Warn(msg) => {
            run_action(server, token,SendMe(Warning(msg)));
        }
        //_ => unimplemented!(),
    }
}
