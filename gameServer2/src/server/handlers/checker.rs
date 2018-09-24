use mio;
use log::*;

use crate::{
    server::{
        server::HWServer,
        coretypes::ClientId,
    },
    protocol::messages::{
        HWProtocolMessage
    },
};

pub fn handle(server: & mut HWServer, client_id: ClientId, message: HWProtocolMessage) {
    match message {
        _ => warn!("Unknown command"),
    }
}
