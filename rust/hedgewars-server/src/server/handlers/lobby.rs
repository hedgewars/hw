use mio;

use super::common::rnd_reply;
use crate::{
    protocol::messages::{
        add_flags, remove_flags, HWProtocolMessage, HWServerMessage::*, ProtocolFlags as Flags,
    },
    server::{
        client::HWClient,
        core::HWServer,
        coretypes::{ClientId, ServerVar},
    },
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
                    add_flags(&[Flags::RoomMaster, Flags::Ready]),
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

                response.add(
                    ClientFlags(add_flags(&[Flags::InRoom]), vec![client.nick.clone()]).send_self(),
                );
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
                    super::common::enter_room(server, client_id, room_id, response);
                }
            } else {
                response.add(Warning("No such room.".to_string()).send_self());
            }
        }
        Follow(nick) => {
            if let Some(HWClient {
                room_id: Some(room_id),
                ..
            }) = server.find_client(&nick)
            {
                let room = &server.rooms[*room_id];
                response.add(Joining(room.name.clone()).send_self());
                super::common::enter_room(server, client_id, *room_id, response);
            }
        }
        SetServerVar(var) => {
            if !server.clients[client_id].is_admin() {
                response.add(Warning("Access denied.".to_string()).send_self());
            } else {
                match var {
                    ServerVar::MOTDNew(msg) => server.greetings.for_latest_protocol = msg,
                    ServerVar::MOTDOld(msg) => server.greetings.for_old_protocols = msg,
                    ServerVar::LatestProto(n) => server.latest_protocol = n,
                }
            }
        }
        GetServerVar => {
            if !server.clients[client_id].is_admin() {
                response.add(Warning("Access denied.".to_string()).send_self());
            } else {
                let vars: Vec<_> = [
                    ServerVar::MOTDNew(server.greetings.for_latest_protocol.clone()),
                    ServerVar::MOTDOld(server.greetings.for_old_protocols.clone()),
                    ServerVar::LatestProto(server.latest_protocol),
                ]
                .iter()
                .flat_map(|v| v.to_protocol())
                .collect();
                response.add(ServerVars(vars).send_self());
            }
        }
        Rnd(v) => {
            response.add(rnd_reply(&v).send_self());
        }
        List => warn!("Deprecated LIST message received"),
        _ => warn!("Incorrect command in lobby state"),
    }
}
