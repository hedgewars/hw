use nom::{
    branch::alt,
    bytes::complete::{escaped_transform, is_not, tag, take_while, take_while1},
    character::{is_alphanumeric, is_digit, is_space},
    combinator::{map, map_res},
    multi::separated_list,
    sequence::{delimited, pair, preceded, separated_pair},
    ExtendInto, IResult,
};
use std::{
    collections::HashMap,
    fmt::{Display, Error, Formatter},
};

type HaskellResult<'a, T> = IResult<&'a [u8], T, ()>;

#[derive(Debug, PartialEq)]
pub enum HaskellValue {
    Number(u8),
    String(String),
    Tuple(Vec<HaskellValue>),
    List(Vec<HaskellValue>),
    AnonStruct {
        name: String,
        fields: Vec<HaskellValue>,
    },
    Struct {
        name: String,
        fields: HashMap<String, HaskellValue>,
    },
}

fn write_sequence(
    f: &mut Formatter<'_>,
    brackets: &[u8; 2],
    mut items: std::slice::Iter<HaskellValue>,
) -> Result<(), Error> {
    write!(f, "{}", brackets[0] as char)?;
    while let Some(value) = items.next() {
        write!(f, "{}", value);
        if !items.as_slice().is_empty() {
            write!(f, ", ")?;
        }
    }
    if brackets[1] != b'\0' {
        write!(f, "{}", brackets[1] as char)
    } else {
        Ok(())
    }
}

fn write_text(f: &mut Formatter<'_>, text: &str) -> Result<(), Error> {
    write!(f, "\"")?;
    for c in text.chars() {
        if c.is_ascii() && !(c as u8).is_ascii_control() {
            write!(f, "{}", c)?;
        } else {
            let mut bytes = [0u8; 4];
            let size = c.encode_utf8(&mut bytes).len();
            for byte in &bytes[0..size] {
                write!(f, "\\{:03}", byte)?;
            }
        }
    }
    write!(f, "\"")
}

impl Display for HaskellValue {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result<(), Error> {
        match self {
            HaskellValue::Number(value) => write!(f, "{}", value),
            HaskellValue::String(value) => write_text(f, value),
            HaskellValue::Tuple(items) => write_sequence(f, b"()", items.iter()),
            HaskellValue::List(items) => write_sequence(f, b"[]", items.iter()),
            HaskellValue::AnonStruct { name, fields } => {
                write!(f, "{} ", name)?;
                write_sequence(f, b" \0", fields.iter())
            }
            HaskellValue::Struct { name, fields } => {
                write!(f, "{} {{", name)?;
                let fields = fields.iter().collect::<Vec<_>>();
                let mut items = fields.iter();
                while let Some((field_name, value)) = items.next() {
                    write!(f, "{} = {}", field_name, value)?;
                    if !items.as_slice().is_empty() {
                        write!(f, ", ")?;
                    }
                }
                write!(f, "}}")
            }
        }
    }
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

enum Escape {
    Empty,
    Byte(u8),
}

impl ExtendInto for Escape {
    type Item = u8;
    type Extender = Vec<u8>;

    fn new_builder(&self) -> Self::Extender {
        Vec::new()
    }

    fn extend_into(&self, acc: &mut Self::Extender) {
        if let Escape::Byte(b) = self {
            acc.push(*b);
        }
    }
}

impl Extend<Escape> for Vec<u8> {
    fn extend<T: IntoIterator<Item = Escape>>(&mut self, iter: T) {
        for item in iter {
            item.extend_into(self);
        }
    }
}

fn string_escape(input: &[u8]) -> HaskellResult<Escape> {
    use Escape::*;
    alt((
        map(number_raw, |n| Byte(n)),
        alt((
            map(tag("\\"), |_| Byte(b'\\')),
            map(tag("\""), |_| Byte(b'\"')),
            map(tag("'"), |_| Byte(b'\'')),
            map(tag("n"), |_| Byte(b'\n')),
            map(tag("r"), |_| Byte(b'\r')),
            map(tag("t"), |_| Byte(b'\t')),
            map(tag("a"), |_| Byte(b'\x07')),
            map(tag("b"), |_| Byte(b'\x08')),
            map(tag("v"), |_| Byte(b'\x0B')),
            map(tag("f"), |_| Byte(b'\x0C')),
            map(tag("&"), |_| Empty),
            map(tag("NUL"), |_| Byte(b'\x00')),
            map(tag("SOH"), |_| Byte(b'\x01')),
            map(tag("STX"), |_| Byte(b'\x02')),
            map(tag("ETX"), |_| Byte(b'\x03')),
            map(tag("EOT"), |_| Byte(b'\x04')),
            map(tag("ENQ"), |_| Byte(b'\x05')),
            map(tag("ACK"), |_| Byte(b'\x06')),
        )),
        alt((
            map(tag("SO"), |_| Byte(b'\x0E')),
            map(tag("SI"), |_| Byte(b'\x0F')),
            map(tag("DLE"), |_| Byte(b'\x10')),
            map(tag("DC1"), |_| Byte(b'\x11')),
            map(tag("DC2"), |_| Byte(b'\x12')),
            map(tag("DC3"), |_| Byte(b'\x13')),
            map(tag("DC4"), |_| Byte(b'\x14')),
            map(tag("NAK"), |_| Byte(b'\x15')),
            map(tag("SYN"), |_| Byte(b'\x16')),
            map(tag("ETB"), |_| Byte(b'\x17')),
            map(tag("CAN"), |_| Byte(b'\x18')),
            map(tag("EM"), |_| Byte(b'\x19')),
            map(tag("SUB"), |_| Byte(b'\x1A')),
            map(tag("ESC"), |_| Byte(b'\x1B')),
            map(tag("FS"), |_| Byte(b'\x1C')),
            map(tag("GS"), |_| Byte(b'\x1D')),
            map(tag("RS"), |_| Byte(b'\x1E')),
            map(tag("US"), |_| Byte(b'\x1F')),
            map(tag("DEL"), |_| Byte(b'\x7F')),
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
            String("text\t1".to_string()),
            List(vec![Number(1), Number(2), Number(3)]),
        ]);

        assert_eq!(
            tuple(b"(64, \"text\\t1\", [1 , 2, 3])"),
            Ok((&b""[..], value))
        );
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
