/** The parsers for the chat and multiplayer protocol. The main parser is `message`.
 * # Protocol
 * All messages consist of `\n`-separated strings. The end of a message is
 * indicated by a double newline - `\n\n`.
 *
 * For example, a nullary command like PING will be actually sent as `PING\n\n`.
 * A unary command, such as `START_GAME nick` will be actually sent as `START_GAME\nnick\n\n`.
 */
use nom::*;

use super::messages::{HWProtocolMessage, HWProtocolMessage::*};
use crate::server::coretypes::{GameCfg, HedgehogInfo, TeamInfo, VoteType, MAX_HEDGEHOGS_PER_TEAM};
use std::{ops::Range, str, str::FromStr};
#[cfg(test)]
use {
    super::test::gen_proto_msg,
    proptest::{proptest, proptest_helper},
};

named!(end_of_message, tag!("\n\n"));
named!(str_line<&[u8],   &str>, map_res!(not_line_ending, str::from_utf8));
named!(  a_line<&[u8], String>, map!(str_line, String::from));
named!(cmd_arg<&[u8], String>,
    map!(map_res!(take_until_either!(" \n"), str::from_utf8), String::from));
named!( u8_line<&[u8],     u8>, map_res!(str_line, FromStr::from_str));
named!(u16_line<&[u8],    u16>, map_res!(str_line, FromStr::from_str));
named!(u32_line<&[u8],    u32>, map_res!(str_line, FromStr::from_str));
named!(yes_no_line<&[u8], bool>, alt!(
      do_parse!(tag_no_case!("YES") >> (true))
    | do_parse!(tag_no_case!("NO") >> (false))));
named!(opt_param<&[u8], Option<String> >, alt!(
      do_parse!(peek!(tag!("\n\n")) >> (None))
    | do_parse!(tag!("\n") >> s: str_line >> (Some(s.to_string())))));
named!(spaces<&[u8], &[u8]>, preceded!(tag!(" "), eat_separator!(" ")));
named!(opt_space_param<&[u8], Option<String> >, alt!(
      do_parse!(peek!(tag!("\n\n")) >> (None))
    | do_parse!(spaces >> s: str_line >> (Some(s.to_string())))));
named!(hog_line<&[u8], HedgehogInfo>,
    do_parse!(name: str_line >> eol >> hat: str_line >>
        (HedgehogInfo{name: name.to_string(), hat: hat.to_string()})));
named!(_8_hogs<&[u8], [HedgehogInfo; MAX_HEDGEHOGS_PER_TEAM as usize]>,
    do_parse!(h1: hog_line >> eol >> h2: hog_line >> eol >>
              h3: hog_line >> eol >> h4: hog_line >> eol >>
              h5: hog_line >> eol >> h6: hog_line >> eol >>
              h7: hog_line >> eol >> h8: hog_line >>
              ([h1, h2, h3, h4, h5, h6, h7, h8])));
named!(voting<&[u8], VoteType>, alt!(
      do_parse!(tag_no_case!("KICK") >> spaces >> n: a_line >>
        (VoteType::Kick(n)))
    | do_parse!(tag_no_case!("MAP") >>
        n: opt!(preceded!(spaces, a_line)) >>
        (VoteType::Map(n)))
    | do_parse!(tag_no_case!("PAUSE") >>
        (VoteType::Pause))
    | do_parse!(tag_no_case!("NEWSEED") >>
        (VoteType::NewSeed))
    | do_parse!(tag_no_case!("HEDGEHOGS") >> spaces >> n: u8_line >>
        (VoteType::HedgehogsPerTeam(n)))));

/** Recognizes messages which do not take any parameters */
named!(basic_message<&[u8], HWProtocolMessage>, alt!(
      do_parse!(tag!("PING") >> (Ping))
    | do_parse!(tag!("PONG") >> (Pong))
    | do_parse!(tag!("LIST") >> (List))
    | do_parse!(tag!("BANLIST")        >> (BanList))
    | do_parse!(tag!("GET_SERVER_VAR") >> (GetServerVar))
    | do_parse!(tag!("TOGGLE_READY")   >> (ToggleReady))
    | do_parse!(tag!("START_GAME")     >> (StartGame))
    | do_parse!(tag!("ROUNDFINISHED")  >> _m: opt_param >> (RoundFinished))
    | do_parse!(tag!("TOGGLE_RESTRICT_JOINS")  >> (ToggleRestrictJoin))
    | do_parse!(tag!("TOGGLE_RESTRICT_TEAMS")  >> (ToggleRestrictTeams))
    | do_parse!(tag!("TOGGLE_REGISTERED_ONLY") >> (ToggleRegisteredOnly))
));

/** Recognizes messages which take exactly one parameter */
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

    | do_parse!(tag!("PROTO")   >> eol >> d: u16_line >> (Proto(d)))

    | do_parse!(tag!("QUIT")   >> msg: opt_param >> (Quit(msg)))
));

/** Recognizes messages preceded with CMD */
named!(cmd_message<&[u8], HWProtocolMessage>, preceded!(tag!("CMD\n"), alt!(
      do_parse!(tag_no_case!("STATS") >> (Stats))
    | do_parse!(tag_no_case!("FIX")   >> (Fix))
    | do_parse!(tag_no_case!("UNFIX") >> (Unfix))
    | do_parse!(tag_no_case!("RESTART_SERVER") >> spaces >> tag!("YES") >> (RestartServer))
    | do_parse!(tag_no_case!("REGISTERED_ONLY") >> (ToggleServerRegisteredOnly))
    | do_parse!(tag_no_case!("SUPER_POWER")     >> (SuperPower))
    | do_parse!(tag_no_case!("PART")     >> m: opt_space_param >> (Part(m)))
    | do_parse!(tag_no_case!("QUIT")     >> m: opt_space_param >> (Quit(m)))
    | do_parse!(tag_no_case!("DELEGATE") >> spaces >> n: a_line  >> (Delegate(n)))
    | do_parse!(tag_no_case!("SAVE")     >> spaces >> n: cmd_arg >> spaces >> l: cmd_arg >> (Save(n, l)))
    | do_parse!(tag_no_case!("DELETE")   >> spaces >> n: a_line  >> (Delete(n)))
    | do_parse!(tag_no_case!("SAVEROOM") >> spaces >> r: a_line  >> (SaveRoom(r)))
    | do_parse!(tag_no_case!("LOADROOM") >> spaces >> r: a_line  >> (LoadRoom(r)))
    | do_parse!(tag_no_case!("GLOBAL")   >> spaces >> m: a_line  >> (Global(m)))
    | do_parse!(tag_no_case!("WATCH")    >> spaces >> i: a_line  >> (Watch(i)))
    | do_parse!(tag_no_case!("GREETING") >> spaces >> m: a_line  >> (Greeting(m)))
    | do_parse!(tag_no_case!("VOTE")     >> spaces >> m: yes_no_line >> (Vote(m)))
    | do_parse!(tag_no_case!("FORCE")    >> spaces >> m: yes_no_line >> (ForceVote(m)))
    | do_parse!(tag_no_case!("INFO")     >> spaces >> n: a_line  >> (Info(n)))
    | do_parse!(tag_no_case!("MAXTEAMS") >> spaces >> n: u8_line >> (MaxTeams(n)))
    | do_parse!(tag_no_case!("CALLVOTE") >>
        v: opt!(preceded!(spaces, voting)) >> (CallVote(v)))
    | do_parse!(
        tag_no_case!("RND") >> alt!(spaces | peek!(end_of_message)) >>
        v: str_line >>
        (Rnd(v.split_whitespace().map(String::from).collect())))
)));

named!(complex_message<&[u8], HWProtocolMessage>, alt!(
      do_parse!(tag!("PASSWORD")  >> eol >>
                    p: a_line     >> eol >>
                    s: a_line     >>
                    (Password(p, s)))
    | do_parse!(tag!("CHECKER")   >> eol >>
                    i: u16_line   >> eol >>
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
                    (AddTeam(Box::new(TeamInfo{
                        name, color, grave, fort,
                        voice_pack, flag, difficulty,
                        hedgehogs, hedgehogs_number: 0
                     }))))
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
                name: a_line     >>
                values: opt!(preceded!(eol, separated_list!(eol, a_line))) >>
                (GameCfg::Scheme(name, values.unwrap_or_default())))
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

#[cfg(test)]
proptest! {
    #[test]
    fn is_parser_composition_idempotent(ref msg in gen_proto_msg()) {
        println!("!! Msg: {:?}, Bytes: {:?} !!", msg, msg.to_raw_protocol().as_bytes());
        assert_eq!(message(msg.to_raw_protocol().as_bytes()), Ok((&b""[..], msg.clone())))
    }
}

#[test]
fn parse_test() {
    assert_eq!(message(b"PING\n\n"), Ok((&b""[..], Ping)));
    assert_eq!(message(b"START_GAME\n\n"), Ok((&b""[..], StartGame)));
    assert_eq!(
        message(b"NICK\nit's me\n\n"),
        Ok((&b""[..], Nick("it's me".to_string())))
    );
    assert_eq!(message(b"PROTO\n51\n\n"), Ok((&b""[..], Proto(51))));
    assert_eq!(
        message(b"QUIT\nbye-bye\n\n"),
        Ok((&b""[..], Quit(Some("bye-bye".to_string()))))
    );
    assert_eq!(message(b"QUIT\n\n"), Ok((&b""[..], Quit(None))));
    assert_eq!(
        message(b"CMD\nwatch demo\n\n"),
        Ok((&b""[..], Watch("demo".to_string())))
    );
    assert_eq!(
        message(b"BAN\nme\nbad\n77\n\n"),
        Ok((&b""[..], Ban("me".to_string(), "bad".to_string(), 77)))
    );

    assert_eq!(message(b"CMD\nPART\n\n"), Ok((&b""[..], Part(None))));
    assert_eq!(
        message(b"CMD\nPART _msg_\n\n"),
        Ok((&b""[..], Part(Some("_msg_".to_string()))))
    );

    assert_eq!(message(b"CMD\nRND\n\n"), Ok((&b""[..], Rnd(vec![]))));
    assert_eq!(
        message(b"CMD\nRND A B\n\n"),
        Ok((&b""[..], Rnd(vec![String::from("A"), String::from("B")])))
    );

    assert_eq!(
        extract_messages(b"QUIT\n1\n2\n\n"),
        Ok((&b""[..], vec![Malformed]))
    );

    assert_eq!(
        extract_messages(b"PING\n\nPING\n\nP"),
        Ok((&b"P"[..], vec![Ping, Ping]))
    );
    assert_eq!(
        extract_messages(b"SING\n\nPING\n\n"),
        Ok((&b""[..], vec![Malformed, Ping]))
    );
    assert_eq!(
        extract_messages(b"\n\n\n\nPING\n\n"),
        Ok((&b""[..], vec![Empty, Empty, Ping]))
    );
    assert_eq!(
        extract_messages(b"\n\n\nPING\n\n"),
        Ok((&b""[..], vec![Empty, Empty, Ping]))
    );
}
