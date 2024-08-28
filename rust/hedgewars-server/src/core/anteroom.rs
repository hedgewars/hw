use super::{indexslab::IndexSlab, types::ClientId};
use chrono::{offset, DateTime};
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
    pub clients: IndexSlab<HwAnteroomClient>,
    bans: BanCollection,
}

impl HwAnteroom {
    pub fn new(clients_limit: usize) -> Self {
        let clients = IndexSlab::with_capacity(clients_limit);
        HwAnteroom {
            clients,
            bans: BanCollection::new(),
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

    pub fn remove_client(&mut self, client_id: ClientId) -> Option<HwAnteroomClient> {
        let client = self.clients.remove(client_id);
        client
    }
}
