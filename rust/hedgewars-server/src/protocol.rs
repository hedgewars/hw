use bytes::{Buf, BufMut, BytesMut};
use log::*;
use std::{io, io::ErrorKind, marker::Unpin};
use tokio::io::AsyncReadExt;

use hedgewars_network_protocol::{
    messages::HwProtocolMessage,
    parser::{malformed_message, message},
};

pub struct ProtocolDecoder {
    buffer: BytesMut,
    is_recovering: bool,
}

impl ProtocolDecoder {
    pub fn new() -> ProtocolDecoder {
        ProtocolDecoder {
            buffer: BytesMut::with_capacity(1024),
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
                    self.recover();
                }
            }
        }
        None
    }

    pub async fn read_from<R: AsyncReadExt + Unpin>(
        &mut self,
        stream: &mut R,
    ) -> Option<HwProtocolMessage> {
        loop {
            if !self.buffer.has_remaining() {
                let count = stream.read_buf(&mut self.buffer).await.ok()?;
                if count == 0 {
                    return None;
                }
            }
            while !self.buffer.is_empty() {
                if let Some(result) = self.extract_message() {
                    return Some(result);
                }
            }
        }
    }
}
