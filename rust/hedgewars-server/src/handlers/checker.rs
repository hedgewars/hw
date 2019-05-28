use log::*;
use mio;

use crate::{
    protocol::messages::HWProtocolMessage,
    core::{server::HWServer, types::ClientId},
};

pub fn handle(_server: &mut HWServer, _client_id: ClientId, message: HWProtocolMessage) {
    match message {
        _ => warn!("Unknown command"),
    }
}
