use mio;

pub const PROTOCOL_VERSION : u32 = 3;
pub const SERVER: mio::Token = mio::Token(1000000000 + 0);

pub fn is_name_illegal(name: &str ) -> bool{
    name.len() > 40 ||
        name.trim().is_empty() ||
        name.chars().any(|c|
            "$()*+?[]^{|}\x7F".contains(c) ||
                '\x00' <= c && c <= '\x1F')
}