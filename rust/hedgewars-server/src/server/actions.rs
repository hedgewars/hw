use super::{
    client::HWClient,
    core::HWServer,
    coretypes::{ClientId, GameCfg, RoomId, VoteType},
    handlers,
    room::HWRoom,
    room::{GameInfo, RoomFlags},
};
use crate::{
    protocol::messages::{server_chat, HWProtocolMessage, HWServerMessage, HWServerMessage::*},
    utils::to_engine_msg,
};
use rand::{distributions::Uniform, thread_rng, Rng};
use std::{io, io::Write, iter::once, mem::replace};

#[cfg(feature = "official-server")]
use super::database;

pub enum Destination {
    ToId(ClientId),
    ToSelf,
    ToAll {
        room_id: Option<RoomId>,
        protocol: Option<u16>,
        skip_self: bool,
    },
}

pub struct PendingMessage {
    pub destination: Destination,
    pub message: HWServerMessage,
}

impl PendingMessage {
    pub fn send(message: HWServerMessage, client_id: ClientId) -> PendingMessage {
        PendingMessage {
            destination: Destination::ToId(client_id),
            message,
        }
    }

    pub fn send_self(message: HWServerMessage) -> PendingMessage {
        PendingMessage {
            destination: Destination::ToSelf,
            message,
        }
    }

    pub fn send_all(message: HWServerMessage) -> PendingMessage {
        let destination = Destination::ToAll {
            room_id: None,
            protocol: None,
            skip_self: false,
        };
        PendingMessage {
            destination,
            message,
        }
    }

    pub fn in_room(mut self, clients_room_id: RoomId) -> PendingMessage {
        if let Destination::ToAll {
            ref mut room_id, ..
        } = self.destination
        {
            *room_id = Some(clients_room_id)
        }
        self
    }

    pub fn with_protocol(mut self, protocol_number: u16) -> PendingMessage {
        if let Destination::ToAll {
            ref mut protocol, ..
        } = self.destination
        {
            *protocol = Some(protocol_number)
        }
        self
    }

    pub fn but_self(mut self) -> PendingMessage {
        if let Destination::ToAll {
            ref mut skip_self, ..
        } = self.destination
        {
            *skip_self = true
        }
        self
    }
}

impl HWServerMessage {
    pub fn send(self, client_id: ClientId) -> PendingMessage {
        PendingMessage::send(self, client_id)
    }
    pub fn send_self(self) -> PendingMessage {
        PendingMessage::send_self(self)
    }
    pub fn send_all(self) -> PendingMessage {
        PendingMessage::send_all(self)
    }
}

pub enum Action {
    ChangeMaster(RoomId, Option<ClientId>),
    StartRoomGame(RoomId),
    SendTeamRemovalMessage(String),
    FinishRoomGame(RoomId),
    SendRoomData {
        to: ClientId,
        teams: bool,
        config: bool,
        flags: bool,
    },
}

use self::Action::*;

pub fn run_action(server: &mut HWServer, client_id: usize, action: Action) {
    match action {
        SendRoomData {
            to,
            teams,
            config,
            flags,
        } => {
            let room_id = server.clients[client_id].room_id;
            if let Some(r) = room_id.and_then(|id| server.rooms.get(id)) {
                if config {
                    /*                    actions.push(
                        ConfigEntry("FULLMAPCONFIG".to_string(), r.map_config())
                            .send(to)
                            .action(),
                    )*/
;
                    for cfg in r.game_config() {
                        //actions.push(cfg.to_server_msg().send(to).action());
                    }
                }
                if teams {
                    let current_teams = match r.game_info {
                        Some(ref info) => &info.teams_at_start,
                        None => &r.teams,
                    };
                    for (owner_id, team) in current_teams.iter() {
                        /*actions.push(
                            TeamAdd(HWRoom::team_info(&server.clients[*owner_id], &team))
                                .send(to)
                                .action(),
                        );
                        actions.push(TeamColor(team.name.clone(), team.color).send(to).action());
                        actions.push(
                            HedgehogsNumber(team.name.clone(), team.hedgehogs_number)
                                .send(to)
                                .action(),
                        );*/
                    }
                }
                if flags {
                    if let Some(id) = r.master_id {
                        /*
                                                actions.push(
                                                    ClientFlags("+h".to_string(), vec![server.clients[id].nick.clone()])
                                                        .send(to)
                                                        .action(),
                                                );
                        */
                    }
                    let nicks: Vec<_> = server
                        .clients
                        .iter()
                        .filter(|(_, c)| c.room_id == Some(r.id) && c.is_ready())
                        .map(|(_, c)| c.nick.clone())
                        .collect();
                    if !nicks.is_empty() {
                        /*actions.push(ClientFlags("+r".to_string(), nicks).send(to).action())*/
;
                    }
                }
            }
        }
        ChangeMaster(room_id, new_id) => {
            let room_client_ids = server.room_clients(room_id);
            let new_id = if server
                .room(client_id)
                .map(|r| r.is_fixed())
                .unwrap_or(false)
            {
                new_id
            } else {
                new_id.or_else(|| room_client_ids.iter().find(|id| **id != client_id).cloned())
            };
            let new_nick = new_id.map(|id| server.clients[id].nick.clone());

            if let (c, Some(r)) = server.client_and_room(client_id) {
                match r.master_id {
                    Some(id) if id == c.id => {
                        c.set_is_master(false);
                        r.master_id = None;
                        /*actions.push(
                            ClientFlags("-h".to_string(), vec![c.nick.clone()])
                                .send_all()
                                .in_room(r.id)
                                .action(),
                        );*/
                    }
                    Some(_) => unreachable!(),
                    None => {}
                }
                r.master_id = new_id;
                if !r.is_fixed() && c.protocol_number < 42 {
                    r.name
                        .replace_range(.., new_nick.as_ref().map_or("[]", String::as_str));
                }
                r.set_join_restriction(false);
                r.set_team_add_restriction(false);
                let is_fixed = r.is_fixed();
                r.set_unregistered_players_restriction(is_fixed);
                if let Some(nick) = new_nick {
                    /*actions.push(
                        ClientFlags("+h".to_string(), vec![nick])
                            .send_all()
                            .in_room(r.id)
                            .action(),
                    );*/
                }
            }
            if let Some(id) = new_id {
                server.clients[id].set_is_master(true)
            }
        }
        StartRoomGame(room_id) => {
            let (room_clients, room_nicks): (Vec<_>, Vec<_>) = server
                .clients
                .iter()
                .map(|(id, c)| (id, c.nick.clone()))
                .unzip();
            let room = &mut server.rooms[room_id];

            if !room.has_multiple_clans() {
                /*Warn(
                    "The game can't be started with less than two clans!".to_string(),
                )*/
            } else if room.protocol_number <= 43 && room.players_number != room.ready_players_number
            {
                /*Warn("Not all players are ready".to_string())*/
            } else if room.game_info.is_some() {
                /*Warn("The game is already in progress".to_string())*/
            } else {
                room.start_round();
                for id in room_clients {
                    let c = &mut server.clients[id];
                    c.set_is_in_game(false);
                    c.team_indices = room.client_team_indices(c.id);
                }
                /*RunGame.send_all().in_room(room.id).action(),*/
                //SendRoomUpdate(None),
                /*ClientFlags("+g".to_string(), room_nicks)
                .send_all()
                .in_room(room.id)
                .action(),*/
            }
        }
        SendTeamRemovalMessage(team_name) => {
            let mut actions = Vec::new();
            if let Some(r) = server.room(client_id) {
                if let Some(ref mut info) = r.game_info {
                    let msg = once(b'F').chain(team_name.bytes());
                    /*actions.push(
                        ForwardEngineMessage(vec![to_engine_msg(msg)])
                            .send_all()
                            .in_room(r.id)
                            .but_self()
                            .action(),
                    );*/
                    info.teams_in_game -= 1;
                    if info.teams_in_game == 0 {
                        actions.push(FinishRoomGame(r.id));
                    }
                    let remove_msg = to_engine_msg(once(b'F').chain(team_name.bytes()));
                    if let Some(m) = &info.sync_msg {
                        info.msg_log.push(m.clone());
                    }
                    if info.sync_msg.is_some() {
                        info.sync_msg = None
                    }
                    info.msg_log.push(remove_msg.clone());
                    /*actions.push(
                        ForwardEngineMessage(vec![remove_msg])
                            .send_all()
                            .in_room(r.id)
                            .but_self()
                            .action(),
                    );*/
                }
            }
        }
        FinishRoomGame(room_id) => {
            let mut actions = Vec::new();

            let r = &mut server.rooms[room_id];
            r.ready_players_number = 1;
            //actions.push(SendRoomUpdate(None));
            //actions.push(RoundFinished.send_all().in_room(r.id).action());

            if let Some(info) = replace(&mut r.game_info, None) {
                for (_, c) in server.clients.iter() {
                    if c.room_id == Some(room_id) && c.is_joined_mid_game() {
                        actions.push(SendRoomData {
                            to: c.id,
                            teams: false,
                            config: true,
                            flags: false,
                        });
                        for name in &info.left_teams {
                            //actions.push(TeamRemove(name.clone()).send(c.id).action());
                        }
                    }
                }
            }

            let nicks: Vec<_> = server
                .clients
                .iter_mut()
                .filter(|(_, c)| c.room_id == Some(room_id))
                .map(|(_, c)| {
                    c.set_is_ready(c.is_master());
                    c.set_is_joined_mid_game(false);
                    c
                })
                .filter_map(|c| {
                    if !c.is_master() {
                        Some(c.nick.clone())
                    } else {
                        None
                    }
                })
                .collect();

            if !nicks.is_empty() {
                let msg = if r.protocol_number < 38 {
                    LegacyReady(false, nicks)
                } else {
                    ClientFlags("-r".to_string(), nicks)
                };
                //actions.push(msg.send_all().in_room(room_id).action());
            }
        }
    }
}
