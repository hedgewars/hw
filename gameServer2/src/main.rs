#![allow(unused_imports)]
#![deny(bare_trait_objects)]

extern crate rand;
extern crate mio;
extern crate slab;
extern crate netbuf;
extern crate base64;
#[macro_use]
extern crate nom;
#[macro_use]
extern crate log;
extern crate env_logger;
#[cfg(test)]
#[macro_use] extern crate proptest;
#[macro_use] extern crate bitflags;
extern crate serde;
extern crate serde_yaml;
#[cfg(feature = "tls-connections")]
extern crate openssl;
#[macro_use] extern crate serde_derive;

//use std::io::*;
//use rand::Rng;
//use std::cmp::Ordering;
use mio::net::*;
use mio::*;

mod utils;
mod server;
mod protocol;

use crate::server::network::NetworkLayer;
use std::time::Duration;

fn main() {
    env_logger::init();

    info!("Hedgewars game server, protocol {}", utils::PROTOCOL_VERSION);

    let address = "0.0.0.0:46631".parse().unwrap();
    let listener = TcpListener::bind(&address).unwrap();

    let poll = Poll::new().unwrap();
    let mut hw_network = NetworkLayer::new(listener, 1024, 512);
    hw_network.register_server(&poll).unwrap();

    let mut events = Events::with_capacity(1024);

    loop {
        let timeout = if hw_network.has_pending_operations() {
            Some(Duration::from_millis(1))
        } else {
            None
        };
        poll.poll(&mut events, timeout).unwrap();

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
        hw_network.on_idle(&poll).unwrap();
    }
}
