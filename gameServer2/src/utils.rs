use std::iter::Iterator;
use mio;
use base64::{encode};

pub const PROTOCOL_VERSION : u32 = 3;
pub const SERVER: mio::Token = mio::Token(1_000_000_000);

pub fn is_name_illegal(name: &str ) -> bool{
    name.len() > 40 ||
        name.trim().is_empty() ||
        name.chars().any(|c|
            "$()*+?[]^{|}\x7F".contains(c) ||
                '\x00' <= c && c <= '\x1F')
}

pub fn to_engine_msg<T>(msg: T) -> String
    where T: Iterator<Item = u8> + Clone
{
    let mut tmp = Vec::new();
    tmp.push(msg.clone().count() as u8);
    tmp.extend(msg);
    encode(&tmp)
}