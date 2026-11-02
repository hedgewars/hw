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
            if let Some(c) = server.get_checker_mut(checker_id) {
                c.set_is_ready(true);
            }
            if let Some((_, demo_msgs)) = server.assign_replay_to_checker(checker_id) {
                response.add(HwServerMessage::Replay(demo_msgs).send_self());
            }
        }
        HwProtocolMessage::CheckedOk(info) => {
            if let Some(c) = server.get_checker_mut(checker_id) {
                let protocol = c.protocol_number;
                if let Some(id) = c.current_replay.take() {
                    let filename = id.filename();
                    let teams = std::mem::take(&mut c.current_teams);
                    let details = c.current_details.take();
                    if let Some(ref mut storage) = server.replay_storage {
                        storage.move_checked_replay(&id).ok();
                    }
                    #[cfg(feature = "official-server")]
                    if let Some(game_details) = details {
                        response.request_io(super::IoTask::StoreAchievements {
                            protocol,
                            filename,
                            teams,
                            game_details,
                            info,
                        });
                    }
                }
            }
        }
        HwProtocolMessage::CheckedFail(_message) => {
            if let Some(c) = server.get_checker_mut(checker_id) {
                c.current_teams.clear();
                c.current_details = None;
                if let Some(id) = c.current_replay.take() {
                    if let Some(ref mut storage) = server.replay_storage {
                        storage.move_failed_replay(&id).ok();
                    }
                }
            }
        }
        _ => response.error("Unknown command"),
    }
}
