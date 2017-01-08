use nom::*;

use std::str;
use std::str::FromStr;
use super::messages::HWProtocolMessage;
use super::messages::HWProtocolMessage::*;

named!(end_of_message, tag!("\n\n"));
named!(a_line<&[u8], &str>, map_res!(not_line_ending, str::from_utf8));
//fn number_line<T>(input: &[u8]) -> IResult<&[u8], T> {
//}
named!(basic_message<&[u8], HWProtocolMessage>, alt!(
    do_parse!(tag!("PING") >> (Ping))
    | do_parse!(tag!("PONG") >> (Pong))
    | do_parse!(tag!("LIST") >> (List))
    | do_parse!(tag!("BANLIST") >> (BanList))
    | do_parse!(tag!("GET_SERVER_VAR") >> (GetServerVar))
    | do_parse!(tag!("TOGGLE_READY") >> (ToggleReady))
    | do_parse!(tag!("START_GAME") >> (StartGame))
    | do_parse!(tag!("ROUNDFINISHED") >> (RoundFinished))
    | do_parse!(tag!("TOGGLE_RESTRICT_JOINS") >> (ToggleRestrictJoin))
    | do_parse!(tag!("TOGGLE_RESTRICT_TEAMS") >> (ToggleRestrictTeams))
    | do_parse!(tag!("TOGGLE_REGISTERED_ONLY") >> (ToggleRegisteredOnly))
));

named!(one_param_message<&[u8], HWProtocolMessage>, alt!(
    do_parse!(tag!("NICK") >> eol >> n: a_line >> (Nick(n)))
    | do_parse!(tag!("PROTO") >> eol >> d: map_res!(a_line, FromStr::from_str) >> (Proto(d)))
));

named!(message<&[u8],HWProtocolMessage>, terminated!(alt!(
    basic_message
    | one_param_message
), end_of_message));

named!(messages<&[u8], Vec<HWProtocolMessage> >, many0!(message));

#[test]
fn parse_test() {
    assert_eq!(message(b"PING\n\n"), IResult::Done(&b""[..], Ping));
    assert_eq!(message(b"START_GAME\n\n"), IResult::Done(&b""[..], StartGame));
    assert_eq!(message(b"NICK\nit's me\n\n"), IResult::Done(&b""[..], Nick("it's me")));
    assert_eq!(message(b"PROTO\n51\n\n"), IResult::Done(&b""[..], Proto(51)));
}
