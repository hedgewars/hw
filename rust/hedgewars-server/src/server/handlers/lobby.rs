use mio;

use super::common::rnd_reply;
use crate::{
    protocol::messages::{HWProtocolMessage, HWServerMessage::*},
    server::{core::HWServer, coretypes::ClientId},
    utils::is_name_illegal,
};
use log::*;

pub fn handle(
    server: &mut HWServer,
    client_id: ClientId,
    response: &mut super::Response,
    message: HWProtocolMessage,
) {
    use crate::protocol::messages::HWProtocolMessage::*;
    match message {
        CreateRoom(name, password) => {
            if is_name_illegal(&name) {
                response.add(Warning("Illegal room name! A room name must be between 1-40 characters long, must not have a trailing or leading space and must not have any of these characters: $()*+?[]^{|}".to_string()).send_self());
            } else if server.has_room(&name) {
                response.add(
                    Warning("A room with the same name already exists.".to_string()).send_self(),
                );
            } else {
                let flags_msg = ClientFlags(
                    "+hr".to_string(),
                    vec![server.clients[client_id].nick.clone()],
                );

                let room_id = server.create_room(client_id, name, password);
                let room = &server.rooms[room_id];
                let client = &server.clients[client_id];

                response.add(
                    RoomAdd(room.info(Some(&client)))
                        .send_all()
                        .with_protocol(room.protocol_number),
                );
                response.add(flags_msg.send_self());

                response.add(ClientFlags("+i".to_string(), vec![client.nick.clone()]).send_self());
            };
        }
        Chat(msg) => {
            response.add(
                ChatMsg {
                    nick: server.clients[client_id].nick.clone(),
                    msg,
                }
                .send_all()
                .in_lobby()
                .but_self(),
            );
        }
        JoinRoom(name, _password) => {
            let room = server.rooms.iter().find(|(_, r)| r.name == name);
            let room_id = room.map(|(_, r)| r.id);
            let nicks = server
                .clients
                .iter()
                .filter(|(_, c)| c.room_id == room_id)
                .map(|(_, c)| c.nick.clone())
                .collect();
            let client = &mut server.clients[client_id];

            if let Some((_, room)) = room {
                if client.protocol_number != room.protocol_number {
                    response.add(
                        Warning("Room version incompatible to your Hedgewars version!".to_string())
                            .send_self(),
                    );
                } else if room.is_join_restricted() {
                    response.add(
                        Warning(
                            "Access denied. This room currently doesn't allow joining.".to_string(),
                        )
                        .send_self(),
                    );
                } else if room.players_number == u8::max_value() {
                    response.add(Warning("This room is already full".to_string()).send_self());
                } else if let Some(room_id) = room_id {
                    let nick = client.nick.clone();
                    server.move_to_room(client_id, room_id);

                    response.add(RoomJoined(vec![nick.clone()]).send_all().in_room(room_id));
                    response.add(ClientFlags("+i".to_string(), vec![nick]).send_all());
                    response.add(RoomJoined(nicks).send_self());

                    let room = &server.rooms[room_id];

                    if !room.greeting.is_empty() {
                        response.add(
                            ChatMsg {
                                nick: "[greeting]".to_string(),
                                msg: room.greeting.clone(),
                            }
                            .send_self(),
                        );
                    }
                }
            } else {
                response.add(Warning("No such room.".to_string()).send_self());
            }
        }
        Rnd(v) => {
            response.add(rnd_reply(&v).send_self());
        }
        List => warn!("Deprecated LIST message received"),
        _ => warn!("Incorrect command in lobby state"),
    }
}
