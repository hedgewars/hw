use base64::encode;
use mio;
use std::iter::Iterator;

pub const SERVER_VERSION: u32 = 3;
pub const SERVER_TOKEN: mio::Token = mio::Token(1_000_000_000);
pub const TIMER_TOKEN: mio::Token = mio::Token(1_000_000_001);
pub const IO_TOKEN: mio::Token = mio::Token(1_000_000_002);

pub fn is_name_illegal(name: &str) -> bool {
    name.len() > 40
        || name.trim().is_empty()
        || name.trim() != name
        || name
            .chars()
            .any(|c| "$()*+?[]^{|}\x7F".contains(c) || '\x00' <= c && c <= '\x1F')
}

pub fn to_engine_msg<T>(msg: T) -> String
where
    T: Iterator<Item = u8> + Clone,
{
    let mut tmp = Vec::new();
    tmp.push(msg.clone().count() as u8);
    tmp.extend(msg);
    encode(&tmp)
}

pub fn protocol_version_string(protocol_number: u16) -> &'static str {
    match protocol_number {
        17 => "0.9.7-dev",
        19 => "0.9.7",
        20 => "0.9.8-dev",
        21 => "0.9.8",
        22 => "0.9.9-dev",
        23 => "0.9.9",
        24 => "0.9.10-dev",
        25 => "0.9.10",
        26 => "0.9.11-dev",
        27 => "0.9.11",
        28 => "0.9.12-dev",
        29 => "0.9.12",
        30 => "0.9.13-dev",
        31 => "0.9.13",
        32 => "0.9.14-dev",
        33 => "0.9.14",
        34 => "0.9.15-dev",
        35 => "0.9.14.1",
        37 => "0.9.15",
        38 => "0.9.16-dev",
        39 => "0.9.16",
        40 => "0.9.17-dev",
        41 => "0.9.17",
        42 => "0.9.18-dev",
        43 => "0.9.18",
        44 => "0.9.19-dev",
        45 => "0.9.19",
        46 => "0.9.20-dev",
        47 => "0.9.20",
        48 => "0.9.21-dev",
        49 => "0.9.21",
        50 => "0.9.22-dev",
        51 => "0.9.22",
        52 => "0.9.23-dev",
        53 => "0.9.23",
        54 => "0.9.24-dev",
        55 => "0.9.24",
        56 => "0.9.25-dev",
        57 => "0.9.25",
        58 => "1.0.0-dev",
        _ => "Unknown",
    }
}
