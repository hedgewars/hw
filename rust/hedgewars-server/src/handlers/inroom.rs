use super::{common::rnd_reply, strings::*};
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
        Part(_msg) => {
            let result = room_control.leave_room();
            super::common::get_room_leave_result(
                room_control.server(),
                room_control.room(),
                "",
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
            let _ = room_control.fix_room();
        }
        Unfix => {
            if client.is_admin() {
                if !client.is_master() {
                    response.warn(NOT_MASTER);
                } else {
                    let _ = room_control.unfix_room();
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
                Ok(()) => {}
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
                room_control.save_config(name, location);
            }
        }
        SaveRoom(filename) => {
            if client.is_admin() {
                #[cfg(feature = "official-server")]
                {
                    match room.get_saves() {
                        Ok(contents) => {
                            if let Err(e) = std::fs::write(&filename, contents) {
                                warn!(
                                    "Error while writing the room config file \"{}\": {}",
                                    filename, e
                                );
                            }
                        }
                        Err(e) => {
                            warn!("Error while serializing the room configs: {}", e);
                        }
                    }
                }
            }
        }
        LoadRoom(filename) => {
            if client.is_admin() {
                #[cfg(feature = "official-server")]
                {
                    match std::fs::read_to_string(&filename) {
                        Ok(contents) => {
                            if let Err(e) = room_control.room_mut().set_saves(&contents) {
                                warn!("Error while deserializing the room configs: {}", e);
                            }
                        }
                        Err(e) => {
                            warn!(
                                "Error while reading the room config file \"{}\": {}",
                                filename, e
                            );
                        }
                    }
                }
            }
        }
        Delete(name) => {
            if client.is_admin() {
                room_control.delete_config(&name);
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
                let server = room_control.server();
                let room = room_control.room();
                let mut owners: Vec<&str> = room.teams.iter().map(|t| t.owner_nick.as_str()).collect();
                owners.sort_unstable();
                owners.dedup();
                let not_only_2_players = owners.len() > 2;

                match server.find_client(&kick_nick) {
                    None => response.warn("Player is not online."),
                    Some(kick_cl) => {
                        let kick_id = kick_cl.id;
                        if kick_id == client_id {
                            response.warn("You can't kick yourself!");
                        } else if !(room.game_info.is_none()
                            || not_only_2_players
                            || kick_cl.teams_in_game == 0)
                        {
                            response.warn("You can't kick the only other player!");
                        } else if kick_cl.room_id != Some(room_id) {
                            response.warn("The player is not in your room.");
                        } else if kick_cl.has_super_power() {
                            response.warn("This player is protected from being kicked.");
                        } else {
                            response.add(Kicked.send(kick_id));
                            let leave_result = room_control.kick_user(kick_id);
                            super::common::get_room_leave_result_for_client(
                                room_control.server(),
                                room_control.room(),
                                kick_id,
                                "kicked",
                                leave_result,
                                response,
                            );
                        }
                    }
                }
            }
        }
        RoomBan(ban_nick) => {
            if client.is_master() {
                if let Some(ban_cl) = room_control.server().find_client(&ban_nick) {
                    let ban_id = ban_cl.id;
                    if ban_id != client_id && ban_cl.room_id == Some(room_id) {
                        response.add(Kicked.send(ban_id));
                        let leave_result = room_control.kick_user(ban_id);
                        super::common::get_room_leave_result_for_client(
                            room_control.server(),
                            room_control.room(),
                            ban_id,
                            "kicked",
                            leave_result,
                            response,
                        );
                    }
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
