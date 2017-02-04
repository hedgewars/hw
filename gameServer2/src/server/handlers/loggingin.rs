use mio;

use server::server::HWServer;
use server::actions::Action;
use server::actions::Action::*;
use protocol::messages::HWProtocolMessage;
use protocol::messages::HWServerMessage::*;

pub fn handle(server: &mut HWServer, token: mio::Token, poll: &mio::Poll, message: HWProtocolMessage) {
    match message {
        HWProtocolMessage::Nick(nick) =>
            if server.clients[token].room_id == None {
                server.react(token, poll, vec![SendMe(Nick(&nick).to_raw_protocol())]);
                server.clients[token].nick = nick;
                server.react(token, poll, vec![CheckRegistered]);
            },
        HWProtocolMessage::Proto(proto) => {
            server.clients[token].protocol_number = proto;
            server.react(token, poll, vec![CheckRegistered]);
        },
        _ => warn!("Incorrect command in logging-in state"),
    }
}
