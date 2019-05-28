#![allow(unused_imports)]
#![deny(bare_trait_objects)]

use getopts::Options;
use log::*;
use mio::{net::*, *};
use std::{env, str::FromStr as _, time::Duration};

mod core;
mod handlers;
mod protocol;
mod server;
mod utils;

use crate::server::network::{NetworkLayer, NetworkLayerBuilder};

const PROGRAM_NAME: &'_ str = "Hedgewars Game Server";

fn main() {
    env_logger::init();

    info!("Hedgewars game server, protocol {}", utils::SERVER_VERSION);

    let args: Vec<String> = env::args().collect();
    let mut opts = Options::new();

    opts.optopt("p", "port", "port - defaults to 46631", "PORT");
    opts.optflag("h", "help", "help");
    let matches = match opts.parse(&args[1..]) {
        Ok(m) => m,
        Err(e) => {
            println!("{}\n{}", e, opts.short_usage(""));
            return;
        }
    };
    if matches.opt_present("h") {
        println!("{}", opts.usage(PROGRAM_NAME));
        return;
    }

    let port = matches
        .opt_str("p")
        .and_then(|s| u16::from_str(&s).ok())
        .unwrap_or(46631);
    let address = format!("0.0.0.0:{}", port).parse().unwrap();

    let listener = TcpListener::bind(&address).unwrap();

    let poll = Poll::new().unwrap();
    let mut hw_builder = NetworkLayerBuilder::default().with_listener(listener);

    #[cfg(feature = "tls-connections")]
    {
        let address = format!("0.0.0.0:{}", port + 1).parse().unwrap();
        hw_builder = hw_builder.with_secure_listener(TcpListener::bind(&address).unwrap());
    }

    let mut hw_network = hw_builder.build();
    hw_network.register(&poll).unwrap();

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
                    token @ utils::SERVER_TOKEN | token @ utils::SECURE_SERVER_TOKEN => {
                        match hw_network.accept_client(&poll, token) {
                            Ok(()) => (),
                            Err(e) => debug!("Error accepting client: {}", e),
                        }
                    }
                    utils::TIMER_TOKEN => match hw_network.handle_timeout(&poll) {
                        Ok(()) => (),
                        Err(e) => debug!("Error in timer event: {}", e),
                    },
                    #[cfg(feature = "official-server")]
                    utils::IO_TOKEN => match hw_network.handle_io_result() {
                        Ok(()) => (),
                        Err(e) => debug!("Error in IO task: {}", e),
                    },
                    Token(token) => match hw_network.client_readable(&poll, token) {
                        Ok(()) => (),
                        Err(e) => debug!("Error reading from client socket {}: {}", token, e),
                    },
                }
            }
            if event.readiness() & Ready::writable() == Ready::writable() {
                match event.token() {
                    utils::SERVER_TOKEN
                    | utils::SECURE_SERVER_TOKEN
                    | utils::TIMER_TOKEN
                    | utils::IO_TOKEN => unreachable!(),
                    Token(token) => match hw_network.client_writable(&poll, token) {
                        Ok(()) => (),
                        Err(e) => debug!("Error writing to client socket {}: {}", token, e),
                    },
                }
            }
        }

        match hw_network.on_idle(&poll) {
            Ok(()) => (),
            Err(e) => debug!("Error in idle handler: {}", e),
        };
    }
}
