/** The parsers for the chat and multiplayer protocol. The main parser is `message`.
 * # Protocol
 * All messages consist of `\n`-separated strings. The end of a message is
 * indicated by a double newline - `\n\n`.
 *
 * For example, a nullary command like PING will be actually sent as `PING\n\n`.
 * A unary command, such as `START_GAME nick` will be actually sent as `START_GAME\nnick\n\n`.
 */
use nom::{
    branch::alt,
    bytes::complete::{tag, tag_no_case, take_until, take_while},
    character::complete::{newline, not_line_ending},
    combinator::{map, peek},
    error::{ErrorKind, ParseError},
    multi::separated_list0,
    sequence::{delimited, pair, preceded, terminated, tuple},
    Err, IResult,
};

use std::{
    num::ParseIntError,
    ops::Range,
    str,
    str::{FromStr, Utf8Error},
};

use super::messages::{HwProtocolMessage, HwProtocolMessage::*};
use crate::core::types::{
    GameCfg, HedgehogInfo, ServerVar, TeamInfo, VoteType, MAX_HEDGEHOGS_PER_TEAM,
};

#[derive(Debug, PartialEq)]
pub struct HwProtocolError {}

impl HwProtocolError {
    fn new() -> Self {
        HwProtocolError {}
    }
}

impl<I> ParseError<I> for HwProtocolError {
    fn from_error_kind(input: I, kind: ErrorKind) -> Self {
        HwProtocolError::new()
    }

    fn append(input: I, kind: ErrorKind, other: Self) -> Self {
        HwProtocolError::new()
    }
}

impl From<Utf8Error> for HwProtocolError {
    fn from(_: Utf8Error) -> Self {
        HwProtocolError::new()
    }
}

impl From<ParseIntError> for HwProtocolError {
    fn from(_: ParseIntError) -> Self {
        HwProtocolError::new()
    }
}

pub type HwResult<'a, O> = IResult<&'a [u8], O, HwProtocolError>;

fn end_of_message(input: &[u8]) -> HwResult<&[u8]> {
    tag("\n\n")(input)
}

fn convert_utf8(input: &[u8]) -> HwResult<&str> {
    match str::from_utf8(input) {
        Ok(str) => Ok((b"", str)),
        Err(utf_err) => Result::Err(Err::Failure(utf_err.into())),
    }
}

fn convert_from_str<T>(str: &str) -> HwResult<T>
where
    T: FromStr<Err = ParseIntError>,
{
    match T::from_str(str) {
        Ok(x) => Ok((b"", x)),
        Err(format_err) => Result::Err(Err::Failure(format_err.into())),
    }
}

fn str_line(input: &[u8]) -> HwResult<&str> {
    let (i, text) = not_line_ending(input.clone())?;
    if i != input {
        Ok((i, convert_utf8(text)?.1))
    } else {
        Err(Err::Error(HwProtocolError::new()))
    }
}

fn a_line(input: &[u8]) -> HwResult<String> {
    map(str_line, String::from)(input)
}

fn cmd_arg(input: &[u8]) -> HwResult<String> {
    let delimiters = b" \n";
    let (i, str) = take_while(move |c| !delimiters.contains(&c))(input.clone())?;
    if i != input {
        Ok((i, convert_utf8(str)?.1.to_string()))
    } else {
        Err(Err::Error(HwProtocolError::new()))
    }
}

fn u8_line(input: &[u8]) -> HwResult<u8> {
    let (i, str) = str_line(input)?;
    Ok((i, convert_from_str(str)?.1))
}

fn u16_line(input: &[u8]) -> HwResult<u16> {
    let (i, str) = str_line(input)?;
    Ok((i, convert_from_str(str)?.1))
}

fn u32_line(input: &[u8]) -> HwResult<u32> {
    let (i, str) = str_line(input)?;
    Ok((i, convert_from_str(str)?.1))
}

fn yes_no_line(input: &[u8]) -> HwResult<bool> {
    alt((
        map(tag_no_case(b"YES"), |_| true),
        map(tag_no_case(b"NO"), |_| false),
    ))(input)
}

fn opt_arg<'a>(input: &'a [u8]) -> HwResult<'a, Option<String>> {
    alt((
        map(peek(end_of_message), |_| None),
        map(preceded(tag("\n"), a_line), Some),
    ))(input)
}

fn spaces(input: &[u8]) -> HwResult<&[u8]> {
    preceded(tag(" "), take_while(|c| c == b' '))(input)
}

fn opt_space_arg<'a>(input: &'a [u8]) -> HwResult<'a, Option<String>> {
    alt((
        map(peek(end_of_message), |_| None),
        map(preceded(spaces, a_line), Some),
    ))(input)
}

fn hedgehog_array(input: &[u8]) -> HwResult<[HedgehogInfo; 8]> {
    fn hedgehog_line(input: &[u8]) -> HwResult<HedgehogInfo> {
        map(
            tuple((terminated(a_line, newline), a_line)),
            |(name, hat)| HedgehogInfo { name, hat },
        )(input)
    }

    let (i, (h1, h2, h3, h4, h5, h6, h7, h8)) = tuple((
        terminated(hedgehog_line, newline),
        terminated(hedgehog_line, newline),
        terminated(hedgehog_line, newline),
        terminated(hedgehog_line, newline),
        terminated(hedgehog_line, newline),
        terminated(hedgehog_line, newline),
        terminated(hedgehog_line, newline),
        hedgehog_line,
    ))(input)?;

    Ok((i, [h1, h2, h3, h4, h5, h6, h7, h8]))
}

fn voting(input: &[u8]) -> HwResult<VoteType> {
    alt((
        map(tag_no_case("PAUSE"), |_| VoteType::Pause),
        map(tag_no_case("NEWSEED"), |_| VoteType::NewSeed),
        map(
            preceded(pair(tag_no_case("KICK"), spaces), a_line),
            VoteType::Kick,
        ),
        map(
            preceded(pair(tag_no_case("HEDGEHOGS"), spaces), u8_line),
            VoteType::HedgehogsPerTeam,
        ),
        map(preceded(tag_no_case("MAP"), opt_space_arg), VoteType::Map),
    ))(input)
}

fn no_arg_message(input: &[u8]) -> HwResult<HwProtocolMessage> {
    fn message<'a>(
        name: &'a str,
        msg: HwProtocolMessage,
    ) -> impl Fn(&'a [u8]) -> HwResult<'a, HwProtocolMessage> {
        move |i| map(tag(name), |_| msg.clone())(i)
    }

    alt((
        message("PING", Ping),
        message("PONG", Pong),
        message("LIST", List),
        message("BANLIST", BanList),
        message("GET_SERVER_VAR", GetServerVar),
        message("TOGGLE_READY", ToggleReady),
        message("START_GAME", StartGame),
        message("TOGGLE_RESTRICT_JOINS", ToggleRestrictJoin),
        message("TOGGLE_RESTRICT_TEAMS", ToggleRestrictTeams),
        message("TOGGLE_REGISTERED_ONLY", ToggleRegisteredOnly),
    ))(input)
}

fn single_arg_message(input: &[u8]) -> HwResult<HwProtocolMessage> {
    fn message<'a, T, F, G>(
        name: &'a str,
        parser: F,
        constructor: G,
    ) -> impl FnMut(&'a [u8]) -> HwResult<'a, HwProtocolMessage>
    where
        F: Fn(&[u8]) -> HwResult<T>,
        G: Fn(T) -> HwProtocolMessage,
    {
        map(preceded(tag(name), parser), constructor)
    }

    alt((
        message("NICK\n", a_line, Nick),
        message("INFO\n", a_line, Info),
        message("CHAT\n", a_line, Chat),
        message("PART", opt_arg, Part),
        message("FOLLOW\n", a_line, Follow),
        message("KICK\n", a_line, Kick),
        message("UNBAN\n", a_line, Unban),
        message("EM\n", a_line, EngineMessage),
        message("TEAMCHAT\n", a_line, TeamChat),
        message("ROOM_NAME\n", a_line, RoomName),
        message("REMOVE_TEAM\n", a_line, RemoveTeam),
        message("ROUNDFINISHED", opt_arg, |_| RoundFinished),
        message("PROTO\n", u16_line, Proto),
        message("QUIT", opt_arg, Quit),
    ))(input)
}

fn cmd_message<'a>(input: &'a [u8]) -> HwResult<'a, HwProtocolMessage> {
    fn cmd_no_arg<'a>(
        name: &'a str,
        msg: HwProtocolMessage,
    ) -> impl Fn(&'a [u8]) -> HwResult<'a, HwProtocolMessage> {
        move |i| map(tag_no_case(name), |_| msg.clone())(i)
    }

    fn cmd_single_arg<'a, T, F, G>(
        name: &'a str,
        parser: F,
        constructor: G,
    ) -> impl FnMut(&'a [u8]) -> HwResult<'a, HwProtocolMessage>
    where
        F: Fn(&'a [u8]) -> HwResult<'a, T>,
        G: Fn(T) -> HwProtocolMessage,
    {
        map(
            preceded(pair(tag_no_case(name), spaces), parser),
            constructor,
        )
    }

    fn cmd_no_arg_message(input: &[u8]) -> HwResult<HwProtocolMessage> {
        alt((
            cmd_no_arg("STATS", Stats),
            cmd_no_arg("FIX", Fix),
            cmd_no_arg("UNFIX", Unfix),
            cmd_no_arg("REGISTERED_ONLY", ToggleServerRegisteredOnly),
            cmd_no_arg("SUPER_POWER", SuperPower),
        ))(input)
    }

    fn cmd_single_arg_message(input: &[u8]) -> HwResult<HwProtocolMessage> {
        alt((
            cmd_single_arg("RESTART_SERVER", |i| tag("YES")(i), |_| RestartServer),
            cmd_single_arg("DELEGATE", a_line, Delegate),
            cmd_single_arg("DELETE", a_line, Delete),
            cmd_single_arg("SAVEROOM", a_line, SaveRoom),
            cmd_single_arg("LOADROOM", a_line, LoadRoom),
            cmd_single_arg("GLOBAL", a_line, Global),
            cmd_single_arg("WATCH", u32_line, Watch),
            cmd_single_arg("VOTE", yes_no_line, Vote),
            cmd_single_arg("FORCE", yes_no_line, ForceVote),
            cmd_single_arg("INFO", a_line, Info),
            cmd_single_arg("MAXTEAMS", u8_line, MaxTeams),
            cmd_single_arg("CALLVOTE", voting, |v| CallVote(Some(v))),
        ))(input)
    }

    preceded(
        tag("CMD\n"),
        alt((
            cmd_no_arg_message,
            cmd_single_arg_message,
            map(tag_no_case("CALLVOTE"), |_| CallVote(None)),
            map(preceded(tag_no_case("GREETING"), opt_space_arg), Greeting),
            map(preceded(tag_no_case("PART"), opt_space_arg), Part),
            map(preceded(tag_no_case("QUIT"), opt_space_arg), Quit),
            map(
                preceded(
                    tag_no_case("SAVE"),
                    pair(preceded(spaces, cmd_arg), preceded(spaces, cmd_arg)),
                ),
                |(n, l)| Save(n, l),
            ),
            map(
                preceded(
                    tag_no_case("RND"),
                    alt((
                        map(peek(end_of_message), |_| vec![]),
                        preceded(spaces, separated_list0(spaces, cmd_arg)),
                    )),
                ),
                Rnd,
            ),
        )),
    )(input)
}

fn config_message<'a>(input: &'a [u8]) -> HwResult<'a, HwProtocolMessage> {
    fn cfg_single_arg<'a, T, F, G>(
        name: &'a str,
        parser: F,
        constructor: G,
    ) -> impl FnMut(&'a [u8]) -> HwResult<'a, GameCfg>
    where
        F: Fn(&[u8]) -> HwResult<T>,
        G: Fn(T) -> GameCfg,
    {
        map(preceded(pair(tag(name), newline), parser), constructor)
    }

    let (i, cfg) = preceded(
        tag("CFG\n"),
        alt((
            cfg_single_arg("THEME", a_line, GameCfg::Theme),
            cfg_single_arg("SCRIPT", a_line, GameCfg::Script),
            cfg_single_arg("MAP", a_line, GameCfg::MapType),
            cfg_single_arg("MAPGEN", u32_line, GameCfg::MapGenerator),
            cfg_single_arg("MAZE_SIZE", u32_line, GameCfg::MazeSize),
            cfg_single_arg("TEMPLATE", u32_line, GameCfg::Template),
            cfg_single_arg("FEATURE_SIZE", u32_line, GameCfg::FeatureSize),
            cfg_single_arg("SEED", a_line, GameCfg::Seed),
            cfg_single_arg("DRAWNMAP", a_line, GameCfg::DrawnMap),
            preceded(pair(tag("AMMO"), newline), |i| {
                let (i, name) = a_line(i)?;
                let (i, value) = opt_arg(i)?;
                Ok((i, GameCfg::Ammo(name, value)))
            }),
            preceded(
                pair(tag("SCHEME"), newline),
                map(
                    pair(
                        a_line,
                        alt((
                            map(peek(end_of_message), |_| None),
                            map(preceded(newline, separated_list0(newline, a_line)), Some),
                        )),
                    ),
                    |(name, values)| GameCfg::Scheme(name, values.unwrap_or_default()),
                ),
            ),
        )),
    )(input)?;
    Ok((i, Cfg(cfg)))
}

fn server_var_message(input: &[u8]) -> HwResult<HwProtocolMessage> {
    map(
        preceded(
            tag("SET_SERVER_VAR\n"),
            alt((
                map(preceded(tag("MOTD_NEW\n"), a_line), ServerVar::MOTDNew),
                map(preceded(tag("MOTD_OLD\n"), a_line), ServerVar::MOTDOld),
                map(
                    preceded(tag("LATEST_PROTO\n"), u16_line),
                    ServerVar::LatestProto,
                ),
            )),
        ),
        SetServerVar,
    )(input)
}

fn complex_message(input: &[u8]) -> HwResult<HwProtocolMessage> {
    alt((
        preceded(
            pair(tag("PASSWORD"), newline),
            map(pair(terminated(a_line, newline), a_line), |(pass, salt)| {
                Password(pass, salt)
            }),
        ),
        preceded(
            pair(tag("CHECKER"), newline),
            map(
                tuple((
                    terminated(u16_line, newline),
                    terminated(a_line, newline),
                    a_line,
                )),
                |(protocol, name, pass)| Checker(protocol, name, pass),
            ),
        ),
        preceded(
            pair(tag("CREATE_ROOM"), newline),
            map(pair(a_line, opt_arg), |(name, pass)| CreateRoom(name, pass)),
        ),
        preceded(
            pair(tag("JOIN_ROOM"), newline),
            map(pair(a_line, opt_arg), |(name, pass)| JoinRoom(name, pass)),
        ),
        preceded(
            pair(tag("ADD_TEAM"), newline),
            map(
                tuple((
                    terminated(a_line, newline),
                    terminated(u8_line, newline),
                    terminated(a_line, newline),
                    terminated(a_line, newline),
                    terminated(a_line, newline),
                    terminated(a_line, newline),
                    terminated(u8_line, newline),
                    hedgehog_array,
                )),
                |(name, color, grave, fort, voice_pack, flag, difficulty, hedgehogs)| {
                    AddTeam(Box::new(TeamInfo {
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
                    }))
                },
            ),
        ),
        preceded(
            pair(tag("HH_NUM"), newline),
            map(
                pair(terminated(a_line, newline), u8_line),
                |(name, count)| SetHedgehogsNumber(name, count),
            ),
        ),
        preceded(
            pair(tag("TEAM_COLOR"), newline),
            map(
                pair(terminated(a_line, newline), u8_line),
                |(name, color)| SetTeamColor(name, color),
            ),
        ),
        preceded(
            pair(tag("BAN"), newline),
            map(
                tuple((
                    terminated(a_line, newline),
                    terminated(a_line, newline),
                    u32_line,
                )),
                |(name, reason, time)| Ban(name, reason, time),
            ),
        ),
        preceded(
            pair(tag("BAN_IP"), newline),
            map(
                tuple((
                    terminated(a_line, newline),
                    terminated(a_line, newline),
                    u32_line,
                )),
                |(ip, reason, time)| BanIp(ip, reason, time),
            ),
        ),
        preceded(
            pair(tag("BAN_NICK"), newline),
            map(
                tuple((
                    terminated(a_line, newline),
                    terminated(a_line, newline),
                    u32_line,
                )),
                |(nick, reason, time)| BanNick(nick, reason, time),
            ),
        ),
    ))(input)
}

pub fn malformed_message(input: &[u8]) -> HwResult<()> {
    map(terminated(take_until(&b"\n\n"[..]), end_of_message), |_| ())(input)
}

pub fn message(input: &[u8]) -> HwResult<HwProtocolMessage> {
    delimited(
        take_while(|c| c == b'\n'),
        alt((
            no_arg_message,
            single_arg_message,
            cmd_message,
            config_message,
            server_var_message,
            complex_message,
        )),
        end_of_message,
    )(input)
}

#[cfg(test)]
mod test {
    use super::message;
    use crate::{
        core::types::GameCfg,
        protocol::{messages::HwProtocolMessage::*, parser::HwProtocolError, test::gen_proto_msg},
    };
    use proptest::{proptest, proptest_helper};

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
            message(b"CMD\nwatch 49471\n\n"),
            Ok((&b""[..], Watch(49471)))
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
            message(b"CFG\nSCHEME\na\nA\n\n"),
            Ok((
                &b""[..],
                Cfg(GameCfg::Scheme("a".to_string(), vec!["A".to_string()]))
            ))
        );

        assert_eq!(
            message(b"QUIT\n1\n2\n\n"),
            Err(nom::Err::Error(HwProtocolError::new()))
        );
    }
}
