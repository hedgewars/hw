use log::*;

use crate::core::{server::HwServer, types::CheckerId};
use hedgewars_network_protocol::messages::HwProtocolMessage;

pub fn handle(
    server: &mut HwServer,
    checker_id: CheckerId,
    _response: &mut super::Response,
    message: HwProtocolMessage,
) {
    match message {
        HwProtocolMessage::CheckerReady => {
            if let Some(c) = server.get_checker_mut(checker_id) {
                c.set_is_ready(true)
            }
            warn!("Unimplemented")
        }
        HwProtocolMessage::CheckedOk(info) => {
            warn!("Unimplemented")
        }
        HwProtocolMessage::CheckedFail(message) => {
            warn!("Unimplemented")
        }
        _ => warn!("Unknown command"),
    }
}
