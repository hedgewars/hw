use nom::*;

use std::str;
use std::str::FromStr;
use super::messages::HWProtocolMessage;
use super::messages::HWProtocolMessage::*;

named!(end_of_message, tag!("\n\n"));
named!(a_line<&[u8], &str>, map_res!(not_line_ending, str::from_utf8));
named!( u8_line<&[u8],  u8>, map_res!(a_line, FromStr::from_str));
named!(u32_line<&[u8], u32>, map_res!(a_line, FromStr::from_str));
named!(opt_param<&[u8], Option<&str> >, opt!(flat_map!(preceded!(eol, a_line), non_empty)));

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
    | do_parse!(tag_no_case!("PART")     >> eol >> m: opt_param >> (Quit(m)))
    | do_parse!(tag_no_case!("QUIT")     >> eol >> m: opt_param >> (Part(m)))
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

named!(message<&[u8], HWProtocolMessage>, terminated!(alt!(
      basic_message
    | one_param_message
    | cmd_message
    | complex_message
    ), end_of_message
));

named!(pub extract_messages<&[u8], Vec<HWProtocolMessage> >, many0!(complete!(message)));

#[test]
fn parse_test() {
    assert_eq!(message(b"PING\n\n"),          IResult::Done(&b""[..], Ping));
    assert_eq!(message(b"START_GAME\n\n"),    IResult::Done(&b""[..], StartGame));
    assert_eq!(message(b"NICK\nit's me\n\n"), IResult::Done(&b""[..], Nick("it's me")));
    assert_eq!(message(b"PROTO\n51\n\n"),     IResult::Done(&b""[..], Proto(51)));
    assert_eq!(message(b"QUIT\nbye-bye\n\n"), IResult::Done(&b""[..], Quit(Some("bye-bye"))));
    assert_eq!(message(b"QUIT\n\n"),          IResult::Done(&b""[..], Quit(None)));
    assert_eq!(message(b"CMD\nwatch\ndemo\n\n"), IResult::Done(&b""[..], Watch("demo")));
    assert_eq!(message(b"BAN\nme\nbad\n77\n\n"), IResult::Done(&b""[..], Ban("me", "bad", 77)));

    assert_eq!(extract_messages(b"PING\n\nPING\n\nP"),   IResult::Done(&b"P"[..], vec![Ping, Ping]));
}
