use slab;
use mio::tcp::*;
use mio::*;
use std::io::Write;
use std::io;
use netbuf;

use utils;

pub struct HWClient {
    sock: TcpStream,
    buf_in: netbuf::Buf,
    buf_out: netbuf::Buf
}

impl HWClient {
    pub fn new(sock: TcpStream) -> HWClient {
        HWClient {
            sock: sock,
            buf_in: netbuf::Buf::new(),
            buf_out: netbuf::Buf::new(),
        }
    }

    pub fn register(&mut self, poll: &Poll, token: Token) {
        poll.register(&self.sock, token, Ready::readable(),
                      PollOpt::edge())
            .ok().expect("could not register socket with event loop");

        self.send_raw_msg(
            format!("CONNECTED\nHedgewars server http://www.hedgewars.org/\n{}\n\n"
                    , utils::PROTOCOL_VERSION).as_bytes());
    }

    fn send_raw_msg(&mut self, msg: &[u8]) {
        self.buf_out.write(msg).unwrap();
        self.flush();
    }

    fn flush(&mut self) {
        self.buf_out.write_to(&mut self.sock).unwrap();
        self.sock.flush();
    }

    pub fn readable(&mut self, poll: &Poll) -> io::Result<()> {
        self.buf_in.read_from(&mut self.sock)?;
        println!("Incoming buffer size: {}", self.buf_in.len());
        Ok(())
    }

    pub fn writable(&mut self, poll: &Poll) -> io::Result<()> {
        self.buf_out.write_to(&mut self.sock)?;
        Ok(())
    }
}
