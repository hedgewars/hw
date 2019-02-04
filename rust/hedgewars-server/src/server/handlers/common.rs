use crate::server::client::HWClient;
use crate::server::room::HWRoom;
use crate::utils::to_engine_msg;
use crate::{
    protocol::messages::{
        HWProtocolMessage::{self, Rnd},
        HWServerMessage::{
            self, Bye, ChatMsg, ClientFlags, ForwardEngineMessage, LobbyLeft, RoomLeft, RoomRemove,
            RoomUpdated, TeamRemove,
        },
    },
    server::{actions::Action, core::HWServer},
};
use rand::{self, thread_rng, Rng};
use std::iter::once;

pub fn rnd_reply(options: &[String]) -> HWServerMessage {
    let mut rng = thread_rng();
    let reply = if options.is_empty() {
        (*rng.choose(&["heads", "tails"]).unwrap()).to_owned()
    } else {
        rng.choose(&options).unwrap().clone()
    };

    ChatMsg {
        nick: "[random]".to_owned(),
        msg: reply.clone(),
    }
}

pub fn remove_teams(
    room: &mut HWRoom,
    team_names: Vec<String>,
    is_in_game: bool,
    response: &mut super::Response,
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
                if info.teams_in_game == 0 {
                    //FinishRoomGame(room.id)
                }

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

pub fn exit_room(client: &HWClient, room: &mut HWRoom, response: &mut super::Response, msg: &str) {
    if room.players_number > 1 || room.is_fixed() {
        room.players_number -= 1;
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

        //ChangeMaster(room.id, None));
    }

    let update_msg = if room.players_number == 0 && !room.is_fixed() {
        RoomRemove(room.name.clone())
    } else {
        RoomUpdated(room.name.clone(), room.info(Some(&client)))
    };
    response.add(update_msg.send_all().with_protocol(room.protocol_number));

    response.add(ClientFlags("-i".to_string(), vec![client.nick.clone()]).send_all());
}

pub fn remove_client(server: &mut HWServer, response: &mut super::Response, msg: String) {
    let client_id = response.client_id();
    let lobby_id = server.lobby_id;
    let client = &mut server.clients[client_id];
    let (nick, room_id) = (client.nick.clone(), client.room_id);

    if let Some(room_id) = room_id {
        let room = &mut server.rooms[room_id];
        exit_room(client, room, response, &msg);
        client.room_id = Some(lobby_id);
    }

    server.remove_client(client_id);

    response.add(LobbyLeft(nick, msg.to_string()).send_all());
    response.add(Bye("User quit: ".to_string() + &msg).send_self());
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::protocol::messages::HWServerMessage::ChatMsg;
    use crate::server::actions::{
        Action::{self, Send},
        PendingMessage,
    };

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
