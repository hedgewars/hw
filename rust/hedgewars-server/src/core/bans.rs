use chrono::{DateTime, Duration, offset::Utc};

#[derive(Clone, Debug)]
pub enum BanEntry {
    ByIp {
        ip: String,
        reason: String,
        until: DateTime<Utc>,
    },
    ByNick {
        nick: String,
        reason: String,
        until: DateTime<Utc>,
    },
}

impl BanEntry {
    pub fn until(&self) -> DateTime<Utc> {
        match self {
            BanEntry::ByIp { until, .. } | BanEntry::ByNick { until, .. } => *until,
        }
    }

    pub fn reason(&self) -> &str {
        match self {
            BanEntry::ByIp { reason, .. } | BanEntry::ByNick { reason, .. } => reason,
        }
    }
}

fn is_ban_match(pattern: &str, target: &str) -> bool {
    if pattern.is_empty() {
        false
    } else {
        target
            .to_ascii_lowercase()
            .contains(&pattern.to_ascii_lowercase())
    }
}

pub struct BanCollection {
    entries: Vec<BanEntry>,
}

impl BanCollection {
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
        }
    }

    fn prune_expired(&mut self, now: DateTime<Utc>) {
        self.entries.retain(|entry| entry.until() >= now);
    }

    pub fn find_ip_ban(&mut self, addr: [u8; 4]) -> Option<String> {
        let ip_str = format!("{}.{}.{}.{}", addr[0], addr[1], addr[2], addr[3]);
        self.find_ip_str_ban(&ip_str)
    }

    pub fn find_ip_str_ban(&mut self, ip: &str) -> Option<String> {
        let now = Utc::now();
        self.prune_expired(now);
        self.entries.iter().find_map(|entry| match entry {
            BanEntry::ByIp {
                ip: ban_ip, reason, ..
            } if is_ban_match(ban_ip, ip) => Some(reason.clone()),
            _ => None,
        })
    }

    pub fn find_nick_ban(&mut self, nick: &str) -> Option<String> {
        let now = Utc::now();
        self.prune_expired(now);
        self.entries.iter().find_map(|entry| match entry {
            BanEntry::ByNick {
                nick: ban_nick,
                reason,
                ..
            } if is_ban_match(ban_nick, nick) => Some(reason.clone()),
            _ => None,
        })
    }

    pub fn add_ip_ban_raw(&mut self, ip: String, reason: String, duration_secs: i64) {
        let until = Utc::now() + Duration::seconds(duration_secs);
        self.entries.insert(
            0,
            BanEntry::ByIp {
                ip,
                reason,
                until,
            },
        );
    }

    pub fn add_ip_ban(&mut self, ip: String, reason: String, seconds: u32) {
        let msg = format!("Ban for {}s ({})", seconds, reason);
        self.add_ip_ban_raw(ip, msg, seconds as i64);
    }

    pub fn add_nick_ban(&mut self, nick: String, reason: String, seconds: u32) {
        let msg = if seconds > 60 * 60 * 24 * 365 {
            format!("Permanent ban ({})", reason)
        } else {
            format!("Ban for {}s ({})", seconds, reason)
        };
        let until = Utc::now() + Duration::seconds(seconds as i64);
        self.entries.insert(
            0,
            BanEntry::ByNick {
                nick,
                reason: msg,
                until,
            },
        );
    }

    pub fn unban(&mut self, target: &str) {
        self.entries.retain(|entry| match entry {
            BanEntry::ByIp { ip, .. } => ip != target,
            BanEntry::ByNick { nick, .. } => nick != target,
        });
    }

    pub fn to_protocol_list(&mut self) -> Vec<String> {
        let now = Utc::now();
        self.prune_expired(now);
        let mut result = Vec::with_capacity(self.entries.len() * 4);
        for entry in &self.entries {
            let remaining = (entry.until() - now).num_seconds().max(0);
            match entry {
                BanEntry::ByIp { ip, reason, .. } => {
                    result.push("I".to_string());
                    result.push(ip.clone());
                    result.push(reason.clone());
                    result.push(format!("{}s", remaining));
                }
                BanEntry::ByNick { nick, reason, .. } => {
                    result.push("N".to_string());
                    result.push(nick.clone());
                    result.push(reason.clone());
                    result.push(format!("{}s", remaining));
                }
            }
        }
        result
    }
}
