use nom::*;

use std::{
    str, str::FromStr,
    ops::Range
};
use super::{
    messages::{HWProtocolMessage, HWProtocolMessage::*},
    test::gen_proto_msg
};
use server::coretypes::{
    HedgehogInfo, TeamInfo, GameCfg
};

named!(end_of_message, tag!("\n\n"));
named!(str_line<&[u8],   &str>, map_res!(not_line_ending, str::from_utf8));
named!(  a_line<&[u8], String>, map!(str_line, String::from));
named!( u8_line<&[u8],     u8>, map_res!(str_line, FromStr::from_str));
named!(u32_line<&[u8],    u32>, map_res!(str_line, FromStr::from_str));
named!(opt_param<&[u8], Option<String> >, opt!(map!(flat_map!(preceded!(eol, str_line), non_empty), String::from)));
named!(hog_line<&[u8], HedgehogInfo>,
    do_parse!(name: str_line >> eol >> hat: str_line >>
        (HedgehogInfo{name: name.to_string(), hat: hat.to_string()})));
named!(_8_hogs<&[u8], [HedgehogInfo; 8]>,
    do_parse!(h1: hog_line >> eol >> h2: hog_line >> eol >>
              h3: hog_line >> eol >> h4: hog_line >> eol >>
              h5: hog_line >> eol >> h6: hog_line >> eol >>
              h7: hog_line >> eol >> h8: hog_line >>
              ([h1, h2, h3, h4, h5, h6, h7, h8])));

named!(basic_message<&[u8], HWProtocolMessage>, alt!(
      do_parse!(tag!("PING") >> (Ping))
    | do_parse!(tag!("PONG") >> (Pong))
    | do_parse!(tag!("LIST") >> (List))
    | do_parse!(tag!("BANLIST")        >> (BanList))
    | do_parse!(tag!("GET_SERVER_VAR") >> (GetServerVar))
    | do_parse!(tag!("TOGGLE_READY")   >> (ToggleReady))
    | do_parse!(tag!("START_GAME")     >> (StartGame))
    | do_parse!(tag!("ROUNDFINISHED")  >> m: opt_param >> (RoundFinished))
    | do_parse!(tag!("TOGGLE_RESTRICT_JOINS")  >> (ToggleRestrictJoin))
    | do_parse!(tag!("TOGGLE_RESTRICT_TEAMS")  >> (ToggleRestrictTeams))
    | do_parse!(tag!("TOGGLE_REGISTERED_ONLY") >> (ToggleRegisteredOnly))
));

named!(one_param_message<&[u8], HWProtocolMessage>, alt!(
      do_parse!(tag!("NICK")    >> eol >> n: a_line >> (Nick(n)))
    | do_parse!(tag!("INFO")    >> eol >> n: a_line >> (Info(n)))
    | do_parse!(tag!("CHAT")    >> eol >> m: a_line >> (Chat(m)))
    | do_parse!(tag!("PART")    >> msg: opt_param   >> (Part(msg)))
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
    | do_parse!(tag!("JOIN_ROOM")   >> eol >>
                    n: a_line       >>
                    p: opt_param    >>
                    (JoinRoom(n, p)))
    | do_parse!(tag!("ADD_TEAM")    >> eol >>
                    name: a_line    >> eol >>
                    color: u8_line  >> eol >>
                    grave: a_line   >> eol >>
                    fort: a_line    >> eol >>
                    voice_pack: a_line >> eol >>
                    flag: a_line    >> eol >>
                    difficulty: u8_line >> eol >>
                    hedgehogs: _8_hogs >>
                    (AddTeam(TeamInfo{
                        name, color, grave, fort,
                        voice_pack, flag, difficulty,
                        hedgehogs, hedgehogs_number: 0
                     })))
    | do_parse!(tag!("HH_NUM")    >> eol >>
                    n: a_line     >> eol >>
                    c: u8_line    >>
                    (SetHedgehogsNumber(n, c)))
    | do_parse!(tag!("TEAM_COLOR")    >> eol >>
                    n: a_line     >> eol >>
                    c: u8_line    >>
                    (SetTeamColor(n, c)))
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

named!(cfg_message<&[u8], HWProtocolMessage>, preceded!(tag!("CFG\n"), map!(alt!(
      do_parse!(tag!("THEME")    >> eol >>
                name: a_line     >>
                (GameCfg::Theme(name)))
    | do_parse!(tag!("SCRIPT")   >> eol >>
                name: a_line     >>
                (GameCfg::Script(name)))
    | do_parse!(tag!("AMMO")     >> eol >>
                name: a_line     >>
                value: opt_param >>
                (GameCfg::Ammo(name, value)))
    | do_parse!(tag!("SCHEME")   >> eol >>
                name: a_line     >> eol >>
                values: separated_list!(eol, a_line) >>
                (GameCfg::Scheme(name,
                    if values.is_empty() {None} else {Some(values)})))
    | do_parse!(tag!("FEATURE_SIZE") >> eol >>
                value: u32_line    >>
                (GameCfg::FeatureSize(value)))
    | do_parse!(tag!("MAP")      >> eol >>
                value: a_line    >>
                (GameCfg::MapType(value)))
    | do_parse!(tag!("MAPGEN")   >> eol >>
                value: u32_line  >>
                (GameCfg::MapGenerator(value)))
    | do_parse!(tag!("MAZE_SIZE") >> eol >>
                value: u32_line   >>
                (GameCfg::MazeSize(value)))
    | do_parse!(tag!("SEED")     >> eol >>
                value: a_line    >>
                (GameCfg::Seed(value)))
    | do_parse!(tag!("TEMPLATE") >> eol >>
                value: u32_line  >>
                (GameCfg::Template(value)))
    | do_parse!(tag!("DRAWNMAP") >> eol >>
                value: a_line    >>
                (GameCfg::DrawnMap(value)))
), Cfg)));

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
        | cfg_message
        ), end_of_message
    )
    | terminated!(malformed_message, end_of_message)
    | empty_message
    )
);

named!(pub extract_messages<&[u8], Vec<HWProtocolMessage> >, many0!(complete!(message)));

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