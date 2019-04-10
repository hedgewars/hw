pub type ClientId = usize;
pub type RoomId = usize;

pub const MAX_HEDGEHOGS_PER_TEAM: u8 = 8;

#[derive(PartialEq, Eq, Clone, Debug)]
pub enum ServerVar {
    MOTDNew(String),
    MOTDOld(String),
    LatestProto(u16),
}

#[derive(PartialEq, Eq, Clone, Debug)]
pub enum GameCfg {
    FeatureSize(u32),
    MapType(String),
    MapGenerator(u32),
    MazeSize(u32),
    Seed(String),
    Template(u32),

    Ammo(String, Option<String>),
    Scheme(String, Vec<String>),
    Script(String),
    Theme(String),
    DrawnMap(String),
}

#[derive(PartialEq, Eq, Clone, Debug)]
pub struct TeamInfo {
    pub name: String,
    pub color: u8,
    pub grave: String,
    pub fort: String,
    pub voice_pack: String,
    pub flag: String,
    pub difficulty: u8,
    pub hedgehogs_number: u8,
    pub hedgehogs: [HedgehogInfo; MAX_HEDGEHOGS_PER_TEAM as usize],
}

#[derive(PartialEq, Eq, Clone, Debug)]
pub struct HedgehogInfo {
    pub name: String,
    pub hat: String,
}

#[derive(PartialEq, Eq, Clone, Debug)]
pub enum VoteType {
    Kick(String),
    Map(Option<String>),
    Pause,
    NewSeed,
    HedgehogsPerTeam(u8),
}

pub struct Vote {
    pub is_pro: bool,
    pub is_forced: bool,
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
