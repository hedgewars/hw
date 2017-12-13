use mio;
use mio::Token;
use std::io::Write;
use std::io;

use super::server::HWServer;
use super::server::HWRoom;
use protocol::messages::HWProtocolMessage;
use protocol::messages::HWServerMessage::*;
use super::handlers;

pub enum Action {
    SendMe(String),
    SendAllButMe(String),
    RemoveClient,
    ByeClient(String),
    ReactProtocolMessage(HWProtocolMessage),
    CheckRegistered,
    JoinLobby,
    AddRoom(String, Option<String>),
    Warn(String),
}

use self::Action::*;

pub fn run_action(server: &mut HWServer, token: mio::Token, poll: &mio::Poll, action: Action) {
    match action {
        SendMe(msg) =>
            server.send(token, &msg),
        SendAllButMe(msg) => {
            for (_, c) in server.clients.iter_mut() {
                if c.id != token {
                    c.send_string(&msg)
                }
            }
        },
        ByeClient(msg) => {
            server.react(token, poll, vec![
                SendMe(Bye(&msg).to_raw_protocol()),
                RemoveClient,
                ]);
        },
        RemoveClient => {
            server.clients[token.0].deregister(poll);
            server.clients.remove(token.0);
        },
        ReactProtocolMessage(msg) =>
            handlers::handle(server, token, poll, msg),
        CheckRegistered =>
            if server.clients[token.0].protocol_number > 0 && server.clients[token.0].nick != "" {
                server.react(token, poll, vec![
                    JoinLobby,
                    ]);
            },
        JoinLobby => {
            server.clients[token.0].room_id = Some(server.lobby_id);

            let joined_msg;
            {
                let mut lobby_nicks: Vec<&str> = Vec::new();
                for (_, c) in server.clients.iter() {
                    if c.room_id.is_some() {
                        lobby_nicks.push(&c.nick);
                    }
                }
                joined_msg = LobbyJoined(&lobby_nicks).to_raw_protocol();
            }
            let everyone_msg = LobbyJoined(&[&server.clients[token.0].nick]).to_raw_protocol();
            server.react(token, poll, vec![
                SendAllButMe(everyone_msg),
                SendMe(joined_msg),
                ]);
        },
        AddRoom(name, password) => {
            let room_id = Token(server.rooms.insert(HWRoom::new()));
            {
                let r = &mut server.rooms[room_id.0];
                let c = &mut server.clients[token.0];
                r.name = name;
                r.password = password;
                r.id = room_id.clone();
                r.ready_players_number = 1;
                r.protocol_number = c.protocol_number;
                c.room_id = Some(room_id);
            }

        },
        Warn(msg) => {
            run_action(server, token, poll, SendMe(Warning(&msg).to_raw_protocol()));
        }
        //_ => unimplemented!(),
    }
}
