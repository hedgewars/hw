use slab;
use mio::tcp::*;
use mio::*;
use std::io::Write;
use std::io;
use netbuf;

use utils;
use protocol::ProtocolDecoder;
use protocol::messages;
use protocol::messages::HWProtocolMessage::*;

pub struct HWClient {
    sock: TcpStream,
    decoder: ProtocolDecoder,
    buf_out: netbuf::Buf
}

impl HWClient {
    pub fn new(sock: TcpStream) -> HWClient {
        HWClient {
            sock: sock,
            decoder: ProtocolDecoder::new(),
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

    fn send_msg(&mut self, msg: messages::HWProtocolMessage) {
        self.send_raw_msg(&msg.to_raw_protocol().into_bytes());
    }

    fn flush(&mut self) {
        self.buf_out.write_to(&mut self.sock).unwrap();
        self.sock.flush();
    }

    pub fn readable(&mut self, poll: &Poll) -> io::Result<()> {
        let v = self.decoder.read_from(&mut self.sock)?;
        println!("Read {} bytes", v);
        let mut response = Vec::new();
        {
            let msgs = self.decoder.extract_messages();
            for msg in msgs {
                match msg {
                    Ping => response.push(Pong),
                    _ => println!("Unknown message")
                }
            }
        }
        for r in response {
            self.send_msg(r);
        }
        self.decoder.sweep();
        Ok(())
    }

    pub fn writable(&mut self, poll: &Poll) -> io::Result<()> {
        self.buf_out.write_to(&mut self.sock)?;
        Ok(())
    }
}
