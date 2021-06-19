use crate::{
    core::{
        client::HwClient,
        room::HwRoom,
        server::{
            EndGameResult, HwRoomControl, HwServer, JoinRoomError, LeaveRoomResult, StartGameError,
            VoteError, VoteResult,
        },
        types::{ClientId, GameCfg, RoomId, TeamInfo, Vote, VoteType, MAX_HEDGEHOGS_PER_TEAM},
    },
    protocol::messages::{
        add_flags, remove_flags, server_chat,
        HwProtocolMessage::{self, Rnd},
        HwServerMessage::{self, *},
        ProtocolFlags as Flags,
    },
    utils::to_engine_msg,
};

use super::{
    actions::{Destination, DestinationGroup},
    Response,
};

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
            .iter_rooms()
            .filter(|r| r.protocol_number == client.protocol_number)
            .flat_map(|r| r.info(r.master_id.map(|id| server.client(id))))
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
    fn partition_nicks<'a, I, F>(clients: I, f: F) -> (Vec<String>, Vec<String>)
    where
        I: Iterator<Item = &'a HwClient> + Clone,
        F: Fn(&&'a HwClient) -> bool,
    {
        (
            clients
                .clone()
                .filter(|c| f(c))
                .map(|c| &c.nick)
                .cloned()
                .collect(),
            clients
                .filter(|c| !f(c))
                .map(|c| &c.nick)
                .cloned()
                .collect(),
        )
    }

    let nick = client.nick.clone();
    response.add(
        RoomJoined(vec![nick.clone()])
            .send_all()
            .in_room(room.id)
            .but_self(),
    );
    response.add(ClientFlags(add_flags(&[Flags::InRoom]), vec![nick.clone()]).send_all());
    let nicks = room_clients.clone().map(|c| c.nick.clone()).collect();
    response.add(RoomJoined(nicks).send_self());

    let mut flag_selectors = [
        (
            Flags::RoomMaster,
            partition_nicks(room_clients.clone(), |c| c.is_master()),
        ),
        (
            Flags::Ready,
            partition_nicks(room_clients.clone(), |c| c.is_ready()),
        ),
        (
            Flags::InGame,
            partition_nicks(room_clients.clone(), |c| c.is_in_game()),
        ),
    ];

    for (flag, (set_nicks, cleared_nicks)) in &mut flag_selectors {
        if !set_nicks.is_empty() {
            response.add(ClientFlags(add_flags(&[*flag]), replace(set_nicks, vec![])).send_self());
        }

        if !cleared_nicks.is_empty() {
            response.add(
                ClientFlags(remove_flags(&[*flag]), replace(cleared_nicks, vec![])).send_self(),
            );
        }
    }

    get_active_room_teams(room, Destination::ToSelf, response);
    get_active_room_config(room, Destination::ToSelf, response);

    if !room.greeting.is_empty() {
        response.add(
            ChatMsg {
                nick: "[greeting]".to_string(),
                msg: room.greeting.clone(),
            }
            .send_self(),
        );
    }

    if let Some(info) = &room.game_info {
        response.add(
            ClientFlags(add_flags(&[Flags::Ready, Flags::InGame]), vec![nick])
                .send_all()
                .in_room(room.id),
        );
        response.add(RunGame.send_self());

        response.add(
            ForwardEngineMessage(
                once(to_engine_msg("e$spectate 1".bytes()))
                    .chain(info.msg_log.iter().cloned())
                    .collect(),
            )
            .send_self(),
        );

        for team in info.client_teams(client.id) {
            response.add(
                ForwardEngineMessage(vec![to_engine_msg(once(b'G').chain(team.name.bytes()))])
                    .send_all()
                    .in_room(room.id),
            );
        }

        if info.is_paused {
            response.add(ForwardEngineMessage(vec![to_engine_msg(once(b'I'))]).send_self());
        }

        for (_, original_team) in &info.original_teams {
            if let Some(team) = room.find_team(|team| team.name == original_team.name) {
                if team != original_team {
                    response.add(TeamRemove(original_team.name.clone()).send_self());
                    response.add(TeamAdd(team.to_protocol()).send_self());
                }
            } else {
                response.add(TeamRemove(original_team.name.clone()).send_self());
            }
        }

        for (_, team) in &room.teams {
            if !info.original_teams.iter().any(|(_, t)| t.name == team.name) {
                response.add(TeamAdd(team.to_protocol()).send_self());
            }
        }

        get_room_config_impl(room.config(), Destination::ToSelf, response);
    }
}

pub fn get_room_join_error(error: JoinRoomError, response: &mut Response) {
    use super::strings::*;
    match error {
        JoinRoomError::DoesntExist => response.warn(NO_ROOM),
        JoinRoomError::WrongProtocol => response.warn(INCOMPATIBLE_ROOM_PROTOCOL),
        JoinRoomError::WrongPassword => {
            response.add(Notice("WrongPassword".to_string()).send_self())
        }
        JoinRoomError::Full => response.warn(ROOM_FULL),
        JoinRoomError::Restricted => response.warn(ROOM_JOIN_RESTRICTED),
        JoinRoomError::RegistrationRequired => response.warn(ROOM_REGISTRATION_REQUIRED),
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
            let remove_msg = to_engine_msg(once(b'F').chain(team_name.bytes()));

            response.add(
                ForwardEngineMessage(vec![remove_msg])
                    .send_all()
                    .in_room(room_id)
                    .but_self(),
            );
        }
    } else {
        for team_name in removed_teams {
            response.add(TeamRemove(team_name).send_all().in_room(room_id));
        }
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

pub fn remove_client(server: &mut HwServer, response: &mut Response, msg: String) {
    let client_id = response.client_id();
    let client = server.client(client_id);
    let nick = client.nick.clone();

    if let Some(mut room_control) = server.get_room_control(client_id) {
        let room_id = room_control.room().id;
        let result = room_control.leave_room();
        get_room_leave_result(server, server.room(room_id), &msg, result, response);
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

pub fn get_room_config_impl(
    config: &RoomConfig,
    destination: Destination,
    response: &mut Response,
) {
    response.add(
        ConfigEntry("FULLMAPCONFIG".to_string(), config.to_map_config())
            .send_to_destination(destination.clone()),
    );
    for cfg in config.to_game_config() {
        response.add(cfg.to_server_msg().send_to_destination(destination.clone()));
    }
}

pub fn get_active_room_config(room: &HwRoom, destination: Destination, response: &mut Response) {
    get_room_config_impl(room.active_config(), destination, response);
}

pub fn get_teams<'a, I>(teams: I, destination: Destination, response: &mut Response)
where
    I: Iterator<Item = &'a TeamInfo>,
{
    for team in teams {
        response.add(TeamAdd(team.to_protocol()).send_to_destination(destination.clone()));
        response
            .add(TeamColor(team.name.clone(), team.color).send_to_destination(destination.clone()));
        response.add(
            HedgehogsNumber(team.name.clone(), team.hedgehogs_number)
                .send_to_destination(destination.clone()),
        );
    }
}

pub fn get_active_room_teams(room: &HwRoom, destination: Destination, response: &mut Response) {
    let current_teams = match room.game_info {
        Some(ref info) => &info.original_teams,
        None => &room.teams,
    };

    get_teams(current_teams.iter().map(|(_, t)| t), destination, response);
}

pub fn get_room_flags(
    server: &HwServer,
    room_id: RoomId,
    destination: Destination,
    response: &mut Response,
) {
    let room = server.room(room_id);
    if let Some(id) = room.master_id {
        response.add(
            ClientFlags(
                add_flags(&[Flags::RoomMaster]),
                vec![server.client(id).nick.clone()],
            )
            .send_to_destination(destination.clone()),
        );
    }
    let nicks = server.collect_nicks(|(_, c)| c.room_id == Some(room_id) && c.is_ready());

    if !nicks.is_empty() {
        response
            .add(ClientFlags(add_flags(&[Flags::Ready]), nicks).send_to_destination(destination));
    }
}

pub fn check_vote(
    server: &HwServer,
    room: &HwRoom,
    kind: &VoteType,
    response: &mut Response,
) -> bool {
    let error = match &kind {
        VoteType::Kick(nick) => {
            if server
                .find_client(&nick)
                .filter(|c| c.room_id == Some(room.id))
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
            if room.game_info.is_some() {
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
        None => true,
        Some(msg) => {
            response.add(server_chat(msg).send_self());
            false
        }
    }
}

pub fn get_vote_data(
    room_id: RoomId,
    result: &Result<VoteResult, VoteError>,
    response: &mut Response,
) {
    match result {
        Ok(VoteResult::Submitted) => {
            response.add(server_chat("Your vote has been counted.".to_string()).send_self())
        }
        Ok(VoteResult::Succeeded(_) | VoteResult::Failed) => response.add(
            server_chat("Voting closed.".to_string())
                .send_all()
                .in_room(room_id),
        ),
        Err(VoteError::NoVoting) => {
            response.add(server_chat("There's no voting going on.".to_string()).send_self())
        }
        Err(VoteError::AlreadyVoted) => {
            response.add(server_chat("You already have voted.".to_string()).send_self())
        }
    }
}

pub fn handle_vote(
    mut room_control: HwRoomControl,
    result: Result<VoteResult, VoteError>,
    response: &mut super::Response,
) {
    let room_id = room_control.room().id;
    super::common::get_vote_data(room_control.room().id, &result, response);

    if let Ok(VoteResult::Succeeded(kind)) = result {
        match kind {
            VoteType::Kick(nick) => {
                if let Some(kicked_client) = room_control.server().find_client(&nick) {
                    let kicked_id = kicked_client.id;
                    if let Some(mut room_control) = room_control.change_client(kicked_id) {
                        response.add(Kicked.send(kicked_id));
                        let result = room_control.leave_room();
                        super::common::get_room_leave_result(
                            room_control.server(),
                            room_control.room(),
                            "kicked",
                            result,
                            response,
                        );
                    }
                }
            }
            VoteType::Map(None) => (),
            VoteType::Map(Some(name)) => {
                if let Some(location) = room_control.load_config(&name) {
                    let msg = server_chat(location.to_string());
                    let room = room_control.room();
                    response.add(msg.send_all().in_room(room.id));

                    let room_master = room.master_id.map(|id| room_control.server().client(id));

                    super::common::get_room_update(None, room, room_master, response);

                    let room_destination = Destination::ToAll {
                        group: DestinationGroup::Room(room.id),
                        skip_self: false,
                    };
                    super::common::get_active_room_config(room, room_destination, response);
                }
            }
            VoteType::Pause => {
                if room_control.toggle_pause() {
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
                room_control.set_config(cfg);
            }
            VoteType::HedgehogsPerTeam(number) => {
                let nicks = room_control.set_hedgehogs_number(number);
                response.extend(
                    nicks
                        .into_iter()
                        .map(|n| HedgehogsNumber(n, number).send_all().in_room(room_id)),
                );
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
    let room_master = room.master_id.map(|id| server.client(id));

    get_room_update(None, room, room_master, response);
    response.add(RoundFinished.send_all().in_room(room_id));

    response.extend(
        result
            .left_teams
            .iter()
            .filter(|name| room.find_team(|t| t.name == **name).is_some())
            .map(|name| TeamRemove(name.clone()).send_all().in_room(room.id)),
    );

    if !result.unreadied_nicks.is_empty() {
        response.add(
            ClientFlags(remove_flags(&[Flags::Ready]), result.unreadied_nicks)
                .send_all()
                .in_room(room_id),
        );
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
}
