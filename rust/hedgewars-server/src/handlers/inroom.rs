use super::{common::rnd_reply, strings::*};
use crate::core::room::GameInfo;
use crate::core::server::{AddTeamError, SetTeamCountError};
use crate::{
    core::{
        room::{HwRoom, RoomFlags, MAX_TEAMS_IN_ROOM},
        server::{
            ChangeMasterError, ChangeMasterResult, HwRoomControl, LeaveRoomResult, ModifyTeamError,
            StartGameError,
        },
        types,
        types::{ClientId, GameCfg, RoomId, VoteType, Voting, MAX_HEDGEHOGS_PER_TEAM},
    },
    protocol::messages::{
        add_flags, remove_flags, server_chat, HwProtocolMessage, HwServerMessage::*,
        ProtocolFlags as Flags,
    },
    utils::{is_name_illegal, to_engine_msg},
};
use base64::{decode, encode};
use log::*;
use std::{cmp::min, iter::once, mem::swap};

#[derive(Clone)]
struct ByMsg<'a> {
    messages: &'a [u8],
}

impl<'a> Iterator for ByMsg<'a> {
    type Item = &'a [u8];

    fn next(&mut self) -> Option<<Self as Iterator>::Item> {
        if let Some(size) = self.messages.get(0) {
            let (msg, next) = self.messages.split_at(*size as usize + 1);
            self.messages = next;
            Some(msg)
        } else {
            None
        }
    }
}

fn by_msg(source: &[u8]) -> ByMsg {
    ByMsg { messages: source }
}

const VALID_MESSAGES: &[u8] =
    b"M#+LlRrUuDdZzAaSjJ,NpPwtgfhbc12345\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A";
const NON_TIMED_MESSAGES: &[u8] = b"M#hb";

/*#[cfg(canhazslicepatterns)]
fn is_msg_valid(msg: &[u8], team_indices: &[u8]) -> bool {
    match msg {
        [size, typ, body..MAX] => {
            VALID_MESSAGES.contains(typ)
                && match body {
                    [1..=MAX_HEDGEHOGS_PER_TEAM, team, ..] if *typ == b'h' => {
                        team_indices.contains(team)
                    }
                    _ => *typ != b'h',
                }
        }
        _ => false,
    }
}*/

fn is_msg_valid(msg: &[u8], _team_indices: &[u8]) -> bool {
    if let Some(typ) = msg.get(1) {
        VALID_MESSAGES.contains(typ)
    } else {
        false
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
            VoteType::HedgehogsPerTeam(number) => format!("hedgehogs per team: {}", number),
        }
    )
}

fn room_message_flag(msg: &HwProtocolMessage) -> RoomFlags {
    use crate::protocol::messages::HwProtocolMessage::*;
    match msg {
        ToggleRestrictJoin => RoomFlags::RESTRICTED_JOIN,
        ToggleRestrictTeams => RoomFlags::RESTRICTED_TEAM_ADD,
        ToggleRegisteredOnly => RoomFlags::RESTRICTED_UNREGISTERED_PLAYERS,
        _ => RoomFlags::empty(),
    }
}

pub fn handle(
    mut room_control: HwRoomControl,
    response: &mut super::Response,
    message: HwProtocolMessage,
) {
    let (client, room) = room_control.get();
    let (client_id, room_id) = (client.id, room.id);

    use crate::protocol::messages::HwProtocolMessage::*;
    match message {
        Part(msg) => {
            let msg = match msg {
                Some(s) => format!("part: {}", s),
                None => "part".to_string(),
            };

            let result = room_control.leave_room();
            super::common::get_room_leave_result(
                room_control.server(),
                room_control.room(),
                &msg,
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
                .in_room(room_id),
            );
        }
        TeamChat(msg) => {
            if let Some(ref info) = room.game_info {
                if let Some(clan_color) = room.find_team_color(client_id) {
                    let engine_msg =
                        to_engine_msg(format!("b{}]{}\x20\x20", client.nick, msg).bytes());
                    let team = room.clan_team_owners(clan_color).collect();
                    response.add(ForwardEngineMessage(vec![engine_msg]).send_many(team))
                }
            }
        }
        Fix => {
            if let Err(_) = room_control.fix_room() {
                response.warn(ACCESS_DENIED)
            }
        }
        Unfix => {
            if let Err(_) = room_control.unfix_room() {
                response.warn(ACCESS_DENIED)
            }
        }
        Greeting(text) => {
            if let Err(_) = room_control.set_room_greeting(text) {
                response.warn(ACCESS_DENIED)
            }
        }
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
                    super::common::get_room_update(Some(old_name), room, Some(client), response)
                }
                Err(ModifyRoomNameError::AccessDenied) => response.warn(ACCESS_DENIED),
                Err(ModifyRoomNameError::InvalidName) => response.warn(ILLEGAL_ROOM_NAME),
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
                    let room_master = if let Some(id) = room.master_id {
                        Some(room_control.server().client(id))
                    } else {
                        None
                    };
                    super::common::get_room_update(None, room, room_master, response);
                }
                Err(AddTeamError::TooManyTeams) => response.warn(TOO_MANY_TEAMS),
                Err(AddTeamError::TooManyHedgehogs) => response.warn(TOO_MANY_HEDGEHOGS),
                Err(AddTeamError::TeamAlreadyExists) => response.warn(TEAM_EXISTS),
                Err(AddTeamError::GameInProgress) => response.warn(ROUND_IN_PROGRESS),
                Err(AddTeamError::Restricted) => response.warn(TEAM_ADD_RESTRICTED),
            }
        }
        RemoveTeam(name) => {
            use crate::core::server::RemoveTeamError;
            match room_control.remove_team(&name) {
                Ok(()) => {
                    let (client, room) = room_control.get();

                    let removed_teams = vec![name];
                    super::common::get_remove_teams_data(
                        room_id,
                        client.is_in_game(),
                        removed_teams,
                        response,
                    );

                    match room.game_info {
                        Some(ref info) if info.teams_in_game == 0 => {
                            if let Some(result) = room_control.end_game() {
                                super::common::get_end_game_result(
                                    room_control.server(),
                                    room_id,
                                    result,
                                    response,
                                );
                            }
                        }
                        _ => (),
                    }
                }
                Err(RemoveTeamError::NoTeam) => response.warn(NO_TEAM_TO_REMOVE),
                Err(RemoveTeamError::TeamNotOwned) => response.warn(TEAM_NOT_OWNED),
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
            response.add(
                server_chat(format!("Room config saved as {}", name))
                    .send_all()
                    .in_room(room_id),
            );
            room_control.save_config(name, location);
        }
        #[cfg(feature = "official-server")]
        SaveRoom(filename) => {
            if client.is_admin() {
                match room.get_saves() {
                    Ok(contents) => response.request_io(super::IoTask::SaveRoom {
                        room_id,
                        filename,
                        contents,
                    }),
                    Err(e) => {
                        warn!("Error while serializing the room configs: {}", e);
                        response.warn("Unable to serialize the room configs.")
                    }
                }
            }
        }
        #[cfg(feature = "official-server")]
        LoadRoom(filename) => {
            if client.is_admin() {
                response.request_io(super::IoTask::LoadRoom { room_id, filename });
            }
        }
        Delete(name) => {
            if !room_control.delete_config(&name) {
                response.add(Warning(format!("Save doesn't exist: {}", name)).send_self());
            } else {
                response.add(
                    server_chat(format!("Room config {} has been deleted", name))
                        .send_all()
                        .in_room(room_id),
                );
            }
        }
        CallVote(None) => {
            response.add(server_chat("Available callvote commands: kick <nickname>, map <name>, pause, newseed, hedgehogs <number>".to_string())
                .send_self());
        }
        /*CallVote(Some(kind)) => {
            let is_in_game = room.game_info.is_some();
            let error = match &kind {
                VoteType::Kick(nick) => {
                    if room_control.server()
                        .find_client(&nick)
                        .filter(|c| c.room_id == Some(room_id))
                        .is_some()
                    {
                        None
                    } else {
                        Some("/callvote kick: No such user!".to_string())
                    }
                }
                VoteType::Map(None) => {
                    let names: Vec<_> = room.saves.keys().cloned().collect();
                    if names.is_empty() {
                        Some("/callvote map: No maps saved in this room!".to_string())
                    } else {
                        Some(format!("Available maps: {}", names.join(", ")))
                    }
                }
                VoteType::Map(Some(name)) => {
                    if room.saves.get(&name[..]).is_some() {
                        None
                    } else {
                        Some("/callvote map: No such map!".to_string())
                    }
                }
                VoteType::Pause => {
                    if is_in_game {
                        None
                    } else {
                        Some("/callvote pause: No game in progress!".to_string())
                    }
                }
                VoteType::NewSeed => None,
                VoteType::HedgehogsPerTeam(number) => match number {
                    1..=MAX_HEDGEHOGS_PER_TEAM => None,
                    _ => Some("/callvote hedgehogs: Specify number from 1 to 8.".to_string()),
                },
            };

            match error {
                None => {
                    let msg = voting_description(&kind);
                    let voting = Voting::new(kind, room_control.server().room_clients(client_id).collect());
                    let room = room_control.server().room_mut(room_id);
                    room.voting = Some(voting);
                    response.add(server_chat(msg).send_all().in_room(room_id));
                    super::common::submit_vote(
                        room_control.server(),
                        types::Vote {
                            is_pro: true,
                            is_forced: false,
                        },
                        response,
                    );
                }
                Some(msg) => {
                    response.add(server_chat(msg).send_self());
                }
            }
        }*/
        /*Vote(vote) => {
            super::common::submit_vote(
                room_control.server(),
                types::Vote {
                    is_pro: vote,
                    is_forced: false,
                },
                response,
            );
        }*/
        /*ForceVote(vote) => {
            let is_forced = client.is_admin();
            super::common::submit_vote(
                room_control.server(),
                types::Vote {
                    is_pro: vote,
                    is_forced,
                },
                response,
            );
        }*/
        ToggleRestrictJoin | ToggleRestrictTeams | ToggleRegisteredOnly => {
            if room_control.toggle_flag(room_message_flag(&message)) {
                let (client, room) = room_control.get();
                super::common::get_room_update(None, room, Some(&client), response);
            }
        }
        StartGame => {
            let result = room_control.start_game();
            super::common::get_start_game_data(room_control.server(), room_id, result, response);
        }
        /*EngineMessage(em) => {
            if client.teams_in_game > 0 {
                let decoding = decode(&em[..]).unwrap();
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

                let em_response = encode(&valid.flat_map(|msg| msg).cloned().collect::<Vec<_>>());
                if !em_response.is_empty() {
                    response.add(
                        ForwardEngineMessage(vec![em_response])
                            .send_all()
                            .in_room(room.id)
                            .but_self(),
                    );
                }
                let em_log = encode(&non_empty.flat_map(|msg| msg).cloned().collect::<Vec<_>>());
                if let Some(ref mut info) = room.game_info {
                    if !em_log.is_empty() {
                        info.msg_log.push(em_log);
                    }
                    if let Some(msg) = sync_msg {
                        info.sync_msg = msg;
                    }
                }
            }
        }*/
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

                if let Some(GameInfo {
                    teams_in_game: 0, ..
                }) = room.game_info
                {
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
            echo.extend(v.into_iter());
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
                response.add(
                    ClientFlags(
                        add_flags(&[Flags::RoomMaster]),
                        vec![room_control.server().client(new_master_id).nick.clone()],
                    )
                    .send_all()
                    .in_room(room_id),
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
        _ => warn!("Unimplemented!"),
    }
}
