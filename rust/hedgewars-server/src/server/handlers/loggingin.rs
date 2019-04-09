use mio;

use crate::protocol::messages::HWProtocolMessage::LoadRoom;
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

pub enum LoginResult {
    Unchanged,
    Complete,
    Exit,
}

fn completion_result(client: &HWAnteClient, response: &mut super::Response) -> LoginResult {
    #[cfg(feature = "official-server")]
    {
        response.add(AskPassword(client.server_salt.clone()).send_self());
        LoginResult::Unchanged
    }

    #[cfg(not(feature = "official-server"))]
    {
        LoginResult::Complete
    }
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
                    completion_result(&client, response)
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
                    completion_result(&client, response)
                } else {
                    LoginResult::Unchanged
                }
            }
        }
        #[cfg(feature = "official-server")]
        HWProtocolMessage::Password(hash, salt) => {
            let client = &anteroom.clients[client_id];

            if let (Some(nick), Some(protocol)) = (client.nick.as_ref(), client.protocol_number) {
                response.request_io(super::IoTask::GetAccount {
                    nick: nick.clone(),
                    protocol: protocol.get(),
                    server_salt: client.server_salt.clone(),
                    client_salt: salt,
                    password_hash: hash,
                });
            };

            LoginResult::Unchanged
        }
        #[cfg(feature = "official-server")]
        HWProtocolMessage::Checker(protocol, nick, password) => {
            let client = &mut anteroom.clients[client_id];
            client.protocol_number = NonZeroU16::new(protocol);
            client.nick = Some(nick);
            //client.set_is_checker(true);
            LoginResult::Complete
        }
        _ => {
            warn!("Incorrect command in logging-in state");
            LoginResult::Unchanged
        }
    }
}
