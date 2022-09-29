use hedgewars_network_protocol::types::{RoomConfig, TeamInfo, VoteType};
use serde_derive::{Deserialize, Serialize};

pub type CheckerId = usize;
pub type ClientId = usize;
pub type RoomId = usize;

#[derive(Debug)]
pub struct Replay {
    pub config: RoomConfig,
    pub teams: Vec<TeamInfo>,
    pub message_log: Vec<String>,
}

#[derive(Clone, Debug)]
pub struct Voting {
    pub ttl: u32,
    pub voters: Vec<ClientId>,
    pub votes: Vec<(ClientId, bool)>,
    pub kind: VoteType,
}

impl Voting {
    pub fn new(kind: VoteType, voters: Vec<ClientId>) -> Voting {
        Voting {
            kind,
            voters,
            ttl: 2,
            votes: Vec::new(),
        }
    }
}
