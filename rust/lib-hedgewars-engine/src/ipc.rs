use hedgewars_engine_messages::{messages::*, parser::extract_message};
use netbuf::*;
use std::io::*;

pub struct IPC {
    in_buffer: Buf,
    out_buffer: Buf,
}

impl IPC {
    pub fn new() -> Self {
        Self {
            in_buffer: Buf::new(),
            out_buffer: Buf::new(),
        }
    }

    pub fn send_message(&mut self, message: &EngineMessage) {
        self.out_buffer.write(&message.to_bytes()).unwrap();
    }

    pub fn iter(&mut self) -> IPCMessagesIterator {
        IPCMessagesIterator::new(self)
    }
}

impl Write for IPC {
    fn write(&mut self, buf: &[u8]) -> Result<usize> {
        self.in_buffer.write(buf)
    }

    fn flush(&mut self) -> Result<()> {
        self.in_buffer.flush()
    }
}

impl Read for IPC {
    fn read(&mut self, buf: &mut [u8]) -> Result<usize> {
        let read_bytes = self.out_buffer.as_ref().read(buf)?;

        self.out_buffer.consume(read_bytes);

        Ok(read_bytes)
    }
}

pub struct IPCMessagesIterator<'a> {
    ipc: &'a mut IPC,
}

impl<'a> IPCMessagesIterator<'a> {
    pub fn new(ipc: &'a mut IPC) -> Self {
        Self { ipc }
    }
}

impl<'a> Iterator for IPCMessagesIterator<'a> {
    type Item = EngineMessage;

    fn next(&mut self) -> Option<Self::Item> {
        let (consumed, message) = extract_message(&self.ipc.in_buffer[..])?;

        self.ipc.in_buffer.consume(consumed);

        Some(message)
    }
}
