use mio;

use crate::{
    protocol::messages::{HWProtocolMessage, HWServerMessage::*},
    server::{
        actions::{Action, Action::*},
        client::HWClient,
        core::HWServer,
        coretypes::ClientId,
    },
    utils::is_name_illegal,
};
use log::*;
#[cfg(feature = "official-server")]
use openssl::sha::sha1;
use std::fmt::{Formatter, LowerHex};

#[derive(PartialEq)]
struct Sha1Digest([u8; 20]);

impl LowerHex for Sha1Digest {
    fn fmt(&self, f: &mut Formatter) -> Result<(), std::fmt::Error> {
        for byte in &self.0 {
            write!(f, "{:02x}", byte)?;
        }
        Ok(())
    }
}

#[cfg(feature = "official-server")]
fn get_hash(client: &HWClient, salt1: &str, salt2: &str) -> Sha1Digest {
    let s = format!(
        "{}{}{}{}{}",
        salt1, salt2, client.web_password, client.protocol_number, "!hedgewars"
    );
    Sha1Digest(sha1(s.as_bytes()))
}

pub fn handle(
    server: &mut HWServer,
    client_id: ClientId,
    response: &mut super::Response,
    message: HWProtocolMessage,
) {
    match message {
        HWProtocolMessage::Nick(nick) => {
            let client = &mut server.clients[client_id];
            debug!("{} {}", nick, is_name_illegal(&nick));
            if client.room_id != None {
                unreachable!()
            } else if !client.nick.is_empty() {
                response.add(Error("Nickname already provided.".to_string()).send_self());
            } else if is_name_illegal(&nick) {
                super::common::remove_client(server, response, "Illegal nickname! Nicknames must be between 1-40 characters long, must not have a trailing or leading space and must not have any of these characters: $()*+?[]^{|}".to_string())
            } else {
                client.nick = nick.clone();
                response.add(Nick(nick).send_self());

                if client.protocol_number > 0 {
                    super::common::process_login(server, response);
                }
            }
        }
        HWProtocolMessage::Proto(proto) => {
            let client = &mut server.clients[client_id];
            if client.protocol_number != 0 {
                response.add(Error("Protocol already known.".to_string()).send_self());
            } else if proto == 0 {
                response.add(Error("Bad number.".to_string()).send_self());
            } else {
                client.protocol_number = proto;
                response.add(Proto(proto).send_self());

                if client.nick != "" {
                    super::common::process_login(server, response);
                }
            }
        }
        #[cfg(feature = "official-server")]
        HWProtocolMessage::Password(hash, salt) => {
            let c = &server.clients[client_id];

            let client_hash = get_hash(c, &salt, &c.server_salt);
            let server_hash = get_hash(c, &c.server_salt, &salt);
            if client_hash == server_hash {
                response.add(ServerAuth(format!("{:x}", server_hash)).send_self());
            //TODO enter lobby
            } else {
                super::common::remove_client(server, response, "Authentication failed".to_string())
            };
        }
        #[cfg(feature = "official-server")]
        HWProtocolMessage::Checker(protocol, nick, password) => {
            let c = &mut server.clients[client_id];
            c.nick = nick;
            c.web_password = password;
            c.set_is_checker(true);
        }
        _ => warn!("Incorrect command in logging-in state"),
    }
}
