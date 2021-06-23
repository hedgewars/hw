use serde_derive::{Deserialize, Serialize};

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

#[derive(PartialEq, Eq, Clone, Debug, Default)]
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

#[derive(PartialEq, Eq, Clone, Debug, Default)]
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

//#[cfg(test)]
#[macro_use]
pub mod testing {
    use crate::types::ServerVar::*;
    use crate::types::*;
    use proptest::{
        arbitrary::{any, Arbitrary},
        strategy::{BoxedStrategy, Just, Strategy},
    };

    // Due to inability to define From between Options
    pub trait Into2<T>: Sized {
        fn into2(self) -> T;
    }
    impl<T> Into2<T> for T {
        fn into2(self) -> T {
            self
        }
    }
    impl Into2<Vec<String>> for Vec<Ascii> {
        fn into2(self) -> Vec<String> {
            self.into_iter().map(|x| x.0).collect()
        }
    }
    impl Into2<String> for Ascii {
        fn into2(self) -> String {
            self.0
        }
    }
    impl Into2<Option<String>> for Option<Ascii> {
        fn into2(self) -> Option<String> {
            self.map(|x| x.0)
        }
    }

    #[macro_export]
    macro_rules! proto_msg_case {
        ($val: ident()) => {
            Just($val)
        };
        ($val: ident($arg: ty)) => {
            any::<$arg>().prop_map(|v| $val(v.into2()))
        };
        ($val: ident($arg1: ty, $arg2: ty)) => {
            any::<($arg1, $arg2)>().prop_map(|v| $val(v.0.into2(), v.1.into2()))
        };
        ($val: ident($arg1: ty, $arg2: ty, $arg3: ty)) => {
            any::<($arg1, $arg2, $arg3)>().prop_map(|v| $val(v.0.into2(), v.1.into2(), v.2.into2()))
        };
    }

    #[macro_export]
    macro_rules! proto_msg_match {
    ($var: expr, def = $default: expr, $($num: expr => $constr: ident $res: tt),*) => (
        match $var {
            $($num => (proto_msg_case!($constr $res)).boxed()),*,
            _ => Just($default).boxed()
        }
    )
}

    /// Wrapper type for generating non-empty strings
    #[derive(Debug)]
    pub struct Ascii(String);

    impl Arbitrary for Ascii {
        type Parameters = <String as Arbitrary>::Parameters;

        fn arbitrary_with(_args: Self::Parameters) -> Self::Strategy {
            "[a-zA-Z0-9]+".prop_map(Ascii).boxed()
        }

        type Strategy = BoxedStrategy<Ascii>;
    }

    impl Arbitrary for GameCfg {
        type Parameters = ();

        fn arbitrary_with(_args: <Self as Arbitrary>::Parameters) -> <Self as Arbitrary>::Strategy {
            use crate::types::GameCfg::*;
            (0..10)
                .no_shrink()
                .prop_flat_map(|i| {
                    proto_msg_match!(i, def = FeatureSize(0),
            0 => FeatureSize(u32),
            1 => MapType(Ascii),
            2 => MapGenerator(u32),
            3 => MazeSize(u32),
            4 => Seed(Ascii),
            5 => Template(u32),
            6 => Ammo(Ascii, Option<Ascii>),
            7 => Scheme(Ascii, Vec<Ascii>),
            8 => Script(Ascii),
            9 => Theme(Ascii),
            10 => DrawnMap(Ascii))
                })
                .boxed()
        }

        type Strategy = BoxedStrategy<GameCfg>;
    }

    impl Arbitrary for TeamInfo {
        type Parameters = ();

        fn arbitrary_with(_args: <Self as Arbitrary>::Parameters) -> <Self as Arbitrary>::Strategy {
            (
                "[a-z]+",
                0u8..127u8,
                "[a-z]+",
                "[a-z]+",
                "[a-z]+",
                "[a-z]+",
                0u8..127u8,
            )
                .prop_map(|(name, color, grave, fort, voice_pack, flag, difficulty)| {
                    fn hog(n: u8) -> HedgehogInfo {
                        HedgehogInfo {
                            name: format!("hog{}", n),
                            hat: format!("hat{}", n),
                        }
                    }
                    let hedgehogs = [
                        hog(1),
                        hog(2),
                        hog(3),
                        hog(4),
                        hog(5),
                        hog(6),
                        hog(7),
                        hog(8),
                    ];
                    TeamInfo {
                        owner: String::new(),
                        name,
                        color,
                        grave,
                        fort,
                        voice_pack,
                        flag,
                        difficulty,
                        hedgehogs,
                        hedgehogs_number: 0,
                    }
                })
                .boxed()
        }

        type Strategy = BoxedStrategy<TeamInfo>;
    }

    impl Arbitrary for ServerVar {
        type Parameters = ();

        fn arbitrary_with(_args: Self::Parameters) -> Self::Strategy {
            (0..=2)
                .no_shrink()
                .prop_flat_map(|i| {
                    proto_msg_match!(i, def = ServerVar::LatestProto(0),
                        0 => MOTDNew(Ascii),
                        1 => MOTDOld(Ascii),
                        2 => LatestProto(u16)
                    )
                })
                .boxed()
        }

        type Strategy = BoxedStrategy<ServerVar>;
    }

    impl Arbitrary for VoteType {
        type Parameters = ();

        fn arbitrary_with(_args: Self::Parameters) -> Self::Strategy {
            use VoteType::*;
            (0..=4)
                .no_shrink()
                .prop_flat_map(|i| {
                    proto_msg_match!(i, def = VoteType::Pause,
                        0 => Kick(Ascii),
                        1 => Map(Option<Ascii>),
                        2 => Pause(),
                        3 => NewSeed(),
                        4 => HedgehogsPerTeam(u8)
                    )
                })
                .boxed()
        }

        type Strategy = BoxedStrategy<VoteType>;
    }
}
