use hedgewars_network_protocol::types::{RoomConfig, TeamInfo, VoteType};

pub type CheckerId = usize;
pub type ClientId = usize;
pub type RoomId = usize;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ReplayTeam {
    pub info: TeamInfo,
    pub is_owner_registered: bool,
}

#[derive(Debug)]
pub struct Replay {
    pub config: RoomConfig,
    pub teams: Vec<ReplayTeam>,
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
