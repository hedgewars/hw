use mio;

use crate::{
    protocol::messages::{HWProtocolMessage, HWServerMessage::*},
    server::{
        core::{HWAnteClient, HWAnteroom},
        coretypes::ClientId,
    },
    utils::is_name_illegal,
};
use log::*;
#[cfg(feature = "official-server")]
use openssl::sha::sha1;
use std::{
    fmt::{Formatter, LowerHex},
    num::NonZeroU16,
};

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
fn get_hash(client: &HWAnteClient, salt1: &str, salt2: &str) -> Sha1Digest {
    let s = format!(
        "{}{}{}{}{}",
        salt1, salt2, client.web_password, client.protocol_number, "!hedgewars"
    );
    Sha1Digest(sha1(s.as_bytes()))
}

pub enum LoginResult {
    Unchanged,
    Complete,
    Exit,
}

pub fn handle(
    anteroom: &mut HWAnteroom,
    client_id: ClientId,
    response: &mut super::Response,
    message: HWProtocolMessage,
) -> LoginResult {
    match message {
        HWProtocolMessage::Quit(_) => {
            response.add(Bye("User quit".to_string()).send_self());
            LoginResult::Exit
        }
        HWProtocolMessage::Nick(nick) => {
            let client = &mut anteroom.clients[client_id];
            debug!("{} {}", nick, is_name_illegal(&nick));
            if !client.nick.is_some() {
                response.add(Error("Nickname already provided.".to_string()).send_self());
                LoginResult::Unchanged
            } else if is_name_illegal(&nick) {
                response.add(Bye("Illegal nickname! Nicknames must be between 1-40 characters long, must not have a trailing or leading space and must not have any of these characters: $()*+?[]^{|}".to_string()).send_self());
                LoginResult::Exit
            } else {
                client.nick = Some(nick.clone());
                response.add(Nick(nick).send_self());

                if client.protocol_number.is_some() {
                    LoginResult::Complete
                } else {
                    LoginResult::Unchanged
                }
            }
        }
        HWProtocolMessage::Proto(proto) => {
            let client = &mut anteroom.clients[client_id];
            if client.protocol_number.is_some() {
                response.add(Error("Protocol already known.".to_string()).send_self());
                LoginResult::Unchanged
            } else if proto == 0 {
                response.add(Error("Bad number.".to_string()).send_self());
                LoginResult::Unchanged
            } else {
                client.protocol_number = NonZeroU16::new(proto);
                response.add(Proto(proto).send_self());

                if client.nick.is_some() {
                    LoginResult::Complete
                } else {
                    LoginResult::Unchanged
                }
            }
        }
        #[cfg(feature = "official-server")]
        HWProtocolMessage::Password(hash, salt) => {
            let client = &anteroom.clients[client_id];

            let client_hash = get_hash(client, &salt, &client.server_salt);
            let server_hash = get_hash(client, &client.server_salt, &salt);
            if client_hash == server_hash {
                response.add(ServerAuth(format!("{:x}", server_hash)).send_self());
                LoginResult::Complete
            } else {
                response.add(Bye("Authentication failed".to_string()).send_self());
                LoginResult::Exit
            }
        }
        #[cfg(feature = "official-server")]
        HWProtocolMessage::Checker(protocol, nick, password) => {
            let client = &mut anteroom.clients[client_id];
            client.protocol_number = Some(protocol);
            client.nick = Some(nick);
            client.web_password = password;
            //client.set_is_checker(true);
            LoginResult::Complete
        }
        _ => {
            warn!("Incorrect command in logging-in state");
            LoginResult::Unchanged
        }
    }
}
