use super::{indexslab::IndexSlab, types::ClientId};
use crate::core::client::HwClient;
use crate::core::digest::Sha1Digest;
use chrono::{offset, DateTime};
use std::collections::{HashMap, HashSet};
use std::{iter::Iterator, num::NonZeroU16};

pub struct HwAnteroomClient {
    pub nick: Option<String>,
    pub protocol_number: Option<NonZeroU16>,
    pub server_salt: String,
    pub is_checker: bool,
    pub is_local_admin: bool,
    pub is_registered: bool,
    pub is_admin: bool,
    pub is_contributor: bool,
}

struct Ipv4AddrRange {
    min: [u8; 4],
    max: [u8; 4],
}

impl Ipv4AddrRange {
    fn contains(&self, addr: [u8; 4]) -> bool {
        (0..4).all(|i| self.min[i] <= addr[i] && addr[i] <= self.max[i])
    }
}

struct BanCollection {
    ban_ips: Vec<Ipv4AddrRange>,
    ban_timeouts: Vec<DateTime<offset::Utc>>,
    ban_reasons: Vec<String>,
}

impl BanCollection {
    fn new() -> Self {
        //todo!("add nick bans");
        Self {
            ban_ips: vec![],
            ban_timeouts: vec![],
            ban_reasons: vec![],
        }
    }

    fn find(&self, addr: [u8; 4]) -> Option<String> {
        let time = offset::Utc::now();
        self.ban_ips
            .iter()
            .enumerate()
            .find(|(i, r)| r.contains(addr) && time < self.ban_timeouts[*i])
            .map(|(i, _)| self.ban_reasons[i].clone())
    }
}

pub struct HwAnteroom {
    clients: IndexSlab<HwAnteroomClient>,
    bans: BanCollection,
    taken_nicks: HashSet<String>,
    reconnection_tokens: HashMap<String, String>,
}

impl HwAnteroom {
    pub fn new(clients_limit: usize) -> Self {
        let clients = IndexSlab::with_capacity(clients_limit);
        HwAnteroom {
            clients,
            bans: BanCollection::new(),
            taken_nicks: Default::default(),
            reconnection_tokens: Default::default(),
        }
    }

    pub fn find_ip_ban(&self, addr: [u8; 4]) -> Option<String> {
        self.bans.find(addr)
    }

    pub fn add_client(&mut self, client_id: ClientId, salt: String, is_local_admin: bool) {
        let client = HwAnteroomClient {
            nick: None,
            protocol_number: None,
            server_salt: salt,
            is_checker: false,
            is_local_admin,
            is_registered: false,
            is_admin: false,
            is_contributor: false,
        };
        self.clients.insert(client_id, client);
    }

    pub fn has_client(&self, id: ClientId) -> bool {
        self.clients.contains(id)
    }

    pub fn get_client(&mut self, id: ClientId) -> &HwAnteroomClient {
        &self.clients[id]
    }

    pub fn get_client_mut(&mut self, id: ClientId) -> &mut HwAnteroomClient {
        &mut self.clients[id]
    }

    pub fn remove_client(&mut self, client_id: ClientId) -> Option<HwAnteroomClient> {
        let client = self.clients.remove(client_id);
        if let Some(HwAnteroomClient {
            nick: Some(nick), ..
        }) = &client
        {
            self.taken_nicks.remove(nick);
        }
        client
    }

    pub fn nick_taken(&self, nick: &str) -> bool {
        self.taken_nicks.contains(nick)
    }

    pub fn remember_nick(&mut self, nick: String) {
        self.taken_nicks.insert(nick);
    }

    pub fn forget_nick(&mut self, nick: &str) {
        self.taken_nicks.remove(nick);
    }

    #[inline]
    pub fn get_nick_token(&self, nick: &str) -> Option<&str> {
        self.reconnection_tokens.get(nick).map(|s| &s[..])
    }

    #[inline]
    pub fn register_nick_token(&mut self, nick: &str) -> Option<&str> {
        if self.reconnection_tokens.contains_key(nick) {
            None
        } else {
            let token = format!("{:x}", Sha1Digest::random());
            self.reconnection_tokens.insert(nick.to_string(), token);
            Some(&self.reconnection_tokens[nick])
        }
    }
}
