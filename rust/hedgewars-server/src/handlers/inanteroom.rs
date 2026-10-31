use super::strings::*;
use crate::handlers::actions::ToPendingMessage;
use crate::{
    core::{
        anteroom::{HwAnteroom, HwAnteroomClient},
        server::HwServer,
        types::ClientId,
    },
    utils::is_name_illegal,
};
use hedgewars_network_protocol::messages::{HwProtocolMessage, HwServerMessage::*};
use std::num::NonZeroU16;

pub enum LoginResult {
    Unchanged,
    Complete(HwAnteroomClient),
    Exit,
}

fn get_completion_result(
    server: &HwServer,
    anteroom: &mut HwAnteroom,
    client_id: ClientId,
    response: &mut super::Response,
) -> LoginResult {
    let (nick, proto, is_checker, web_password) = {
        let client = anteroom.get_client(client_id);
        (
            client.nick.as_ref().unwrap().clone(),
            client.protocol_number.map_or(0, |p| p.get()),
            client.is_checker,
            client.web_password.clone(),
        )
    };

    if !is_checker
        && server
            .iter_clients()
            .any(|c| c.nick.eq_ignore_ascii_case(&nick))
    {
        if proto < 38 {
            response.add(Bye("Nickname is already in use".to_string()).send_self());
            return LoginResult::Exit;
        } else {
            response.add(Notice("0".to_string()).send_self());
            anteroom.get_client_mut(client_id).nick = None;
            return LoginResult::Unchanged;
        }
    }

    if let Some(reason) = anteroom.bans.find_nick_ban(&nick) {
        response.add(Bye(reason).send_self());
        return LoginResult::Exit;
    }

    #[cfg(feature = "official-server")]
    {
        if is_checker {
            response.request_io(super::IoTask::GetCheckerAccount {
                nick,
                password: web_password,
            });
        } else {
            response.request_io(super::IoTask::CheckRegistered { nick });
        }
        LoginResult::Unchanged
    }

    #[cfg(not(feature = "official-server"))]
    {
        let _ = web_password;
        if is_checker {
            response.add(Bye(NO_CHECKER_RIGHTS.to_string()).send_self());
            LoginResult::Exit
        } else if server.is_registered_only() {
            response.add(Bye(REGISTRATION_REQUIRED.to_string()).send_self());
            LoginResult::Exit
        } else {
            LoginResult::Complete(anteroom.remove_client(client_id).unwrap())
        }
    }
}

pub fn handle(
    server: &HwServer,
    anteroom: &mut HwAnteroom,
    client_id: ClientId,
    response: &mut super::Response,
    message: HwProtocolMessage,
) -> LoginResult {
    match message {
        HwProtocolMessage::Quit(msg) => {
            let msg = msg.unwrap_or_else(|| "bye".to_string());
            response.add(Bye(msg).send_self());
            LoginResult::Exit
        }
        HwProtocolMessage::Nick(nick, _token) => {
            let client = anteroom.get_client_mut(client_id);

            if client.nick.is_some() {
                response.error(NICKNAME_PROVIDED);
                LoginResult::Unchanged
            } else if is_name_illegal(&nick) {
                response.add(Bye(ILLEGAL_CLIENT_NAME.to_string()).send_self());
                LoginResult::Exit
            } else {
                client.nick = Some(nick.clone());
                let has_proto = client.protocol_number.is_some();
                response.add(Nick(nick).send_self());

                if has_proto {
                    get_completion_result(server, anteroom, client_id, response)
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
            } else if proto == 0 {
                response.error(BAD_NUMBER);
                LoginResult::Unchanged
            } else {
                client.protocol_number = NonZeroU16::new(proto);
                let has_nick = client.nick.is_some();
                response.add(Proto(proto).send_self());

                if has_nick {
                    get_completion_result(server, anteroom, client_id, response)
                } else {
                    LoginResult::Unchanged
                }
            }
        }
        HwProtocolMessage::Password(hash, salt) => {
            #[cfg(feature = "official-server")]
            {
                let client = anteroom.get_client(client_id);
                if let (Some(nick), Some(protocol)) = (client.nick.as_ref(), client.protocol_number)
                {
                    if client.has_password_challenge && protocol.get() >= 48 {
                        response.request_io(super::IoTask::GetAccount {
                            nick: nick.clone(),
                            protocol: protocol.get(),
                            server_salt: client.server_salt.clone(),
                            client_salt: salt,
                            password_hash: hash,
                        });
                        return LoginResult::Unchanged;
                    }
                }
            }
            let _ = (hash, salt);
            response.add(Bye(AUTHENTICATION_FAILED.to_string()).send_self());
            LoginResult::Exit
        }
        HwProtocolMessage::LegacyPassword(password) => {
            #[cfg(feature = "official-server")]
            {
                let client = anteroom.get_client(client_id);
                if let (Some(nick), Some(protocol)) = (client.nick.as_ref(), client.protocol_number)
                {
                    if client.has_password_challenge && protocol.get() < 48 {
                        response.request_io(super::IoTask::GetAccount {
                            nick: nick.clone(),
                            protocol: protocol.get(),
                            server_salt: client.server_salt.clone(),
                            client_salt: String::new(),
                            password_hash: password,
                        });
                        return LoginResult::Unchanged;
                    }
                }
            }
            let _ = password;
            response.add(Bye(AUTHENTICATION_FAILED.to_string()).send_self());
            LoginResult::Exit
        }
        HwProtocolMessage::Checker(protocol, nick, password) => {
            if protocol == 0 {
                response.error(BAD_NUMBER);
                LoginResult::Unchanged
            } else {
                let client = anteroom.get_client_mut(client_id);
                client.protocol_number = NonZeroU16::new(protocol);
                client.nick = Some(nick);
                client.web_password = password;
                client.is_checker = true;
                get_completion_result(server, anteroom, client_id, response)
            }
        }
        HwProtocolMessage::Malformed(lines) => {
            let refs: Vec<&str> = lines.iter().map(|s| s.as_str()).collect();
            match refs.as_slice() {
                [] => response.error("Empty command (state: not entered)"),
                ["PROTO", _] => {
                    if anteroom.get_client(client_id).protocol_number.is_some() {
                        response.error(PROTOCOL_PROVIDED);
                    } else {
                        response.error(BAD_NUMBER);
                    }
                }
                ["CHECKER", _, _, _] => response.error(BAD_NUMBER),
                ["NICK", _] => {
                    if anteroom.get_client(client_id).nick.is_some() {
                        response.error(NICKNAME_PROVIDED);
                    } else {
                        response.add(Bye(ILLEGAL_CLIENT_NAME.to_string()).send_self());
                        return LoginResult::Exit;
                    }
                }
                [cmd, ..] => {
                    response.error(&format!("Incorrect command '{}' (state: not entered)", cmd))
                }
            }
            LoginResult::Unchanged
        }
        other => {
            let cmd = super::common::protocol_cmd_name(&other);
            response.error(&format!("Incorrect command '{}' (state: not entered)", cmd));
            LoginResult::Unchanged
        }
    }
}
