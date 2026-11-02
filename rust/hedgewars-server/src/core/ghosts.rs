use base64::{decode, encode};
use flate2::{read::ZlibDecoder, write::ZlibEncoder, Compression};
use std::{
    fs,
    io::{Read, Write},
};

pub fn sanitize_name(name: &str) -> String {
    name.chars()
        .map(|c| if c.is_ascii_alphanumeric() { c } else { '_' })
        .collect()
}

pub fn load_ghost_points(location: &str) -> Vec<(i16, i16)> {
    let filename = format!("ghosts/{}", sanitize_name(location));
    match fs::read_to_string(&filename) {
        Ok(content) => {
            let trimmed = content.trim();
            let inner = trimmed
                .strip_prefix('[')
                .and_then(|s| s.strip_suffix(']'))
                .unwrap_or(trimmed);
            if inner.trim().is_empty() {
                return Vec::new();
            }
            let nums: Vec<i16> = inner
                .split(',')
                .filter_map(|s| s.trim().parse::<i32>().ok().map(|v| v as i16))
                .collect();
            nums.chunks_exact(2).map(|c| (c[0], c[1])).collect()
        }
        Err(_) => Vec::new(),
    }
}

pub fn unpack_drawn_map(dm: &str) -> Vec<u8> {
    let Ok(decoded) = decode(dm) else {
        return Vec::new();
    };
    if decoded.len() <= 4 {
        return Vec::new();
    }
    let mut decoder = ZlibDecoder::new(&decoded[4..]);
    let mut out = Vec::new();
    let _ = decoder.read_to_end(&mut out);
    out
}

pub fn pack_drawn_map(uncompressed: &[u8]) -> String {
    let mut encoder = ZlibEncoder::new(Vec::new(), Compression::default());
    let _ = encoder.write_all(uncompressed);
    let compressed = encoder.finish().unwrap_or_default();

    let mut buf = Vec::with_capacity(4 + compressed.len());
    buf.extend_from_slice(&(uncompressed.len() as u32).to_be_bytes());
    buf.extend_from_slice(&compressed);
    encode(&buf)
}

pub fn prepend_ghost_points(pts: &[(i16, i16)], dm: &str) -> String {
    let mut raw = Vec::with_capacity(pts.len() * 5);
    for &(x, y) in pts {
        raw.extend_from_slice(&x.to_be_bytes());
        raw.extend_from_slice(&y.to_be_bytes());
        raw.push(99u8);
    }
    raw.extend_from_slice(&unpack_drawn_map(dm));
    pack_drawn_map(&raw)
}
