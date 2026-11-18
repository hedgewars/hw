use super::strings::*;
use crate::handlers::actions::ToPendingMessage;
use crate::{
    core::{
        anteroom::{HwAnteroom, HwAnteroomClient},
        server::HwServer,
        types::ClientId,
    },
    utils::{is_name_illegal, loc},
};
use hedgewars_network_protocol::messages::{HwProtocolMessage, HwServerMessage::*};
use log::*;
use rand::{thread_rng, Rng};
use std::num::NonZeroU16;

const GUEST_ADJECTIVES: &[&str] = &[
    "happy", "bouncy", "sneaky", "brave", "fuzzy", "spiky", "sleepy", "lucky", "dizzy", "swift",
    "cosmic", "pixel", "turbo", "stealth", "jolly", "mighty", "quirky", "flying", "atomic",
    "crimson", "golden", "silent", "wild", "clever", "rusty", "shiny", "noble", "eager", "chill",
    "epic", "astro", "cyber", "neon", "mystic", "grumpy", "fluffy", "daring", "curious", "rapid",
    "vivid",
];

const GUEST_NOUNS: &[&str] = &[
    "hog", "hedgehog", "melon", "bazooka", "ninja", "pirate", "knight", "wizard", "viking",
    "cyborg", "panda", "badger", "otter", "falcon", "dragon", "penguin", "cactus", "comet",
    "pilot", "ranger", "scout", "tinker", "jester", "samurai", "captain", "voyager", "nomad",
    "walker", "jumper", "diver",
];

pub fn generate_guest_nick(server: &HwServer, anteroom: &mut HwAnteroom) -> String {
    let mut rng = thread_rng();
    let is_taken = |candidate: &str, anteroom: &HwAnteroom| {
        is_name_illegal(candidate)
            || server
                .iter_clients()
                .any(|c| c.nick.eq_ignore_ascii_case(candidate))
            || anteroom.has_client_nick(candidate)
    };

    for _ in 0..64 {
        let adj = GUEST_ADJECTIVES[rng.gen_range(0..GUEST_ADJECTIVES.len())];
        let noun = GUEST_NOUNS[rng.gen_range(0..GUEST_NOUNS.len())];
        let num: u16 = rng.gen_range(10..1000);
        let small_num: u16 = rng.gen_range(10..100);
        let candidate = match rng.gen_range(0..6) {
            0 => format!("{}_guest_{}", adj, num),
            1 => format!("guest_{}_{}{}", adj, noun, small_num),
            2 => format!("{}_{}_guest_{}", adj, noun, small_num),
            3 => format!("guest_{}_{}", noun, num),
            4 => format!("{}-guest-{}", adj, num),
            _ => format!("guest-{}-{}-{}", adj, noun, small_num),
        };

        if !is_taken(&candidate, anteroom) && anteroom.bans.find_nick_ban(&candidate).is_none() {
            return candidate;
        }
    }

    loop {
        let candidate = format!("guest_{}", rng.gen_range(10_000..1_000_000));
        if !is_taken(&candidate, anteroom) {
            return candidate;
        }
    }
}

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
    let (mut nick, proto, is_checker, web_password) = {
        let client = anteroom.get_client(client_id);
        (
            client.nick.as_ref().unwrap().clone(),
            client.protocol_number.map_or(0, |p| p.get()),
            client.is_checker,
            client.web_password.clone(),
        )
    };

    if !is_checker {
        if let Some(reason) = anteroom.bans.find_nick_ban(&nick) {
            let new_nick = generate_guest_nick(server, anteroom);
            info!(
                "Client {} joined with banned nickname '{}' ({}), renamed to '{}'",
                client_id, nick, reason, new_nick
            );
            anteroom.get_client_mut(client_id).nick = Some(new_nick.clone());
            response.add(Nick(new_nick.clone()).send_self());
            nick = new_nick;
        }
    }

    if !is_checker
        && server
            .iter_clients()
            .any(|c| c.nick.eq_ignore_ascii_case(&nick))
    {
        if proto < 38 {
            warn!(
                "Client {} failed to join server: nickname '{}' already in use",
                client_id, nick
            );
            response.add(Bye(loc("Nickname is already in use").to_string()).send_self());
            return LoginResult::Exit;
        } else {
            info!(
                "Client {} nickname '{}' already in use, notice sent",
                client_id, nick
            );
            response.add(Notice("0".to_string()).send_self());
            anteroom.get_client_mut(client_id).nick = None;
            return LoginResult::Unchanged;
        }
    }

    if is_checker {
        if let Some(reason) = anteroom.bans.find_nick_ban(&nick) {
            warn!(
                "Client {} failed to join server: active ban for nickname '{}': {}",
                client_id, nick, reason
            );
            response.add(Bye(reason).send_self());
            return LoginResult::Exit;
        }
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
        } else if anteroom
            .no_anon
            .matches_opt(anteroom.get_client(client_id).ip_addr)
        {
            warn!("Client '{}' (id: {}) failed to join server: registered account required from this IP", nick, client_id);
            response.error(loc(
                "Registered account is required when logging in from this IP address",
            ));
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
            let msg = msg.unwrap_or_else(|| loc("bye").to_string());
            let nick_str = anteroom
                .get_client(client_id)
                .nick
                .as_deref()
                .unwrap_or("<unnamed>");
            info!(
                "Client '{}' (id: {}) quit from anteroom: {}",
                nick_str, client_id, msg
            );
            response.add(Bye(msg).send_self());
            LoginResult::Exit
        }
        HwProtocolMessage::Nick(mut nick, _token) => {
            if anteroom.get_client(client_id).nick.is_some() {
                warn!(
                    "Client {} failed to set nickname: already provided",
                    client_id
                );
                response.error(NICKNAME_PROVIDED);
                LoginResult::Unchanged
            } else if is_name_illegal(&nick) {
                warn!(
                    "Client {} failed to join server: illegal nickname '{}'",
                    client_id, nick
                );
                response.add(Bye(ILLEGAL_CLIENT_NAME.to_string()).send_self());
                LoginResult::Exit
            } else {
                if let Some(reason) = anteroom.bans.find_nick_ban(&nick) {
                    let new_nick = generate_guest_nick(server, anteroom);
                    info!(
                        "Client {} joined with banned nickname '{}' ({}), renamed to '{}'",
                        client_id, nick, reason, new_nick
                    );
                    nick = new_nick;
                }
                let client = anteroom.get_client_mut(client_id);
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
                warn!(
                    "Client {} failed to set protocol: already provided",
                    client_id
                );
                response.error(PROTOCOL_PROVIDED);
                LoginResult::Unchanged
            } else if proto == 0 {
                warn!(
                    "Client {} failed to join server: bad protocol number 0",
                    client_id
                );
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
            let nick_str = anteroom
                .get_client(client_id)
                .nick
                .as_deref()
                .unwrap_or("<unnamed>");
            warn!(
                "Client '{}' (id: {}) failed to join server: authentication failed",
                nick_str, client_id
            );
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
            let nick_str = anteroom
                .get_client(client_id)
                .nick
                .as_deref()
                .unwrap_or("<unnamed>");
            warn!(
                "Client '{}' (id: {}) failed to join server: authentication failed",
                nick_str, client_id
            );
            response.add(Bye(AUTHENTICATION_FAILED.to_string()).send_self());
            LoginResult::Exit
        }
        HwProtocolMessage::Checker(protocol, nick, password) => {
            if protocol == 0 {
                warn!(
                    "Checker '{}' failed to join server: bad protocol number 0",
                    nick
                );
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
                [] => response.error(loc("Empty command (state: not entered)")),
                ["PROTO", _] => {
                    if anteroom.get_client(client_id).protocol_number.is_some() {
                        warn!(
                            "Client {} failed to set protocol: already provided",
                            client_id
                        );
                        response.error(PROTOCOL_PROVIDED);
                    } else {
                        warn!(
                            "Client {} failed to join server: bad protocol number (malformed)",
                            client_id
                        );
                        response.error(BAD_NUMBER);
                    }
                }
                ["CHECKER", _, _, _] => {
                    warn!("Checker failed to join server: bad protocol number (malformed)");
                    response.error(BAD_NUMBER);
                }
                ["NICK", _] => {
                    if anteroom.get_client(client_id).nick.is_some() {
                        warn!(
                            "Client {} failed to set nickname: already provided",
                            client_id
                        );
                        response.error(NICKNAME_PROVIDED);
                    } else {
                        warn!(
                            "Client {} failed to join server: illegal nickname (malformed)",
                            client_id
                        );
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::handlers::{Response, ServerState};

    #[test]
    fn test_banned_nick_renamed_to_guest_and_let_in() {
        let mut state = ServerState::new(1024, 512);
        state
            .anteroom
            .bans
            .add_nick_ban("OutlawNick".to_string(), "bad nick".to_string(), 60);

        let cid: ClientId = 1;
        state.anteroom.add_client_with_ip(
            cid,
            "salt123456789012".to_string(),
            false,
            Some(std::net::IpAddr::V4(std::net::Ipv4Addr::LOCALHOST)),
        );

        let mut response = Response::new(cid);
        let res = handle(
            &state.server,
            &mut state.anteroom,
            cid,
            &mut response,
            HwProtocolMessage::Nick("OutlawNick".to_string(), None),
        );
        assert!(matches!(res, LoginResult::Unchanged));

        let assigned_nick = state
            .anteroom
            .get_client(cid)
            .nick
            .clone()
            .expect("nick should be set");
        assert_ne!(assigned_nick, "OutlawNick");
        assert!(
            assigned_nick.contains("guest"),
            "Assigned nick '{}' must contain 'guest'",
            assigned_nick
        );
        assert!(!is_name_illegal(&assigned_nick));

        let msgs: Vec<_> = response.extract_messages(&state.server).collect();
        assert_eq!(msgs.len(), 1);
        assert_eq!(msgs[0].1, Nick(assigned_nick.clone()));

        let mut response2 = Response::new(cid);
        let res2 = handle(
            &state.server,
            &mut state.anteroom,
            cid,
            &mut response2,
            HwProtocolMessage::Proto(59),
        );
        #[cfg(not(feature = "official-server"))]
        {
            match res2 {
                LoginResult::Complete(client) => {
                    assert_eq!(client.nick.as_deref(), Some(assigned_nick.as_str()));
                }
                _ => panic!("Expected LoginResult::Complete"),
            }
        }
        #[cfg(feature = "official-server")]
        {
            assert!(matches!(res2, LoginResult::Unchanged));
        }
    }
}
