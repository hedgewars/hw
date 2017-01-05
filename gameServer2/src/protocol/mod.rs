use netbuf;
use std::io::Read;
use std::io::Result;

mod messages;
mod hwprotocol;
mod lexer;

pub struct FrameDecoder {
    buf: netbuf::Buf,
}

impl FrameDecoder {
    pub fn new() -> FrameDecoder {
        FrameDecoder {
            buf: netbuf::Buf::new()
        }
    }

    pub fn read_from<R: Read>(&mut self, stream: &mut R) -> Result<usize> {
        self.buf.read_from(stream)
    }

    pub fn extract_messages(&mut self) -> &[u8] {
        &self.buf[..]
    }
}

#[test]
fn testparser() {
    assert_eq!(messages::HWProtocolMessage::Nick("hey".to_string()),
               hwprotocol::parse_ProtocolMessage("NICK\nhey\n\n").unwrap());
}
