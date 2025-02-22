use super::strings::*;
use crate::handlers::actions::ToPendingMessage;
use crate::{
    core::{
        anteroom::{HwAnteroom, HwAnteroomClient},
        client::HwClient,
        server::HwServer,
        types::ClientId,
    },
    utils::is_name_illegal,
};
use hedgewars_network_protocol::messages::{
    HwProtocolMessage, HwProtocolMessage::LoadRoom, HwServerMessage::*,
};
use log::*;
use std::{
    fmt::{Formatter, LowerHex},
    num::NonZeroU16,
};

pub enum LoginResult {
    Unchanged,
    Complete(HwAnteroomClient),
    Exit,
}

fn get_completion_result(
    anteroom: &mut HwAnteroom,
    client_id: ClientId,
    response: &mut super::Response,
) -> LoginResult {
    #[cfg(feature = "official-server")]
    {
        let client = anteroom.get_client(client_id);
        response.request_io(super::IoTask::CheckRegistered {
            nick: client.nick.as_ref().unwrap().clone(),
        });
        LoginResult::Unchanged
    }

    #[cfg(not(feature = "official-server"))]
    {
        LoginResult::Complete(anteroom.remove_client(client_id).unwrap())
    }
}

pub fn handle(
    anteroom: &mut HwAnteroom,
    client_id: ClientId,
    response: &mut super::Response,
    message: HwProtocolMessage,
) -> LoginResult {
    //todo!("Handle parsing of empty nicks")
    match message {
        HwProtocolMessage::Quit(_) => {
            response.add(Bye("User quit".to_string()).send_self());
            LoginResult::Exit
        }
        HwProtocolMessage::Nick(nick, token) => {
            if anteroom.nick_taken(&nick) {
                response.add(Notice("NickAlreadyInUse".to_string()).send_self());
                return LoginResult::Unchanged;
            }
            let reconnect = token
                .map(|t| anteroom.get_nick_token(&nick) == Some(&t[..]))
                .unwrap_or(false);
            let client = anteroom.get_client_mut(client_id);

            if client.nick.is_some() {
                response.error(NICKNAME_PROVIDED);
                LoginResult::Unchanged
            } else if is_name_illegal(&nick) {
                response.add(Bye(ILLEGAL_CLIENT_NAME.to_string()).send_self());
                LoginResult::Exit
            } else {
                client.nick = Some(nick.clone());
                let protocol_number = client.protocol_number;
                if reconnect {
                    client.is_registered = reconnect;
                } else if let Some(token) = anteroom.register_nick_token(&nick) {
                    response.add(Token(token.to_string()).send_self());
                }
                response.add(Nick(nick).send_self());

                if protocol_number.is_some() {
                    get_completion_result(anteroom, client_id, response)
                } else {
                    LoginResult::Unchanged
                }
            }
        }
        HwProtocolMessage::Proto(proto) => {
            let client = anteroom.get_client_mut(client_id);
            if client.protocol_number.is_some() {
                response.error(PROTOCOL_PROVIDED);
                LoginResult::Unchanged
            } else if proto < 48 {
                response.add(Bye(PROTOCOL_TOO_OLD.to_string()).send_self());
                LoginResult::Exit
            } else {
                client.protocol_number = NonZeroU16::new(proto);
                response.add(Proto(proto).send_self());

                if client.nick.is_some() {
                    get_completion_result(anteroom, client_id, response)
                } else {
                    LoginResult::Unchanged
                }
            }
        }
        #[cfg(feature = "official-server")]
        HwProtocolMessage::Password(hash, salt) => {
            let client = anteroom.get_client(client_id);

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
            let client = anteroom.get_client_mut(client_id);
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
                    anteroom.remember_nick(nick);
                    LoginResult::Complete(anteroom.remove_client(client_id).unwrap())
                }
            }
        }
        _ => {
            warn!("Incorrect command in anteroom");
            LoginResult::Unchanged
        }
    }
}
