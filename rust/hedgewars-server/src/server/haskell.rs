use nom::{
    branch::alt,
    bytes::complete::{escaped_transform, is_not, tag, take_while, take_while1},
    character::{is_alphanumeric, is_digit, is_space},
    combinator::{map, map_res},
    multi::separated_list,
    sequence::{delimited, pair, preceded, separated_pair},
    IResult,
};
use std::collections::HashMap;

type HaskellResult<'a, T> = IResult<&'a [u8], T, ()>;

#[derive(Debug, PartialEq)]
pub enum HaskellValue {
    List(Vec<HaskellValue>),
    Tuple(Vec<HaskellValue>),
    String(String),
    Number(u8),
    Struct {
        name: String,
        fields: HashMap<String, HaskellValue>,
    },
    AnonStruct {
        name: String,
        fields: Vec<HaskellValue>,
    },
}

fn comma(input: &[u8]) -> HaskellResult<&[u8]> {
    delimited(take_while(is_space), tag(","), take_while(is_space))(input)
}

fn surrounded<'a, P, O>(
    prefix: &'static str,
    suffix: &'static str,
    parser: P,
) -> impl Fn(&'a [u8]) -> HaskellResult<'a, O>
where
    P: Fn(&'a [u8]) -> HaskellResult<'a, O>,
{
    move |input| {
        delimited(
            delimited(take_while(is_space), tag(prefix), take_while(is_space)),
            |i| parser(i),
            delimited(take_while(is_space), tag(suffix), take_while(is_space)),
        )(input)
    }
}

fn number_raw(input: &[u8]) -> HaskellResult<u8> {
    use std::str::FromStr;
    map_res(take_while(is_digit), |s| {
        std::str::from_utf8(s)
            .map_err(|_| ())
            .and_then(|s| u8::from_str(s).map_err(|_| ()))
    })(input)
}

fn number(input: &[u8]) -> HaskellResult<HaskellValue> {
    map(number_raw, HaskellValue::Number)(input)
}

const BYTES: &[u8] = b"\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff";

fn string_escape(input: &[u8]) -> HaskellResult<&[u8]> {
    alt((
        map(number_raw, |n| &BYTES[n as usize..(n + 1) as usize]),
        alt((
            map(tag("\\"), |_| &b"\\"[..]),
            map(tag("\""), |_| &b"\""[..]),
            map(tag("'"), |_| &b"'"[..]),
            map(tag("n"), |_| &b"\n"[..]),
            map(tag("r"), |_| &b"\r"[..]),
            map(tag("t"), |_| &b"\t"[..]),
            map(tag("a"), |_| &b"\x07"[..]),
            map(tag("b"), |_| &b"\x08"[..]),
            map(tag("v"), |_| &b"\x0B"[..]),
            map(tag("f"), |_| &b"\x0C"[..]),
            map(tag("&"), |_| &b""[..]),
            map(tag("NUL"), |_| &b"\x00"[..]),
            map(tag("SOH"), |_| &b"\x01"[..]),
            map(tag("STX"), |_| &b"\x02"[..]),
            map(tag("ETX"), |_| &b"\x03"[..]),
            map(tag("EOT"), |_| &b"\x04"[..]),
            map(tag("ENQ"), |_| &b"\x05"[..]),
            map(tag("ACK"), |_| &b"\x06"[..]),
        )),
        alt((
            map(tag("SO"), |_| &b"\x0E"[..]),
            map(tag("SI"), |_| &b"\x0F"[..]),
            map(tag("DLE"), |_| &b"\x10"[..]),
            map(tag("DC1"), |_| &b"\x11"[..]),
            map(tag("DC2"), |_| &b"\x12"[..]),
            map(tag("DC3"), |_| &b"\x13"[..]),
            map(tag("DC4"), |_| &b"\x14"[..]),
            map(tag("NAK"), |_| &b"\x15"[..]),
            map(tag("SYN"), |_| &b"\x16"[..]),
            map(tag("ETB"), |_| &b"\x17"[..]),
            map(tag("CAN"), |_| &b"\x18"[..]),
            map(tag("EM"), |_| &b"\x19"[..]),
            map(tag("SUB"), |_| &b"\x1A"[..]),
            map(tag("ESC"), |_| &b"\x1B"[..]),
            map(tag("FS"), |_| &b"\x1C"[..]),
            map(tag("GS"), |_| &b"\x1D"[..]),
            map(tag("RS"), |_| &b"\x1E"[..]),
            map(tag("US"), |_| &b"\x1F"[..]),
            map(tag("SP"), |_| &b"\x20"[..]),
            map(tag("DEL"), |_| &b"\x7F"[..]),
        )),
    ))(input)
}

fn string_content(mut input: &[u8]) -> HaskellResult<String> {
    map_res(
        escaped_transform(is_not("\"\\"), '\\', string_escape),
        |bytes| String::from_utf8(bytes).map_err(|_| ()),
    )(input)
}

fn string(input: &[u8]) -> HaskellResult<HaskellValue> {
    map(surrounded("\"", "\"", string_content), HaskellValue::String)(input)
}

fn tuple(input: &[u8]) -> HaskellResult<HaskellValue> {
    map(
        surrounded("(", ")", separated_list(comma, value)),
        HaskellValue::Tuple,
    )(input)
}

fn list(input: &[u8]) -> HaskellResult<HaskellValue> {
    map(
        surrounded("[", "]", separated_list(comma, value)),
        HaskellValue::List,
    )(input)
}

fn identifier(input: &[u8]) -> HaskellResult<String> {
    map_res(take_while1(is_alphanumeric), |s| {
        std::str::from_utf8(s).map_err(|_| ()).map(String::from)
    })(input)
}

fn named_field(input: &[u8]) -> HaskellResult<(String, HaskellValue)> {
    separated_pair(
        identifier,
        delimited(take_while(is_space), tag("="), take_while(is_space)),
        value,
    )(input)
}

fn structure(input: &[u8]) -> HaskellResult<HaskellValue> {
    alt((
        map(
            pair(
                identifier,
                surrounded("{", "}", separated_list(comma, named_field)),
            ),
            |(name, mut fields)| HaskellValue::Struct {
                name,
                fields: fields.drain(..).collect(),
            },
        ),
        map(
            pair(
                identifier,
                preceded(take_while1(is_space), separated_list(comma, value)),
            ),
            |(name, mut fields)| HaskellValue::AnonStruct {
                name: name.clone(),
                fields,
            },
        ),
    ))(input)
}

fn value(input: &[u8]) -> HaskellResult<HaskellValue> {
    alt((number, string, tuple, list, structure))(input)
}

#[inline]
pub fn parse(input: &[u8]) -> HaskellResult<HaskellValue> {
    delimited(take_while(is_space), value, take_while(is_space))(input)
}

mod test {
    use super::*;

    #[test]
    fn terminals() {
        use HaskellValue::*;

        matches!(number(b"127"), Ok((_, Number(127))));
        matches!(number(b"adas"), Err(nom::Err::Error(())));

        assert_eq!(
            string(b"\"Hail \\240\\159\\166\\148!\""),
            Ok((&b""[..], String("Hail \u{1f994}!".to_string())))
        );
    }

    #[test]
    fn sequences() {
        use HaskellValue::*;

        let value = Tuple(vec![
            Number(64),
            String("text".to_string()),
            List(vec![Number(1), Number(2), Number(3)]),
        ]);

        assert_eq!(tuple(b"(64, \"text\", [1 , 2, 3])"), Ok((&b""[..], value)));
    }

    #[test]
    fn structures() {
        use HaskellValue::*;

        let value = Struct {
            name: "Hog".to_string(),
            fields: vec![
                ("name".to_string(), String("\u{1f994}".to_string())),
                ("health".to_string(), Number(100)),
            ]
            .drain(..)
            .collect(),
        };

        assert_eq!(
            structure(b"Hog {name = \"\\240\\159\\166\\148\", health = 100}"),
            Ok((&b""[..], value))
        );

        let value = AnonStruct {
            name: "Hog".to_string(),
            fields: vec![Number(100), String("\u{1f994}".to_string())],
        };

        assert_eq!(
            structure(b"Hog 100, \"\\240\\159\\166\\148\""),
            Ok((&b""[..], value))
        );
    }
}
