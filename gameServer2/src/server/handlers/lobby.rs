use mio;

use server::server::HWServer;
use server::actions::Action;
use server::actions::Action::*;
use protocol::messages::HWProtocolMessage;
use protocol::messages::HWServerMessage::*;

pub fn handle(server: &mut HWServer, token: mio::Token, poll: &mio::Poll, message: HWProtocolMessage) {
    match message {
        HWProtocolMessage::Chat(msg) => {
            let chat_msg = ChatMsg(&server.clients[token.0].nick, &msg).to_raw_protocol();
            server.react(token, poll, vec![SendAllButMe(chat_msg)]);
        },
        HWProtocolMessage::CreateRoom(name, password) => {
            let room_exists = server.rooms.iter().find(|&(_, ref r)| r.name == name).is_some();
            if room_exists {
                server.react(token, poll, vec![Warn("Room exists".to_string())]);
            } else {
                let flags_msg = ClientFlags("+hr", &[&server.clients[token.0].nick]).to_raw_protocol();
                {
                    let c = &mut server.clients[token.0];
                    c.is_master = true;
                    c.is_ready = true;
                    c.is_joined_mid_game = false;
                }
                server.react(token, poll, vec![
                    AddRoom(name, password)
                    , SendMe(flags_msg)
                    ]);
            }
        },
        HWProtocolMessage::Join(name, password) => {

        },
        HWProtocolMessage::List => warn!("Deprecated LIST message received"),
        _ => warn!("Incorrect command in lobby state"),
    }
}
