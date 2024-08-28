use bytes::{Buf, BufMut, BytesMut};
use log::*;
use std::{
    error::Error,
    fmt::{Debug, Display, Formatter},
    io,
    io::ErrorKind,
    marker::Unpin,
    time::Duration,
};
use tokio::{io::AsyncReadExt, time::timeout};

use crate::protocol::ProtocolError::Timeout;
use hedgewars_network_protocol::{
    messages::HwProtocolMessage,
    parser::HwProtocolError,
    parser::{malformed_message, message},
};

#[derive(Debug)]
pub enum ProtocolError {
    Eof,
    Timeout,
    Network(Box<dyn Error + Send>),
}

impl Display for ProtocolError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            ProtocolError::Eof => write!(f, "Connection reset by peer"),
            ProtocolError::Timeout => write!(f, "Read operation timed out"),
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
    read_timeout: Duration,
    is_recovering: bool,
}

impl ProtocolDecoder {
    pub fn new(read_timeout: Duration) -> ProtocolDecoder {
        ProtocolDecoder {
            buffer: BytesMut::with_capacity(1024),
            read_timeout,
            is_recovering: false,
        }
    }

    fn recover(&mut self) -> bool {
        self.is_recovering = match malformed_message(&self.buffer[..]) {
            Ok((tail, ())) => {
                let remaining = tail.len();
                self.buffer.advance(self.buffer.len() - remaining);
                false
            }
            _ => {
                self.buffer.clear();
                true
            }
        };
        !self.is_recovering
    }

    fn extract_message(&mut self) -> Option<HwProtocolMessage> {
        if !self.is_recovering || self.recover() {
            match message(&self.buffer[..]) {
                Ok((tail, message)) => {
                    let remaining = tail.len();
                    self.buffer.advance(self.buffer.len() - remaining);
                    return Some(message);
                }
                Err(nom::Err::Incomplete(_)) => {}
                Err(nom::Err::Failure(e) | nom::Err::Error(e)) => {
                    debug!("Invalid message: {:?}", e);
                    trace!(
                        "Buffer content: {:?}",
                        String::from_utf8_lossy(&self.buffer[..])
                    );
                    self.recover();
                }
            }
        }
        None
    }

    pub async fn read_from<R: AsyncReadExt + Unpin>(
        &mut self,
        stream: &mut R,
    ) -> Result<HwProtocolMessage> {
        use ProtocolError::*;

        loop {
            let remaining = self.buffer.capacity() - self.buffer.len();
            if remaining < 1024 {
                self.buffer.reserve(2048 - remaining);
            }

            if !self.buffer.has_remaining() || self.is_recovering {
                //todo!("ensure the buffer doesn't grow indefinitely")
                match timeout(self.read_timeout, stream.read_buf(&mut self.buffer)).await {
                    Err(_) => return Err(Timeout),
                    Ok(Err(e)) => return Err(Network(Box::new(e))),
                    Ok(Ok(0)) => return Err(Eof),
                    Ok(Ok(_)) => (),
                };
            }
            while !self.buffer.is_empty() {
                if let Some(result) = self.extract_message() {
                    return Ok(result);
                }
            }
        }
    }
}
