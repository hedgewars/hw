use mio;

use server::server::HWServer;
use server::actions::Action;
use server::actions::Action::*;
use protocol::messages::HWProtocolMessage;
use protocol::messages::HWServerMessage::*;
use utils::is_name_illegal;

pub fn handle(server: & mut HWServer, token: usize, message: HWProtocolMessage) {
    match message {
        HWProtocolMessage::Nick(nick) => {
            let actions;
            {
                let client = &mut server.clients[token];
                debug!("{} {}", nick, is_name_illegal(&nick));
                actions = if client.room_id != None {
                    unreachable!()
                }
                else if !client.nick.is_empty() {
                    vec![ProtocolError("Nickname already provided.".to_string())]
                }
                else if     is_name_illegal(&nick) {
                    vec![ByeClient("Illegal nickname! Nicknames must be between 1-40 characters long, must not have a trailing or leading space and must not have any of these characters: $()*+?[]^{|}".to_string())]
                }
                else {
                    client.nick = nick.clone();
                    vec![SendMe(Nick(nick)), CheckRegistered]
                };
            }
            server.react(token, actions);
        },
        HWProtocolMessage::Proto(proto) => {
            let actions;
            {
                let client = &mut server.clients[token];
                actions = if client.protocol_number != 0 {
                    vec![ProtocolError("Protocol already known.".to_string())]
                }
                else if proto == 0 {
                    vec![ProtocolError("Bad number.".to_string())]
                }
                else {
                    client.protocol_number = proto;
                    vec![SendMe(Proto(proto)), CheckRegistered]
                };
            }
            server.react(token, actions);
        },
        _ => warn!("Incorrect command in logging-in state"),
    }
}
