use super::{common::rnd_reply, strings::*};
use crate::handlers::actions::ToPendingMessage;
use crate::core::{
    anteroom::HwAnteroom,
    flood::FloodEvent,
    server::{CreateRoomError, HwServer},
    types::ClientId,
};
use hedgewars_network_protocol::{
    messages::{
        add_flags, HwProtocolMessage,
        HwServerMessage::{self, *},
        ProtocolFlags as Flags,
    },
    types::ServerVar,
};
use log::*;

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
                    response.add(RoomJoined(vec![client.nick.clone()]).send_self());
                    response.add(
                        ClientFlags(add_flags(&[Flags::InRoom]), vec![client.nick.clone()])
                            .send_all(),
                    );
                    for protocol in all_protocols {
                        response.add(
                            RoomAdd(room.info(Some(client), protocol))
                                .send_all()
                                .with_protocol(protocol),
                        );
                    }
                    response.add(
                        ClientFlags(
                            add_flags(&[Flags::RoomMaster, Flags::Ready]),
                            vec![client.nick.clone()],
                        )
                        .send_self(),
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
                    let room_name = server.room(room_id).name.clone();
                    response.add(Joining(room_name).send_self());
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
                }
            }
        }
        SetServerVar(var) => {
            if let ServerVar::LatestProto(0) = var {
                return;
            }
            let _ = server.set_var(client_id, var);
        }
        GetServerVar => {
            if let Ok(vars) = server.get_vars(client_id) {
                response.add(
                    ServerVars(vars.iter().flat_map(|v| v.to_protocol()).collect()).send_self(),
                );
            }
        }
        Rnd(v) => {
            response.add(rnd_reply(&v).send_self());
        }
        Stats => {
            if let Ok(protocols) = server.get_used_protocols(client_id) {
                let mut html = Vec::with_capacity(protocols.len() + 2);

                html.push("<table border=1>".to_string());
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
        }
        RestartServerConfirm => {
            if server.is_admin(client_id) {
                response.warn("Please confirm server restart with '/restart_server yes'.");
            }
        }
        RestartServer => {
            if server.is_admin(client_id) {
                info!("Server restart requested by admin {}", client_id);
            }
        }
        List => {
            if !server.client(client_id).has_asked_list {
                server.client_mut(client_id).has_asked_list = true;
                let client = server.client(client_id);
                let rooms = server
                    .iter_rooms()
                    .filter(|r| r.protocol_number != 0)
                    .flat_map(|r| {
                        r.info(
                            r.master_id.map(|id| server.client(id)),
                            client.protocol_number,
                        )
                    })
                    .collect();
                response.add(Rooms(rooms).send_self());
            }
        }
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
        Delegate(_) | SaveRoom(_) | LoadRoom(_) | Save(_, _) | Delete(_) | Fix | Unfix
        | Greeting(_) | CallVote(_) | Vote(_) | ForceVote(_) | MaxTeams(_) => {
            response.warn("This command is only available in rooms.");
        }
        Malformed(lines) => {
            let refs: Vec<&str> = lines.iter().map(|s| s.as_str()).collect();
            match refs.as_slice() {
                [] => response.error("Empty command (state: in lobby)"),
                ["CMD"] => response.warn(
                    "Unknown command or invalid parameters. Say '/help' in chat for a list of commands.",
                ),
                ["CMD", params] => {
                    let (cmd, rest) = match params.find(' ') {
                        Some(idx) => (&params[..idx], params[idx + 1..].trim_start_matches(' ')),
                        None => (*params, ""),
                    };
                    let cmd_upper = cmd.to_ascii_uppercase();
                    match cmd_upper.as_str() {
                        "DELEGATE" | "SAVEROOM" | "LOADROOM" | "DELETE" if !rest.is_empty() => {
                            response.warn("This command is only available in rooms.")
                        }
                        "SAVE" if rest.contains(' ') => {
                            response.warn("This command is only available in rooms.")
                        }
                        "FIX" | "UNFIX" | "GREETING" | "CALLVOTE" | "VOTE" | "FORCE"
                        | "MAXTEAMS" => response.warn("This command is only available in rooms."),
                        _ => response.warn(
                            "Unknown command or invalid parameters. Say '/help' in chat for a list of commands.",
                        ),
                    }
                }
                ["RESTART_SERVER", _] => {
                    if server.is_admin(client_id) {
                        response.warn("Please confirm server restart with '/restart_server yes'.");
                    }
                }
                ["SET_SERVER_VAR", "LATEST_PROTO", _] => {}
                [cmd, ..] => {
                    response.error(&format!("Incorrect command '{}' (state: in lobby)", cmd))
                }
            }
        }
        other => {
            let cmd = super::common::protocol_cmd_name(&other);
            response.error(&format!("Incorrect command '{}' (state: in lobby)", cmd));
        }
    }
}
