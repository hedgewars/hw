use mio;

use super::common::rnd_reply;
use crate::{
    protocol::messages::{server_chat, HWProtocolMessage, HWServerMessage::*},
    server::{
        actions::{Action, Action::*},
        core::HWServer,
        coretypes,
        coretypes::{ClientId, GameCfg, RoomId, VoteType, Voting, MAX_HEDGEHOGS_PER_TEAM},
        room::{HWRoom, RoomFlags},
    },
    utils::is_name_illegal,
};
use base64::{decode, encode};
use log::*;
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
    use crate::protocol::messages::HWProtocolMessage::*;
    match message {
        Part(msg) => {
            let lobby_id = server.lobby_id;
            if let (client, Some(room)) = server.client_and_room(client_id) {
                let msg = match msg {
                    Some(s) => format!("part: {}", s),
                    None => "part".to_string(),
                };
                super::common::exit_room(client, room, response, &msg);
                client.room_id = Some(lobby_id);
            }
        }
        Chat(msg) => {
            let client = &mut server.clients[client_id];
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
            if let (client, Some(room)) = server.client_and_room(client_id) {
                if client.is_admin() {
                    room.set_is_fixed(true)
                }
            }
        }
        Unfix => {
            if let (client, Some(room)) = server.client_and_room(client_id) {
                if client.is_admin() {
                    room.set_is_fixed(false)
                }
            }
        }
        Greeting(text) => {
            if let (clienr, Some(room)) = server.client_and_room(client_id) {
                if clienr.is_admin() || clienr.is_master() && !room.is_fixed() {
                    room.greeting = text
                }
            }
        }
        RoomName(new_name) => {
            if is_name_illegal(&new_name) {
                response.add(Warning("Illegal room name! A room name must be between 1-40 characters long, must not have a trailing or leading space and must not have any of these characters: $()*+?[]^{|}".to_string()).send_self());
            } else if server.rooms[room_id].is_fixed() {
                response.add(Warning("Access denied.".to_string()).send_self());
            } else if server.has_room(&new_name) {
                response.add(
                    Warning("A room with the same name already exists.".to_string()).send_self(),
                );
            } else {
                let mut old_name = new_name.clone();
                let client = &server.clients[client_id];
                let room = &mut server.rooms[room_id];
                swap(&mut room.name, &mut old_name);
                super::common::get_room_update(Some(old_name), room, Some(&client), response);
            };
        }
        ToggleReady => {
            if let (client, Some(room)) = server.client_and_room(client_id) {
                let flags = if client.is_ready() {
                    room.ready_players_number -= 1;
                    "-r"
                } else {
                    room.ready_players_number += 1;
                    "+r"
                };

                let msg = if client.protocol_number < 38 {
                    LegacyReady(client.is_ready(), vec![client.nick.clone()])
                } else {
                    ClientFlags(flags.to_string(), vec![client.nick.clone()])
                };
                response.add(msg.send_all().in_room(room.id));
                if room.is_fixed() && room.ready_players_number == room.players_number {
                    //StartRoomGame(r.id)
                }

                client.set_is_ready(!client.is_ready());
            }
        }
        AddTeam(info) => {
            if let (client, Some(room)) = server.client_and_room(client_id) {
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
                        Warning("Joining not possible: Round is in progress.".to_string())
                            .send_self(),
                    );
                } else if room.is_team_add_restricted() {
                    response.add(
                        Warning("This room currently does not allow adding new teams.".to_string())
                            .send_self(),
                    );
                } else {
                    let team = room.add_team(client.id, *info, client.protocol_number < 42);
                    client.teams_in_game += 1;
                    client.clan = Some(team.color);
                    response.add(TeamAccepted(team.name.clone()).send_self());
                    response.add(
                        TeamAdd(HWRoom::team_info(&client, team))
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

                    super::common::get_room_update(None, room, Some(&client), response);
                }
            }
        }
        RemoveTeam(name) => {
            if let (client, Some(room)) = server.client_and_room(client_id) {
                match room.find_team_owner(&name) {
                    None => response.add(
                        Warning("Error: The team you tried to remove does not exist.".to_string())
                            .send_self(),
                    ),
                    Some((id, _)) if id != client_id => response.add(
                        Warning("You can't remove a team you don't own.".to_string()).send_self(),
                    ),
                    Some((_, name)) => {
                        client.teams_in_game -= 1;
                        client.clan = room.find_team_color(client.id);
                        super::common::remove_teams(
                            room,
                            vec![name.to_string()],
                            client.is_in_game(),
                            response,
                        );
                    }
                }
            }
        }
        SetHedgehogsNumber(team_name, number) => {
            if let (client, Some(room)) = server.client_and_room(client_id) {
                let addable_hedgehogs = room.addable_hedgehogs();
                if let Some((_, team)) = room.find_team_and_owner_mut(|t| t.name == team_name) {
                    if !client.is_master() {
                        response.add(Error("You're not the room master!".to_string()).send_self());
                    } else if number < 1
                        || number > MAX_HEDGEHOGS_PER_TEAM
                        || number > addable_hedgehogs + team.hedgehogs_number
                    {
                        response.add(
                            HedgehogsNumber(team.name.clone(), team.hedgehogs_number).send_self(),
                        );
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
        }
        SetTeamColor(team_name, color) => {
            if let (client, Some(room)) = server.client_and_room(client_id) {
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
        }
        Cfg(cfg) => {
            if let (client, Some(room)) = server.client_and_room(client_id) {
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
        }
        Save(name, location) => {
            response.add(
                server_chat(format!("Room config saved as {}", name))
                    .send_all()
                    .in_room(room_id),
            );
            server.rooms[room_id].save_config(name, location);
        }
        SaveRoom(filename) => {
            if server.clients[client_id].is_admin() {
                match server.rooms[room_id].get_saves() {
                    Ok(text) => match server.io.write_file(&filename, &text) {
                        Ok(_) => response.add(
                            server_chat("Room configs saved successfully.".to_string()).send_self(),
                        ),
                        Err(e) => {
                            warn!(
                                "Error while writing the config file \"{}\": {}",
                                filename, e
                            );
                            response.add(
                                Warning("Unable to save the room configs.".to_string()).send_self(),
                            );
                        }
                    },
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
        LoadRoom(filename) => {
            if server.clients[client_id].is_admin() {
                match server.io.read_file(&filename) {
                    Ok(text) => match server.rooms[room_id].set_saves(&text) {
                        Ok(_) => response.add(
                            server_chat("Room configs loaded successfully.".to_string())
                                .send_self(),
                        ),
                        Err(e) => {
                            warn!("Error while deserializing the room configs: {}", e);
                            response.add(
                                Warning("Unable to deserialize the room configs.".to_string())
                                    .send_self(),
                            );
                        }
                    },
                    Err(e) => {
                        warn!(
                            "Error while reading the config file \"{}\": {}",
                            filename, e
                        );
                        response.add(
                            Warning("Unable to load the room configs.".to_string()).send_self(),
                        );
                    }
                }
            }
        }
        Delete(name) => {
            if !server.rooms[room_id].delete_config(&name) {
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
            let is_in_game = server.rooms[room_id].game_info.is_some();
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
                    if server.rooms[room_id].saves.get(&name[..]).is_some() {
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
                    let voting = Voting::new(kind, server.room_clients(client_id));
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
            let is_forced = server.clients[client_id].is_admin();
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
            let client = &server.clients[client_id];
            let room = &mut server.rooms[room_id];
            if client.is_master() {
                room.flags.toggle(room_message_flag(&message));
                super::common::get_room_update(None, room, Some(&client), response);
            }
        }
        StartGame => {
            // StartRoomGame(room_id);
        }
        EngineMessage(em) => {
            if let (c, Some(r)) = server.client_and_room(client_id) {
                if c.teams_in_game > 0 {
                    let decoding = decode(&em[..]).unwrap();
                    let messages = by_msg(&decoding);
                    let valid = messages.filter(|m| is_msg_valid(m, &c.team_indices));
                    let non_empty = valid.clone().filter(|m| !is_msg_empty(m));
                    let sync_msg = valid.clone().filter(|m| is_msg_timed(m)).last().map(|m| {
                        if is_msg_empty(m) {
                            Some(encode(m))
                        } else {
                            None
                        }
                    });

                    let em_response =
                        encode(&valid.flat_map(|msg| msg).cloned().collect::<Vec<_>>());
                    if !em_response.is_empty() {
                        response.add(
                            ForwardEngineMessage(vec![em_response])
                                .send_all()
                                .in_room(r.id)
                                .but_self(),
                        );
                    }
                    let em_log =
                        encode(&non_empty.flat_map(|msg| msg).cloned().collect::<Vec<_>>());
                    if let Some(ref mut info) = r.game_info {
                        if !em_log.is_empty() {
                            info.msg_log.push(em_log);
                        }
                        if let Some(msg) = sync_msg {
                            info.sync_msg = msg;
                        }
                    }
                }
            }
        }
        RoundFinished => {
            if let (c, Some(r)) = server.client_and_room(client_id) {
                if c.is_in_game() {
                    c.set_is_in_game(false);
                    response.add(
                        ClientFlags("-g".to_string(), vec![c.nick.clone()])
                            .send_all()
                            .in_room(r.id),
                    );
                    if r.game_info.is_some() {
                        for team in r.client_teams(c.id) {
                            //SendTeamRemovalMessage(team.name.clone());
                        }
                    }
                }
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
        _ => warn!("Unimplemented!"),
    }
}
