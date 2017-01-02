use netbuf;
use std::io::Read;
use std::io::Result;


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
