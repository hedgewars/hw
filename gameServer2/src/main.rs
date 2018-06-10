#![allow(unused_imports)]

extern crate rand;
extern crate mio;
extern crate slab;
extern crate netbuf;
#[macro_use]
extern crate nom;
#[macro_use]
extern crate log;
extern crate env_logger;
#[macro_use] extern crate proptest;

//use std::io::*;
//use rand::Rng;
//use std::cmp::Ordering;
use mio::net::*;
use mio::*;

mod utils;
mod server;
mod protocol;

use server::network::NetworkLayer;

fn main() {
    env_logger::init().unwrap();

    info!("Hedgewars game server, protocol {}", utils::PROTOCOL_VERSION);

    let address = "0.0.0.0:46631".parse().unwrap();
    let listener = TcpListener::bind(&address).unwrap();

    let poll = Poll::new().unwrap();
    let mut hw_network = NetworkLayer::new(listener, 1024, 512);
    hw_network.register_server(&poll).unwrap();

    let mut events = Events::with_capacity(1024);

    loop {
        poll.poll(&mut events, None).unwrap();

        for event in events.iter() {
            if event.readiness() & Ready::readable() == Ready::readable() {
                match event.token() {
                    utils::SERVER => hw_network.accept_client(&poll).unwrap(),
                    Token(tok) => hw_network.client_readable(&poll, tok).unwrap(),
                }
            }
            if event.readiness() & Ready::writable() == Ready::writable() {
                match event.token() {
                    utils::SERVER => unreachable!(),
                    Token(tok) => hw_network.client_writable(&poll, tok).unwrap(),
                }
            }
//            if event.kind().is_hup() || event.kind().is_error() {
//                match event.token() {
//                    utils::SERVER => unreachable!(),
//                    Token(tok) => server.client_error(&poll, tok).unwrap(),
//                }
//            }
        }
    }
}
