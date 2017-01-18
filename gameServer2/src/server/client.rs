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
use server::actions::Action::*;
use server::actions::Action;
use log;

pub struct HWClient {
    sock: TcpStream,
    decoder: ProtocolDecoder,
    buf_out: netbuf::Buf,
    pub nick: String,
    roomId: Token,
}

impl HWClient {
    pub fn new(sock: TcpStream, roomId: &Token) -> HWClient {
        HWClient {
            sock: sock,
            decoder: ProtocolDecoder::new(),
            buf_out: netbuf::Buf::new(),
            nick: String::new(),
            roomId: roomId.clone(),
        }
    }

    pub fn register(&mut self, poll: &Poll, token: Token) {
        poll.register(&self.sock, token, Ready::all(),
                      PollOpt::edge())
            .ok().expect("could not register socket with event loop");

        self.send_msg(Connected(utils::PROTOCOL_VERSION));
    }

    pub fn deregister(&mut self, poll: &Poll) {
        poll.deregister(&self.sock);
    }

    pub fn send_raw_msg(&mut self, msg: &[u8]) {
        self.buf_out.write(msg).unwrap();
        self.flush();
    }

    pub fn send_string(&mut self, msg: &String) {
        self.send_raw_msg(&msg.as_bytes());
    }

    pub fn send_msg(&mut self, msg: messages::HWProtocolMessage) {
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
            let msgs = self.decoder.extract_messages();
            for msg in msgs {
                match msg {
                    Ping => response.push(SendMe(Pong.to_raw_protocol())),
                    Quit(Some(msg)) => response.push(ByeClient("User quit: ".to_string() + msg)),
                    Quit(None) => response.push(ByeClient("User quit".to_string())),
                    Nick(nick) => if self.nick.len() == 0 {
                        response.push(SetNick(nick.to_string()));
                    },
                    Malformed => warn!("Malformed/unknown message"),
                    Empty => warn!("Empty message"),
                    _ => unimplemented!(),
                }
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
