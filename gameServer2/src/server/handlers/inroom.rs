use mio;

use server::server::HWServer;
use server::actions::Action;
use server::actions::Action::*;
use protocol::messages::HWProtocolMessage;
use protocol::messages::HWServerMessage::*;

pub fn handle(server: &mut HWServer, token: usize, message: HWProtocolMessage) {
    match message {
        _ => warn!("Unimplemented!"),
    }
}
