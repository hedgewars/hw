use mio;

use crate::{
    server::{
        client::HWClient,
        server::HWServer,
        coretypes::ClientId,
        actions::{Action, Action::*}
    },
    protocol::messages::{
        HWProtocolMessage, HWServerMessage::*
    },
    utils::is_name_illegal
};
#[cfg(feature = "official-server")]
use openssl::sha::sha1;
use std::fmt::{Formatter, LowerHex};
use log::*;

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
    let s = format!("{}{}{}{}{}", salt1, salt2,
                    client.web_password, client.protocol_number, "!hedgewars");
    Sha1Digest(sha1(s.as_bytes()))
}

pub fn handle(server: & mut HWServer, client_id: ClientId, message: HWProtocolMessage) {
    match message {
        HWProtocolMessage::Nick(nick) => {
            let client = &mut server.clients[client_id];
            debug!("{} {}", nick, is_name_illegal(&nick));
            let actions = if client.room_id != None {
                unreachable!()
            }
            else if !client.nick.is_empty() {
                vec![ProtocolError("Nickname already provided.".to_string())]
            }
            else if is_name_illegal(&nick) {
                vec![ByeClient("Illegal nickname! Nicknames must be between 1-40 characters long, must not have a trailing or leading space and must not have any of these characters: $()*+?[]^{|}".to_string())]
            }
            else {
                client.nick = nick.clone();
                vec![Nick(nick).send_self().action(),
                     CheckRegistered]
            };

            server.react(client_id, actions);
        }
        HWProtocolMessage::Proto(proto) => {
            let client = &mut server.clients[client_id];
            let actions = if client.protocol_number != 0 {
                vec![ProtocolError("Protocol already known.".to_string())]
            }
            else if proto == 0 {
                vec![ProtocolError("Bad number.".to_string())]
            }
            else {
                client.protocol_number = proto;
                vec![Proto(proto).send_self().action(),
                     CheckRegistered]
            };
            server.react(client_id, actions);
        }
        #[cfg(feature = "official-server")]
        HWProtocolMessage::Password(hash, salt) => {
            let c = &server.clients[client_id];

            let client_hash = get_hash(c, &salt, &c.server_salt);
            let server_hash = get_hash(c, &c.server_salt, &salt);
            let actions = if client_hash == server_hash {
                vec![ServerAuth(format!("{:x}", server_hash)).send_self().action(),
                     JoinLobby]
            } else {
                vec![ByeClient("Authentication failed".to_string())]
            };
            server.react(client_id, actions);
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
