use mio;

use server::server::HWServer;
use server::actions::Action;
use server::actions::Action::*;
use protocol::messages::HWProtocolMessage;
use protocol::messages::HWServerMessage::*;

pub fn handle(server: &mut HWServer, token: usize, message: HWProtocolMessage) {
    use protocol::messages::HWProtocolMessage::*;
    match message {
        Chat(msg) => {
            let chat_msg = ChatMsg(server.clients[token].nick.clone(), msg);
            server.react(token, vec![SendAllButMe(chat_msg)]);
        },
        CreateRoom(name, password) => {
            let room_exists = server.rooms.iter().find(|&(_, r)| r.name == name).is_some();
            if room_exists {
                server.react(token, vec![Warn("Room exists".to_string())]);
            } else {
                let flags_msg = ClientFlags("+hr".to_string(), vec![server.clients[token].nick.clone()]);
                {
                    let c = &mut server.clients[token];
                    c.is_master = true;
                    c.is_ready = true;
                    c.is_joined_mid_game = false;
                }
                server.react(token, vec![
                    AddRoom(name, password)
                    , SendMe(flags_msg)
                    ]);
            }
        },
        Join(name, password) => {

        },
        List => warn!("Deprecated LIST message received"),
        _ => warn!("Incorrect command in lobby state"),
    }
}
