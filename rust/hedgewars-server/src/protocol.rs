use bytes::{Buf, BytesMut};
use log::*;
use std::{
    error::Error,
    fmt::{Debug, Display, Formatter},
};
use tokio::io::AsyncReadExt;

use hedgewars_network_protocol::{
    messages::HwProtocolMessage,
    parser::{malformed_message, message},
};

#[derive(Debug)]
pub enum ProtocolError {
    Eof,
    Network(Box<dyn Error + Send>),
}

impl Display for ProtocolError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            ProtocolError::Eof => write!(f, "Connection reset by peer"),
            ProtocolError::Network(source) => write!(f, "{:?}", source),
        }
    }
}

impl Error for ProtocolError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        if let Self::Network(source) = self {
            Some(source.as_ref())
        } else {
            None
        }
    }
}

pub type Result<T> = std::result::Result<T, ProtocolError>;

pub struct ProtocolDecoder {
    buffer: BytesMut,
}

impl ProtocolDecoder {
    pub fn new() -> ProtocolDecoder {
        ProtocolDecoder {
            buffer: BytesMut::with_capacity(1024),
        }
    }

    fn extract_message(&mut self) -> Option<HwProtocolMessage> {
        if self.buffer.is_empty() {
            return None;
        }
        match message(&self.buffer[..]) {
            Ok((tail, message)) => {
                let remaining = tail.len();
                self.buffer.advance(self.buffer.len() - remaining);
                Some(message)
            }
            Err(nom::Err::Incomplete(_)) => None,
            Err(nom::Err::Failure(e) | nom::Err::Error(e)) => {
                debug!("Invalid message: {:?}", e);
                match malformed_message(&self.buffer[..]) {
                    Ok((tail, raw)) => {
                        let remaining = tail.len();
                        self.buffer.advance(self.buffer.len() - remaining);
                        let lines = if raw.is_empty() {
                            vec![]
                        } else {
                            raw.split(|b| *b == b'\n')
                                .map(|s| String::from_utf8_lossy(s).into_owned())
                                .collect()
                        };
                        Some(HwProtocolMessage::Malformed(lines))
                    }
                    Err(nom::Err::Incomplete(_)) => None,
                    Err(_) => {
                        self.buffer.clear();
                        None
                    }
                }
            }
        }
    }

    pub async fn read_from<R: AsyncReadExt + Unpin>(
        &mut self,
        stream: &mut R,
    ) -> Result<HwProtocolMessage> {
        use ProtocolError::*;

        loop {
            if let Some(result) = self.extract_message() {
                return Ok(result);
            }

            let remaining = self.buffer.capacity() - self.buffer.len();
            if remaining < 1024 {
                self.buffer.reserve(2048 - remaining);
            }

            match stream.read_buf(&mut self.buffer).await {
                Err(e) => return Err(Network(Box::new(e))),
                Ok(0) => return Err(Eof),
                Ok(_) => (),
            };
        }
    }
}
