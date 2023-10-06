use std::str;

use nom::branch::alt;
use nom::bytes::streaming::*;
use nom::combinator::*;
use nom::error::{ErrorKind, ParseError};
use nom::multi::*;
use nom::number::streaming::*;
use nom::sequence::{pair, preceded, terminated, tuple};
use nom::{Err, IResult, Parser};

use crate::messages::{
    ConfigEngineMessage::*, EngineMessage::*, KeystrokeAction::*, SyncedEngineMessage::*,
    UnorderedEngineMessage::*, *,
};

fn eof_slice<I>(i: I) -> IResult<I, I>
where
    I: nom::InputLength + Clone,
{
    if i.input_len() == 0 {
        Ok((i.clone(), i))
    } else {
        Err(Err::Error(nom::error::Error::new(i, ErrorKind::Eof)))
    }
}
fn unrecognized_message(input: &[u8]) -> IResult<&[u8], EngineMessage> {
    map(rest, |i: &[u8]| Unknown(i.to_owned()))(input)
}

fn string_tail(input: &[u8]) -> IResult<&[u8], String> {
    map_res(rest, str::from_utf8)(input).map(|(i, s)| (i, s.to_owned()))
}

fn length_without_timestamp(input: &[u8]) -> IResult<&[u8], usize> {
    map_opt(rest_len, |l| if l > 2 { Some(l - 2) } else { None })(input)
}

fn synced_message(input: &[u8]) -> IResult<&[u8], SyncedEngineMessage> {
    alt((
        alt((
            map(tag(b"L"), |_| Left(Press)),
            map(tag(b"l"), |_| Left(Release)),
            map(tag(b"R"), |_| Right(Press)),
            map(tag(b"r"), |_| Right(Release)),
            map(tag(b"U"), |_| Up(Press)),
            map(tag(b"u"), |_| Up(Release)),
            map(tag(b"D"), |_| Down(Press)),
            map(tag(b"d"), |_| Down(Release)),
            map(tag(b"Z"), |_| Precise(Press)),
            map(tag(b"z"), |_| Precise(Release)),
            map(tag(b"A"), |_| Attack(Press)),
            map(tag(b"a"), |_| Attack(Release)),
            map(tag(b"N"), |_| NextTurn),
            map(tag(b"j"), |_| LongJump),
            map(tag(b"J"), |_| HighJump),
            map(tag(b"S"), |_| Switch),
        )),
        alt((
            map(tag(b","), |_| Skip),
            map(tag(b"1"), |_| Timer(1)),
            map(tag(b"2"), |_| Timer(2)),
            map(tag(b"3"), |_| Timer(3)),
            map(tag(b"4"), |_| Timer(4)),
            map(tag(b"5"), |_| Timer(5)),
            map(tuple((tag(b"p"), be_i24, be_i24)), |(_, x, y)| Put(x, y)),
            map(tuple((tag(b"P"), be_i24, be_i24)), |(_, x, y)| {
                CursorMove(x, y)
            }),
            map(preceded(tag(b"f"), string_tail), TeamControlLost),
            map(preceded(tag(b"g"), string_tail), TeamControlGained),
            map(preceded(tag(b"t"), be_u8), Taunt),
            map(preceded(tag(b"w"), be_u8), SetWeapon),
            map(preceded(tag(b"~"), be_u8), Slot),
            map(tag(b"+"), |_| Heartbeat),
        )),
    ))(input)
}

fn unsynced_message(input: &[u8]) -> IResult<&[u8], UnsyncedEngineMessage> {
    alt((
        map(
            preceded(tag(b"F"), string_tail),
            UnsyncedEngineMessage::TeamControlLost,
        ),
        map(
            preceded(tag(b"G"), string_tail),
            UnsyncedEngineMessage::TeamControlGained,
        ),
        map(
            preceded(tag(b"h"), string_tail),
            UnsyncedEngineMessage::HogSay,
        ),
        map(
            preceded(tag(b"s"), string_tail),
            UnsyncedEngineMessage::ChatMessage,
        ),
        map(
            preceded(tag(b"b"), string_tail),
            UnsyncedEngineMessage::TeamMessage,
        ),
    ))(input)
}

fn unordered_message(input: &[u8]) -> IResult<&[u8], UnorderedEngineMessage> {
    alt((
        map(tag(b"?"), |_| Ping),
        map(tag(b"!"), |_| Pong),
        map(preceded(tag(b"E"), string_tail), Error),
        map(preceded(tag(b"W"), string_tail), Warning),
        map(preceded(tag(b"M"), string_tail), GameSetupChecksum),
        map(tag(b"o"), |_| StopSyncing),
        map(tag(b"I"), |_| PauseToggled),
    ))(input)
}

fn config_message(input: &[u8]) -> IResult<&[u8], ConfigEngineMessage> {
    alt((
        map(tag(b"C"), |_| ConfigRequest),
        map(preceded(tag(b"eseed "), string_tail), SetSeed),
        map(preceded(tag(b"e$feature_size "), string_tail), |s| {
            SetFeatureSize(s.parse().unwrap_or_default())
        }),
    ))(input)
}

fn timestamped_message(input: &[u8]) -> IResult<&[u8], (SyncedEngineMessage, u16)> {
    terminated(pair(synced_message, be_u16), eof_slice)(input)
}
fn unwrapped_message(input: &[u8]) -> IResult<&[u8], EngineMessage> {
    alt((
        map(timestamped_message, |(m, t)| {
            EngineMessage::Synced(m, t as u32)
        }),
        map(tag(b"#"), |_| Synced(TimeWrap, 65535u32)),
        map(unordered_message, Unordered),
        map(unsynced_message, Unsynced),
        map(config_message, Config),
        unrecognized_message,
    ))(input)
}

fn length_specifier(input: &[u8]) -> IResult<&[u8], u16> {
    alt((
        verify(map(take(1usize), |a: &[u8]| a[0] as u16), |&l| l < 64),
        map(take(2usize), |a: &[u8]| {
            (a[0] as u16 - 64) * 256 + a[1] as u16 + 64
        }),
    ))(input)
}

fn empty_message(input: &[u8]) -> IResult<&[u8], EngineMessage> {
    map(tag(b"\0"), |_| Empty)(input)
}

fn non_empty_message(input: &[u8]) -> IResult<&[u8], EngineMessage> {
    map_parser(length_data(length_specifier), unwrapped_message)(input)
}

fn message(input: &[u8]) -> IResult<&[u8], EngineMessage> {
    alt((empty_message, non_empty_message))(input)
}

pub fn extract_messages(input: &[u8]) -> IResult<&[u8], Vec<EngineMessage>> {
    many0(complete(message))(input)
}

pub fn extract_message(buf: &[u8]) -> Option<(usize, EngineMessage)> {
    let parse_result = message(buf);
    match parse_result {
        Ok((tail, msg)) => {
            let consumed = buf.len() - tail.len();

            Some((consumed, msg))
        }
        Err(Err::Incomplete(_)) => None,
        Err(Err::Error(_)) | Err(Err::Failure(_)) => unreachable!(),
    }
}

#[cfg(test)]
mod tests {
    use crate::messages::UnsyncedEngineMessage::*;
    use crate::parser::*;

    #[test]
    fn parse_length() {
        assert_eq!(length_specifier(b"\x01"), Ok((&b""[..], 1)));
        assert_eq!(length_specifier(b"\x00"), Ok((&b""[..], 0)));
        assert_eq!(length_specifier(b"\x3f"), Ok((&b""[..], 63)));
        assert_eq!(length_specifier(b"\x40\x00"), Ok((&b""[..], 64)));
        assert_eq!(
            length_specifier(b"\xff\xff"),
            Ok((&b""[..], EngineMessage::MAX_LEN))
        );
    }

    #[test]
    fn parse_synced_messages() {
        assert_eq!(
            message(b"\x03L\x01\x02"),
            Ok((&b""[..], Synced(Left(Press), 258)))
        );

        assert_eq!(message(b"\x01#"), Ok((&b""[..], Synced(TimeWrap, 65535))));

        assert_eq!(
            message(&vec![9, b'p', 255, 133, 151, 1, 0, 2, 0, 0]),
            Ok((&b""[..], Synced(Put(-31337, 65538), 0)))
        );
    }

    #[test]
    fn parse_unsynced_messages() {
        assert_eq!(
            message(b"\x06shello"),
            Ok((&b""[..], Unsynced(ChatMessage(String::from("hello")))))
        );
    }

    #[test]
    fn parse_incorrect_messages() {
        assert_eq!(message(b"\x00"), Ok((&b""[..], Empty)));
        assert_eq!(message(b"\x01\x00"), Ok((&b""[..], Unknown(vec![0]))));

        // garbage after correct message
        assert_eq!(
            message(b"\x04La\x01\x02"),
            Ok((&b""[..], Unknown(vec![76, 97, 1, 2])))
        );
    }

    #[test]
    fn parse_config_messages() {
        assert_eq!(message(b"\x01C"), Ok((&b""[..], Config(ConfigRequest))));
    }

    #[test]
    fn parse_test_general() {
        assert_eq!(string_tail(b"abc"), Ok((&b""[..], String::from("abc"))));

        assert_eq!(extract_message(b"\x02#"), None);

        assert_eq!(synced_message(b"L"), Ok((&b""[..], Left(Press))));

        assert_eq!(
            extract_message(b"\x01#"),
            Some((2, Synced(TimeWrap, 65535)))
        );
    }
}
