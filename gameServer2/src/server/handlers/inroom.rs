use mio;

use server::{
    server::HWServer,
    actions::{Action, Action::*}
};
use protocol::messages::{
    HWProtocolMessage,
    HWServerMessage::*
};
use utils::is_name_illegal;
use std::mem::swap;

pub fn handle(server: &mut HWServer, token: usize, message: HWProtocolMessage) {
    use protocol::messages::HWProtocolMessage::*;
    match message {
        Part(None) => server.react(token, vec![
            MoveToLobby("part".to_string())]),
        Part(Some(msg)) => server.react(token, vec![
            MoveToLobby(format!("part: {}", msg))]),
        Chat(msg) => {
            let chat_msg;
            let room_id;
            {
                let c = &mut server.clients[token];
                chat_msg = ChatMsg(c.nick.clone(), msg);
                room_id = c.room_id;
            }
            let client_ids = server.other_clients_in_room(token);
            server.react(token, vec![
                SendToSelected(client_ids, chat_msg)]);
        },
        RoomName(new_name) => {
            let actions =
                if is_name_illegal(&new_name) {
                    vec![Warn("Illegal room name! A room name must be between 1-40 characters long, must not have a trailing or leading space and must not have any of these characters: $()*+?[]^{|}".to_string())]
                } else if server.has_room(&new_name) {
                    vec![Warn("A room with the same name already exists.".to_string())]
                } else {
                    let mut old_name = new_name.clone();
                    if let (c, Some(r)) = server.client_and_room(token) {
                        swap(&mut r.name, &mut old_name);
                        vec![SendRoomUpdate(Some(old_name))]
                    } else {
                        Vec::new()
                    }
                };
            server.react(token, actions);
        }
        _ => warn!("Unimplemented!"),
    }
}
