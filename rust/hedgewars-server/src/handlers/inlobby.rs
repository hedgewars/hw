use super::{common::rnd_reply, strings::*};
use crate::handlers::{actions::ToPendingMessage, checker};
use crate::{
    core::{
        client::HwClient,
        server::{AccessError, CreateRoomError, HwServer, JoinRoomError},
        types::ClientId,
    },
    utils::is_name_illegal,
};
use hedgewars_network_protocol::{
    messages::{
        add_flags, remove_flags, server_chat, HwProtocolMessage, HwServerMessage::*,
        ProtocolFlags as Flags,
    },
    types::ServerVar,
};
use log::*;
use std::{collections::HashSet, convert::identity};

pub fn handle(
    server: &mut HwServer,
    client_id: ClientId,
    response: &mut super::Response,
    message: HwProtocolMessage,
) {
    use hedgewars_network_protocol::messages::HwProtocolMessage::*;

    //todo!("add kick/ban handlers");
    //todo!("add command for forwarding lobby chat into rooms

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
                        add_flags(&[Flags::RoomMaster, Flags::Ready, Flags::InRoom]),
                        vec![client.nick.clone()],
                    )
                    .send_all(),
                );
            }
        },
        Chat(msg) => {
            //todo!("add client quiet flag");
            response.add(
                ChatMsg {
                    nick: server.client(client_id).nick.clone(),
                    msg,
                }
                .send_all()
                .in_lobby()
                .but_self(),
            );
        }
        JoinRoom(name, password) => {
            match server.join_room_by_name(client_id, &name, password.as_deref()) {
                Err(error) => super::common::get_room_join_error(error, response),
                Ok((client, room, room_clients)) => {
                    super::common::get_room_join_data(client, room, room_clients, response)
                }
            }
        }
        Follow(nick) => {
            if let Some(client) = server.find_client(&nick) {
                if let Some(room_id) = client.room_id {
                    match server.join_room(client_id, room_id, None) {
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
                        server.protocol_client_ids(protocol).count(),
                        server.protocol_room_ids(protocol).count()
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
