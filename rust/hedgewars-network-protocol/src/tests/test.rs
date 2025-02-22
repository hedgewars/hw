use crate::{
    messages::{HwProtocolMessage, HwServerMessage},
    parser::{message, server_message},
    types::ServerVar::*,
    types::*,
    types::{GameCfg, ServerVar, TeamInfo, VoteType},
};

use proptest::{
    arbitrary::{any, Arbitrary},
    proptest,
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

pub fn gen_proto_msg() -> BoxedStrategy<HwProtocolMessage> where {
    use HwProtocolMessage::*;

    let res = (0..=58).no_shrink().prop_flat_map(|i| {
        proto_msg_match!(i, def = Ping,
            0 => Ping(),
            1 => Pong(),
            2 => Quit(Option<Ascii>),
            4 => Global(Ascii),
            5 => Watch(u32),
            6 => ToggleServerRegisteredOnly(),
            7 => SuperPower(),
            8 => Info(Ascii),
            9 => Nick(Ascii, Option<Ascii>),
            10 => Proto(u16),
            11 => Password(Ascii, Ascii),
            12 => Checker(u16, Ascii, Ascii),
            13 => List(),
            14 => Chat(Ascii),
            15 => CreateRoom(Ascii, Option<Ascii>),
            16 => JoinRoom(Ascii, Option<Ascii>),
            17 => Follow(Ascii),
            18 => Rnd(Vec<Ascii>),
            19 => Kick(Ascii),
            20 => Ban(Ascii, Ascii, u32),
            21 => BanIp(Ascii, Ascii, u32),
            22 => BanNick(Ascii, Ascii, u32),
            23 => BanList(),
            24 => Unban(Ascii),
            25 => SetServerVar(ServerVar),
            26 => GetServerVar(),
            27 => RestartServer(),
            28 => Stats(),
            29 => Part(Option<Ascii>),
            30 => Cfg(GameCfg),
            31 => AddTeam(Box<TeamInfo>),
            32 => RemoveTeam(Ascii),
            33 => SetHedgehogsNumber(Ascii, u8),
            34 => SetTeamColor(Ascii, u8),
            35 => ToggleReady(),
            36 => StartGame(),
            37 => EngineMessage(Ascii),
            38 => RoundFinished(),
            39 => ToggleRestrictJoin(),
            40 => ToggleRestrictTeams(),
            41 => ToggleRegisteredOnly(),
            42 => RoomName(Ascii),
            43 => Delegate(Ascii),
            44 => TeamChat(Ascii),
            45 => MaxTeams(u8),
            46 => Fix(),
            47 => Unfix(),
            48 => Greeting(Option<Ascii>),
            49 => CallVote(Option<VoteType>),
            50 => Vote(bool),
            51 => ForceVote(bool),
            52 => Save(Ascii, Ascii),
            53 => Delete(Ascii),
            54 => SaveRoom(Ascii),
            55 => LoadRoom(Ascii),
            56 => CheckerReady(),
            57 => CheckedOk(Vec<Ascii>),
            58 => CheckedFail(Ascii)
        )
    });
    res.boxed()
}

pub fn gen_server_msg() -> BoxedStrategy<HwServerMessage> where {
    use HwServerMessage::*;

    let res = (0..=39).no_shrink().prop_flat_map(|i| {
        proto_msg_match!(i, def = Ping,
                    0 => Connected(Ascii, u32),
                    1 => Redirect(u16),
                    2 => Ping(),
                    3 => Pong(),
                    4 => Bye(Ascii),
                    5 => Nick(Ascii),
                    6 => Proto(u16),
                    7 => AskPassword(Ascii),
                    8 => ServerAuth(Ascii),
                    9 => LogonPassed(),
                    10 => LobbyLeft(Ascii, Ascii),
                    11 => LobbyJoined(Vec<Ascii>),
        //            12 => ChatMsg { Ascii, Ascii },
                    13 => ClientFlags(Ascii, Vec<Ascii>),
                    14 => Rooms(Vec<Ascii>),
                    15 => RoomAdd(Vec<Ascii>),
                    16=> RoomJoined(Vec<Ascii>),
                    17 => RoomLeft(Ascii, Ascii),
                    18 => RoomRemove(Ascii),
                    19 => RoomUpdated(Ascii, Vec<Ascii>),
                    20 => Joining(Ascii),
                    21 => TeamAdd(Vec<Ascii>),
                    22 => TeamRemove(Ascii),
                    23 => TeamAccepted(Ascii),
                    24 => TeamColor(Ascii, u8),
                    25 => HedgehogsNumber(Ascii, u8),
                    26 => ConfigEntry(Ascii, Vec<Ascii>),
                    27 => Kicked(),
                    28 => RunGame(),
                    29 => ForwardEngineMessage(Vec<Ascii>),
                    30 => RoundFinished(),
                    31 => ReplayStart(),
                    32 => Info(Vec<Ascii>),
                    33 => ServerMessage(Ascii),
                    34 => ServerVars(Vec<Ascii>),
                    35 => Notice(Ascii),
                    36 => Warning(Ascii),
                    37 => Error(Ascii),
                    38 => Replay(Vec<Ascii>),
                    39 => Token(Ascii)
                )
    });
    res.boxed()
}

proptest! {
    #[test]
    fn is_parser_composition_idempotent(ref msg in gen_proto_msg()) {
        println!("!! Msg: {:?}, Bytes: {:?} !!", msg, msg.to_raw_protocol().as_bytes());
        assert_eq!(message(msg.to_raw_protocol().as_bytes()), Ok((&b""[..], msg.clone())))
    }

    #[test]
    fn is_server_message_parser_composition_idempotent(ref msg in gen_server_msg()) {
        println!("!! Msg: {:?}, Bytes: {:?} !!", msg, msg.to_raw_protocol().as_bytes());
        assert_eq!(server_message(msg.to_raw_protocol().as_bytes()), Ok((&b""[..], msg.clone())))
    }
}
