use super::{
    actions::{Destination, DestinationGroup},
    Response,
};
use log::*;
use crate::core::{
    anteroom::HwAnteroom,
    flood::{FloodAction, FloodEvent},
    server::HwRoomOrServer,
};
use crate::handlers::actions::ToPendingMessage;
use crate::{
    core::{
        client::HwClient,
        room::HwRoom,
        server::{
            EndGameResult, HwRoomControl, HwServer, JoinRoomError, LeaveRoomResult, StartGameError,
            VoteEffect, VoteError, VoteResult,
        },
        types::{ClientId, RoomId},
    },
    utils::to_engine_msg,
};
use hedgewars_network_protocol::{
    messages::{
        add_flags, remove_flags, server_chat,
        HwProtocolMessage,
        HwServerMessage::{self, *},
        ProtocolFlags as Flags,
    },
    types::{RoomConfig, TeamInfo, VoteType, MAX_HEDGEHOGS_PER_TEAM},
};
use rand::{seq::SliceRandom, thread_rng};
use std::iter::once;

pub fn rnd_reply(options: &[String]) -> HwServerMessage {
    let mut rng = thread_rng();

    let (nick, reply) = if options.is_empty() {
        (
            "[random]".to_string(),
            (["heads", "tails"].choose(&mut rng).unwrap()).to_string(),
        )
    } else {
        (
            "(random)".to_string(),
            options.choose(&mut rng).unwrap().clone(),
        )
    };

    ChatMsg { nick, msg: reply }
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

    let all_nicks: Vec<_> = once(client.nick.clone())
        .chain(
            server
                .iter_clients()
                .filter(|c| c.id != client_id)
                .map(|c| c.nick.clone()),
        )
        .collect();

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
            .filter(|r| r.protocol_number != 0)
            .flat_map(|r| {
                r.info(
                    r.master_id.map(|id| server.client(id)),
                    client.protocol_number,
                )
            })
            .collect(),
    );

    response.add(LobbyJoined(nick.clone()).send_all().but_self());
    response.add(LobbyJoined(all_nicks).send_self());
    for (flag, nicks) in &mut flag_selectors {
        if !nicks.is_empty() {
            response.add(ClientFlags(add_flags(&[*flag]), std::mem::take(nicks)).send_self());
        }
    }
    if !flags.is_empty() {
        response.add(ClientFlags(add_flags(&flags), nick).send_all());
    }

    response.add(server_msg.send_self());
    response.add(rooms_msg.send_self());
}

pub fn get_room_join_data<'a, I: Iterator<Item = &'a HwClient> + Clone>(
    protocols: &mut impl Iterator<Item = u16>,
    client: &HwClient,
    master: Option<&HwClient>,
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
    response.add(RoomJoined(vec![nick.clone()]).send_all().in_room(room.id));
    response.add(ClientFlags(add_flags(&[Flags::InRoom]), vec![nick.clone()]).send_all());
    response.add(
        ClientFlags(remove_flags(&[Flags::Ready]), vec![nick.clone()])
            .send_all()
            .in_room(room.id),
    );

    let other_clients = room_clients.clone().filter(|c| c.id != client.id);
    let other_nicks: Vec<String> = other_clients.clone().map(|c| c.nick.clone()).collect();
    if !other_nicks.is_empty() {
        response.add(RoomJoined(other_nicks).send_self());
    }

    if let Some(master_client) = master {
        response.add(
            ClientFlags(
                add_flags(&[Flags::RoomMaster]),
                vec![master_client.nick.clone()],
            )
            .send_self(),
        );
    }

    let mut flag_selectors = [
        (
            Flags::Ready,
            partition_nicks(other_clients.clone(), |c| c.is_ready()),
        ),
        (
            Flags::InGame,
            partition_nicks(other_clients, |c| c.is_in_game()),
        ),
    ];

    for (flag, (set_nicks, cleared_nicks)) in &mut flag_selectors {
        if !set_nicks.is_empty() {
            response.add(ClientFlags(add_flags(&[*flag]), std::mem::take(set_nicks)).send_self());
        }

        if !cleared_nicks.is_empty() {
            response.add(
                ClientFlags(remove_flags(&[*flag]), std::mem::take(cleared_nicks)).send_self(),
            );
        }
    }

    get_active_room_config(room, Destination::ToSelf, response);
    get_active_room_teams(room, Destination::ToSelf, response);

    if !room.greeting.is_empty() {
        response.add(
            ChatMsg {
                nick: "(greeting)".to_string(),
                msg: room.greeting.clone(),
            }
            .send_self(),
        );
    }

    if let Some(info) = &room.game_info {
        response.add(RunGame.send_self());
        response.add(
            ClientFlags(add_flags(&[Flags::InGame]), vec![nick])
                .send_all()
                .in_room(room.id),
        );

        response.add(
            ForwardEngineMessage(
                once(to_engine_msg("e$spectate 1".bytes()))
                    .chain(info.msg_log.iter().cloned())
                    .collect(),
            )
            .send_self(),
        );

        for team in room.client_teams(client.id) {
            response.add(
                ForwardEngineMessage(vec![to_engine_msg(once(b'G').chain(team.name.bytes()))])
                    .send_all()
                    .in_room(room.id),
            );
        }

        if info.is_paused {
            response.add(ForwardEngineMessage(vec![to_engine_msg(once(b'I'))]).send_self());
        }
    }

    get_room_update(protocols, None, room, master, response);
}

pub fn get_room_join_error(error: JoinRoomError, response: &mut Response) {
    use super::strings::*;
    match error {
        JoinRoomError::DoesntExist => response.warn(NO_ROOM),
        JoinRoomError::WrongProtocol => response.warn(INCOMPATIBLE_ROOM_PROTOCOL),
        JoinRoomError::WrongPassword => response.add(Notice("2".to_string()).send_self()),
        JoinRoomError::Full => response.warn(ROOM_FULL),
        JoinRoomError::Restricted => response.warn(ROOM_JOIN_RESTRICTED),
        JoinRoomError::RegistrationRequired => response.warn(ROOM_REGISTRATION_REQUIRED),
        JoinRoomError::RoomBanned => response.warn("You are banned from this room."),
    }
}

pub fn get_remove_teams_data(
    room_id: RoomId,
    was_in_game: bool,
    removed_teams: Vec<String>,
    response: &mut Response,
) {
    for team_name in removed_teams {
        response.add(
            TeamRemove(team_name.clone())
                .send_all()
                .in_room(room_id)
                .but_self(),
        );
        if was_in_game {
            let remove_msg = to_engine_msg(once(b'F').chain(team_name.bytes()));

            response.add(
                ForwardEngineMessage(vec![remove_msg])
                    .send_all()
                    .in_room(room_id)
                    .but_self(),
            );
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
    get_room_leave_result_for_client(
        server,
        room,
        response.client_id,
        leave_message,
        result,
        response,
    );
}

pub fn get_room_leave_result_for_client(
    server: &HwServer,
    room: &HwRoom,
    leaving_client_id: ClientId,
    leave_message: &str,
    result: LeaveRoomResult,
    response: &mut Response,
) {
    let client = server.client(leaving_client_id);
    response.add(ClientFlags(remove_flags(&[Flags::InRoom]), vec![client.nick.clone()]).send_all());

    match result {
        LeaveRoomResult::RoomRemoved => {
            get_room_remove(server, room, response);
        }

        LeaveRoomResult::RoomRemains {
            is_empty,
            was_master,
            new_master,
            was_in_game,
            removed_teams,
            end_game_result,
        } => {
            if !is_empty {
                response.add(
                    RoomLeft(client.nick.clone(), leave_message.to_string())
                        .send_all()
                        .in_room(room.id),
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
                    response.add(RoomControlAccess(true).send(new_master_id));
                    response.add(
                        ClientFlags(add_flags(&[Flags::RoomMaster]), vec![new_master_nick])
                            .send_all()
                            .in_room(room.id),
                    );
                    response.add(
                        server_chat("You're the new room master!".to_string()).send(new_master_id),
                    );
                }

                response.add(Notice("1".to_string()).send(leaving_client_id));
            }

            get_remove_teams_data(room.id, was_in_game, removed_teams, response);

            if let Some(end_result) = end_game_result {
                get_end_game_result(server, room.id, end_result, response);
            }

            let master = new_master.map(|id| server.client(id));

            get_room_update(
                server.all_client_protocols().into_iter(),
                None,
                room,
                master,
                response,
            );
        }
    }
}

pub fn remove_client(
    server: &mut HwServer,
    anteroom: &mut HwAnteroom,
    response: &mut Response,
    msg: String,
) {
    let client_id = response.client_id();
    remove_client_by_id(server, anteroom, client_id, response, msg);
}

pub fn remove_client_by_id(
    server: &mut HwServer,
    anteroom: &mut HwAnteroom,
    client_id: ClientId,
    response: &mut Response,
    msg: String,
) {
    if server.is_checker(client_id) {
        info!("Checker (id: {}) quit the server: {}", client_id, msg);
        server.remove_client(client_id);
        response.add(Bye(msg).send(client_id));
        response.remove_client(client_id);
        return;
    }

    if !server.has_client(client_id) {
        return;
    }

    let nick = server.client(client_id).nick.clone();
    info!("Client '{}' (id: {}) quit the server: {}", nick, client_id, msg);
    anteroom.forget_nick(&nick);

    if let HwRoomOrServer::Room(mut control) = server.get_room_control(client_id) {
        let room_id = control.room().id;
        let room_name = control.room().name.clone();
        info!("Client '{}' left room '{}' (server quit)", nick, room_name);
        let result = control.leave_room();
        let server = control.server();
        get_room_leave_result_for_client(
            server,
            server.room(room_id),
            client_id,
            &msg,
            result,
            response,
        );
    }

    server.remove_client(client_id);

    response.add(LobbyLeft(nick, msg.clone()).send_all());
    response.add(Bye(msg).send(client_id));
    response.remove_client(client_id);
}

pub fn register_flood_event(
    server: &mut HwServer,
    anteroom: &mut HwAnteroom,
    client_id: ClientId,
    event: FloodEvent,
    response: &mut Response,
) {
    let action = server
        .client_mut(client_id)
        .flood_control
        .register_event(event);
    match action {
        FloodAction::None => {}
        FloodAction::Warn(msg) => response.warn(msg),
        FloodAction::Bye(msg) => {
            let nick = server.client(client_id).nick.clone();
            warn!("Client '{}' (id: {}) kicked from server for flood: {}", nick, client_id, msg);
            remove_client_by_id(server, anteroom, client_id, response, msg.to_string())
        }
    }
}

pub fn protocol_cmd_name(message: &HwProtocolMessage) -> &str {
    use HwProtocolMessage::*;
    match message {
        Ping => "PING",
        Pong => "PONG",
        Quit(_) => "QUIT",
        Global(_) | Watch(_) | ToggleServerRegisteredOnly | SuperPower | Help
        | RestartServerConfirm => "CMD",
        Info(_) => "INFO",
        Nick(_, _) => "NICK",
        Proto(_) => "PROTO",
        Password(_, _) | LegacyPassword(_) => "PASSWORD",
        Checker(_, _, _) => "CHECKER",
        List => "LIST",
        Chat(_) => "CHAT",
        CreateRoom(_, _) => "CREATE_ROOM",
        JoinRoom(_, _) => "JOIN_ROOM",
        Follow(_) => "FOLLOW",
        Rnd(_) => "RND",
        Kick(_) => "KICK",
        Ban(_, _, _) | RoomBan(_) => "BAN",
        BanIp(_, _, _) => "BANIP",
        BanNick(_, _, _) => "BANNICK",
        BanList => "BANLIST",
        Unban(_) => "UNBAN",
        SetServerVar(_) => "SET_SERVER_VAR",
        GetServerVar => "GET_SERVER_VAR",
        RestartServer => "RESTART_SERVER",
        ClearAccountsCache => "CLEAR_ACCOUNTS_CACHE",
        Stats => "STATS",
        Part(_) => "PART",
        Cfg(_) => "CFG",
        AddTeam(_) => "ADD_TEAM",
        RemoveTeam(_) => "REMOVE_TEAM",
        SetHedgehogsNumber(_, _) => "HH_NUM",
        SetTeamColor(_, _) => "TEAM_COLOR",
        ToggleReady => "TOGGLE_READY",
        StartGame => "START_GAME",
        EngineMessage(_) => "EM",
        RoundFinished => "ROUNDFINISHED",
        ToggleRestrictJoin => "TOGGLE_RESTRICT_JOINS",
        ToggleRestrictTeams => "TOGGLE_RESTRICT_TEAMS",
        ToggleRegisteredOnly => "TOGGLE_REGISTERED_ONLY",
        RoomName(_) => "ROOM_NAME",
        Delegate(_) => "DELEGATE",
        TeamChat(_) => "TEAMCHAT",
        MaxTeams(_) => "MAXTEAMS",
        Fix => "FIX",
        Unfix => "UNFIX",
        Greeting(_) => "GREETING",
        CallVote(_) => "CALLVOTE",
        Vote(_) | ForceVote(_) => "VOTE",
        Save(_, _) => "SAVE",
        Delete(_) => "DELETE",
        SaveRoom(_) => "SAVEROOM",
        LoadRoom(_) => "LOADROOM",
        CheckerReady => "READY",
        CheckedOk(_) | CheckedFail(_) => "CHECKED",
        Malformed(lines) => lines.first().map(|s| s.as_str()).unwrap_or(""),
    }
}

pub fn get_room_update(
    protocols: impl Iterator<Item = u16>,
    old_name: Option<String>,
    room: &HwRoom,
    master: Option<&HwClient>,
    response: &mut Response,
) {
    for protocol in protocols {
        let base_old_name = old_name.as_ref().unwrap_or(&room.name);
        let formatted_old_name = if protocol < 60 && protocol != room.protocol_number {
            format!(
                "[v{}] {}",
                crate::utils::protocol_version_string(room.protocol_number),
                base_old_name
            )
        } else {
            base_old_name.clone()
        };
        let update_msg = RoomUpdated(formatted_old_name, room.info(master, protocol));
        response.add(update_msg.send_all().with_protocol(protocol));
    }
}

pub fn get_room_remove(server: &HwServer, room: &HwRoom, response: &mut Response) {
    info!("Room '{}' removed", room.name);
    for protocol in server.all_client_protocols() {
        response.add(
            RoomRemove(room.get_name(protocol))
                .send_all()
                .with_protocol(protocol),
        );
    }
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
    match room.game_info {
        Some(ref info) => get_teams(
            info.original_teams.iter().map(|(_, team)| team),
            destination,
            response,
        ),
        None => get_teams(
            room.teams.iter().map(|team| &team.info),
            destination,
            response,
        ),
    }
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
            if room.master_id.is_some() {
                Some((
                    true,
                    "/callvote kick: This is only allowed in rooms without a room master."
                        .to_string(),
                ))
            } else if server
                .find_client(nick)
                .filter(|c| c.room_id == Some(room.id))
                .is_some()
            {
                None
            } else {
                Some((true, "/callvote kick: No such user!".to_string()))
            }
        }
        VoteType::Map(None) => {
            let mut names: Vec<_> = room.saves.keys().cloned().collect();
            names.sort();
            if names.is_empty() {
                Some((false, "/callvote map: No maps available.".to_string()))
            } else {
                Some((false, format!("/callvote map: {}", names.join(", "))))
            }
        }
        VoteType::Map(Some(name)) => {
            if room.saves.contains_key(&name[..]) {
                None
            } else {
                Some((true, "/callvote map: No such map!".to_string()))
            }
        }
        VoteType::Pause => {
            if room.game_info.is_some() {
                None
            } else {
                Some((true, "/callvote pause: No game in progress!".to_string()))
            }
        }
        VoteType::NewSeed => None,
        VoteType::HedgehogsPerTeam(number) => match number {
            1..=MAX_HEDGEHOGS_PER_TEAM => None,
            _ => Some((
                true,
                "/callvote hedgehogs: Specify number from 1 to 8.".to_string(),
            )),
        },
    };

    match error {
        None => true,
        Some((true, msg)) => {
            response.warn(&msg);
            false
        }
        Some((false, msg)) => {
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
        Ok(VoteResult::Succeeded(_) | VoteResult::Failed) => {
            response.add(server_chat("Your vote has been counted.".to_string()).send_self());
            response.add(
                server_chat("Voting closed.".to_string())
                    .send_all()
                    .in_room(room_id),
            );
        }
        Err(VoteError::NoVoting) => {
            response.warn("There's no voting going on.");
        }
        Err(VoteError::AlreadyVoted) => {
            response.warn("You already have voted.");
        }
        Err(VoteError::NotEntitled) => {}
    }
}

pub fn handle_vote(
    room_control: HwRoomControl,
    result: Result<VoteResult, VoteError>,
    response: &mut super::Response,
) {
    let room_id = room_control.room().id;
    get_vote_data(room_control.room().id, &result, response);

    if let Ok(VoteResult::Succeeded(effect)) = result {
        match effect {
            VoteEffect::Kicked(kicked_id, leave_result) => {
                let kicked_nick = room_control.server().client(kicked_id).nick.clone();
                let room_name = room_control.room().name.clone();
                info!("Client '{}' was kicked from room '{}' by vote", kicked_nick, room_name);
                response.add(Kicked.send(kicked_id));
                get_room_leave_result_for_client(
                    room_control.server(),
                    room_control.room(),
                    kicked_id,
                    "kicked",
                    leave_result,
                    response,
                );
            }
            VoteEffect::Map(location) => {
                let msg = server_chat(location.to_string());
                let room = room_control.room();
                response.add(msg.send_all().in_room(room.id));

                let room_master = room.master_id.map(|id| room_control.server().client(id));

                get_room_update(
                    room_control.server().all_client_protocols().into_iter(),
                    None,
                    room,
                    room_master,
                    response,
                );

                let room_destination = Destination::ToAll {
                    group: DestinationGroup::Room(room.id),
                    skip_self: false,
                };
                get_active_room_config(room, room_destination, response);
            }
            VoteEffect::Pause => {
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
            VoteEffect::NewSeed(cfg) => {
                response.add(cfg.to_server_msg().send_all().in_room(room_id));
            }
            VoteEffect::HedgehogsPerTeam(number, team_names) => {
                response.extend(
                    team_names
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
            get_room_update(
                server.all_client_protocols().into_iter(),
                None,
                room,
                room_master,
                response,
            );
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

    get_room_update(
        server.all_client_protocols().into_iter(),
        None,
        room,
        room_master,
        response,
    );
    response.add(RoundFinished.send_all().in_room(room_id));

    response.extend(
        result
            .left_teams
            .into_iter()
            .map(|name| TeamRemove(name).send_all().in_room(room.id)),
    );

    if !result.unreadied_nicks.is_empty() {
        response.add(
            ClientFlags(remove_flags(&[Flags::Ready]), result.unreadied_nicks)
                .send_all()
                .in_room(room_id),
        );
    }

    if let Some((checker_id, demo_msgs)) = result.checker_replay {
        response.add(HwServerMessage::Replay(demo_msgs).send(checker_id));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::handlers::actions::PendingMessage;
    use hedgewars_network_protocol::messages::HwServerMessage::ChatMsg;

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
