use mio::tcp::*;
use mio::*;
use std::io::Write;
use std::io;
use netbuf;

use utils;
use protocol::ProtocolDecoder;
use protocol::messages::*;
use super::actions::Action::*;
use super::actions::Action;

pub struct HWClient {
    sock: TcpStream,
    decoder: ProtocolDecoder,
    buf_out: netbuf::Buf,

    pub id: Token,
    pub room_id: Option<Token>,
    pub nick: String,
    pub protocol_number: u32,
    pub is_master: bool,
    pub is_ready: bool,
    pub is_joined_mid_game: bool,
}

impl HWClient {
    pub fn new(sock: TcpStream) -> HWClient {
        HWClient {
            sock: sock,
            decoder: ProtocolDecoder::new(),
            buf_out: netbuf::Buf::new(),
            room_id: None,
            id: Token(0),

            nick: String::new(),
            protocol_number: 0,
            is_master: false,
            is_ready: false,
            is_joined_mid_game: false,
        }
    }

    pub fn register(&mut self, poll: &Poll, token: Token) {
        poll.register(&self.sock, token, Ready::all(),
                      PollOpt::edge())
            .ok().expect("could not register socket with event loop");

        self.send_msg(HWServerMessage::Connected(utils::PROTOCOL_VERSION));
    }

    pub fn deregister(&mut self, poll: &Poll) {
        poll.deregister(&self.sock)
            .ok().expect("could not deregister socket");
    }

    pub fn send_raw_msg(&mut self, msg: &[u8]) {
        self.buf_out.write(msg).unwrap();
        self.flush();
    }

    pub fn send_string(&mut self, msg: &String) {
        self.send_raw_msg(&msg.as_bytes());
    }

    pub fn send_msg(&mut self, msg: HWServerMessage) {
        self.send_string(&msg.to_raw_protocol());
    }

    fn flush(&mut self) {
        self.buf_out.write_to(&mut self.sock).unwrap();
        self.sock.flush();
    }

    pub fn readable(&mut self, poll: &Poll) -> Vec<Action> {
        let v = self.decoder.read_from(&mut self.sock).unwrap();
        debug!("Read {} bytes", v);
        let mut response = Vec::new();
        {
            for msg in self.decoder.extract_messages() {
                response.push(ReactProtocolMessage(msg));
            }
        }
        self.decoder.sweep();
        response
    }

    pub fn writable(&mut self, poll: &Poll) -> io::Result<()> {
        self.buf_out.write_to(&mut self.sock)?;

        Ok(())
    }

    pub fn error(&mut self, poll: &Poll) -> Vec<Action> {
        return vec![ByeClient("Connection reset".to_string())]
    }
}
