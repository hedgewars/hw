use rand::{thread_rng, RngCore};
use std::fmt::{Formatter, LowerHex};

#[derive(PartialEq, Debug)]
pub struct Sha1Digest([u8; 20]);

impl Sha1Digest {
    pub fn new(digest: [u8; 20]) -> Self {
        Self(digest)
    }

    pub fn random() -> Self {
        let mut result = Sha1Digest(Default::default());
        thread_rng().fill_bytes(&mut result.0);
        result
    }
}

impl LowerHex for Sha1Digest {
    fn fmt(&self, f: &mut Formatter) -> Result<(), std::fmt::Error> {
        for byte in &self.0 {
            write!(f, "{:02x}", byte)?;
        }
        Ok(())
    }
}

impl PartialEq<&str> for Sha1Digest {
    fn eq(&self, other: &&str) -> bool {
        if other.len() != self.0.len() * 2 {
            false
        } else {
            #[inline]
            fn convert(c: u8) -> u8 {
                if c > b'9' {
                    c.wrapping_sub(b'a').saturating_add(10)
                } else {
                    c.wrapping_sub(b'0')
                }
            }

            other
                .as_bytes()
                .chunks_exact(2)
                .zip(&self.0)
                .all(|(chars, byte)| {
                    if let [hi, lo] = chars {
                        convert(*lo) == byte & 0x0f && convert(*hi) == (byte & 0xf0) >> 4
                    } else {
                        unreachable!()
                    }
                })
        }
    }
}
