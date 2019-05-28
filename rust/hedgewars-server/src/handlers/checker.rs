use log::*;
use mio;

use crate::{
    core::{server::HwServer, types::ClientId},
    protocol::messages::HwProtocolMessage,
};

pub fn handle(_server: &mut HwServer, _client_id: ClientId, message: HwProtocolMessage) {
    match message {
        _ => warn!("Unknown command"),
    }
}
