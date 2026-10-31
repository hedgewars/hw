use super::{common::rnd_reply, strings::*};
use crate::handlers::{actions::ToPendingMessage, checker};
use crate::{
    core::{
        anteroom::HwAnteroom,
        client::HwClient,
        flood::FloodEvent,
        server::{AccessError, CreateRoomError, HwServer, JoinRoomError},
        types::ClientId,
    },
    utils::is_name_illegal,
};
use hedgewars_network_protocol::{
    messages::{
        add_flags, remove_flags, server_chat, HwProtocolMessage,
        HwServerMessage::{self, *},
        ProtocolFlags as Flags,
    },
    types::ServerVar,
};
use log::*;
use std::{collections::HashSet, convert::identity, time::Duration};

pub fn handle(
    server: &mut HwServer,
    anteroom: &mut HwAnteroom,
    client_id: ClientId,
    response: &mut super::Response,
    message: HwProtocolMessage,
) {
    use hedgewars_network_protocol::messages::HwProtocolMessage::*;

    //todo!("add kick/ban handlers");
    //todo!("add command for forwarding lobby chat into rooms
    //todo!("report player account age")
    //todo!("port listing rooms for incompatible protocols"))

    match message {
        CreateRoom(name, password) => {
            let all_protocols = server.all_client_protocols();
            match server.create_room(client_id, name, password) {
                Err(CreateRoomError::InvalidName) => response.warn(ILLEGAL_ROOM_NAME),
                Err(CreateRoomError::AlreadyExists) => response.warn(ROOM_EXISTS),
                Ok((client, room)) => {
                    for protocol in all_protocols {
                        response.add(
                            RoomAdd(room.info(Some(client), protocol))
                                .send_all()
                                .in_lobby()
                                .with_protocol(protocol),
                        );
                    }
                    response.add(RoomJoined(vec![client.nick.clone()]).send_self());
                    response.add(
                        ClientFlags(
                            add_flags(&[Flags::RoomMaster, Flags::Ready, Flags::InRoom]),
                            vec![client.nick.clone()],
                        )
                        .send_all(),
                    );
                    super::common::register_flood_event(
                        server,
                        anteroom,
                        client_id,
                        FloodEvent::RoomJoin,
                        response,
                    );
                }
            }
        }
        Chat(msg) => {
            response.add(
                ChatMsg {
                    nick: server.client(client_id).nick.clone(),
                    msg,
                }
                .send_all()
                .in_lobby()
                .but_self(),
            );
            super::common::register_flood_event(
                server,
                anteroom,
                client_id,
                FloodEvent::LobbyChatMessage,
                response,
            );
        }
        JoinRoom(name, password) => {
            let protocols = server.all_client_protocols();
            let joined = match server.join_room_by_name(client_id, &name, password.as_deref()) {
                Err(error) => {
                    super::common::get_room_join_error(error, response);
                    false
                }
                Ok((client, master, room, room_clients)) => {
                    super::common::get_room_join_data(
                        &mut protocols.into_iter(),
                        client,
                        master,
                        room,
                        room_clients,
                        response,
                    );
                    true
                }
            };
            if joined {
                super::common::register_flood_event(
                    server,
                    anteroom,
                    client_id,
                    FloodEvent::RoomJoin,
                    response,
                );
            }
        }
        Follow(nick) => {
            if let Some(client) = server.find_client(&nick) {
                if let Some(room_id) = client.room_id {
                    let protocols = server.all_client_protocols();
                    let joined = match server.join_room(client_id, room_id, None) {
                        Err(error) => {
                            super::common::get_room_join_error(error, response);
                            false
                        }
                        Ok((client, master, room, room_clients)) => {
                            super::common::get_room_join_data(
                                &mut protocols.into_iter(),
                                client,
                                master,
                                room,
                                room_clients,
                                response,
                            );
                            true
                        }
                    };
                    if joined {
                        super::common::register_flood_event(
                            server,
                            anteroom,
                            client_id,
                            FloodEvent::RoomJoin,
                            response,
                        );
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
        Kick(nick) => {
            if server.is_admin(client_id) {
                if let Some(target) = server.find_client(&nick) {
                    let target_id = target.id;
                    if target_id != client_id {
                        let host = target.host.clone();
                        if !host.is_empty() {
                            anteroom.bans.add_ip_ban_raw(
                                host,
                                "60 seconds cooldown after kick".to_string(),
                                60,
                            );
                        }
                        server.client_mut(target_id).is_kicked_from_server = true;
                        super::common::remove_client_by_id(
                            server,
                            anteroom,
                            target_id,
                            response,
                            "Kicked".to_string(),
                        );
                    }
                }
            }
        }
        Ban(nick, reason, time) => {
            if server.is_admin(client_id) {
                if let Some(target) = server.find_client(&nick) {
                    let target_id = target.id;
                    if target_id != client_id {
                        let host = target.host.clone();
                        if !host.is_empty() {
                            anteroom.bans.add_ip_ban_raw(
                                host.clone(),
                                "60 seconds cooldown after kick".to_string(),
                                60,
                            );
                            anteroom.bans.add_ip_ban(host, reason, time);
                        }
                        server.client_mut(target_id).is_kicked_from_server = true;
                        super::common::remove_client_by_id(
                            server,
                            anteroom,
                            target_id,
                            response,
                            "Kicked".to_string(),
                        );
                    }
                }
            }
        }
        BanIp(ip, reason, time) => {
            if server.is_admin(client_id) {
                anteroom.bans.add_ip_ban(ip, reason, time);
            }
        }
        BanNick(nick, reason, time) => {
            if server.is_admin(client_id) {
                anteroom.bans.add_nick_ban(nick, reason, time);
            }
        }
        HwProtocolMessage::BanList => {
            if server.is_admin(client_id) {
                response.add(HwServerMessage::BanList(anteroom.bans.to_protocol_list()).send_self());
            }
        }
        Unban(entry) => {
            if server.is_admin(client_id) {
                anteroom.bans.unban(&entry);
            }
        }
        _ => warn!("Incorrect command in lobby state"),
    }
}
