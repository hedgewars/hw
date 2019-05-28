use self::parser::message;
use log::*;
use netbuf;
use nom::{Err, ErrorKind, IResult};
use std::io::{Read, Result};

pub mod messages;
mod parser;
#[cfg(test)]
pub mod test;

pub struct ProtocolDecoder {
    buf: netbuf::Buf,
    is_recovering: bool,
}

impl ProtocolDecoder {
    pub fn new() -> ProtocolDecoder {
        ProtocolDecoder {
            buf: netbuf::Buf::new(),
            is_recovering: false,
        }
    }

    fn recover(&mut self) -> bool {
        self.is_recovering = match parser::malformed_message(&self.buf[..]) {
            Ok((tail, ())) => {
                self.buf.consume(self.buf.len() - tail.len());
                false
            }
            _ => {
                self.buf.consume(self.buf.len());
                true
            }
        };
        !self.is_recovering
    }

    pub fn read_from<R: Read>(&mut self, stream: &mut R) -> Result<usize> {
        let count = self.buf.read_from(stream)?;
        if count > 0 && self.is_recovering {
            self.recover();
        }
        Ok(count)
    }

    pub fn extract_messages(&mut self) -> Vec<messages::HWProtocolMessage> {
        let mut messages = vec![];
        if !self.is_recovering {
            loop {
                match parser::message(&self.buf[..]) {
                    Ok((tail, message)) => {
                        messages.push(message);
                        self.buf.consume(self.buf.len() - tail.len());
                    }
                    Err(nom::Err::Incomplete(_)) => break,
                    Err(nom::Err::Failure(e)) | Err(nom::Err::Error(e)) => {
                        debug!("Invalid message: {:?}", e);
                        if !self.recover() || self.buf.is_empty() {
                            break;
                        }
                    }
                }
            }
        }
        messages
    }
}
