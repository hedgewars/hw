#![forbid(unsafe_code)]
#![allow(unused_imports)]
#![allow(dead_code)]
#![allow(unused_variables)]
#![deny(bare_trait_objects)]

use getopts::Options;
use log::*;
use std::{env, net::SocketAddr, str::FromStr as _};

mod core;
mod handlers;
mod protocol;
mod server;
mod utils;

use crate::server::network::{NetworkLayer, NetworkLayerBuilder};

const PROGRAM_NAME: &'_ str = "Hedgewars Game Server";

#[tokio::main]
async fn main() -> tokio::io::Result<()> {
    env_logger::init();

    info!("Hedgewars game server, protocol {}", utils::SERVER_VERSION);

    let args: Vec<String> = env::args().collect();
    let mut opts = Options::new();

    //todo!("Add options for cert paths");
    opts.optopt("p", "port", "port - defaults to 46631", "PORT");
    opts.optflag("h", "help", "help");
    let matches = match opts.parse(&args[1..]) {
        Ok(m) => m,
        Err(e) => {
            println!("{}\n{}", e, opts.short_usage(""));
            return Ok(());
        }
    };
    if matches.opt_present("h") {
        println!("{}", opts.usage(PROGRAM_NAME));
        return Ok(());
    }

    let port = matches
        .opt_str("p")
        .and_then(|s| u16::from_str(&s).ok())
        .unwrap_or(46631);
    let address: SocketAddr = format!("0.0.0.0:{}", port).parse().unwrap();

    let server = tokio::net::TcpListener::bind(address).await.unwrap();

    let mut hw_network = NetworkLayerBuilder::default().with_listener(server).build();

    hw_network.run().await;
    Ok(())
}
