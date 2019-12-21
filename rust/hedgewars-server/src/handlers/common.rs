use crate::{
    core::{
        client::HwClient,
        room::HwRoom,
        server::{
            EndGameResult, HwServer, JoinRoomError, LeaveRoomError, LeaveRoomResult, StartGameError,
        },
        types::{ClientId, GameCfg, RoomId, TeamInfo, Vote, VoteType},
    },
    protocol::messages::{
        add_flags, remove_flags, server_chat,
        HwProtocolMessage::{self, Rnd},
        HwServerMessage::{self, *},
        ProtocolFlags as Flags,
    },
    utils::to_engine_msg,
};

use super::Response;

use crate::core::types::RoomConfig;
use rand::{self, seq::SliceRandom, thread_rng, Rng};
use std::{iter::once, mem::replace};

pub fn rnd_reply(options: &[String]) -> HwServerMessage {
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

pub fn get_lobby_join_data(server: &HwServer, response: &mut Response) {
    let client_id = response.client_id();

    let client = server.client(client_id);
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

    let server_msg = ServerMessage(server.get_greetings(client).to_string());

    let rooms_msg = Rooms(
        server
            .rooms
            .iter()
            .filter(|(_, r)| r.protocol_number == client.protocol_number)
            .flat_map(|(_, r)| r.info(r.master_id.map(|id| server.client(id))))
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

pub fn get_room_join_data<'a, I: Iterator<Item = &'a HwClient> + Clone>(
    client: &HwClient,
    room: &HwRoom,
    room_clients: I,
    response: &mut Response,
) {
    #[inline]
    fn collect_nicks<'a, I, F>(clients: I, f: F) -> Vec<String>
    where
        I: Iterator<Item = &'a HwClient>,
        F: Fn(&&'a HwClient) -> bool,
    {
        clients.filter(f).map(|c| &c.nick).cloned().collect()
    }

    let nick = client.nick.clone();
    response.add(RoomJoined(vec![nick.clone()]).send_all().in_room(room.id));
    response.add(ClientFlags(add_flags(&[Flags::InRoom]), vec![nick]).send_all());
    let nicks = collect_nicks(room_clients.clone(), |c| c.room_id == Some(room.id));
    response.add(RoomJoined(nicks).send_self());

    get_room_teams(room, client.id, response);
    get_room_config(room, client.id, response);

    let mut flag_selectors = [
        (
            Flags::RoomMaster,
            collect_nicks(room_clients.clone(), |c| c.is_master()),
        ),
        (
            Flags::Ready,
            collect_nicks(room_clients.clone(), |c| c.is_ready()),
        ),
        (
            Flags::InGame,
            collect_nicks(room_clients.clone(), |c| c.is_in_game()),
        ),
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

pub fn get_room_join_error(error: JoinRoomError, response: &mut Response) {
    use super::strings::*;
    match error {
        JoinRoomError::DoesntExist => response.warn(NO_ROOM),
        JoinRoomError::WrongProtocol => response.warn(WRONG_PROTOCOL),
        JoinRoomError::Full => response.warn(ROOM_FULL),
        JoinRoomError::Restricted => response.warn(ROOM_JOIN_RESTRICTED),
    }
}

pub fn get_remove_teams_data(
    room_id: RoomId,
    was_in_game: bool,
    removed_teams: Vec<String>,
    response: &mut Response,
) {
    if was_in_game {
        for team_name in &removed_teams {
            let msg = once(b'F').chain(team_name.bytes());
            response.add(
                ForwardEngineMessage(vec![to_engine_msg(msg)])
                    .send_all()
                    .in_room(room_id)
                    .but_self(),
            );

            let remove_msg = to_engine_msg(once(b'F').chain(team_name.bytes()));

            response.add(
                ForwardEngineMessage(vec![remove_msg])
                    .send_all()
                    .in_room(room_id)
                    .but_self(),
            );
        }
    }

    for team_name in removed_teams {
        response.add(TeamRemove(team_name).send_all().in_room(room_id));
    }
}

pub fn get_room_leave_result(
    server: &HwServer,
    room: &HwRoom,
    leave_message: &str,
    result: LeaveRoomResult,
    response: &mut Response,
) {
    let client = server.client(response.client_id);
    response.add(ClientFlags(remove_flags(&[Flags::InRoom]), vec![client.nick.clone()]).send_all());

    match result {
        LeaveRoomResult::RoomRemoved => {
            response.add(
                RoomRemove(room.name.clone())
                    .send_all()
                    .with_protocol(room.protocol_number),
            );
        }

        LeaveRoomResult::RoomRemains {
            is_empty,
            was_master,
            new_master,
            was_in_game,
            removed_teams,
        } => {
            if !is_empty {
                response.add(
                    RoomLeft(client.nick.clone(), leave_message.to_string())
                        .send_all()
                        .in_room(room.id)
                        .but_self(),
                );
            }

            if was_master {
                response.add(
                    ClientFlags(
                        remove_flags(&[Flags::RoomMaster]),
                        vec![client.nick.clone()],
                    )
                    .send_all()
                    .in_room(room.id),
                );

                if let Some(new_master_id) = new_master {
                    let new_master_nick = server.client(new_master_id).nick.clone();
                    response.add(
                        ClientFlags(add_flags(&[Flags::RoomMaster]), vec![new_master_nick])
                            .send_all()
                            .in_room(room.id),
                    );
                }
            }

            get_remove_teams_data(room.id, was_in_game, removed_teams, response);

            response.add(
                RoomUpdated(room.name.clone(), room.info(Some(&client)))
                    .send_all()
                    .with_protocol(room.protocol_number),
            );
        }
    }
}

pub fn get_room_leave_data(
    server: &HwServer,
    room_id: RoomId,
    leave_message: &str,
    result: Result<LeaveRoomResult, LeaveRoomError>,
    response: &mut Response,
) {
    match result {
        Ok(result) => {
            let room = server.room(room_id);
            get_room_leave_result(server, room, leave_message, result, response)
        }
        Err(_) => (),
    }
}

pub fn remove_client(server: &mut HwServer, response: &mut Response, msg: String) {
    let client_id = response.client_id();
    let client = server.client(client_id);
    let nick = client.nick.clone();

    if let Some(room_id) = client.room_id {
        let result = server.leave_room(client_id);
        get_room_leave_data(server, room_id, &msg, result, response);
    }

    server.remove_client(client_id);

    response.add(LobbyLeft(nick, msg.clone()).send_all());
    response.add(Bye(msg).send_self());
    response.remove_client(client_id);
}

pub fn get_room_update(
    room_name: Option<String>,
    room: &HwRoom,
    master: Option<&HwClient>,
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

pub fn get_room_config(room: &HwRoom, to_client: ClientId, response: &mut Response) {
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

pub fn get_room_teams(room: &HwRoom, to_client: ClientId, response: &mut Response) {
    let current_teams = match room.game_info {
        Some(ref info) => &info.teams_at_start,
        None => &room.teams,
    };

    get_teams(current_teams.iter().map(|(_, t)| t), to_client, response);
}

pub fn get_room_flags(
    server: &HwServer,
    room_id: RoomId,
    to_client: ClientId,
    response: &mut Response,
) {
    let room = &server.rooms[room_id];
    if let Some(id) = room.master_id {
        response.add(
            ClientFlags(
                add_flags(&[Flags::RoomMaster]),
                vec![server.client(id).nick.clone()],
            )
            .send(to_client),
        );
    }
    let nicks = server.collect_nicks(|(_, c)| c.room_id == Some(room_id) && c.is_ready());

    if !nicks.is_empty() {
        response.add(ClientFlags(add_flags(&[Flags::Ready]), nicks).send(to_client));
    }
}

pub fn apply_voting_result(
    server: &mut HwServer,
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
                    let result = server.leave_room(id);
                    get_room_leave_data(server, room_id, "kicked", result, response);
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
                    Some(server.client(id))
                } else {
                    None
                };
                get_room_update(None, room, room_master, response);

                for client in server.iter_clients() {
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

fn add_vote(room: &mut HwRoom, response: &mut Response, vote: Vote) -> Option<bool> {
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

pub fn submit_vote(server: &mut HwServer, vote: Vote, response: &mut Response) {
    let client_id = response.client_id;
    let client = server.client(client_id);

    if let Some(room_id) = client.room_id {
        let room = server.room_mut(room_id);

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

pub fn get_start_game_data(
    server: &HwServer,
    room_id: RoomId,
    result: Result<Vec<String>, StartGameError>,
    response: &mut Response,
) {
    match result {
        Ok(room_nicks) => {
            let room = server.room(room_id);
            response.add(RunGame.send_all().in_room(room.id));
            response.add(
                ClientFlags(add_flags(&[Flags::InGame]), room_nicks)
                    .send_all()
                    .in_room(room.id),
            );

            let room_master = room.master_id.map(|id| server.client(id));
            get_room_update(None, room, room_master, response);
        }
        Err(StartGameError::NotEnoughClans) => {
            response.warn("The game can't be started with less than two clans!")
        }
        Err(StartGameError::NotEnoughTeams) => (),
        Err(StartGameError::NotReady) => response.warn("Not all players are ready"),
        Err(StartGameError::AlreadyInGame) => response.warn("The game is already in progress"),
    }
}

pub fn get_end_game_result(
    server: &HwServer,
    room_id: RoomId,
    result: EndGameResult,
    response: &mut Response,
) {
    let room = server.room(room_id);
    let room_master = if let Some(id) = room.master_id {
        Some(server.client(id))
    } else {
        None
    };

    get_room_update(None, room, room_master, response);
    response.add(RoundFinished.send_all().in_room(room_id));

    for client_id in result.joined_mid_game_clients {
        super::common::get_room_config(room, client_id, response);
        response.extend(
            result
                .left_teams
                .iter()
                .map(|name| TeamRemove(name.clone()).send(client_id)),
        );
    }

    if !result.unreadied_nicks.is_empty() {
        let msg = if room.protocol_number < 38 {
            LegacyReady(false, result.unreadied_nicks)
        } else {
            ClientFlags(remove_flags(&[Flags::Ready]), result.unreadied_nicks)
        };
        response.add(msg.send_all().in_room(room_id));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::handlers::actions::PendingMessage;
    use crate::protocol::messages::HwServerMessage::ChatMsg;

    fn reply2string(r: HwServerMessage) -> String {
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
