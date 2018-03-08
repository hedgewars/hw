use nom::*;

use std::str;
use std::str::FromStr;
use super::messages::HWProtocolMessage;
use super::messages::HWProtocolMessage::*;

use proptest::test_runner::{TestRunner, Reason};
use proptest::arbitrary::{any, any_with, Arbitrary, StrategyFor};
use proptest::strategy::{Strategy, BoxedStrategy, Just, Filter, ValueTree};
use proptest::string::RegexGeneratorValueTree;
use std::ops::Range;

named!(end_of_message, tag!("\n\n"));
named!(str_line<&[u8],   &str>, map_res!(not_line_ending, str::from_utf8));
named!(  a_line<&[u8], String>, map!(str_line, String::from));
named!( u8_line<&[u8],     u8>, map_res!(str_line, FromStr::from_str));
named!(u32_line<&[u8],    u32>, map_res!(str_line, FromStr::from_str));
named!(opt_param<&[u8], Option<String> >, opt!(map!(flat_map!(preceded!(eol, str_line), non_empty), String::from)));

named!(basic_message<&[u8], HWProtocolMessage>, alt!(
      do_parse!(tag!("PING") >> (Ping))
    | do_parse!(tag!("PONG") >> (Pong))
    | do_parse!(tag!("LIST") >> (List))
    | do_parse!(tag!("BANLIST")        >> (BanList))
    | do_parse!(tag!("GET_SERVER_VAR") >> (GetServerVar))
    | do_parse!(tag!("TOGGLE_READY")   >> (ToggleReady))
    | do_parse!(tag!("START_GAME")     >> (StartGame))
    | do_parse!(tag!("ROUNDFINISHED")  >> (RoundFinished))
    | do_parse!(tag!("TOGGLE_RESTRICT_JOINS")  >> (ToggleRestrictJoin))
    | do_parse!(tag!("TOGGLE_RESTRICT_TEAMS")  >> (ToggleRestrictTeams))
    | do_parse!(tag!("TOGGLE_REGISTERED_ONLY") >> (ToggleRegisteredOnly))
));

named!(one_param_message<&[u8], HWProtocolMessage>, alt!(
      do_parse!(tag!("NICK")    >> eol >> n: a_line >> (Nick(n)))
    | do_parse!(tag!("INFO")    >> eol >> n: a_line >> (Info(n)))
    | do_parse!(tag!("CHAT")    >> eol >> m: a_line >> (Chat(m)))
    | do_parse!(tag!("FOLLOW")  >> eol >> n: a_line >> (Follow(n)))
    | do_parse!(tag!("KICK")    >> eol >> n: a_line >> (Kick(n)))
    | do_parse!(tag!("UNBAN")   >> eol >> n: a_line >> (Unban(n)))
    | do_parse!(tag!("EM")      >> eol >> m: a_line >> (EngineMessage(m)))
    | do_parse!(tag!("TEAMCHAT")    >> eol >> m: a_line >> (TeamChat(m)))
    | do_parse!(tag!("ROOM_NAME")   >> eol >> n: a_line >> (RoomName(n)))
    | do_parse!(tag!("REMOVE_TEAM") >> eol >> n: a_line >> (RemoveTeam(n)))

    | do_parse!(tag!("PROTO")   >> eol >> d: u32_line >> (Proto(d)))

    | do_parse!(tag!("QUIT")   >> msg: opt_param >> (Quit(msg)))
));

named!(cmd_message<&[u8], HWProtocolMessage>, preceded!(tag!("CMD\n"), alt!(
      do_parse!(tag_no_case!("STATS") >> (Stats))
    | do_parse!(tag_no_case!("FIX")   >> (Fix))
    | do_parse!(tag_no_case!("UNFIX") >> (Unfix))
    | do_parse!(tag_no_case!("RESTART_SERVER") >> eol >> tag!("YES") >> (RestartServer))
    | do_parse!(tag_no_case!("REGISTERED_ONLY") >> (ToggleServerRegisteredOnly))
    | do_parse!(tag_no_case!("SUPER_POWER")     >> (SuperPower))
    | do_parse!(tag_no_case!("PART")     >> m: opt_param >> (Part(m)))
    | do_parse!(tag_no_case!("QUIT")     >> m: opt_param >> (Quit(m)))
    | do_parse!(tag_no_case!("DELEGATE") >> eol >> n: a_line  >> (Delegate(n)))
    | do_parse!(tag_no_case!("SAVEROOM") >> eol >> r: a_line  >> (SaveRoom(r)))
    | do_parse!(tag_no_case!("LOADROOM") >> eol >> r: a_line  >> (LoadRoom(r)))
    | do_parse!(tag_no_case!("DELETE")   >> eol >> r: a_line  >> (Delete(r)))
    | do_parse!(tag_no_case!("GLOBAL")   >> eol >> m: a_line  >> (Global(m)))
    | do_parse!(tag_no_case!("WATCH")    >> eol >> i: a_line  >> (Watch(i)))
    | do_parse!(tag_no_case!("GREETING") >> eol >> m: a_line  >> (Greeting(m)))
    | do_parse!(tag_no_case!("VOTE")     >> eol >> m: a_line  >> (Vote(m)))
    | do_parse!(tag_no_case!("FORCE")    >> eol >> m: a_line  >> (ForceVote(m)))
    | do_parse!(tag_no_case!("INFO")     >> eol >> n: a_line  >> (Info(n)))
    | do_parse!(tag_no_case!("MAXTEAMS") >> eol >> n: u8_line >> (MaxTeams(n)))
)));

named!(complex_message<&[u8], HWProtocolMessage>, alt!(
      do_parse!(tag!("PASSWORD")  >> eol >>
                    p: a_line     >> eol >>
                    s: a_line     >>
                    (Password(p, s)))
    | do_parse!(tag!("CHECKER")   >> eol >>
                    i: u32_line   >> eol >>
                    n: a_line     >> eol >>
                    p: a_line     >>
                    (Checker(i, n, p)))
    | do_parse!(tag!("CREATE_ROOM") >> eol >>
                    n: a_line       >>
                    p: opt_param    >>
                    (CreateRoom(n, p)))
    | do_parse!(tag!("JOIN")        >> eol >>
                    n: a_line       >>
                    p: opt_param    >>
                    (Join(n, p)))
    | do_parse!(tag!("BAN")    >> eol >>
                    n: a_line     >> eol >>
                    r: a_line     >> eol >>
                    t: u32_line   >>
                    (Ban(n, r, t)))
    | do_parse!(tag!("BAN_IP")    >> eol >>
                    n: a_line     >> eol >>
                    r: a_line     >> eol >>
                    t: u32_line   >>
                    (BanIP(n, r, t)))
    | do_parse!(tag!("BAN_NICK")    >> eol >>
                    n: a_line     >> eol >>
                    r: a_line     >> eol >>
                    t: u32_line   >>
                    (BanNick(n, r, t)))
));

named!(malformed_message<&[u8], HWProtocolMessage>,
    do_parse!(separated_list!(eol, a_line) >> (Malformed)));

named!(empty_message<&[u8], HWProtocolMessage>,
    do_parse!(alt!(end_of_message | eol) >> (Empty)));

named!(message<&[u8], HWProtocolMessage>, alt!(terminated!(
    alt!(
          basic_message
        | one_param_message
        | cmd_message
        | complex_message
        ), end_of_message
    )
    | terminated!(malformed_message, end_of_message)
    | empty_message
    )
);

named!(pub extract_messages<&[u8], Vec<HWProtocolMessage> >, many0!(complete!(message)));

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
    type ValueTree = Box<ValueTree<Value = Ascii>>;
}

fn gen_proto_msg() -> BoxedStrategy<HWProtocolMessage> where {
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
        16 => Join(Ascii, Option<Ascii>),
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

proptest! {
    #[test]
    fn is_parser_composition_idempotent(ref msg in gen_proto_msg()) {
        println!("!! Msg: {:?}, Bytes: {:?} !!", msg, msg.to_raw_protocol().as_bytes());
        assert_eq!(message(msg.to_raw_protocol().as_bytes()), IResult::Done(&b""[..], msg.clone()))
    }
}

#[test]
fn parse_test() {
    assert_eq!(message(b"PING\n\n"),          IResult::Done(&b""[..], Ping));
    assert_eq!(message(b"START_GAME\n\n"),    IResult::Done(&b""[..], StartGame));
    assert_eq!(message(b"NICK\nit's me\n\n"), IResult::Done(&b""[..], Nick("it's me".to_string())));
    assert_eq!(message(b"PROTO\n51\n\n"),     IResult::Done(&b""[..], Proto(51)));
    assert_eq!(message(b"QUIT\nbye-bye\n\n"), IResult::Done(&b""[..], Quit(Some("bye-bye".to_string()))));
    assert_eq!(message(b"QUIT\n\n"),          IResult::Done(&b""[..], Quit(None)));
    assert_eq!(message(b"CMD\nwatch\ndemo\n\n"), IResult::Done(&b""[..], Watch("demo".to_string())));
    assert_eq!(message(b"BAN\nme\nbad\n77\n\n"), IResult::Done(&b""[..], Ban("me".to_string(), "bad".to_string(), 77)));

    assert_eq!(message(b"CMD\nPART\n\n"),      IResult::Done(&b""[..], Part(None)));
    assert_eq!(message(b"CMD\nPART\n_msg_\n\n"), IResult::Done(&b""[..], Part(Some("_msg_".to_string()))));

    assert_eq!(extract_messages(b"QUIT\n1\n2\n\n"),    IResult::Done(&b""[..], vec![Malformed]));

    assert_eq!(extract_messages(b"PING\n\nPING\n\nP"), IResult::Done(&b"P"[..], vec![Ping, Ping]));
    assert_eq!(extract_messages(b"SING\n\nPING\n\n"),  IResult::Done(&b""[..],  vec![Malformed, Ping]));
    assert_eq!(extract_messages(b"\n\n\n\nPING\n\n"),  IResult::Done(&b""[..],  vec![Empty, Empty, Ping]));
    assert_eq!(extract_messages(b"\n\n\nPING\n\n"),    IResult::Done(&b""[..],  vec![Empty, Empty, Ping]));
}