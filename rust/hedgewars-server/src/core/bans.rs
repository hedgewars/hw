use chrono::{DateTime, Duration, NaiveDateTime, offset::Utc};

#[derive(Clone, Debug, PartialEq, Eq)]
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

    pub fn to_haskell_str(&self) -> String {
        match self {
            BanEntry::ByIp { ip, reason, until } => format!(
                "BanByIP {} {} {}",
                format_haskell_string(ip),
                format_haskell_string(reason),
                format_haskell_utc(*until)
            ),
            BanEntry::ByNick {
                nick,
                reason,
                until,
            } => format!(
                "BanByNick {} {} {}",
                format_haskell_string(nick),
                format_haskell_string(reason),
                format_haskell_utc(*until)
            ),
        }
    }
}

fn format_haskell_string(text: &str) -> String {
    let mut out = String::with_capacity(text.len() + 2);
    out.push('"');
    for c in text.chars() {
        if c == '"' || c == '\\' {
            out.push('\\');
            out.push(c);
        } else if c.is_ascii() && !(c as u8).is_ascii_control() {
            out.push(c);
        } else {
            let mut bytes = [0u8; 4];
            let size = c.encode_utf8(&mut bytes).len();
            for byte in &bytes[0..size] {
                out.push_str(&format!("\\{:03}", byte));
            }
        }
    }
    out.push('"');
    out
}

fn parse_haskell_string(input: &str) -> Option<(String, &str)> {
    let input = input.trim_start();
    let rest = input.strip_prefix('"')?;
    let mut bytes = Vec::new();
    let mut chars = rest.char_indices().peekable();
    while let Some((idx, c)) = chars.next() {
        if c == '"' {
            let tail = &rest[idx + 1..];
            let decoded = String::from_utf8(bytes).ok()?;
            return Some((decoded, tail));
        } else if c == '\\' {
            let (_, esc) = chars.next()?;
            match esc {
                '\\' => bytes.push(b'\\'),
                '"' => bytes.push(b'"'),
                '\'' => bytes.push(b'\''),
                'n' => bytes.push(b'\n'),
                'r' => bytes.push(b'\r'),
                't' => bytes.push(b'\t'),
                '&' => {}
                d if d.is_ascii_digit() => {
                    let mut num = (d as u8 - b'0') as u32;
                    while let Some(&(_, next_c)) = chars.peek() {
                        if next_c.is_ascii_digit() {
                            chars.next();
                            num = num * 10 + (next_c as u8 - b'0') as u32;
                        } else {
                            break;
                        }
                    }
                    if let Ok(b) = u8::try_from(num) {
                        bytes.push(b);
                    }
                }
                other => {
                    let mut buf = [0u8; 4];
                    bytes.extend_from_slice(other.encode_utf8(&mut buf).as_bytes());
                }
            }
        } else {
            let mut buf = [0u8; 4];
            bytes.extend_from_slice(c.encode_utf8(&mut buf).as_bytes());
        }
    }
    None
}

fn format_haskell_utc(dt: DateTime<Utc>) -> String {
    let base = dt.format("%Y-%m-%d %H:%M:%S").to_string();
    let nanos = dt.timestamp_subsec_nanos();
    if nanos == 0 {
        format!("{} UTC", base)
    } else {
        let frac = format!("{:09}", nanos);
        let frac = frac.trim_end_matches('0');
        format!("{}.{} UTC", base, frac)
    }
}

fn parse_haskell_utc(input: &str) -> Option<(DateTime<Utc>, &str)> {
    let input = input.trim_start();
    let utc_pos = input.find("UTC")?;
    let ts_str = input[..utc_pos].trim();
    let ndt = NaiveDateTime::parse_from_str(ts_str, "%Y-%m-%d %H:%M:%S%.f")
        .or_else(|_| NaiveDateTime::parse_from_str(ts_str, "%Y-%m-%d %H:%M:%S"))
        .ok()?;
    let dt = DateTime::<Utc>::from_naive_utc_and_offset(ndt, Utc);
    Some((dt, &input[utc_pos + 3..]))
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
    dirty: bool,
}

impl BanCollection {
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
            dirty: false,
        }
    }

    pub fn take_dirty(&mut self) -> bool {
        std::mem::replace(&mut self.dirty, false)
    }

    pub fn to_haskell_str(&self) -> String {
        let items: Vec<String> = self.entries.iter().map(BanEntry::to_haskell_str).collect();
        format!("[{}]", items.join(","))
    }

    pub fn from_haskell_str(s: &str) -> Self {
        let mut entries = Vec::new();
        let trimmed = s.trim();
        if let Some(mut rest) = trimmed.strip_prefix('[').and_then(|r| r.strip_suffix(']')) {
            loop {
                rest = rest.trim_start();
                if let Some(after_comma) = rest.strip_prefix(',') {
                    rest = after_comma.trim_start();
                }
                if rest.is_empty() {
                    break;
                }
                let (is_ip, after_tag) = if let Some(r) = rest.strip_prefix("BanByIP") {
                    (true, r)
                } else if let Some(r) = rest.strip_prefix("BanByNick") {
                    (false, r)
                } else {
                    break;
                };
                let Some((target, after_target)) = parse_haskell_string(after_tag) else {
                    break;
                };
                let Some((reason, after_reason)) = parse_haskell_string(after_target) else {
                    break;
                };
                let Some((until, after_utc)) = parse_haskell_utc(after_reason) else {
                    break;
                };
                if is_ip {
                    entries.push(BanEntry::ByIp {
                        ip: target,
                        reason,
                        until,
                    });
                } else {
                    entries.push(BanEntry::ByNick {
                        nick: target,
                        reason,
                        until,
                    });
                }
                rest = after_utc;
            }
        }
        Self {
            entries,
            dirty: false,
        }
    }

    fn prune_expired(&mut self, now: DateTime<Utc>) {
        let before = self.entries.len();
        self.entries.retain(|entry| entry.until() >= now);
        if self.entries.len() != before {
            self.dirty = true;
        }
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
        if ip.is_empty() {
            return;
        }
        let until = Utc::now() + Duration::seconds(duration_secs);
        self.entries.insert(
            0,
            BanEntry::ByIp {
                ip,
                reason,
                until,
            },
        );
        self.dirty = true;
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
        self.dirty = true;
    }

    pub fn unban(&mut self, target: &str) {
        let before = self.entries.len();
        self.entries.retain(|entry| match entry {
            BanEntry::ByIp { ip, .. } => ip != target,
            BanEntry::ByNick { nick, .. } => nick != target,
        });
        if self.entries.len() != before {
            self.dirty = true;
        }
    }

    #[allow(clippy::wrong_self_convention)]
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ban_haskell_roundtrip() {
        let sample = r#"[BanByIP "127.177.126.50" "60 seconds cooldown after kick" 2026-10-30 23:40:26.60201646 UTC]"#;
        let bans = BanCollection::from_haskell_str(sample);
        assert_eq!(bans.entries.len(), 1);
        assert_eq!(bans.to_haskell_str(), sample);

        let multi = r#"[BanByIP "127.0.0.1" "Ban for 60s (test)" 2026-11-02 23:40:00 UTC,BanByNick "OutlawNick" "Ban for 120s (bad)" 2026-11-02 23:42:00.125 UTC]"#;
        let bans2 = BanCollection::from_haskell_str(multi);
        assert_eq!(bans2.entries.len(), 2);
        assert_eq!(bans2.to_haskell_str(), multi);
    }
}
