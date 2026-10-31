use super::{
    bans::BanCollection, indexslab::IndexSlab, joins_monitor::JoinsMonitor, types::ClientId,
};
use crate::utils;
use base64::encode;
use log::*;
use rand::{thread_rng, RngCore};
use std::{collections::HashMap, num::NonZeroU16};

pub struct HwAnteroomClient {
    pub nick: Option<String>,
    pub protocol_number: Option<NonZeroU16>,
    pub server_salt: String,
    pub is_Checker: bool,
    pub is_local_admin: bool,
    pub is_registered: bool,
    pub is_admin: bool,
    pub is_contributor: bool,
    pub is_checker: bool,
    pub ip_addr: Option<[u8; 4]>,
    pub web_password: String,
    pub has_password_challenge: bool,
    pub pings_queue: u32,
}

impl HwAnteroomClient {
    pub fn host_string(&self) -> String {
        if let Some(ip) = self.ip_addr {
            format!("{}.{}.{}.{}", ip[0], ip[1], ip[2], ip[3])
        } else {
            String::new()
        }
    }
}

pub struct HwAnteroom {
    clients: IndexSlab<HwAnteroomClient>,
    pub bans: BanCollection,
    pub joins_monitor: JoinsMonitor,
    nicks: HashMap<String, String>,
}

impl HwAnteroom {
    pub fn new(clients_limit: usize) -> Self {
        let clients = IndexSlab::with_capacity(clients_limit);
        HwAnteroom {
            clients,
            bans: BanCollection::new(),
            joins_monitor: JoinsMonitor::new(),
            nicks: Default::default(),
        }
    }

    pub fn try_accept(&mut self, addr: Option<[u8; 4]>) -> Result<(), String> {
        if let Some(ip) = addr {
            if !self.joins_monitor.check_and_record(ip) {
                return Err("Reconnected too fast".to_string());
            }
            if let Some(reason) = self.bans.find_ip_ban(ip) {
                return Err(reason);
            }
        }
        Ok(())
    }

    pub fn add_client(&mut self, client_id: ClientId, salt: String, is_local: bool) {
        self.add_client_with_ip(client_id, salt, is_local, None);
    }

    pub fn add_client_with_ip(
        &mut self,
        client_id: ClientId,
        salt: String,
        is_local: bool,
        ip_addr: Option<[u8; 4]>,
    ) {
        let client = HwAnteroomClient {
            nick: None,
            protocol_number: None,
            server_salt: salt,
            is_Checker: false,
            is_local_admin: is_local,
            is_registered: false,
            is_admin: false,
            is_contributor: false,
            is_checker: false,
            ip_addr,
            web_password: String::new(),
            has_password_challenge: false,
            pings_queue: 0,
        };
        self.clients.insert(client_id, client);
    }

    pub fn has_client(&self, id: ClientId) -> bool {
        self.clients.contains(id)
    }

    pub fn get_client(&self, id: ClientId) -> &HwAnteroomClient {
        &self.clients[id]
    }

    pub fn get_client_mut(&mut self, id: ClientId) -> &mut HwAnteroomClient {
        &mut self.clients[id]
    }

    pub fn remove_client(&mut self, client_id: ClientId) -> Option<HwAnteroomClient> {
        self.clients.remove(client_id)
    }

    pub fn find_ban(&mut self, addr: [u8; 4]) -> Option<String> {
        self.bans.find_ip_ban(addr)
    }

    pub fn register_nick_token(&mut self, nick: &str) -> Option<&str> {
        debug!("Registering token for {}", nick);
        let mut bytes = [0u8; 18];
        thread_rng().fill_bytes(&mut bytes);
        self.nicks.insert(nick.to_string(), encode(bytes));
        self.get_nick_token(nick)
    }

    pub fn remember_nick(&mut self, nick: String) {
        self.nicks.insert(nick, String::new());
    }

    pub fn forget_nick(&mut self, nick: &str) {
        self.nicks.remove(nick);
    }

    pub fn get_nick_token(&self, nick: &str) -> Option<&str> {
        self.nicks.get(nick).map(|s| &s[..])
    }

    pub fn nick_taken(&self, nick: &str) -> bool {
        self.nicks.contains_key(nick)
    }
}
