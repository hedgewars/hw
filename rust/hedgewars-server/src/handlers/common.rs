use crate::{
    protocol::messages::{
        server_chat,
        add_flags, remove_flags,
        HWProtocolMessage::{self, Rnd},
        HWServerMessage::{self, *},
        ProtocolFlags as Flags,
    },
    core::{
        client::HWClient,
        server::HWServer,
        types::{ClientId, GameCfg, RoomId, TeamInfo, Vote, VoteType},
        room::HWRoom,
    },
    utils::to_engine_msg,
};

use super::Response;

use crate::core::types::RoomConfig;
use rand::{self, seq::SliceRandom, thread_rng, Rng};
use std::{iter::once, mem::replace};

pub fn rnd_reply(options: &[String]) -> HWServerMessage {
    let mut rng = thread_rng();

    let reply = if options.is_empty() {
        (*&["heads", "tails"].choose(&mut rng).unwrap()).to_string()
    } else {
        options.choose(&mut rng).unwrap().clone()
    };

    ChatMsg {
        nick: "[random]".to_string(),
        msg: reply,
    }
}

pub fn join_lobby(server: &mut HWServer, response: &mut Response) {
    let client_id = response.client_id();

    let client = &server.clients[client_id];
    let nick = vec![client.nick.clone()];
    let mut flags = vec![];
    if client.is_registered() {
        flags.push(Flags::Registered)
    }
    if client.is_admin() {
        flags.push(Flags::Admin)
    }
    if client.is_contributor() {
        flags.push(Flags::Contributor)
    }

    let all_nicks: Vec<_> = server.collect_nicks(|_| true);

    let mut flag_selectors = [
        (
            Flags::Registered,
            server.collect_nicks(|(_, c)| c.is_registered()),
        ),
        (Flags::Admin, server.collect_nicks(|(_, c)| c.is_admin())),
        (
            Flags::Contributor,
            server.collect_nicks(|(_, c)| c.is_contributor()),
        ),
        (
            Flags::InRoom,
            server.collect_nicks(|(_, c)| c.room_id.is_some()),
        ),
    ];

    let server_msg = ServerMessage(server.get_greetings(client_id).to_string());

    let rooms_msg = Rooms(
        server
            .rooms
            .iter()
            .filter(|(_, r)| r.protocol_number == client.protocol_number)
            .flat_map(|(_, r)| r.info(r.master_id.map(|id| &server.clients[id])))
            .collect(),
    );

    response.add(LobbyJoined(nick).send_all().but_self());
    response.add(
        ClientFlags(add_flags(&flags), all_nicks.clone())
            .send_all()
            .but_self(),
    );

    response.add(LobbyJoined(all_nicks).send_self());
    for (flag, nicks) in &mut flag_selectors {
        if !nicks.is_empty() {
            response.add(ClientFlags(add_flags(&[*flag]), replace(nicks, vec![])).send_self());
        }
    }

    response.add(server_msg.send_self());
    response.add(rooms_msg.send_self());
}

pub fn remove_teams(
    room: &mut HWRoom,
    team_names: Vec<String>,
    is_in_game: bool,
    response: &mut Response,
) {
    if let Some(ref mut info) = room.game_info {
        for team_name in &team_names {
            info.left_teams.push(team_name.clone());

            if is_in_game {
                let msg = once(b'F').chain(team_name.bytes());
                response.add(
                    ForwardEngineMessage(vec![to_engine_msg(msg)])
                        .send_all()
                        .in_room(room.id)
                        .but_self(),
                );

                info.teams_in_game -= 1;

                let remove_msg = to_engine_msg(once(b'F').chain(team_name.bytes()));
                if let Some(m) = &info.sync_msg {
                    info.msg_log.push(m.clone());
                    info.sync_msg = None
                }
                info.msg_log.push(remove_msg.clone());

                response.add(
                    ForwardEngineMessage(vec![remove_msg])
                        .send_all()
                        .in_room(room.id)
                        .but_self(),
                );
            }
        }
    }

    for team_name in team_names {
        room.remove_team(&team_name);
        response.add(TeamRemove(team_name).send_all().in_room(room.id));
    }
}

fn remove_client_from_room(
    client: &mut HWClient,
    room: &mut HWRoom,
    response: &mut Response,
    msg: &str,
) {
    room.players_number -= 1;
    if room.players_number > 0 || room.is_fixed() {
        if client.is_ready() && room.ready_players_number > 0 {
            room.ready_players_number -= 1;
        }

        let team_names: Vec<_> = room
            .client_teams(client.id)
            .map(|t| t.name.clone())
            .collect();
        remove_teams(room, team_names, client.is_in_game(), response);

        if room.players_number > 0 {
            response.add(
                RoomLeft(client.nick.clone(), msg.to_string())
                    .send_all()
                    .in_room(room.id)
                    .but_self(),
            );
        }

        if client.is_master() && !room.is_fixed() {
            client.set_is_master(false);
            response.add(
                ClientFlags(
                    remove_flags(&[Flags::RoomMaster]),
                    vec![client.nick.clone()],
                )
                .send_all()
                .in_room(room.id),
            );
            room.master_id = None;
        }
    }

    client.room_id = None;

    let update_msg = if room.players_number == 0 && !room.is_fixed() {
        RoomRemove(room.name.clone())
    } else {
        RoomUpdated(room.name.clone(), room.info(Some(&client)))
    };
    response.add(update_msg.send_all().with_protocol(room.protocol_number));

    response.add(ClientFlags(remove_flags(&[Flags::InRoom]), vec![client.nick.clone()]).send_all());
}

pub fn change_master(
    server: &mut HWServer,
    room_id: RoomId,
    new_master_id: ClientId,
    response: &mut Response,
) {
    let room = &mut server.rooms[room_id];
    if let Some(master_id) = room.master_id {
        server.clients[master_id].set_is_master(false);
        response.add(
            ClientFlags(
                remove_flags(&[Flags::RoomMaster]),
                vec![server.clients[master_id].nick.clone()],
            )
            .send_all()
            .in_room(room_id),
        )
    }

    room.master_id = Some(new_master_id);
    server.clients[new_master_id].set_is_master(true);

    response.add(
        ClientFlags(
            add_flags(&[Flags::RoomMaster]),
            vec![server.clients[new_master_id].nick.clone()],
        )
        .send_all()
        .in_room(room_id),
    );
}

pub fn enter_room(
    server: &mut HWServer,
    client_id: ClientId,
    room_id: RoomId,
    response: &mut Response,
) {
    let nick = server.clients[client_id].nick.clone();
    server.move_to_room(client_id, room_id);

    response.add(RoomJoined(vec![nick.clone()]).send_all().in_room(room_id));
    response.add(ClientFlags(add_flags(&[Flags::InRoom]), vec![nick]).send_all());
    let nicks = server.collect_nicks(|(_, c)| c.room_id == Some(room_id));
    response.add(RoomJoined(nicks).send_self());

    get_room_teams(server, room_id, client_id, response);

    let room = &server.rooms[room_id];
    get_room_config(room, client_id, response);

    let mut flag_selectors = [
        (
            Flags::RoomMaster,
            server.collect_nicks(|(_, c)| c.is_master()),
        ),
        (Flags::Ready, server.collect_nicks(|(_, c)| c.is_ready())),
        (Flags::InGame, server.collect_nicks(|(_, c)| c.is_in_game())),
    ];

    for (flag, nicks) in &mut flag_selectors {
        response.add(ClientFlags(add_flags(&[*flag]), replace(nicks, vec![])).send_self());
    }

    if !room.greeting.is_empty() {
        response.add(
            ChatMsg {
                nick: "[greeting]".to_string(),
                msg: room.greeting.clone(),
            }
            .send_self(),
        );
    }
}

pub fn exit_room(server: &mut HWServer, client_id: ClientId, response: &mut Response, msg: &str) {
    let client = &mut server.clients[client_id];

    if let Some(room_id) = client.room_id {
        let room = &mut server.rooms[room_id];

        remove_client_from_room(client, room, response, msg);

        if !room.is_fixed() {
            if room.players_number == 0 {
                server.rooms.remove(room_id);
            } else if room.master_id == None {
                let new_master_id = server.room_clients(room_id).next();
                if let Some(new_master_id) = new_master_id {
                    let new_master_nick = server.clients[new_master_id].nick.clone();
                    let room = &mut server.rooms[room_id];
                    room.master_id = Some(new_master_id);
                    server.clients[new_master_id].set_is_master(true);

                    if room.protocol_number < 42 {
                        room.name = new_master_nick.clone();
                    }

                    room.set_join_restriction(false);
                    room.set_team_add_restriction(false);
                    room.set_unregistered_players_restriction(true);

                    response.add(
                        ClientFlags(add_flags(&[Flags::RoomMaster]), vec![new_master_nick])
                            .send_all()
                            .in_room(room.id),
                    );
                }
            }
        }
    }
}

pub fn remove_client(server: &mut HWServer, response: &mut Response, msg: String) {
    let client_id = response.client_id();
    let client = &mut server.clients[client_id];
    let nick = client.nick.clone();

    exit_room(server, client_id, response, &msg);

    server.remove_client(client_id);

    response.add(LobbyLeft(nick, msg.to_string()).send_all());
    response.add(Bye("User quit: ".to_string() + &msg).send_self());
    response.remove_client(client_id);
}

pub fn get_room_update(
    room_name: Option<String>,
    room: &HWRoom,
    master: Option<&HWClient>,
    response: &mut Response,
) {
    let update_msg = RoomUpdated(room_name.unwrap_or(room.name.clone()), room.info(master));
    response.add(update_msg.send_all().with_protocol(room.protocol_number));
}

pub fn get_room_config_impl(config: &RoomConfig, to_client: ClientId, response: &mut Response) {
    response.add(ConfigEntry("FULLMAPCONFIG".to_string(), config.to_map_config()).send(to_client));
    for cfg in config.to_game_config() {
        response.add(cfg.to_server_msg().send(to_client));
    }
}

pub fn get_room_config(room: &HWRoom, to_client: ClientId, response: &mut Response) {
    get_room_config_impl(room.active_config(), to_client, response);
}

pub fn get_teams<'a, I>(teams: I, to_client: ClientId, response: &mut Response)
where
    I: Iterator<Item = &'a TeamInfo>,
{
    for team in teams {
        response.add(TeamAdd(team.to_protocol()).send(to_client));
        response.add(TeamColor(team.name.clone(), team.color).send(to_client));
        response.add(HedgehogsNumber(team.name.clone(), team.hedgehogs_number).send(to_client));
    }
}

pub fn get_room_teams(
    server: &HWServer,
    room_id: RoomId,
    to_client: ClientId,
    response: &mut Response,
) {
    let room = &server.rooms[room_id];
    let current_teams = match room.game_info {
        Some(ref info) => &info.teams_at_start,
        None => &room.teams,
    };

    get_teams(current_teams.iter().map(|(_, t)| t), to_client, response);
}

pub fn get_room_flags(
    server: &HWServer,
    room_id: RoomId,
    to_client: ClientId,
    response: &mut Response,
) {
    let room = &server.rooms[room_id];
    if let Some(id) = room.master_id {
        response.add(
            ClientFlags(
                add_flags(&[Flags::RoomMaster]),
                vec![server.clients[id].nick.clone()],
            )
            .send(to_client),
        );
    }
    let nicks: Vec<_> = server
        .clients
        .iter()
        .filter(|(_, c)| c.room_id == Some(room_id) && c.is_ready())
        .map(|(_, c)| c.nick.clone())
        .collect();
    if !nicks.is_empty() {
        response.add(ClientFlags(add_flags(&[Flags::Ready]), nicks).send(to_client));
    }
}

pub fn apply_voting_result(
    server: &mut HWServer,
    room_id: RoomId,
    response: &mut Response,
    kind: VoteType,
) {
    match kind {
        VoteType::Kick(nick) => {
            if let Some(client) = server.find_client(&nick) {
                if client.room_id == Some(room_id) {
                    let id = client.id;
                    response.add(Kicked.send(id));
                    exit_room(server, id, response, "kicked");
                }
            }
        }
        VoteType::Map(None) => (),
        VoteType::Map(Some(name)) => {
            if let Some(location) = server.rooms[room_id].load_config(&name) {
                response.add(
                    server_chat(location.to_string())
                        .send_all()
                        .in_room(room_id),
                );
                let room = &server.rooms[room_id];
                let room_master = if let Some(id) = room.master_id {
                    Some(&server.clients[id])
                } else {
                    None
                };
                get_room_update(None, room, room_master, response);

                for (_, client) in server.clients.iter() {
                    if client.room_id == Some(room_id) {
                        super::common::get_room_config(&server.rooms[room_id], client.id, response);
                    }
                }
            }
        }
        VoteType::Pause => {
            if let Some(ref mut info) = server.rooms[room_id].game_info {
                info.is_paused = !info.is_paused;
                response.add(
                    server_chat("Pause toggled.".to_string())
                        .send_all()
                        .in_room(room_id),
                );
                response.add(
                    ForwardEngineMessage(vec![to_engine_msg(once(b'I'))])
                        .send_all()
                        .in_room(room_id),
                );
            }
        }
        VoteType::NewSeed => {
            let seed = thread_rng().gen_range(0, 1_000_000_000).to_string();
            let cfg = GameCfg::Seed(seed);
            response.add(cfg.to_server_msg().send_all().in_room(room_id));
            server.rooms[room_id].set_config(cfg);
        }
        VoteType::HedgehogsPerTeam(number) => {
            let r = &mut server.rooms[room_id];
            let nicks = r.set_hedgehogs_number(number);

            response.extend(
                nicks
                    .into_iter()
                    .map(|n| HedgehogsNumber(n, number).send_all().in_room(room_id)),
            );
        }
    }
}

fn add_vote(room: &mut HWRoom, response: &mut Response, vote: Vote) -> Option<bool> {
    let client_id = response.client_id;
    let mut result = None;

    if let Some(ref mut voting) = room.voting {
        if vote.is_forced || voting.votes.iter().all(|(id, _)| client_id != *id) {
            response.add(server_chat("Your vote has been counted.".to_string()).send_self());
            voting.votes.push((client_id, vote.is_pro));
            let i = voting.votes.iter();
            let pro = i.clone().filter(|(_, v)| *v).count();
            let contra = i.filter(|(_, v)| !*v).count();
            let success_quota = voting.voters.len() / 2 + 1;
            if vote.is_forced && vote.is_pro || pro >= success_quota {
                result = Some(true);
            } else if vote.is_forced && !vote.is_pro || contra > voting.voters.len() - success_quota
            {
                result = Some(false);
            }
        } else {
            response.add(server_chat("You already have voted.".to_string()).send_self());
        }
    } else {
        response.add(server_chat("There's no voting going on.".to_string()).send_self());
    }

    result
}

pub fn submit_vote(server: &mut HWServer, vote: Vote, response: &mut Response) {
    let client_id = response.client_id;
    let client = &server.clients[client_id];

    if let Some(room_id) = client.room_id {
        let room = &mut server.rooms[room_id];

        if let Some(res) = add_vote(room, response, vote) {
            response.add(
                server_chat("Voting closed.".to_string())
                    .send_all()
                    .in_room(room.id),
            );
            let voting = replace(&mut room.voting, None).unwrap();
            if res {
                apply_voting_result(server, room_id, response, voting.kind);
            }
        }
    }
}

pub fn start_game(server: &mut HWServer, room_id: RoomId, response: &mut Response) {
    let (room_clients, room_nicks): (Vec<_>, Vec<_>) = server
        .clients
        .iter()
        .map(|(id, c)| (id, c.nick.clone()))
        .unzip();
    let room = &mut server.rooms[room_id];

    if !room.has_multiple_clans() {
        response.add(
            Warning("The game can't be started with less than two clans!".to_string()).send_self(),
        );
    } else if room.protocol_number <= 43 && room.players_number != room.ready_players_number {
        response.add(Warning("Not all players are ready".to_string()).send_self());
    } else if room.game_info.is_some() {
        response.add(Warning("The game is already in progress".to_string()).send_self());
    } else {
        room.start_round();
        for id in room_clients {
            let c = &mut server.clients[id];
            c.set_is_in_game(true);
            c.team_indices = room.client_team_indices(c.id);
        }
        response.add(RunGame.send_all().in_room(room.id));
        response.add(
            ClientFlags(add_flags(&[Flags::InGame]), room_nicks)
                .send_all()
                .in_room(room.id),
        );

        let room_master = if let Some(id) = room.master_id {
            Some(&server.clients[id])
        } else {
            None
        };
        get_room_update(None, room, room_master, response);
    }
}

pub fn end_game(server: &mut HWServer, room_id: RoomId, response: &mut Response) {
    let room = &mut server.rooms[room_id];
    room.ready_players_number = 1;
    let room_master = if let Some(id) = room.master_id {
        Some(&server.clients[id])
    } else {
        None
    };
    get_room_update(None, room, room_master, response);
    response.add(RoundFinished.send_all().in_room(room_id));

    if let Some(info) = replace(&mut room.game_info, None) {
        for (_, client) in server.clients.iter() {
            if client.room_id == Some(room_id) && client.is_joined_mid_game() {
                super::common::get_room_config(room, client.id, response);
                response.extend(
                    info.left_teams
                        .iter()
                        .map(|name| TeamRemove(name.clone()).send(client.id)),
                );
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
        let msg = if room.protocol_number < 38 {
            LegacyReady(false, nicks)
        } else {
            ClientFlags(remove_flags(&[Flags::Ready]), nicks)
        };
        response.add(msg.send_all().in_room(room_id));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::protocol::messages::HWServerMessage::ChatMsg;
    use crate::server::actions::PendingMessage;

    fn reply2string(r: HWServerMessage) -> String {
        match r {
            ChatMsg { msg: p, .. } => String::from(p),
            _ => panic!("expected a ChatMsg"),
        }
    }

    fn run_handle_test(opts: Vec<String>) {
        let opts2 = opts.clone();
        for opt in opts {
            while reply2string(rnd_reply(&opts2)) != opt {}
        }
    }

    /// This test terminates almost surely.
    #[test]
    fn test_handle_rnd_empty() {
        run_handle_test(vec![])
    }

    /// This test terminates almost surely.
    #[test]
    fn test_handle_rnd_nonempty() {
        run_handle_test(vec!["A".to_owned(), "B".to_owned(), "C".to_owned()])
    }

    /// This test terminates almost surely (strong law of large numbers)
    #[test]
    fn test_distribution() {
        let eps = 0.000001;
        let lim = 0.5;
        let opts = vec![0.to_string(), 1.to_string()];
        let mut ones = 0;
        let mut tries = 0;

        while tries < 1000 || ((ones as f64 / tries as f64) - lim).abs() >= eps {
            tries += 1;
            if reply2string(rnd_reply(&opts)) == 1.to_string() {
                ones += 1;
            }
        }
    }
}
