use log::*;
use mio;

use crate::{
    protocol::messages::HWProtocolMessage,
    server::{core::HWServer, coretypes::ClientId},
};

pub fn handle(server: &mut HWServer, client_id: ClientId, message: HWProtocolMessage) {
    match message {
        _ => warn!("Unknown command"),
    }
}
