use proptest::{
    test_runner::{TestRunner, Reason},
    arbitrary::{any, any_with, Arbitrary, StrategyFor},
    strategy::{Strategy, BoxedStrategy, Just, Filter, ValueTree},
    string::RegexGeneratorValueTree
};

use super::messages::{
    HWProtocolMessage, HWProtocolMessage::*
};

// Due to inability to define From between Options
trait Into2<T>: Sized { fn into2(self) -> T; }
impl <T> Into2<T> for T { fn into2(self) -> T { self } }
impl Into2<String> for Ascii { fn into2(self) -> String { self.0 } }
impl Into2<Option<String>> for Option<Ascii>{
    fn into2(self) -> Option<String> { self.map(|x| {x.0}) }
}

macro_rules! proto_msg_case {
    ($val: ident()) =>
        (Just($val));
    ($val: ident($arg: ty)) =>
        (any::<$arg>().prop_map(|v| {$val(v.into2())}));
    ($val: ident($arg1: ty, $arg2: ty)) =>
        (any::<($arg1, $arg2)>().prop_map(|v| {$val(v.0.into2(), v.1.into2())}));
    ($val: ident($arg1: ty, $arg2: ty, $arg3: ty)) =>
        (any::<($arg1, $arg2, $arg3)>().prop_map(|v| {$val(v.0.into2(), v.1.into2(), v.2.into2())}));
}

macro_rules! proto_msg_match {
    ($var: expr, def = $default: ident, $($num: expr => $constr: ident $res: tt),*) => (
        match $var {
            $($num => (proto_msg_case!($constr $res)).boxed()),*,
            _ => Just($default).boxed()
        }
    )
}

#[derive(Debug)]
struct Ascii(String);

struct AsciiValueTree(RegexGeneratorValueTree<String>);

impl ValueTree for AsciiValueTree {
    type Value = Ascii;

    fn current(&self) -> Self::Value { Ascii(self.0.current()) }
    fn simplify(&mut self) -> bool { self.0.simplify() }
    fn complicate(&mut self) -> bool { self.0.complicate() }
}

impl Arbitrary for Ascii {
    type Parameters = <String as Arbitrary>::Parameters;

    fn arbitrary_with(args: Self::Parameters) -> Self::Strategy {
        any_with::<String>(args)
            .prop_filter("not ascii", |s| {
                s.len() > 0 && s.is_ascii() &&
                    s.find(|c| {
                        ['\0', '\n', '\x20'].contains(&c)
                    }).is_none()})
            .prop_map(Ascii)
            .boxed()
    }

    type Strategy = BoxedStrategy<Ascii>;
    type ValueTree = Box<dyn ValueTree<Value = Ascii>>;
}

pub fn gen_proto_msg() -> BoxedStrategy<HWProtocolMessage> where {
    let res = (0..58).no_shrink().prop_flat_map(|i| {
        proto_msg_match!(i, def = Malformed,
        0 => Ping(),
        1 => Pong(),
        2 => Quit(Option<Ascii>),
        //3 => Cmd
        4 => Global(Ascii),
        5 => Watch(Ascii),
        6 => ToggleServerRegisteredOnly(),
        7 => SuperPower(),
        8 => Info(Ascii),
        9 => Nick(Ascii),
        10 => Proto(u32),
        11 => Password(Ascii, Ascii),
        12 => Checker(u32, Ascii, Ascii),
        13 => List(),
        14 => Chat(Ascii),
        15 => CreateRoom(Ascii, Option<Ascii>),
        16 => JoinRoom(Ascii, Option<Ascii>),
        17 => Follow(Ascii),
        //18 => Rnd(Vec<String>),
        19 => Kick(Ascii),
        20 => Ban(Ascii, Ascii, u32),
        21 => BanIP(Ascii, Ascii, u32),
        22 => BanNick(Ascii, Ascii, u32),
        23 => BanList(),
        24 => Unban(Ascii),
        //25 => SetServerVar(ServerVar),
        26 => GetServerVar(),
        27 => RestartServer(),
        28 => Stats(),
        29 => Part(Option<Ascii>),
        //30 => Cfg(GameCfg),
        //31 => AddTeam(TeamInfo),
        32 => RemoveTeam(Ascii),
        //33 => SetHedgehogsNumber(String, u8),
        //34 => SetTeamColor(String, u8),
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
        48 => Greeting(Ascii),
        //49 => CallVote(Option<(String, Option<String>)>),
        50 => Vote(String),
        51 => ForceVote(Ascii),
        //52 => Save(String, String),
        53 => Delete(Ascii),
        54 => SaveRoom(Ascii),
        55 => LoadRoom(Ascii),
        56 => Malformed(),
        57 => Empty()
    )});
    res.boxed()
}
