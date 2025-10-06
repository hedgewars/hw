#[derive(Eq, PartialEq, Copy, Clone, Hash, PartialOrd, Ord, Debug)]
pub struct ShortString([u8; 256]);

impl Default for ShortString {
    fn default() -> Self {
        Self([0; 256])
    }
}

impl TryFrom<&str> for ShortString {
    type Error = &'static str;

    fn try_from(value: &str) -> Result<Self, Self::Error> {
        let bytes = value.as_bytes();
        if bytes.len() >= 255 {
            return Err("String is too long");
        }

        let mut vec = Vec::with_capacity(256);
        vec.push(bytes.len() as u8);
        vec.extend_from_slice(bytes);
        vec.resize(256, 0x00);

        let result: [u8; 256] = vec.try_into().expect("Size should match");

        Ok(Self(result))
    }
}
