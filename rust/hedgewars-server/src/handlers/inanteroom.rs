use mio;

use super::strings::*;
use crate::{
    core::{
        anteroom::{HwAnteroom, HwAnteroomClient},
        client::HwClient,
        server::HwServer,
        types::ClientId,
    },
    protocol::messages::{HwProtocolMessage, HwProtocolMessage::LoadRoom, HwServerMessage::*},
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

fn completion_result<'a, I>(
    mut other_clients: I,
    client: &mut HwAnteroomClient,
    response: &mut super::Response,
) -> LoginResult
where
    I: Iterator<Item = &'a HwClient>,
{
    let has_nick_clash = other_clients.any(|c| c.nick == *client.nick.as_ref().unwrap());

    if has_nick_clash {
        client.nick = None;
        response.add(Notice("NickAlreadyInUse".to_string()).send_self());
        LoginResult::Unchanged
    } else {
        #[cfg(feature = "official-server")]
        {
            response.request_io(super::IoTask::CheckRegistered {
                nick: client.nick.as_ref().unwrap().clone(),
            });
            LoginResult::Unchanged
        }

        #[cfg(not(feature = "official-server"))]
        {
            LoginResult::Complete
        }
    }
}

pub fn handle(
    server_state: &mut super::ServerState,
    client_id: ClientId,
    response: &mut super::Response,
    message: HwProtocolMessage,
) -> LoginResult {
    match message {
        HwProtocolMessage::Quit(_) => {
            response.add(Bye("User quit".to_string()).send_self());
            LoginResult::Exit
        }
        HwProtocolMessage::Nick(nick) => {
            let client = &mut server_state.anteroom.clients[client_id];

            if client.nick.is_some() {
                response.error(NICKNAME_PROVIDED);
                LoginResult::Unchanged
            } else if is_name_illegal(&nick) {
                response.add(Bye(ILLEGAL_CLIENT_NAME.to_string()).send_self());
                LoginResult::Exit
            } else {
                client.nick = Some(nick.clone());
                response.add(Nick(nick).send_self());

                if client.protocol_number.is_some() {
                    completion_result(server_state.server.iter_clients(), client, response)
                } else {
                    LoginResult::Unchanged
                }
            }
        }
        HwProtocolMessage::Proto(proto) => {
            let client = &mut server_state.anteroom.clients[client_id];
            if client.protocol_number.is_some() {
                response.error(PROTOCOL_PROVIDED);
                LoginResult::Unchanged
            } else if proto < 51 {
                response.add(Bye(PROTOCOL_TOO_OLD.to_string()).send_self());
                LoginResult::Exit
            } else {
                client.protocol_number = NonZeroU16::new(proto);
                response.add(Proto(proto).send_self());

                if client.nick.is_some() {
                    completion_result(server_state.server.iter_clients(), client, response)
                } else {
                    LoginResult::Unchanged
                }
            }
        }
        #[cfg(feature = "official-server")]
        HwProtocolMessage::Password(hash, salt) => {
            let client = &server_state.anteroom.clients[client_id];

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
        HwProtocolMessage::Checker(protocol, nick, password) => {
            let client = &mut server_state.anteroom.clients[client_id];
            if protocol == 0 {
                response.error("Bad number.");
                LoginResult::Unchanged
            } else {
                client.protocol_number = NonZeroU16::new(protocol);
                client.is_checker = true;
                #[cfg(not(feature = "official-server"))]
                {
                    response.request_io(super::IoTask::GetCheckerAccount {
                        nick: nick,
                        password: password,
                    });
                    LoginResult::Unchanged
                }

                #[cfg(feature = "official-server")]
                {
                    response.add(LogonPassed.send_self());
                    LoginResult::Complete
                }
            }
        }
        _ => {
            warn!("Incorrect command in anteroom");
            LoginResult::Unchanged
        }
    }
}
