use mio;

use server::server::HWServer;
use server::actions::Action;
use server::actions::Action::*;
use protocol::messages::HWProtocolMessage;
use protocol::messages::HWServerMessage::*;

pub fn handle(server: &mut HWServer, token: usize, _poll: &mio::Poll, message: HWProtocolMessage) {
    match message {
        _ => warn!("Unimplemented!"),
    }
}
