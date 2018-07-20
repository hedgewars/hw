use mio;

use protocol::messages::{
    HWProtocolMessage,
    HWServerMessage::*,
    server_chat
};
use server::{
    coretypes::{ClientId, RoomId, Voting, VoteType},
    server::HWServer,
    room::{HWRoom, RoomFlags},
    actions::{Action, Action::*}
};
use utils::is_name_illegal;
use std::{
    mem::swap, fs::{File, OpenOptions},
    io::{Read, Write, Result, Error, ErrorKind}
};
use base64::{encode, decode};
use super::common::rnd_reply;

#[derive(Clone)]
struct ByMsg<'a> {
    messages: &'a[u8]
}

impl <'a> Iterator for ByMsg<'a> {
    type Item = &'a[u8];

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
    ByMsg {messages: source}
}

const VALID_MESSAGES: &[u8] =
    b"M#+LlRrUuDdZzAaSjJ,NpPwtgfhbc12345\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A";
const NON_TIMED_MESSAGES: &[u8] = b"M#hb";

#[cfg(canhazslicepatterns)]
fn is_msg_valid(msg: &[u8], team_indices: &[u8]) -> bool {
    match msg {
        [size, typ, body..] => VALID_MESSAGES.contains(typ)
            && match body {
                [1...8, team, ..] if *typ == b'h' => team_indices.contains(team),
                _ => *typ != b'h'
            },
        _ => false
    }
}

fn is_msg_valid(msg: &[u8], team_indices: &[u8]) -> bool {
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
    msg.get(1).filter(|t| !NON_TIMED_MESSAGES.contains(t)).is_some()
}

fn voting_description(kind: &VoteType) -> String {
    format!("New voting started: {}", match kind {
        VoteType::Kick(nick) => format!("kick {}", nick),
        VoteType::Map(name) => format!("map {}", name.as_ref().unwrap()),
        VoteType::Pause => "pause".to_string(),
        VoteType::NewSeed => "new seed".to_string(),
        VoteType::HedgehogsPerTeam(number) => format!("hedgehogs per team: {}", number)
    })
}

fn room_message_flag(msg: &HWProtocolMessage) -> RoomFlags {
    use protocol::messages::HWProtocolMessage::*;
    match msg {
        ToggleRestrictJoin => RoomFlags::RESTRICTED_JOIN,
        ToggleRestrictTeams => RoomFlags::RESTRICTED_TEAM_ADD,
        ToggleRegisteredOnly => RoomFlags::RESTRICTED_UNREGISTERED_PLAYERS,
        _ => RoomFlags::empty()
    }
}

fn read_file(filename: &str) -> Result<String> {
    let mut reader = File::open(filename)?;
    let mut result = String::new();
    reader.read_to_string(&mut result)?;
    Ok(result)
}

fn write_file(filename: &str, content: &str) -> Result<()> {
    let mut writer = OpenOptions::new().create(true).write(true).open(filename)?;
    writer.write_all(content.as_bytes())
}

pub fn handle(server: &mut HWServer, client_id: ClientId, room_id: RoomId, message: HWProtocolMessage) {
    use protocol::messages::HWProtocolMessage::*;
    match message {
        Part(None) => server.react(client_id, vec![
            MoveToLobby("part".to_string())]),
        Part(Some(msg)) => server.react(client_id, vec![
            MoveToLobby(format!("part: {}", msg))]),
        Chat(msg) => {
            let actions = {
                let c = &mut server.clients[client_id];
                let chat_msg = ChatMsg {nick: c.nick.clone(), msg};
                vec![chat_msg.send_all().in_room(room_id).but_self().action()]
            };
            server.react(client_id, actions);
        },
        Fix => {
            if let (c, Some(r)) = server.client_and_room(client_id) {
                if c.is_admin() { r.set_is_fixed(true) }
            }
        }
        Unfix => {
            if let (c, Some(r)) = server.client_and_room(client_id) {
                if c.is_admin() { r.set_is_fixed(false) }
            }
        }
        Greeting(text) => {
            if let (c, Some(r)) = server.client_and_room(client_id) {
                if c.is_admin() || c.is_master() && !r.is_fixed() {
                    r.greeting = text
                }
            }
        }
        RoomName(new_name) => {
            let actions =
                if is_name_illegal(&new_name) {
                    vec![Warn("Illegal room name! A room name must be between 1-40 characters long, must not have a trailing or leading space and must not have any of these characters: $()*+?[]^{|}".to_string())]
                } else if server.rooms[room_id].is_fixed() {
                    vec![Warn("Access denied.".to_string())]
                } else if server.has_room(&new_name) {
                    vec![Warn("A room with the same name already exists.".to_string())]
                } else {
                    let mut old_name = new_name.clone();
                    swap(&mut server.rooms[room_id].name, &mut old_name);
                    vec![SendRoomUpdate(Some(old_name))]
                };
            server.react(client_id, actions);
        },
        ToggleReady => {
            let actions = if let (c, Some(r)) = server.client_and_room(client_id) {
                let flags = if c.is_ready() {
                    r.ready_players_number -= 1;
                    "-r"
                } else {
                    r.ready_players_number += 1;
                    "+r"
                };
                let is_ready = !c.is_ready();
                c.set_is_ready(is_ready);
                let mut v =
                    vec![ClientFlags(flags.to_string(), vec![c.nick.clone()])
                        .send_all().in_room(r.id).action()];
                if r.is_fixed() && r.ready_players_number == r.players_number {
                    v.push(StartRoomGame(r.id))
                }
                v
            } else {
                Vec::new()
            };
            server.react(client_id, actions);
        }
        AddTeam(info) => {
            let mut actions = Vec::new();
            if let (c, Some(r)) = server.client_and_room(client_id) {
                if r.teams.len() >= r.team_limit as usize {
                    actions.push(Warn("Too many teams!".to_string()))
                } else if r.addable_hedgehogs() == 0 {
                    actions.push(Warn("Too many hedgehogs!".to_string()))
                } else if r.find_team(|t| t.name == info.name) != None {
                    actions.push(Warn("There's already a team with same name in the list.".to_string()))
                } else if r.game_info.is_some() {
                    actions.push(Warn("Joining not possible: Round is in progress.".to_string()))
                } else if r.is_team_add_restricted() {
                    actions.push(Warn("This room currently does not allow adding new teams.".to_string()));
                } else {
                    let team = r.add_team(c.id, *info);
                    c.teams_in_game += 1;
                    c.clan = Some(team.color);
                    actions.push(TeamAccepted(team.name.clone())
                        .send_self().action());
                    actions.push(TeamAdd(HWRoom::team_info(&c, team))
                        .send_all().in_room(room_id).but_self().action());
                    actions.push(TeamColor(team.name.clone(), team.color)
                        .send_all().in_room(room_id).action());
                    actions.push(HedgehogsNumber(team.name.clone(), team.hedgehogs_number)
                        .send_all().in_room(room_id).action());
                    actions.push(SendRoomUpdate(None));
                }
            }
            server.react(client_id, actions);
        },
        RemoveTeam(name) => {
            let mut actions = Vec::new();
            if let (c, Some(r)) = server.client_and_room(client_id) {
                match r.find_team_owner(&name) {
                    None =>
                        actions.push(Warn("Error: The team you tried to remove does not exist.".to_string())),
                    Some((id, _)) if id != client_id =>
                        actions.push(Warn("You can't remove a team you don't own.".to_string())),
                    Some((_, name)) => {
                        c.teams_in_game -= 1;
                        c.clan = r.find_team_color(c.id);
                        actions.push(Action::RemoveTeam(name.to_string()));
                    }
                }
            };
            server.react(client_id, actions);
        },
        SetHedgehogsNumber(team_name, number) => {
            let actions = if let (c, Some(r)) = server.client_and_room(client_id) {
                let addable_hedgehogs = r.addable_hedgehogs();
                if let Some((_, mut team)) = r.find_team_and_owner_mut(|t| t.name == team_name) {
                    if !c.is_master() {
                        vec![ProtocolError("You're not the room master!".to_string())]
                    } else if number < 1 || number > 8
                           || number > addable_hedgehogs + team.hedgehogs_number {
                        vec![HedgehogsNumber(team.name.clone(), team.hedgehogs_number)
                            .send_self().action()]
                    } else {
                        team.hedgehogs_number = number;
                        vec![HedgehogsNumber(team.name.clone(), number)
                            .send_all().in_room(room_id).but_self().action()]
                    }
                } else {
                    vec![(Warn("No such team.".to_string()))]
                }
            } else {
                Vec::new()
            };
            server.react(client_id, actions);
        },
        SetTeamColor(team_name, color) => {
            let mut owner_id = None;
            let actions = if let (c, Some(r)) = server.client_and_room(client_id) {
                if let Some((owner, mut team)) = r.find_team_and_owner_mut(|t| t.name == team_name) {
                    if !c.is_master() {
                        vec![ProtocolError("You're not the room master!".to_string())]
                    } else if false  {
                        Vec::new()
                    } else {
                        owner_id = Some(owner);
                        team.color = color;
                        vec![TeamColor(team.name.clone(), color)
                            .send_all().in_room(room_id).but_self().action()]
                    }
                } else {
                    vec![(Warn("No such team.".to_string()))]
                }
            } else {
                Vec::new()
            };

            if let Some(id) = owner_id {
                server.clients[id].clan = Some(color);
            }

            server.react(client_id, actions);
        },
        Cfg(cfg) => {
            let actions = if let (c, Some(r)) = server.client_and_room(client_id) {
                if r.is_fixed() {
                    vec![Warn("Access denied.".to_string())]
                } else if !c.is_master() {
                    vec![ProtocolError("You're not the room master!".to_string())]
                } else {
                    let v = vec![cfg.to_server_msg()
                        .send_all().in_room(r.id).but_self().action()];
                    r.set_config(cfg);
                    v
                }
            } else {
                Vec::new()
            };
            server.react(client_id, actions);
        }
        Save(name, location) => {
            let actions = vec![server_chat(format!("Room config saved as {}", name))
                .send_all().in_room(room_id).action()];
            server.rooms[room_id].save_config(name, location);
            server.react(client_id, actions);
        }
        SaveRoom(filename) => {
            let actions = if server.clients[client_id].is_admin() {
                match server.rooms[room_id].get_saves() {
                    Ok(text) => match write_file(&filename, &text) {
                        Ok(_) => vec![server_chat("Room configs saved successfully.".to_string())
                            .send_self().action()],
                        Err(e) => {
                            warn!("Error while writing the config file \"{}\": {}", filename, e);
                            vec![Warn("Unable to save the room configs.".to_string())]
                        }
                    }
                    Err(e) => {
                        warn!("Error while serializing the room configs: {}", e);
                        vec![Warn("Unable to serialize the room configs.".to_string())]
                    }
                }
            } else {
                Vec::new()
            };
            server.react(client_id, actions);
        }
        LoadRoom(filename) => {
            let actions = if server.clients[client_id].is_admin() {
                match read_file(&filename) {
                    Ok(text) => match server.rooms[room_id].set_saves(&text) {
                        Ok(_) => vec![server_chat("Room configs loaded successfully.".to_string())
                            .send_self().action()],
                        Err(e) => {
                            warn!("Error while deserializing the room configs: {}", e);
                            vec![Warn("Unable to deserialize the room configs.".to_string())]
                        }
                    }
                    Err(e) => {
                        warn!("Error while reading the config file \"{}\": {}", filename, e);
                        vec![Warn("Unable to load the room configs.".to_string())]
                    }
                }
            } else {
                Vec::new()
            };
            server.react(client_id, actions);
        }
        Delete(name) => {
            let actions = if !server.rooms[room_id].delete_config(&name) {
                vec![Warn(format!("Save doesn't exist: {}", name))]
            } else {
                vec![server_chat(format!("Room config {} has been deleted", name))
                    .send_all().in_room(room_id).action()]
            };
            server.react(client_id, actions);
        }
        CallVote(None) => {
            server.react(client_id, vec![
                server_chat("Available callvote commands: kick <nickname>, map <name>, pause, newseed, hedgehogs <number>".to_string())
                    .send_self().action()])
        }
        CallVote(Some(kind)) => {
            let is_in_game = server.rooms[room_id].game_info.is_some();
            let error = match &kind {
                VoteType::Kick(nick) => {
                    if server.find_client(&nick).filter(|c| c.room_id == Some(room_id)).is_some() {
                        None
                    } else {
                        Some("/callvote kick: No such user!".to_string())
                    }
                },
                VoteType::Map(None) => {
                    let names: Vec<_> = server.rooms[room_id].saves.keys().cloned().collect();
                    if names.is_empty() {
                        Some("/callvote map: No maps saved in this room!".to_string())
                    } else {
                        Some(format!("Available maps: {}", names.join(", ")))
                    }
                },
                VoteType::Map(Some(name)) => {
                    if server.rooms[room_id].saves.get(&name[..]).is_some() {
                        Some("/callvote map: No such map!".to_string())
                    } else {
                        None
                    }
                },
                VoteType::Pause => {
                    if is_in_game {
                        None
                    } else {
                        Some("/callvote pause: No game in progress!".to_string())
                    }
                },
                VoteType::NewSeed => {
                    None
                },
                VoteType::HedgehogsPerTeam(number) => {
                    match number {
                        1...8 => None,
                        _ => Some("/callvote hedgehogs: Specify number from 1 to 8.".to_string())
                    }
                },
            };
            match error {
                None => {
                    let msg = voting_description(&kind);
                    let voting = Voting::new(kind, server.room_clients(client_id));
                    server.rooms[room_id].voting = Some(voting);
                    server.react(client_id, vec![
                        server_chat(msg).send_all().in_room(room_id).action(),
                        AddVote{ vote: true, is_forced: false}]);
                }
                Some(msg) => {
                    server.react(client_id, vec![
                        server_chat(msg).send_self().action()])
                }
            }
        }
        Vote(vote) => {
            server.react(client_id, vec![AddVote{ vote, is_forced: false }]);
        }
        ForceVote(vote) => {
            let is_forced = server.clients[client_id].is_admin();
            server.react(client_id, vec![AddVote{ vote, is_forced }]);
        }
        ToggleRestrictJoin | ToggleRestrictTeams | ToggleRegisteredOnly  => {
            if server.clients[client_id].is_master() {
                server.rooms[room_id].flags.toggle(room_message_flag(&message));
            }
            server.react(client_id, vec![SendRoomUpdate(None)]);
        }
        StartGame => {
            server.react(client_id, vec![StartRoomGame(room_id)]);
        }
        EngineMessage(em) => {
            let mut actions = Vec::new();
            if let (c, Some(r)) = server.client_and_room(client_id) {
                if c.teams_in_game > 0 {
                    let decoding = decode(&em[..]).unwrap();
                    let messages = by_msg(&decoding);
                    let valid = messages.filter(|m| is_msg_valid(m, &c.team_indices));
                    let non_empty = valid.clone().filter(|m| !is_msg_empty(m));
                    let sync_msg = valid.clone().filter(|m| is_msg_timed(m))
                        .last().map(|m| if is_msg_empty(m) {Some(encode(m))} else {None});

                    let em_response = encode(&valid.flat_map(|msg| msg).cloned().collect::<Vec<_>>());
                    if !em_response.is_empty() {
                        actions.push(ForwardEngineMessage(vec![em_response])
                            .send_all().in_room(r.id).but_self().action());
                    }
                    let em_log = encode(&non_empty.flat_map(|msg| msg).cloned().collect::<Vec<_>>());
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
            server.react(client_id, actions)
        }
        RoundFinished => {
            let mut actions = Vec::new();
            if let (c, Some(r)) = server.client_and_room(client_id) {
                if c.is_in_game() {
                    c.set_is_in_game(false);
                    actions.push(ClientFlags("-g".to_string(), vec![c.nick.clone()]).
                        send_all().in_room(r.id).action());
                    if r.game_info.is_some() {
                        for team in r.client_teams(c.id) {
                            actions.push(SendTeamRemovalMessage(team.name.clone()));
                        }
                    }
                }
            }
            server.react(client_id, actions)
        },
        Rnd(v) => {
            let result = rnd_reply(&v);
            let mut echo = vec!["/rnd".to_string()];
            echo.extend(v.into_iter());
            let chat_msg = ChatMsg {
                nick: server.clients[client_id].nick.clone(),
                msg: echo.join(" ")
            };
            server.react(client_id, vec![
                chat_msg.send_all().in_room(room_id).action(),
                result.send_all().in_room(room_id).action()])
        },
        _ => warn!("Unimplemented!")
    }
}
