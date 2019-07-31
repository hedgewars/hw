use serde_derive::{Deserialize, Serialize};

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
    pub owner: String,
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

#[derive(Clone, Serialize, Deserialize, Debug)]
pub struct Ammo {
    pub name: String,
    pub settings: Option<String>,
}

#[derive(Clone, Serialize, Deserialize, Debug)]
pub struct Scheme {
    pub name: String,
    pub settings: Vec<String>,
}

#[derive(Clone, Serialize, Deserialize, Debug)]
pub struct RoomConfig {
    pub feature_size: u32,
    pub map_type: String,
    pub map_generator: u32,
    pub maze_size: u32,
    pub seed: String,
    pub template: u32,

    pub ammo: Ammo,
    pub scheme: Scheme,
    pub script: String,
    pub theme: String,
    pub drawn_map: Option<String>,
}

impl RoomConfig {
    pub fn new() -> RoomConfig {
        RoomConfig {
            feature_size: 12,
            map_type: "+rnd+".to_string(),
            map_generator: 0,
            maze_size: 0,
            seed: "seed".to_string(),
            template: 0,

            ammo: Ammo {
                name: "Default".to_string(),
                settings: None,
            },
            scheme: Scheme {
                name: "Default".to_string(),
                settings: Vec::new(),
            },
            script: "Normal".to_string(),
            theme: "\u{1f994}".to_string(),
            drawn_map: None,
        }
    }

    pub fn set_config(&mut self, cfg: GameCfg) {
        match cfg {
            GameCfg::FeatureSize(s) => self.feature_size = s,
            GameCfg::MapType(t) => self.map_type = t,
            GameCfg::MapGenerator(g) => self.map_generator = g,
            GameCfg::MazeSize(s) => self.maze_size = s,
            GameCfg::Seed(s) => self.seed = s,
            GameCfg::Template(t) => self.template = t,

            GameCfg::Ammo(n, s) => {
                self.ammo = Ammo {
                    name: n,
                    settings: s,
                }
            }
            GameCfg::Scheme(n, s) => {
                self.scheme = Scheme {
                    name: n,
                    settings: s,
                }
            }
            GameCfg::Script(s) => self.script = s,
            GameCfg::Theme(t) => self.theme = t,
            GameCfg::DrawnMap(m) => self.drawn_map = Some(m),
        };
    }

    pub fn to_map_config(&self) -> Vec<String> {
        vec![
            self.feature_size.to_string(),
            self.map_type.to_string(),
            self.map_generator.to_string(),
            self.maze_size.to_string(),
            self.seed.to_string(),
            self.template.to_string(),
        ]
    }

    pub fn to_game_config(&self) -> Vec<GameCfg> {
        use GameCfg::*;
        let mut v = vec![
            Ammo(self.ammo.name.to_string(), self.ammo.settings.clone()),
            Scheme(self.scheme.name.to_string(), self.scheme.settings.clone()),
            Script(self.script.to_string()),
            Theme(self.theme.to_string()),
        ];
        if let Some(ref m) = self.drawn_map {
            v.push(DrawnMap(m.to_string()))
        }
        v
    }
}

#[derive(Debug)]
pub struct Replay {
    pub config: RoomConfig,
    pub teams: Vec<TeamInfo>,
    pub message_log: Vec<String>,
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
