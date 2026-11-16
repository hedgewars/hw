use super::{common::rnd_reply, strings::*, Response};
use std::net::IpAddr;
use crate::core::server::{AddTeamError, SetTeamCountError};
use crate::handlers::actions::ToPendingMessage;
use crate::{
    core::{
        anteroom::HwAnteroom,
        flood::FloodEvent,
        room::{HwRoom, RoomFlags, MAX_TEAMS_IN_ROOM},
        server::{
            ChangeMasterError, ChangeMasterResult, HwRoomControl, LeaveRoomResult,
            ModifyTeamError, StartGameError,
        },
        types::{ClientId, RoomId},
    },
    utils::{is_name_illegal, to_engine_msg},
};
use base64::{decode, encode};
use hedgewars_network_protocol::{
    messages::{
        add_flags, remove_flags, server_chat, HwProtocolMessage, HwServerMessage::*,
        ProtocolFlags as Flags,
    },
    types::{self, GameCfg, Vote, VoteType, MAX_HEDGEHOGS_PER_TEAM},
};
use log::*;
use std::{cmp::min, iter::once};

#[derive(Clone)]
struct ByMsg<'a> {
    messages: &'a [u8],
}

impl<'a> Iterator for ByMsg<'a> {
    type Item = &'a [u8];

    fn next(&mut self) -> Option<<Self as Iterator>::Item> {
        if let Some(size) = self.messages.first() {
            let split_idx = (*size as usize + 1).min(self.messages.len());
            let (msg, next) = self.messages.split_at(split_idx);
            self.messages = next;
            Some(msg)
        } else {
            None
        }
    }
}

fn by_msg(source: &[u8]) -> ByMsg<'_> {
    ByMsg { messages: source }
}

const VALID_MESSAGES: &[u8] =
    b"M#+LlRrUuDdZzAaSjJ,NpPwtgfhbc12345\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A";
const NON_TIMED_MESSAGES: &[u8] = b"M#hb";

fn is_msg_valid(msg: &[u8], team_indices: &[u8]) -> bool {
    match msg {
        [size, typ, body @ ..] => {
            VALID_MESSAGES.contains(typ)
                && match body {
                    [b'1'..=b'8', team, ..] if *typ == b'h' || *size == b'h' => {
                        team_indices.contains(team)
                    }
                    _ => *typ != b'h' && *size != b'h',
                }
        }
        _ => false,
    }
}

fn is_msg_empty(msg: &[u8]) -> bool {
    msg.get(1).filter(|t| **t == b'+').is_some()
}

fn is_msg_timed(msg: &[u8]) -> bool {
    msg.get(1)
        .filter(|t| !NON_TIMED_MESSAGES.contains(t))
        .is_some()
}

fn voting_description(kind: &VoteType) -> String {
    format!(
        "New voting started: {}",
        match kind {
            VoteType::Kick(nick) => format!("kick {}", nick),
            VoteType::Map(name) => format!("map {}", name.as_ref().unwrap()),
            VoteType::Pause => "pause".to_string(),
            VoteType::NewSeed => "new seed".to_string(),
            VoteType::HedgehogsPerTeam(number) => format!("hedgehogs per team:  {}", number),
        }
    )
}

fn has_more_than_two_team_owners(room: &HwRoom) -> bool {
    let mut owners: Vec<&str> = room.teams.iter().map(|t| t.owner_nick.as_str()).collect();
    owners.sort_unstable();
    owners.dedup();
    owners.len() > 2
}

fn validate_kick_target(
    room_control: &HwRoomControl,
    master_id: ClientId,
    target_id: ClientId,
    self_err: &str,
    response: &mut Response,
) -> bool {
    let server = room_control.server();
    let room = room_control.room();
    let not_only_2_players = has_more_than_two_team_owners(room);
    let target_cl = server.client(target_id);

    if target_id == master_id {
        response.warn(self_err);
        false
    } else if !(room.game_info.is_none() || not_only_2_players || target_cl.teams_in_game == 0) {
        response.warn("You can't kick the only other player!");
        false
    } else if target_cl.room_id != Some(room.id) {
        response.warn("The player is not in your room.");
        false
    } else if target_cl.has_super_power() {
        response.warn("This player is protected from being kicked.");
        false
    } else {
        true
    }
}

fn kick_target_from_room(
    room_control: &mut HwRoomControl,
    target_id: ClientId,
    response: &mut Response,
) {
    response.add(Kicked.send(target_id));
    let leave_result = room_control.kick_user(target_id);
    super::common::get_room_leave_result_for_client(
        room_control.server(),
        room_control.room(),
        target_id,
        "kicked",
        leave_result,
        response,
    );
}

fn room_message_flag(msg: &HwProtocolMessage) -> RoomFlags {
    use hedgewars_network_protocol::messages::HwProtocolMessage::*;
    match msg {
        ToggleRestrictJoin => RoomFlags::RESTRICTED_JOIN,
        ToggleRestrictTeams => RoomFlags::RESTRICTED_TEAM_ADD,
        ToggleRegisteredOnly => RoomFlags::REGISTRATION_REQUIRED,
        _ => RoomFlags::empty(),
    }
}

pub fn handle(
    mut room_control: HwRoomControl,
    anteroom: &mut HwAnteroom,
    response: &mut super::Response,
    message: HwProtocolMessage,
) {
    let (client, room) = room_control.get();
    let (client_id, room_id) = (client.id, room.id);

    use hedgewars_network_protocol::messages::HwProtocolMessage::*;
    match message {
        Part(msg) => {
            let msg_str = msg.as_deref().unwrap_or("");
            let nick = room_control.client().nick.clone();
            let room_name = room_control.room().name.clone();
            info!("Client '{}' left room '{}': {}", nick, room_name, msg_str);
            let result = room_control.leave_room();
            super::common::get_room_leave_result(
                room_control.server(),
                room_control.room(),
                msg_str,
                result,
                response,
            );
        }
        Chat(msg) => {
            response.add(
                ChatMsg {
                    nick: client.nick.clone(),
                    msg,
                }
                .send_all()
                .in_room(room_id)
                .but_self(),
            );
        }
        TeamChat(msg) => {
            if room.game_info.is_some() {
                if let Some(clan_color) = room.find_team_color(client_id) {
                    let engine_msg =
                        to_engine_msg(format!("b{}]{}\x20\x20", client.nick, msg).bytes());
                    let team: Vec<_> = room
                        .clan_team_owners(clan_color)
                        .filter(|id| *id != client_id)
                        .collect();
                    response.add(ForwardEngineMessage(vec![engine_msg]).send_many(team))
                }
            }
        }
        Fix => {
            if room_control.fix_room().is_ok() {
                response.add(server_chat("This room is now permanent.".to_string()).send_self());
            }
        }
        Unfix => {
            if client.is_admin() {
                if !client.is_master() {
                    response.warn(NOT_MASTER);
                } else if room_control.unfix_room().is_ok() {
                    response.add(
                        server_chat("This room is no longer permanent.".to_string()).send_self(),
                    );
                }
            }
        }
        Greeting(text) => match room_control.set_room_greeting(text) {
            Ok(is_empty) => {
                let msg = if is_empty {
                    "Greeting message cleared."
                } else {
                    "Greeting message set."
                };
                response.add(server_chat(msg.to_string()).send_self());
            }
            Err(_) => response.warn("You're not the room master or a server admin!"),
        },
        MaxTeams(count) => {
            use crate::core::server::SetTeamCountError;
            match room_control.set_room_max_teams(count) {
                Ok(()) => {
                    response.add(
                        server_chat(format!("Maximum number of teams set to {}.", count))
                            .send_self(),
                    );
                }
                Err(SetTeamCountError::NotMaster) => response.warn(NOT_MASTER),
                Err(SetTeamCountError::InvalidNumber) => {
                    response.warn("/maxteams: specify number from 2 to 8")
                }
            };
        }
        RoomName(new_name) => {
            use crate::core::server::ModifyRoomNameError;
            match room_control.set_room_name(new_name) {
                Ok(old_name) => {
                    let (client, room) = room_control.get();
                    super::common::get_room_update(
                        room_control.server().all_client_protocols().into_iter(),
                        Some(old_name),
                        room,
                        Some(client),
                        response,
                    );
                    super::common::register_flood_event(
                        room_control.server_mut(),
                        anteroom,
                        client_id,
                        FloodEvent::RoomNameUpdate,
                        response,
                    );
                }
                Err(ModifyRoomNameError::NotMaster) => {}
                Err(ModifyRoomNameError::AccessDenied) => response.warn(ACCESS_DENIED),
                Err(ModifyRoomNameError::InvalidName) => response.warn(ILLEGAL_ROOM_RENAME),
                Err(ModifyRoomNameError::DuplicateName) => response.warn(ROOM_EXISTS),
            }
        }
        ToggleReady => {
            let flags = if room_control.toggle_ready() {
                add_flags(&[Flags::Ready])
            } else {
                remove_flags(&[Flags::Ready])
            };
            let (client, room) = room_control.get();

            let msg = if client.protocol_number < 38 {
                LegacyReady(client.is_ready(), vec![client.nick.clone()])
            } else {
                ClientFlags(flags, vec![client.nick.clone()])
            };
            response.add(msg.send_all().in_room(room_id));

            if room.is_fixed() && room.ready_players_number == room.players_number {
                let result = room_control.start_game();
                super::common::get_start_game_data(
                    room_control.server(),
                    room_id,
                    result,
                    response,
                );
            }
        }
        AddTeam(info) => {
            use crate::core::server::AddTeamError;
            match room_control.add_team(info) {
                Ok(team) => {
                    response.add(TeamAccepted(team.name.clone()).send_self());
                    response.add(
                        TeamAdd(team.to_protocol())
                            .send_all()
                            .in_room(room_id)
                            .but_self(),
                    );
                    response.add(
                        TeamColor(team.name.clone(), team.color)
                            .send_all()
                            .in_room(room_id),
                    );
                    response.add(
                        HedgehogsNumber(team.name.clone(), team.hedgehogs_number)
                            .send_all()
                            .in_room(room_id),
                    );

                    let room = room_control.room();
                    let room_master = room.master_id.map(|id| room_control.server().client(id));
                    super::common::get_room_update(
                        room_control.server().all_client_protocols().into_iter(),
                        None,
                        room,
                        room_master,
                        response,
                    );
                }
                Err(AddTeamError::TooManyTeams) => response.warn(TOO_MANY_TEAMS),
                Err(AddTeamError::TooManyHedgehogs) => response.warn(TOO_MANY_HEDGEHOGS),
                Err(AddTeamError::TeamAlreadyExists) => response.warn(TEAM_EXISTS),
                Err(AddTeamError::GameInProgress) => {
                    response.warn("Joining not possible: Round is in progress.")
                }
                Err(AddTeamError::Restricted) => response.warn(TEAM_ADD_RESTRICTED),
            }
        }
        RemoveTeam(name) => {
            use crate::core::server::RemoveTeamError;
            match room_control.remove_team(&name) {
                Ok(()) => {
                    let (client, room) = room_control.get();
                    let was_in_game = room.game_info.is_some() && client.is_in_game();

                    let removed_teams = vec![name];
                    super::common::get_remove_teams_data(
                        room_id,
                        was_in_game,
                        removed_teams,
                        response,
                    );

                    let room = room_control.room();
                    let room_master = room.master_id.map(|id| room_control.server().client(id));
                    super::common::get_room_update(
                        room_control.server().all_client_protocols().into_iter(),
                        None,
                        room,
                        room_master,
                        response,
                    );

                    if was_in_game {
                        if let Some(0) = room_control.room().teams_in_game() {
                            if let Some(result) = room_control.end_game() {
                                super::common::get_end_game_result(
                                    room_control.server(),
                                    room_id,
                                    result,
                                    response,
                                );
                            }
                        }
                    }
                }
                Err(RemoveTeamError::NoTeam) => response.warn(NO_TEAM_TO_REMOVE),
                Err(RemoveTeamError::TeamNotOwned) => response.error(TEAM_NOT_OWNED),
            }
        }
        SetHedgehogsNumber(team_name, number) => {
            use crate::core::server::SetHedgehogsError;
            match room_control.set_team_hedgehogs_number(&team_name, number) {
                Ok(()) => {
                    response.add(
                        HedgehogsNumber(team_name.clone(), number)
                            .send_all()
                            .in_room(room_id)
                            .but_self(),
                    );
                }
                Err(SetHedgehogsError::NotMaster) => response.error(NOT_MASTER),
                Err(SetHedgehogsError::NoTeam) => response.warn(NO_TEAM),
                Err(SetHedgehogsError::InvalidNumber(previous_number)) => {
                    response.add(HedgehogsNumber(team_name.clone(), previous_number).send_self())
                }
            }
        }
        SetTeamColor(team_name, color) => match room_control.set_team_color(&team_name, color) {
            Ok(()) => response.add(
                TeamColor(team_name, color)
                    .send_all()
                    .in_room(room_id)
                    .but_self(),
            ),
            Err(ModifyTeamError::NoTeam) => response.warn(NO_TEAM),
            Err(ModifyTeamError::NotMaster) => response.error(NOT_MASTER),
        },
        Cfg(cfg) => {
            use crate::core::server::SetConfigError;
            let msg = cfg.to_server_msg();
            match room_control.set_config(cfg) {
                Ok(()) => {
                    response.add(msg.send_all().in_room(room_control.room().id).but_self());
                }
                Err(SetConfigError::NotMaster) => response.error(NOT_MASTER),
                Err(SetConfigError::RoomFixed) => response.warn(ACCESS_DENIED),
            }
        }
        Save(name, location) => {
            if client.is_admin() {
                response.add(
                    server_chat(format!("Room config saved as {}", name))
                        .send_all()
                        .in_room(room_id),
                );
                room_control.save_config(name, location);
            }
        }
        SaveRoom(filename) => {
            if client.is_admin() {
                match room.get_saves() {
                    Ok(contents) => match std::fs::write(&filename, contents) {
                        Ok(()) => {
                            response.add(server_chat(ROOM_CONFIG_SAVED.to_string()).send_self());
                        }
                        Err(e) => {
                            warn!(
                                "Error while writing the room config file \"{}\": {}",
                                filename, e
                            );
                            response.warn(ROOM_CONFIG_SAVE_FAILED);
                        }
                    },
                    Err(e) => {
                        warn!("Error while serializing the room configs: {}", e);
                        response.warn("Unable to serialize the room configs.");
                    }
                }
            }
        }
        LoadRoom(filename) => {
            if client.is_admin() {
                match std::fs::read_to_string(&filename) {
                    Ok(contents) => match room_control.room_mut().set_saves(&contents) {
                        Ok(()) => {
                            response.add(server_chat(ROOM_CONFIG_LOADED.to_string()).send_self());
                        }
                        Err(e) => {
                            warn!("Error while deserializing the room configs: {}", e);
                            response.warn(ROOM_CONFIG_DESERIALIZE_FAILED);
                        }
                    },
                    Err(e) => {
                        warn!(
                            "Error while reading the room config file \"{}\": {}",
                            filename, e
                        );
                        response.warn(ROOM_CONFIG_LOAD_FAILED);
                    }
                }
            }
        }
        Delete(name) => {
            if client.is_admin() {
                if !room_control.delete_config(&name) {
                    response.warn(&format!("Save doesn't exist: {}", name));
                } else {
                    response.add(
                        server_chat(format!("Room config {} has been deleted", name))
                            .send_all()
                            .in_room(room_id),
                    );
                }
            }
        }
        CallVote(None) => {
            response.add(
                server_chat(
                    "Available callvote commands: hedgehogs <number>, pause, newseed, map <name>, kick <player>"
                        .to_string(),
                )
                .send_self(),
            );
        }
        CallVote(Some(kind)) => {
            use crate::core::server::StartVoteError;
            let room_id = room_control.room().id;
            if super::common::check_vote(
                room_control.server(),
                room_control.room(),
                &kind,
                response,
            ) {
                match room_control.start_vote(kind.clone()) {
                    Ok(()) => {
                        let msg = voting_description(&kind);
                        response.add(server_chat(msg).send_all().in_room(room_id));
                        let vote_result = room_control.vote(types::Vote {
                            is_pro: true,
                            is_forced: false,
                        });
                        super::common::handle_vote(room_control, vote_result, response);
                    }
                    Err(StartVoteError::VotingInProgress) => {}
                }
            }
        }
        Vote(vote) => {
            let vote_result = room_control.vote(types::Vote {
                is_pro: vote,
                is_forced: false,
            });
            super::common::handle_vote(room_control, vote_result, response);
        }
        ForceVote(vote) => {
            let vote_result = room_control.vote(types::Vote {
                is_pro: vote,
                is_forced: true,
            });
            super::common::handle_vote(room_control, vote_result, response);
        }
        ToggleRestrictJoin | ToggleRestrictTeams | ToggleRegisteredOnly => {
            let send_update = !matches!(message, ToggleRestrictTeams);
            if room_control.toggle_flag(room_message_flag(&message)) && send_update {
                let (client, room) = room_control.get();
                super::common::get_room_update(
                    room_control.server().all_client_protocols().into_iter(),
                    None,
                    room,
                    Some(client),
                    response,
                );
            }
        }
        StartGame => {
            if client.is_master() {
                let result = room_control.start_game();
                super::common::get_start_game_data(
                    room_control.server(),
                    room_id,
                    result,
                    response,
                );
            }
        }
        EngineMessage(em) => {
            if client.teams_in_game > 0 && room.game_info.is_some() {
                if let Ok(decoding) = decode(&em[..]) {
                    let messages = by_msg(&decoding);
                    let valid = messages.filter(|m| is_msg_valid(m, &client.team_indices));
                    let non_empty = valid.clone().filter(|m| !is_msg_empty(m));
                    let sync_msg = valid.clone().filter(|m| is_msg_timed(m)).last().map(|m| {
                        if is_msg_empty(m) {
                            Some(encode(m))
                        } else {
                            None
                        }
                    });

                    let em_response = encode(valid.flatten().cloned().collect::<Vec<_>>());
                    if !em_response.is_empty() {
                        response.add(
                            ForwardEngineMessage(vec![em_response])
                                .send_all()
                                .in_room(room.id)
                                .but_self(),
                        );
                        let em_log = encode(non_empty.flatten().cloned().collect::<Vec<_>>());
                        room_control.log_engine_msg(em_log, sync_msg);
                        super::common::register_flood_event(
                            room_control.server_mut(),
                            anteroom,
                            client_id,
                            FloodEvent::EngineMessage,
                            response,
                        );
                    }
                }
            }
        }
        RoundFinished => {
            if let Some(team_names) = room_control.leave_game() {
                let (client, room) = room_control.get();
                response.add(
                    ClientFlags(remove_flags(&[Flags::InGame]), vec![client.nick.clone()])
                        .send_all()
                        .in_room(room.id),
                );

                for team_name in team_names {
                    let msg = once(b'F').chain(team_name.bytes());
                    response.add(
                        ForwardEngineMessage(vec![to_engine_msg(msg)])
                            .send_all()
                            .in_room(room_id)
                            .but_self(),
                    );
                }

                if let Some(0) = room.teams_in_game() {
                    if let Some(result) = room_control.end_game() {
                        super::common::get_end_game_result(
                            room_control.server(),
                            room_id,
                            result,
                            response,
                        );
                    }
                }
            }
        }
        Rnd(v) => {
            let result = rnd_reply(&v);
            let mut echo = vec!["/rnd".to_string()];
            echo.extend(v);
            let chat_msg = ChatMsg {
                nick: client.nick.clone(),
                msg: echo.join(" "),
            };
            response.add(chat_msg.send_all().in_room(room_id));
            response.add(result.send_all().in_room(room_id));
        }
        Delegate(nick) => match room_control.change_master(nick) {
            Ok(ChangeMasterResult {
                old_master_id,
                new_master_id,
            }) => {
                if let Some(master_id) = old_master_id {
                    response.add(
                        ClientFlags(
                            remove_flags(&[Flags::RoomMaster]),
                            vec![room_control.server().client(master_id).nick.clone()],
                        )
                        .send_all()
                        .in_room(room_id),
                    );
                }
                response.add(RoomControlAccess(true).send(new_master_id));
                response.add(
                    ClientFlags(
                        add_flags(&[Flags::RoomMaster]),
                        vec![room_control.server().client(new_master_id).nick.clone()],
                    )
                    .send_all()
                    .in_room(room_id),
                );
                response.add(
                    server_chat("You're the new room master!".to_string()).send(new_master_id),
                );
                let room = room_control.room();
                let master = Some(room_control.server().client(new_master_id));
                super::common::get_room_update(
                    room_control.server().all_client_protocols().into_iter(),
                    None,
                    room,
                    master,
                    response,
                );
            }
            Err(ChangeMasterError::NoAccess) => {
                response.warn("You're not the room master or a server admin!")
            }
            Err(ChangeMasterError::AlreadyMaster) => {
                response.warn("You're already the room master.")
            }
            Err(ChangeMasterError::NoClient) => response.warn("Player is not online."),
            Err(ChangeMasterError::ClientNotInRoom) => {
                response.warn("The player is not in your room.")
            }
        },
        Kick(kick_nick) => {
            if client.is_master() {
                match room_control.server().find_client(&kick_nick) {
                    None => response.warn("Player is not online."),
                    Some(kick_cl) => {
                        let kick_id = kick_cl.id;
                        if validate_kick_target(
                            &room_control,
                            client_id,
                            kick_id,
                            "You can't kick yourself!",
                            response,
                        ) {
                            let master_nick = room_control.client().nick.clone();
                            let room_name = room_control.room().name.clone();
                            info!(
                                "Client '{}' was kicked from room '{}' by master '{}'",
                                kick_nick, room_name, master_nick
                            );
                            kick_target_from_room(&mut room_control, kick_id, response);
                        }
                    }
                }
            }
        }
        RoomBan(target) => {
            if !client.is_master() {
                response.warn(NOT_MASTER);
            } else {
                let target_id = room_control.server().find_client(&target).map(|c| c.id);
                if let Some(ban_id) = target_id {
                    if validate_kick_target(
                        &room_control,
                        client_id,
                        ban_id,
                        "You can't ban yourself!",
                        response,
                    ) {
                        let master_nick = room_control.client().nick.clone();
                        let room_name = room_control.room().name.clone();
                        let ban_cl = room_control.server().client(ban_id);
                        let ban_nick = ban_cl.nick.clone();
                        let ban_host = ban_cl.host.clone();
                        if !ban_host.is_empty() {
                            room_control.ban_ip(ban_host.clone());
                        }
                        info!(
                            "Client '{}' (ip: '{}') was room-banned and kicked from room '{}' by master '{}'",
                            ban_nick, ban_host, room_name, master_nick
                        );
                        response.add(
                            server_chat(format!("Player '{}' was banned from this room.", ban_nick))
                                .send_self(),
                        );
                        kick_target_from_room(&mut room_control, ban_id, response);
                    }
                } else if let Ok(parsed_ip) = target.parse::<IpAddr>() {
                    let canonical_ip = crate::utils::normalize_ip(parsed_ip).to_string();
                    let master_nick = room_control.client().nick.clone();
                    let room_name = room_control.room().name.clone();
                    room_control.ban_ip(canonical_ip.clone());
                    info!(
                        "IP '{}' was added to ban list of room '{}' by master '{}'",
                        canonical_ip, room_name, master_nick
                    );
                    response.add(
                        server_chat("IP address added to room ban list.".to_string()).send_self(),
                    );
                    let not_only_2_players = has_more_than_two_team_owners(room_control.room());
                    let is_in_game = room_control.room().game_info.is_some();
                    let matching_ids: Vec<ClientId> = room_control
                        .server()
                        .iter_clients()
                        .filter(|c| {
                            c.id != client_id
                                && c.room_id == Some(room_id)
                                && c.host == canonical_ip
                                && !c.has_super_power()
                                && (!is_in_game || not_only_2_players || c.teams_in_game == 0)
                        })
                        .map(|c| c.id)
                        .collect();
                    for ban_id in matching_ids {
                        let ban_nick = room_control.server().client(ban_id).nick.clone();
                        info!(
                            "Client '{}' (ip: '{}') was kicked from room '{}' due to room IP ban by master '{}'",
                            ban_nick, canonical_ip, room_name, master_nick
                        );
                        kick_target_from_room(&mut room_control, ban_id, response);
                    }
                } else {
                    response.warn("Player is not online.");
                }
            }
        }
        List => {}
        Stats | RestartServer | RestartServerConfirm => {
            response.warn("This command is only available in the lobby.");
        }
        Malformed(lines) => {
            let refs: Vec<&str> = lines.iter().map(|s| s.as_str()).collect();
            match refs.as_slice() {
                [] => response.error("Empty command (state: in room)"),
                ["CFG", _] => response.error("Empty config entry."),
                ["ADD_TEAM", ..] => response.error("Corrupted hedgehogs info!"),
                ["HH_NUM", team_name, _] => {
                    if !client.is_master() {
                        response.error(NOT_MASTER);
                    } else if let Some(team) = room.find_team(|t| t.name == *team_name) {
                        response.add(
                            HedgehogsNumber(team.name.clone(), team.hedgehogs_number).send_self(),
                        );
                    }
                }
                ["MAXTEAMS"] | ["MAXTEAMS", _] => {
                    if !client.is_master() {
                        response.warn(NOT_MASTER);
                    } else {
                        response.warn("/maxteams: specify number from 2 to 8");
                    }
                }
                ["CALLVOTE", "KICK"] => {
                    if room.master_id.is_some() {
                        response.warn(
                            "/callvote kick: This is only allowed in rooms without a room master.",
                        );
                    } else {
                        response.warn("/callvote kick: You need to specify a nickname.");
                    }
                }
                ["CALLVOTE", "HEDGEHOGS"] | ["CALLVOTE", "HEDGEHOGS", _] => {
                    response.warn("/callvote hedgehogs: Specify number from 1 to 8.");
                }
                ["CALLVOTE", ..] => {
                    response.add(
                        server_chat(
                            "Available callvote commands: hedgehogs <number>, pause, newseed, map <name>, kick <player>"
                                .to_string(),
                        )
                        .send_self(),
                    );
                }
                ["VOTE", _, "FORCE"] => {
                    response.warn("/force: Please use 'yes' or 'no'.");
                }
                ["VOTE", _] => {
                    response.warn("/vote: Please use 'yes' or 'no'.");
                }
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
                        "STATS" | "RESTART_SERVER" => {
                            response.warn("This command is only available in the lobby.")
                        }
                        "BAN" => {
                            if !client.is_master() {
                                response.warn(NOT_MASTER);
                            } else {
                                response.warn("/ban: specify player nickname or IP address");
                            }
                        }
                        "MAXTEAMS" => {
                            if !client.is_master() {
                                response.warn(NOT_MASTER);
                            } else {
                                response.warn("/maxteams: specify number from 2 to 8");
                            }
                        }
                        "VOTE" => response.warn("/vote: Please use 'yes' or 'no'."),
                        "FORCE" => response.warn("/force: Please use 'yes' or 'no'."),
                        "CALLVOTE" => {
                            let (sub, sub_arg) = match rest.find(' ') {
                                Some(idx) => (&rest[..idx], rest[idx + 1..].trim_start_matches(' ')),
                                None => (rest, ""),
                            };
                            match sub.to_ascii_uppercase().as_str() {
                                "KICK" if sub_arg.is_empty() => {
                                    if room.master_id.is_some() {
                                        response.warn(
                                            "/callvote kick: This is only allowed in rooms without a room master.",
                                        );
                                    } else {
                                        response.warn("/callvote kick: You need to specify a nickname.");
                                    }
                                }
                                "HEDGEHOGS" => {
                                    response.warn("/callvote hedgehogs: Specify number from 1 to 8.");
                                }
                                _ => {
                                    response.add(
                                        server_chat(
                                            "Available callvote commands: hedgehogs <number>, pause, newseed, map <name>, kick <player>"
                                                .to_string(),
                                        )
                                        .send_self(),
                                    );
                                }
                            }
                        }
                        _ => response.warn(
                            "Unknown command or invalid parameters. Say '/help' in chat for a list of commands.",
                        ),
                    }
                }
                [cmd, ..] => {
                    response.error(&format!("Incorrect command '{}' (state: in room)", cmd))
                }
            }
        }
        other => {
            let cmd = super::common::protocol_cmd_name(&other);
            response.error(&format!("Incorrect command '{}' (state: in room)", cmd));
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::{
        anteroom::HwAnteroomClient,
        server::{HwRoomOrServer, HwServer, JoinRoomError},
    };
    use crate::handlers::Response;
    use std::num::NonZeroU16;
    use std::time::{Duration, Instant};

    fn make_client(nick: &str, host: &str, is_admin: bool) -> (HwAnteroomClient, String) {
        let client = HwAnteroomClient {
            nick: Some(nick.to_string()),
            protocol_number: NonZeroU16::new(58),
            server_salt: String::new(),
            is_local_admin: is_admin,
            is_registered: true,
            is_admin,
            is_contributor: false,
            is_checker: false,
            ip_addr: None,
            web_password: String::new(),
            has_password_challenge: false,
            pings_queue: 0,
        };
        (client, host.to_string())
    }

    fn setup_room_with_master() -> (HwServer, HwAnteroom, RoomId) {
        let mut server = HwServer::new(16, 16);
        let anteroom = HwAnteroom::new(16);
        let (master_cl, master_host) = make_client("master", "10.0.0.1", false);
        server.add_client(0, master_cl);
        server.client_mut(0).host = master_host;
        let (_, room) = server.create_room(0, "room1".to_string(), None).unwrap();
        let room_id = room.id;
        (server, anteroom, room_id)
    }

    fn add_joined_client(
        server: &mut HwServer,
        id: ClientId,
        nick: &str,
        host: &str,
        room_id: RoomId,
        is_admin: bool,
    ) {
        let (cl, h) = make_client(nick, host, is_admin);
        server.add_client(id, cl);
        server.client_mut(id).host = h;
        let _ = server.join_room(id, room_id, None).unwrap();
    }

    fn dispatch_in_room(
        server: &mut HwServer,
        anteroom: &mut HwAnteroom,
        client_id: ClientId,
        msg: HwProtocolMessage,
    ) -> Vec<(Vec<ClientId>, hedgewars_network_protocol::messages::HwServerMessage)> {
        let mut response = Response::new(client_id);
        let HwRoomOrServer::Room(room_control) = server.get_room_control(client_id) else {
            panic!("client {} is not in room", client_id);
        };
        handle(room_control, anteroom, &mut response, msg);
        server.assert_invariants();
        response.extract_messages(server).collect()
    }

    #[test]
    fn test_room_ban_by_nick_bans_ip_and_blocks_rejoin() {
        let (mut server, mut anteroom, room_id) = setup_room_with_master();
        add_joined_client(&mut server, 1, "target", "10.0.0.2", room_id, false);
        let (alt_cl, alt_host) = make_client("alt", "10.0.0.2", false);
        server.add_client(2, alt_cl);
        server.client_mut(2).host = alt_host;

        let msgs = dispatch_in_room(
            &mut server,
            &mut anteroom,
            0,
            HwProtocolMessage::RoomBan("target".to_string()),
        );

        assert!(server.client(1).room_id.is_none());
        assert!(server.room(room_id).bans.contains(&"10.0.0.2".to_string()));
        assert!(msgs.iter().any(|(targets, m)| targets == &vec![1] && *m == Kicked));
        // Master should not be shown the banned user's IP address
        for (_, m) in &msgs {
            if let ChatMsg { msg, .. } = m {
                assert!(!msg.contains("10.0.0.2"));
            }
        }
        assert!(matches!(
            server.join_room(1, room_id, None),
            Err(JoinRoomError::RoomBanned)
        ));
        assert!(matches!(
            server.join_room(2, room_id, None),
            Err(JoinRoomError::RoomBanned)
        ));
    }

    #[test]
    fn test_room_ban_by_ip_directly_adds_ip_and_kicks_matching_clients() {
        let (mut server, mut anteroom, room_id) = setup_room_with_master();
        add_joined_client(&mut server, 1, "target", "10.0.0.3", room_id, false);

        let msgs = dispatch_in_room(
            &mut server,
            &mut anteroom,
            0,
            HwProtocolMessage::RoomBan("10.0.0.3".to_string()),
        );

        assert!(server.client(1).room_id.is_none());
        assert!(server.room(room_id).bans.contains(&"10.0.0.3".to_string()));
        assert!(msgs.iter().any(|(targets, m)| targets == &vec![1] && *m == Kicked));
        assert!(matches!(
            server.join_room(1, room_id, None),
            Err(JoinRoomError::RoomBanned)
        ));
    }

    #[test]
    fn test_room_ban_by_ipv6_canonicalizes_and_kicks() {
        let (mut server, mut anteroom, room_id) = setup_room_with_master();
        add_joined_client(&mut server, 1, "v6target", "2001:db8::1", room_id, false);

        // Pass non-canonical IPv6 form; should normalize/canonicalize and kick/ban "2001:db8::1"
        let msgs = dispatch_in_room(
            &mut server,
            &mut anteroom,
            0,
            HwProtocolMessage::RoomBan("2001:0db8:0000:0000:0000:0000:0000:0001".to_string()),
        );

        assert!(server.client(1).room_id.is_none());
        assert!(server.room(room_id).bans.contains(&"2001:db8::1".to_string()));
        assert!(msgs.iter().any(|(targets, m)| targets == &vec![1] && *m == Kicked));
        assert!(matches!(
            server.join_room(1, room_id, None),
            Err(JoinRoomError::RoomBanned)
        ));
    }

    #[test]
    fn test_room_ban_non_master_and_no_banlist_review() {
        let (mut server, mut anteroom, room_id) = setup_room_with_master();
        add_joined_client(&mut server, 1, "pleb", "10.0.0.6", room_id, false);
        add_joined_client(&mut server, 2, "other", "10.0.0.7", room_id, false);

        let msgs = dispatch_in_room(
            &mut server,
            &mut anteroom,
            1,
            HwProtocolMessage::RoomBan("other".to_string()),
        );
        assert_eq!(server.client(2).room_id, Some(room_id));
        assert!(server.room(room_id).bans.is_empty());
        assert!(msgs
            .iter()
            .any(|(_, m)| matches!(m, Warning(s) if s == NOT_MASTER)));

        // Ensure there is no BANLIST or ban-review command in rooms
        let banlist_msgs = dispatch_in_room(
            &mut server,
            &mut anteroom,
            0,
            HwProtocolMessage::BanList,
        );
        assert!(banlist_msgs
            .iter()
            .all(|(_, m)| !matches!(m, hedgewars_network_protocol::messages::HwServerMessage::BanList(_))));

        let cmd_banlist_msgs = dispatch_in_room(
            &mut server,
            &mut anteroom,
            0,
            HwProtocolMessage::Malformed(vec!["CMD".to_string(), "BAN_LIST".to_string()]),
        );
        assert!(cmd_banlist_msgs
            .iter()
            .all(|(_, m)| !matches!(m, hedgewars_network_protocol::messages::HwServerMessage::BanList(_))));
    }

    #[test]
    fn test_quick_kick_within_one_second_autobans_ip() {
        let (mut server, mut anteroom, room_id) = setup_room_with_master();
        add_joined_client(&mut server, 1, "rusher", "10.0.0.4", room_id, false);

        let msgs = dispatch_in_room(
            &mut server,
            &mut anteroom,
            0,
            HwProtocolMessage::Kick("rusher".to_string()),
        );

        assert!(server.client(1).room_id.is_none());
        assert!(msgs.iter().any(|(targets, m)| targets == &vec![1] && *m == Kicked));
        assert!(server.room(room_id).bans.contains(&"10.0.0.4".to_string()));
        assert!(matches!(
            server.join_room(1, room_id, None),
            Err(JoinRoomError::RoomBanned)
        ));
    }

    #[test]
    fn test_kick_after_one_second_does_not_autoban() {
        let (mut server, mut anteroom, room_id) = setup_room_with_master();
        add_joined_client(&mut server, 1, "normal", "10.0.0.5", room_id, false);
        server.client_mut(1).room_joined_at =
            Instant::now().checked_sub(Duration::from_secs(2));

        let msgs = dispatch_in_room(
            &mut server,
            &mut anteroom,
            0,
            HwProtocolMessage::Kick("normal".to_string()),
        );

        assert!(server.client(1).room_id.is_none());
        assert!(msgs.iter().any(|(targets, m)| targets == &vec![1] && *m == Kicked));
        assert!(!server.room(room_id).bans.contains(&"10.0.0.5".to_string()));
        assert!(server.join_room(1, room_id, None).is_ok());
    }

    #[test]
    fn test_room_ban_respects_super_power() {
        let (mut server, mut anteroom, room_id) = setup_room_with_master();
        add_joined_client(&mut server, 1, "admin", "10.0.0.8", room_id, true);
        server.client_mut(1).set_has_super_power(true);

        let msgs = dispatch_in_room(
            &mut server,
            &mut anteroom,
            0,
            HwProtocolMessage::RoomBan("admin".to_string()),
        );

        assert_eq!(server.client(1).room_id, Some(room_id));
        assert!(server.room(room_id).bans.is_empty());
        assert!(msgs
            .iter()
            .any(|(_, m)| matches!(m, Warning(s) if s == "This player is protected from being kicked.")));
    }

    #[test]
    fn test_midgame_joiner_clears_ingame_flag_when_game_ends() {
        use hedgewars_network_protocol::types::{HedgehogInfo, TeamInfo};

        let (mut server, mut anteroom, room_id) = setup_room_with_master();
        add_joined_client(&mut server, 1, "bob", "10.0.0.2", room_id, false);

        let make_team = |name: &str, color: u8| {
            Box::new(TeamInfo {
                owner: String::new(),
                name: name.to_string(),
                color,
                grave: "Statue".to_string(),
                fort: "Plane".to_string(),
                voice_pack: "Default".to_string(),
                flag: "hedgewars".to_string(),
                difficulty: 0,
                hedgehogs: [
                    HedgehogInfo {
                        name: "h1".to_string(),
                        hat: "NoHat".to_string(),
                    },
                    HedgehogInfo {
                        name: "h2".to_string(),
                        hat: "NoHat".to_string(),
                    },
                    HedgehogInfo {
                        name: "h3".to_string(),
                        hat: "NoHat".to_string(),
                    },
                    HedgehogInfo {
                        name: "h4".to_string(),
                        hat: "NoHat".to_string(),
                    },
                    HedgehogInfo {
                        name: "h5".to_string(),
                        hat: "NoHat".to_string(),
                    },
                    HedgehogInfo {
                        name: "h6".to_string(),
                        hat: "NoHat".to_string(),
                    },
                    HedgehogInfo {
                        name: "h7".to_string(),
                        hat: "NoHat".to_string(),
                    },
                    HedgehogInfo {
                        name: "h8".to_string(),
                        hat: "NoHat".to_string(),
                    },
                ],
                hedgehogs_number: 4,
            })
        };

        dispatch_in_room(
            &mut server,
            &mut anteroom,
            0,
            HwProtocolMessage::AddTeam(make_team("T0", 0)),
        );
        dispatch_in_room(
            &mut server,
            &mut anteroom,
            1,
            HwProtocolMessage::AddTeam(make_team("T1", 1)),
        );
        dispatch_in_room(&mut server, &mut anteroom, 1, HwProtocolMessage::ToggleReady);
        dispatch_in_room(&mut server, &mut anteroom, 0, HwProtocolMessage::StartGame);

        // Mid-game spectator joins while game is in progress
        add_joined_client(&mut server, 2, "spectator", "10.0.0.3", room_id, false);
        assert!(server.client(2).is_in_game());

        // Playing clients finish the round before spectator sends RoundFinished
        dispatch_in_room(&mut server, &mut anteroom, 0, HwProtocolMessage::RoundFinished);
        let end_msgs =
            dispatch_in_room(&mut server, &mut anteroom, 1, HwProtocolMessage::RoundFinished);

        // Round ended, but spectator's engine is still running until spectator sends RoundFinished
        assert!(server.client(2).is_in_game());
        assert!(!end_msgs.iter().any(|(_, m)| matches!(
            m,
            ClientFlags(flags, nicks)
                if flags == "-g" && nicks.iter().any(|n| n == "spectator")
        )));

        // Room master cannot start a new game while spectator is still in game
        let blocked_msgs =
            dispatch_in_room(&mut server, &mut anteroom, 0, HwProtocolMessage::StartGame);
        assert!(blocked_msgs.iter().any(|(_, m)| matches!(
            m,
            Warning(s) if s == "Some players are still in game!"
        )));
        assert!(!blocked_msgs.iter().any(|(_, m)| matches!(m, RunGame)));

        // Spectator's engine finishes and sends RoundFinished (after room.game_info became None)
        let spec_msgs =
            dispatch_in_room(&mut server, &mut anteroom, 2, HwProtocolMessage::RoundFinished);
        assert!(!server.client(2).is_in_game());
        assert!(spec_msgs.iter().any(|(targets, m)| {
            targets.contains(&0)
                && targets.contains(&1)
                && targets.contains(&2)
                && matches!(
                    m,
                    ClientFlags(flags, nicks)
                        if flags == "-g" && nicks.iter().any(|n| n == "spectator")
                )
        }));
        assert!(!spec_msgs
            .iter()
            .any(|(_, m)| matches!(m, ForwardEngineMessage(_))));

        // Now master can start another game
        let restart_msgs =
            dispatch_in_room(&mut server, &mut anteroom, 0, HwProtocolMessage::StartGame);
        assert!(restart_msgs.iter().any(|(_, m)| matches!(m, RunGame)));
    }

    #[test]
    fn test_midgame_joiner_removes_timed_out_players_teams_when_game_ends() {
        use hedgewars_network_protocol::types::{HedgehogInfo, TeamInfo};

        let (mut server, mut anteroom, room_id) = setup_room_with_master();
        add_joined_client(&mut server, 1, "bob", "10.0.0.2", room_id, false);

        let make_team = |name: &str, color: u8| {
            Box::new(TeamInfo {
                owner: String::new(),
                name: name.to_string(),
                color,
                grave: "Statue".to_string(),
                fort: "Plane".to_string(),
                voice_pack: "Default".to_string(),
                flag: "hedgewars".to_string(),
                difficulty: 0,
                hedgehogs: std::array::from_fn(|i| HedgehogInfo {
                    name: format!("h{}", i + 1),
                    hat: "NoHat".to_string(),
                }),
                hedgehogs_number: 4,
            })
        };

        dispatch_in_room(
            &mut server,
            &mut anteroom,
            0,
            HwProtocolMessage::AddTeam(make_team("TeamMaster", 0)),
        );
        dispatch_in_room(
            &mut server,
            &mut anteroom,
            1,
            HwProtocolMessage::AddTeam(make_team("TeamBob", 1)),
        );
        dispatch_in_room(&mut server, &mut anteroom, 1, HwProtocolMessage::ToggleReady);
        dispatch_in_room(&mut server, &mut anteroom, 0, HwProtocolMessage::StartGame);

        // Bob times out mid-game -> TeamBob removed from room and recorded in GameInfo::left_teams
        let mut timeout_resp = Response::new(1);
        crate::handlers::common::remove_client(
            &mut server,
            &mut anteroom,
            &mut timeout_resp,
            "Ping timeout".to_string(),
        );
        assert!(server.room(room_id).find_team(|t| t.name == "TeamBob").is_none());

        // Charlie joins mid-game after Bob timed out -> receives original_teams including TeamBob
        let (charlie_cl, charlie_host) = make_client("charlie", "10.0.0.3", false);
        server.add_client(2, charlie_cl);
        server.client_mut(2).host = charlie_host;
        let mut protocols = server.all_client_protocols().into_iter();
        let (client_ref, master_ref, room_ref, room_clients) =
            server.join_room(2, room_id, None).unwrap();
        let mut join_resp = Response::new(2);
        crate::handlers::common::get_room_join_data(
            &mut protocols,
            client_ref,
            master_ref,
            room_ref,
            room_clients,
            &mut join_resp,
        );
        let join_msgs: Vec<_> = join_resp.extract_messages(&server).collect();
        assert!(join_msgs.iter().any(|(targets, m)| {
            targets == &vec![2] && matches!(m, TeamAdd(t) if t.first().map(String::as_str) == Some("TeamBob"))
        }));

        // Master finishes round -> Charlie (joined mid-game) must receive REMOVE_TEAM TeamBob, not master
        let end_msgs =
            dispatch_in_room(&mut server, &mut anteroom, 0, HwProtocolMessage::RoundFinished);
        assert!(end_msgs.iter().any(|(targets, m)| {
            targets == &vec![2] && matches!(m, TeamRemove(name) if name == "TeamBob")
        }));
        assert!(!end_msgs.iter().any(|(targets, m)| {
            targets.contains(&0) && matches!(m, TeamRemove(name) if name == "TeamBob")
        }));
    }
}
