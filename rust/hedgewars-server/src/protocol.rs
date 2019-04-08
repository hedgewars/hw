use netbuf;
use nom::{Err, ErrorKind, IResult};
use std::io::{Read, Result};

pub mod messages;
mod parser;
#[cfg(test)]
pub mod test;

pub struct ProtocolDecoder {
    buf: netbuf::Buf,
    consumed: usize,
}

impl ProtocolDecoder {
    pub fn new() -> ProtocolDecoder {
        ProtocolDecoder {
            buf: netbuf::Buf::new(),
            consumed: 0,
        }
    }

    pub fn read_from<R: Read>(&mut self, stream: &mut R) -> Result<usize> {
        self.buf.read_from(stream)
    }

    pub fn extract_messages(&mut self) -> Vec<messages::HWProtocolMessage> {
        let parse_result = parser::extract_messages(&self.buf[..]);
        match parse_result {
            Ok((tail, msgs)) => {
                self.consumed = self.buf.len() - self.consumed - tail.len();
                msgs
            }
            _ => unreachable!(),
        }
    }

    pub fn sweep(&mut self) {
        self.buf.consume(self.consumed);
        self.consumed = 0;
    }
}
