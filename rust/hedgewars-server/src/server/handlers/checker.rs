use log::*;
use mio;

use crate::{
    protocol::messages::HWProtocolMessage,
    server::{core::HWServer, coretypes::ClientId},
};

pub fn handle(_server: &mut HWServer, _client_id: ClientId, message: HWProtocolMessage) {
    match message {
        _ => warn!("Unknown command"),
    }
}
