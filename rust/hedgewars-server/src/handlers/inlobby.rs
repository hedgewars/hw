use mio;

use super::{common::rnd_reply, strings::*};
use crate::{
    core::{
        client::HwClient,
        server::{AccessError, CreateRoomError, HwServer, JoinRoomError},
        types::{ClientId, ServerVar},
    },
    protocol::messages::{
        add_flags, remove_flags, server_chat, HwProtocolMessage, HwServerMessage::*,
        ProtocolFlags as Flags,
    },
    utils::is_name_illegal,
};
use log::*;
use std::{collections::HashSet, convert::identity};

pub fn handle(
    server: &mut HwServer,
    client_id: ClientId,
    response: &mut super::Response,
    message: HwProtocolMessage,
) {
    use crate::protocol::messages::HwProtocolMessage::*;

    match message {
        CreateRoom(name, password) => match server.create_room(client_id, name, password) {
            Err(CreateRoomError::InvalidName) => response.warn(ILLEGAL_ROOM_NAME),
            Err(CreateRoomError::AlreadyExists) => response.warn(ROOM_EXISTS),
            Ok((client, room)) => {
                response.add(
                    RoomAdd(room.info(Some(&client)))
                        .send_all()
                        .with_protocol(room.protocol_number),
                );
                response.add(RoomJoined(vec![client.nick.clone()]).send_self());
                response.add(
                    ClientFlags(
                        add_flags(&[Flags::RoomMaster, Flags::Ready]),
                        vec![client.nick.clone()],
                    )
                    .send_self(),
                );
                response.add(
                    ClientFlags(add_flags(&[Flags::InRoom]), vec![client.nick.clone()]).send_self(),
                );
            }
        },
        Chat(msg) => {
            response.add(
                ChatMsg {
                    nick: server.get_client_nick(client_id).to_string(),
                    msg,
                }
                .send_all()
                .in_lobby()
                .but_self(),
            );
        }
        JoinRoom(name, _password) => match server.join_room_by_name(client_id, &name) {
            Err(error) => super::common::get_room_join_error(error, response),
            Ok((client, room, room_clients)) => {
                super::common::get_room_join_data(client, room, room_clients, response)
            }
        },
        Follow(nick) => {
            if let Some(client) = server.find_client(&nick) {
                if let Some(room_id) = client.room_id {
                    match server.join_room(client_id, room_id) {
                        Err(error) => super::common::get_room_join_error(error, response),
                        Ok((client, room, room_clients)) => {
                            super::common::get_room_join_data(client, room, room_clients, response)
                        }
                    }
                } else {
                    response.warn(NO_ROOM);
                }
            } else {
                response.warn(NO_USER);
            }
        }
        SetServerVar(var) => match server.set_var(client_id, var) {
            Err(AccessError()) => response.warn(ACCESS_DENIED),
            Ok(()) => response.add(server_chat(VARIABLE_UPDATED.to_string()).send_self()),
        },
        GetServerVar => match server.get_vars(client_id) {
            Err(AccessError()) => response.warn(ACCESS_DENIED),
            Ok(vars) => {
                response.add(
                    ServerVars(vars.iter().flat_map(|v| v.to_protocol()).collect()).send_self(),
                );
            }
        },
        Rnd(v) => {
            response.add(rnd_reply(&v).send_self());
        }
        Stats => match server.get_used_protocols(client_id) {
            Err(AccessError()) => response.warn(ACCESS_DENIED),
            Ok(protocols) => {
                let mut html = Vec::with_capacity(protocols.len() + 2);

                html.push("<table>".to_string());
                for protocol in protocols {
                    html.push(format!(
                        "<tr><td>{}</td><td>{}</td><td>{}</td></tr>",
                        super::utils::protocol_version_string(protocol),
                        server.protocol_clients(protocol).count(),
                        server.protocol_rooms(protocol).count()
                    ));
                }
                html.push("</table>".to_string());

                response.add(Warning(html.join("")).send_self());
            }
        },
        List => warn!("Deprecated LIST message received"),
        _ => warn!("Incorrect command in lobby state"),
    }
}
