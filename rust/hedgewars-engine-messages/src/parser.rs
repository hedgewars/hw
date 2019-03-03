use nom::{Err::Error, *};
use std::str;

use super::messages::{
    ConfigEngineMessage::*, EngineMessage::*, KeystrokeAction::*, SyncedEngineMessage::*,
    UnorderedEngineMessage::*, *,
};

macro_rules! eof_slice (
  ($i:expr,) => (
    {
      if ($i).input_len() == 0 {
        Ok(($i, $i))
      } else {
        Err(Error(error_position!($i, ErrorKind::Eof::<u32>)))
      }
    }
  );
);

named!(unrecognized_message<&[u8], EngineMessage>,
    do_parse!(rest >> (Unknown))
);

named!(string_tail<&[u8], String>, map!(map_res!(rest, str::from_utf8), String::from));

named!(length_without_timestamp<&[u8], usize>,
    map_opt!(rest_len, |l| if l > 2 { Some(l - 2) } else { None } )
);

named!(synced_message<&[u8], SyncedEngineMessage>, alt!(
        do_parse!(tag!("L") >> (Left(Press)))
      | do_parse!(tag!("l") >> ( Left(Release) ))
      | do_parse!(tag!("R") >> ( Right(Press) ))
      | do_parse!(tag!("r") >> ( Right(Release) ))
      | do_parse!(tag!("U") >> ( Up(Press) ))
      | do_parse!(tag!("u") >> ( Up(Release) ))
      | do_parse!(tag!("D") >> ( Down(Press) ))
      | do_parse!(tag!("d") >> ( Down(Release) ))
      | do_parse!(tag!("Z") >> ( Precise(Press) ))
      | do_parse!(tag!("z") >> ( Precise(Release) ))
      | do_parse!(tag!("A") >> ( Attack(Press) ))
      | do_parse!(tag!("a") >> ( Attack(Release) ))
      | do_parse!(tag!("N") >> ( NextTurn ))
      | do_parse!(tag!("j") >> ( LongJump ))
      | do_parse!(tag!("J") >> ( HighJump ))
      | do_parse!(tag!("S") >> ( Switch ))
      | do_parse!(tag!(",") >> ( Skip ))
      | do_parse!(tag!("1") >> ( Timer(1) ))
      | do_parse!(tag!("2") >> ( Timer(2) ))
      | do_parse!(tag!("3") >> ( Timer(3) ))
      | do_parse!(tag!("4") >> ( Timer(4) ))
      | do_parse!(tag!("5") >> ( Timer(5) ))
      | do_parse!(tag!("p") >> x: be_i24 >> y: be_i24 >> ( Put(x, y) ))
      | do_parse!(tag!("P") >> x: be_i24 >> y: be_i24 >> ( CursorMove(x, y) ))
      | do_parse!(tag!("f") >> s: string_tail >> ( SyncedEngineMessage::TeamControlLost(s) ))
      | do_parse!(tag!("g") >> s: string_tail >> ( SyncedEngineMessage::TeamControlGained(s) ))
      | do_parse!(tag!("h") >> s: string_tail >> ( HogSay(s) ))
      | do_parse!(tag!("t") >> t: be_u8 >> ( Taunt(t) ))
      | do_parse!(tag!("w") >> w: be_u8 >> ( SetWeapon(w) ))
      | do_parse!(tag!("~") >> s: be_u8 >> ( Slot(s) ))
      | do_parse!(tag!("+") >> ( Heartbeat ))
));

named!(unsynced_message<&[u8], UnsyncedEngineMessage>, alt!(
        do_parse!(tag!("F") >> s: string_tail >> ( UnsyncedEngineMessage::TeamControlLost(s) ))
      | do_parse!(tag!("G") >> s: string_tail >> ( UnsyncedEngineMessage::TeamControlGained(s) ))
));

named!(unordered_message<&[u8], UnorderedEngineMessage>, alt!(
      do_parse!(tag!("?") >> ( Ping ))
    | do_parse!(tag!("!") >> ( Pong ))
    | do_parse!(tag!("E") >> s: string_tail >> ( UnorderedEngineMessage::Error(s)) )
    | do_parse!(tag!("W") >> s: string_tail >> ( Warning(s)) )
    | do_parse!(tag!("s") >> s: string_tail >> ( ChatMessage(s)) )
    | do_parse!(tag!("b") >> s: string_tail >> ( TeamMessage(s)) ) // TODO: wtf is the format
    | do_parse!(tag!("M") >> s: string_tail >> ( GameSetupChecksum(s)) )
    | do_parse!(tag!("o") >> ( StopSyncing ))
    | do_parse!(tag!("I") >> ( PauseToggled ))
));

named!(config_message<&[u8], ConfigEngineMessage>, alt!(
    do_parse!(tag!("C") >> (ConfigRequest))
    | do_parse!(tag!("eseed ") >> s: string_tail >> ( SetSeed(s)) )
));

named!(timestamped_message<&[u8], (SyncedEngineMessage, u16)>,
    do_parse!(msg: length_value!(length_without_timestamp, terminated!(synced_message, eof_slice!()))
        >> timestamp: be_u16
        >> ((msg, timestamp))
    )
);

named!(unwrapped_message<&[u8], EngineMessage>,
    alt!(
        map!(timestamped_message, |(m, t)| Synced(m, t as u32))
        | do_parse!(tag!("#") >> (Synced(TimeWrap, 65535)))
        | map!(unordered_message, |m| Unordered(m))
        | map!(unsynced_message, |m| Unsynced(m))
        | map!(config_message, |m| Config(m))
        | unrecognized_message
));

named!(length_specifier<&[u8], u16>, alt!(
    verify!(map!(take!(1), |a : &[u8]| a[0] as u16), |l| l < 64)
    | map!(take!(2), |a| (a[0] as u16 - 64) * 256 + a[1] as u16 + 64)
    )
);

named!(empty_message<&[u8], EngineMessage>,
    do_parse!(tag!("\0") >> (Empty))
);

named!(non_empty_message<&[u8], EngineMessage>,
    length_value!(length_specifier, terminated!(unwrapped_message, eof_slice!())));

named!(message<&[u8], EngineMessage>, alt!(
      empty_message
    | non_empty_message
    )
);

named!(pub extract_messages<&[u8], Vec<EngineMessage> >, many0!(complete!(message)));

pub fn extract_message(buf: &[u8]) -> Option<(usize, EngineMessage)> {
    let parse_result = message(buf);
    match parse_result {
        Ok((tail, msg)) => {
            let consumed = buf.len() - tail.len();

            Some((consumed, msg))
        },
        Err(Err::Incomplete(_)) => None,
        Err(Err::Error(_)) | Err(Err::Failure(_)) => unreachable!(),
    }
}

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

    assert_eq!(message(&vec![9, b'p', 255, 133, 151, 1, 0, 2, 0, 0]), Ok((&b""[..], Synced(Put(-31337, 65538), 0))));
}

#[test]
fn parse_unsynced_messages() {
    assert_eq!(
        message(b"\x06shello"),
        Ok((&b""[..], Unordered(ChatMessage(String::from("hello")))))
    );
}

#[test]
fn parse_incorrect_messages() {
    assert_eq!(message(b"\x00"), Ok((&b""[..], Empty)));
    assert_eq!(message(b"\x01\x00"), Ok((&b""[..], Unknown)));

    // garbage after correct message
    assert_eq!(message(b"\x04La\x01\x02"), Ok((&b""[..], Unknown)));
}

#[test]
fn parse_config_messages() {
    assert_eq!(message(b"\x01C"), Ok((&b""[..], Config(ConfigRequest))));
}

#[test]
fn parse_test_general() {
    assert_eq!(string_tail(b"abc"), Ok((&b""[..], String::from("abc"))));

    assert_eq!(extract_message(b"\x02#"), None);
    assert_eq!(extract_message(b"\x01#"), Some((2, Synced(TimeWrap, 65535))));
}
