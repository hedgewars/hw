use log::*;

use crate::core::{server::HwServer, types::CheckerId};
use crate::handlers::actions::ToPendingMessage;
use hedgewars_network_protocol::messages::{HwProtocolMessage, HwServerMessage};

pub fn handle(
    server: &mut HwServer,
    checker_id: CheckerId,
    response: &mut super::Response,
    message: HwProtocolMessage,
) {
    match message {
        HwProtocolMessage::CheckerReady => {
            let protocol = if let Some(c) = server.get_checker_mut(checker_id) {
                c.set_is_ready(true);
                c.protocol_number
            } else {
                0
            };

            if let Some(ref mut storage) = server.replay_storage {
                if let Some((id, replay)) = storage.pick_replay(protocol) {
                    if let Some(c) = server.get_checker_mut(checker_id) {
                        c.set_is_ready(false);
                        c.current_replay = Some(id);
                    }
                    response.add(HwServerMessage::Replay(replay.message_log).send_self());
                }
            }
        }
        HwProtocolMessage::CheckedOk(_info) => {
            if let Some(c) = server.get_checker_mut(checker_id) {
                if let Some(id) = c.current_replay.take() {
                    if let Some(ref mut storage) = server.replay_storage {
                        storage.move_checked_replay(&id).ok();
                    }
                }
            }
        }
        HwProtocolMessage::CheckedFail(_message) => {
            if let Some(c) = server.get_checker_mut(checker_id) {
                if let Some(id) = c.current_replay.take() {
                    if let Some(ref mut storage) = server.replay_storage {
                        storage.move_failed_replay(&id).ok();
                    }
                }
            }
        }
        _ => warn!("Unknown command"),
    }
}
