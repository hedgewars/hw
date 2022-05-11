use log::*;

use crate::core::{server::HwServer, types::ClientId};
use hedgewars_network_protocol::messages::HwProtocolMessage;

pub fn handle(
    _server: &mut HwServer,
    _client_id: ClientId,
    _response: &mut super::Response,
    message: HwProtocolMessage,
) {
    match message {
        HwProtocolMessage::CheckerReady => {
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
