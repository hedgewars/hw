use mio;

use super::common::rnd_reply;
use crate::utils::to_engine_msg;
use crate::{
    protocol::messages::{
        add_flags, remove_flags, server_chat, HWProtocolMessage, HWServerMessage::*,
        ProtocolFlags as Flags,
    },
    server::{
        core::HWServer,
        coretypes,
        coretypes::{ClientId, GameCfg, RoomId, VoteType, Voting, MAX_HEDGEHOGS_PER_TEAM},
        room::{HWRoom, RoomFlags},
    },
    utils::is_name_illegal,
};
use base64::{decode, encode};
use log::*;
use std::iter::once;
use std::mem::swap;

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

#[cfg(canhazslicepatterns)]
fn is_msg_valid(msg: &[u8], team_indices: &[u8]) -> bool {
    match msg {
        [size, typ, body..] => {
            VALID_MESSAGES.contains(typ)
                && match body {
                    [1...MAX_HEDGEHOGS_PER_TEAM, team, ..] if *typ == b'h' => {
                        team_indices.contains(team)
                    }
                    _ => *typ != b'h',
                }
        }
        _ => false,
    }
}

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

fn room_message_flag(msg: &HWProtocolMessage) -> RoomFlags {
    use crate::protocol::messages::HWProtocolMessage::*;
    match msg {
        ToggleRestrictJoin => RoomFlags::RESTRICTED_JOIN,
        ToggleRestrictTeams => RoomFlags::RESTRICTED_TEAM_ADD,
        ToggleRegisteredOnly => RoomFlags::RESTRICTED_UNREGISTERED_PLAYERS,
        _ => RoomFlags::empty(),
    }
}

pub fn handle(
    server: &mut HWServer,
    client_id: ClientId,
    response: &mut super::Response,
    room_id: RoomId,
    message: HWProtocolMessage,
) {
    let client = &mut server.clients[client_id];
    let room = &mut server.rooms[room_id];

    use crate::protocol::messages::HWProtocolMessage::*;
    match message {
        Part(msg) => {
            let msg = match msg {
                Some(s) => format!("part: {}", s),
                None => "part".to_string(),
            };
            super::common::exit_room(server, client_id, response, &msg);
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
        Fix => {
            if client.is_admin() {
                room.set_is_fixed(true);
                room.set_join_restriction(false);
                room.set_team_add_restriction(false);
                room.set_unregistered_players_restriction(true);
            }
        }
        Unfix => {
            if client.is_admin() {
                room.set_is_fixed(false);
            }
        }
        Greeting(text) => {
            if client.is_admin() || client.is_master() && !room.is_fixed() {
                room.greeting = text;
            }
        }
        RoomName(new_name) => {
            if is_name_illegal(&new_name) {
                response.add(Warning("Illegal room name! A room name must be between 1-40 characters long, must not have a trailing or leading space and must not have any of these characters: $()*+?[]^{|}".to_string()).send_self());
            } else if server.has_room(&new_name) {
                response.add(
                    Warning("A room with the same name already exists.".to_string()).send_self(),
                );
            } else {
                let room = &mut server.rooms[room_id];
                if room.is_fixed() || room.master_id != Some(client_id) {
                    response.add(Warning("Access denied.".to_string()).send_self());
                } else {
                    let mut old_name = new_name.clone();
                    let client = &server.clients[client_id];
                    swap(&mut room.name, &mut old_name);
                    super::common::get_room_update(Some(old_name), room, Some(&client), response);
                }
            }
        }
        ToggleReady => {
            let flags = if client.is_ready() {
                room.ready_players_number -= 1;
                remove_flags(&[Flags::Ready])
            } else {
                room.ready_players_number += 1;
                add_flags(&[Flags::Ready])
            };

            let msg = if client.protocol_number < 38 {
                LegacyReady(client.is_ready(), vec![client.nick.clone()])
            } else {
                ClientFlags(flags, vec![client.nick.clone()])
            };
            response.add(msg.send_all().in_room(room.id));
            client.set_is_ready(!client.is_ready());

            if room.is_fixed() && room.ready_players_number == room.players_number {
                super::common::start_game(server, room_id, response);
            }
        }
        AddTeam(mut info) => {
            if room.teams.len() >= room.team_limit as usize {
                response.add(Warning("Too many teams!".to_string()).send_self());
            } else if room.addable_hedgehogs() == 0 {
                response.add(Warning("Too many hedgehogs!".to_string()).send_self());
            } else if room.find_team(|t| t.name == info.name) != None {
                response.add(
                    Warning("There's already a team with same name in the list.".to_string())
                        .send_self(),
                );
            } else if room.game_info.is_some() {
                response.add(
                    Warning("Joining not possible: Round is in progress.".to_string()).send_self(),
                );
            } else if room.is_team_add_restricted() {
                response.add(
                    Warning("This room currently does not allow adding new teams.".to_string())
                        .send_self(),
                );
            } else {
                info.owner = client.nick.clone();
                let team = room.add_team(client.id, *info, client.protocol_number < 42);
                client.teams_in_game += 1;
                client.clan = Some(team.color);
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

                let room_master = if let Some(id) = room.master_id {
                    Some(&server.clients[id])
                } else {
                    None
                };
                super::common::get_room_update(None, room, room_master, response);
            }
        }
        RemoveTeam(name) => match room.find_team_owner(&name) {
            None => response.add(
                Warning("Error: The team you tried to remove does not exist.".to_string())
                    .send_self(),
            ),
            Some((id, _)) if id != client_id => response
                .add(Warning("You can't remove a team you don't own.".to_string()).send_self()),
            Some((_, name)) => {
                client.teams_in_game -= 1;
                client.clan = room.find_team_color(client.id);
                super::common::remove_teams(
                    room,
                    vec![name.to_string()],
                    client.is_in_game(),
                    response,
                );

                match room.game_info {
                    Some(ref info) if info.teams_in_game == 0 => {
                        super::common::end_game(server, room_id, response)
                    }
                    _ => (),
                }
            }
        },
        SetHedgehogsNumber(team_name, number) => {
            let addable_hedgehogs = room.addable_hedgehogs();
            if let Some((_, team)) = room.find_team_and_owner_mut(|t| t.name == team_name) {
                if !client.is_master() {
                    response.add(Error("You're not the room master!".to_string()).send_self());
                } else if number < 1
                    || number > MAX_HEDGEHOGS_PER_TEAM
                    || number > addable_hedgehogs + team.hedgehogs_number
                {
                    response
                        .add(HedgehogsNumber(team.name.clone(), team.hedgehogs_number).send_self());
                } else {
                    team.hedgehogs_number = number;
                    response.add(
                        HedgehogsNumber(team.name.clone(), number)
                            .send_all()
                            .in_room(room_id)
                            .but_self(),
                    );
                }
            } else {
                response.add(Warning("No such team.".to_string()).send_self());
            }
        }
        SetTeamColor(team_name, color) => {
            if let Some((owner, team)) = room.find_team_and_owner_mut(|t| t.name == team_name) {
                if !client.is_master() {
                    response.add(Error("You're not the room master!".to_string()).send_self());
                } else {
                    team.color = color;
                    response.add(
                        TeamColor(team.name.clone(), color)
                            .send_all()
                            .in_room(room_id)
                            .but_self(),
                    );
                    server.clients[owner].clan = Some(color);
                }
            } else {
                response.add(Warning("No such team.".to_string()).send_self());
            }
        }
        Cfg(cfg) => {
            if room.is_fixed() {
                response.add(Warning("Access denied.".to_string()).send_self());
            } else if !client.is_master() {
                response.add(Error("You're not the room master!".to_string()).send_self());
            } else {
                let cfg = match cfg {
                    GameCfg::Scheme(name, mut values) => {
                        if client.protocol_number == 49 && values.len() >= 2 {
                            let mut s = "X".repeat(50);
                            s.push_str(&values.pop().unwrap());
                            values.push(s);
                        }
                        GameCfg::Scheme(name, values)
                    }
                    cfg => cfg,
                };

                response.add(cfg.to_server_msg().send_all().in_room(room.id).but_self());
                room.set_config(cfg);
            }
        }
        Save(name, location) => {
            response.add(
                server_chat(format!("Room config saved as {}", name))
                    .send_all()
                    .in_room(room_id),
            );
            room.save_config(name, location);
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
                        response.add(
                            Warning("Unable to serialize the room configs.".to_string())
                                .send_self(),
                        )
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
            if !room.delete_config(&name) {
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
        CallVote(Some(kind)) => {
            let is_in_game = room.game_info.is_some();
            let error = match &kind {
                VoteType::Kick(nick) => {
                    if server
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
                    let names: Vec<_> = server.rooms[room_id].saves.keys().cloned().collect();
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
                    1...MAX_HEDGEHOGS_PER_TEAM => None,
                    _ => Some("/callvote hedgehogs: Specify number from 1 to 8.".to_string()),
                },
            };

            match error {
                None => {
                    let msg = voting_description(&kind);
                    let voting = Voting::new(kind, server.collect_room_clients(client_id));
                    let room = &mut server.rooms[room_id];
                    room.voting = Some(voting);
                    response.add(server_chat(msg).send_all().in_room(room_id));
                    super::common::submit_vote(
                        server,
                        coretypes::Vote {
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
        }
        Vote(vote) => {
            super::common::submit_vote(
                server,
                coretypes::Vote {
                    is_pro: vote,
                    is_forced: false,
                },
                response,
            );
        }
        ForceVote(vote) => {
            let is_forced = client.is_admin();
            super::common::submit_vote(
                server,
                coretypes::Vote {
                    is_pro: vote,
                    is_forced,
                },
                response,
            );
        }
        ToggleRestrictJoin | ToggleRestrictTeams | ToggleRegisteredOnly => {
            if client.is_master() {
                room.flags.toggle(room_message_flag(&message));
                super::common::get_room_update(None, room, Some(&client), response);
            }
        }
        StartGame => {
            super::common::start_game(server, room_id, response);
        }
        EngineMessage(em) => {
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
        }
        RoundFinished => {
            let mut game_ended = false;
            if client.is_in_game() {
                client.set_is_in_game(false);
                response.add(
                    ClientFlags(remove_flags(&[Flags::InGame]), vec![client.nick.clone()])
                        .send_all()
                        .in_room(room.id),
                );
                let team_names: Vec<_> = room
                    .client_teams(client_id)
                    .map(|t| t.name.clone())
                    .collect();

                if let Some(ref mut info) = room.game_info {
                    info.teams_in_game -= team_names.len() as u8;
                    if info.teams_in_game == 0 {
                        game_ended = true;
                    }

                    for team_name in team_names {
                        let msg = once(b'F').chain(team_name.bytes());
                        response.add(
                            ForwardEngineMessage(vec![to_engine_msg(msg)])
                                .send_all()
                                .in_room(room_id)
                                .but_self(),
                        );

                        let remove_msg = to_engine_msg(once(b'F').chain(team_name.bytes()));
                        if let Some(m) = &info.sync_msg {
                            info.msg_log.push(m.clone());
                        }
                        if info.sync_msg.is_some() {
                            info.sync_msg = None
                        }
                        info.msg_log.push(remove_msg.clone());
                        response.add(
                            ForwardEngineMessage(vec![remove_msg])
                                .send_all()
                                .in_room(room_id)
                                .but_self(),
                        );
                    }
                }
            }
            if game_ended {
                super::common::end_game(server, room_id, response)
            }
        }
        Rnd(v) => {
            let result = rnd_reply(&v);
            let mut echo = vec!["/rnd".to_string()];
            echo.extend(v.into_iter());
            let chat_msg = ChatMsg {
                nick: server.clients[client_id].nick.clone(),
                msg: echo.join(" "),
            };
            response.add(chat_msg.send_all().in_room(room_id));
            response.add(result.send_all().in_room(room_id));
        }
        Delegate(nick) => {
            let delegate_id = server.find_client(&nick).map(|c| (c.id, c.room_id));
            let client = &server.clients[client_id];
            if !(client.is_admin() || client.is_master()) {
                response.add(
                    Warning("You're not the room master or a server admin!".to_string())
                        .send_self(),
                )
            } else {
                match delegate_id {
                    None => response.add(Warning("Player is not online.".to_string()).send_self()),
                    Some((id, _)) if id == client_id => response
                        .add(Warning("You're already the room master.".to_string()).send_self()),
                    Some((_, id)) if id != Some(room_id) => response
                        .add(Warning("The player is not in your room.".to_string()).send_self()),
                    Some((id, _)) => {
                        super::common::change_master(server, client_id, id, room_id, response);
                    }
                }
            }
        }
        _ => warn!("Unimplemented!"),
    }
}
