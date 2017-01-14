extern crate rand;
extern crate mio;
extern crate slab;
extern crate netbuf;
#[macro_use]
extern crate nom;
#[macro_use]
extern crate log;
extern crate env_logger;

//use std::io::*;
//use rand::Rng;
//use std::cmp::Ordering;
use mio::tcp::*;
use mio::*;

mod utils;
mod server;
mod protocol;

fn main() {
    env_logger::init().unwrap();

    info!("Hedgewars game server, protocol {}", utils::PROTOCOL_VERSION);

    let address = "0.0.0.0:46631".parse().unwrap();
    let listener = TcpListener::bind(&address).unwrap();
    let mut server = server::server::HWServer::new(listener, 1024, 512);

    let poll = Poll::new().unwrap();
    server.register(&poll).unwrap();

    let mut events = Events::with_capacity(1024);

    loop {
        poll.poll(&mut events, None).unwrap();

        for event in events.iter() {
            if event.kind().is_readable() {
                match event.token() {
                    utils::SERVER => server.accept(&poll).unwrap(),
                    tok => server.client_readable(&poll, tok).unwrap(),
                }
            }
            if event.kind().is_writable() {
                match event.token() {
                    utils::SERVER => unreachable!(),
                    tok => server.client_writable(&poll, tok).unwrap(),
                }
            }
            if event.kind().is_hup() || event.kind().is_error() {
                match event.token() {
                    utils::SERVER => unreachable!(),
                    tok => server.client_error(&poll, tok).unwrap(),
                }
            }
        }
    }
}
