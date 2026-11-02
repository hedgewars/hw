use super::{anteroom::HwAnteroom, bans::BanCollection, server::HwServer};
use log::*;
use std::{collections::BTreeMap, fs};

pub const CONFIG_FILE_NAME: &str = "hedgewars-server.ini";

#[derive(Debug, Clone)]
pub struct ServerConfig {
    pub db_host: String,
    pub db_name: String,
    pub db_login: String,
    pub db_password: String,
    entries: BTreeMap<String, String>,
}

impl ServerConfig {
    pub fn load(server: &mut HwServer, anteroom: &mut HwAnteroom) -> Option<Self> {
        Self::load_from_file(CONFIG_FILE_NAME, server, anteroom)
    }

    pub fn load_from_file(
        path: &str,
        server: &mut HwServer,
        anteroom: &mut HwAnteroom,
    ) -> Option<Self> {
        let content = fs::read_to_string(path).ok()?;
        let entries = parse_ini(&content);

        let db_host = entries.get("dbHost").cloned().unwrap_or_default();
        let db_name = entries.get("dbName").cloned().unwrap_or_default();
        let db_login = entries.get("dbLogin").cloned().unwrap_or_default();
        let db_password = entries.get("dbPassword").cloned().unwrap_or_default();

        if let Some(msg) = entries.get("sv_message") {
            server.set_latest_greeting(msg.clone());
        }
        if let Some(msg_old) = entries.get("sv_messageOld") {
            server.set_old_greeting(msg_old.clone());
        }
        if let Some(proto_str) = entries.get("sv_latestProto") {
            if let Ok(proto) = proto_str.trim().parse::<u16>() {
                server.set_latest_protocol(proto);
            }
        }
        if let Some(bans_str) = entries.get("bans") {
            anteroom.bans = BanCollection::from_haskell_str(bans_str);
        }

        let mut cfg = Self {
            db_host,
            db_name,
            db_login,
            db_password,
            entries,
        };
        cfg.save_to_file(path, server, anteroom);
        Some(cfg)
    }

    pub fn save(&mut self, server: &HwServer, anteroom: &HwAnteroom) {
        self.save_to_file(CONFIG_FILE_NAME, server, anteroom);
    }

    pub fn save_to_file(&mut self, path: &str, server: &HwServer, anteroom: &HwAnteroom) {
        self.entries
            .insert("dbHost".to_string(), self.db_host.clone());
        self.entries
            .insert("dbName".to_string(), self.db_name.clone());
        self.entries
            .insert("dbLogin".to_string(), self.db_login.clone());
        self.entries
            .insert("dbPassword".to_string(), self.db_password.clone());
        self.entries.insert(
            "sv_message".to_string(),
            server.latest_greeting().to_string(),
        );
        self.entries.insert(
            "sv_messageOld".to_string(),
            server.old_greeting().to_string(),
        );
        self.entries.insert(
            "sv_latestProto".to_string(),
            server.latest_protocol().to_string(),
        );
        self.entries
            .insert("bans".to_string(), anteroom.bans.to_haskell_str());

        let content = format_ini(&self.entries);
        if let Err(e) = fs::write(path, content) {
            warn!("Failed to write server config to {}: {}", path, e);
        }
    }

    #[allow(dead_code)]
    pub fn database_url(&self) -> String {
        let host = if self.db_host.is_empty() || self.db_host == "localhost" {
            "127.0.0.1"
        } else {
            &self.db_host
        };
        let login = if self.db_login.is_empty() {
            "hedgewars"
        } else {
            &self.db_login
        };
        let name = if self.db_name.is_empty() {
            "hedgewars"
        } else {
            &self.db_name
        };
        if self.db_password.is_empty() {
            format!("mysql://{}@{}/{}", login, host, name)
        } else {
            format!("mysql://{}:{}@{}/{}", login, self.db_password, host, name)
        }
    }
}

pub fn parse_ini(content: &str) -> BTreeMap<String, String> {
    let mut map = BTreeMap::new();
    for line in content.lines() {
        if let Some(eq_idx) = line.find('=') {
            let key: String = line[..eq_idx]
                .chars()
                .filter(|c| !c.is_whitespace())
                .collect();
            let val: String = line[eq_idx + 1..]
                .trim_start_matches(|c: char| c.is_whitespace())
                .to_string();
            if !key.is_empty() {
                map.insert(key, val);
            }
        }
    }
    map
}

pub fn format_ini(entries: &BTreeMap<String, String>) -> String {
    let mut out = String::new();
    for (k, v) in entries {
        out.push_str(k);
        out.push_str(" = ");
        out.push_str(v);
        out.push('\n');
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ini_parse_and_format() {
        let sample = "bans = [BanByIP \"127.177.126.50\" \"60 seconds cooldown after kick\" 2026-10-30 23:40:26.60201646 UTC]\n\
dbHost = localhost\n\
dbLogin = hedgewars\n\
dbName = hedgewars\n\
dbPassword = \n\
sv_latestProto = 59\n\
sv_message = <h2><p align=center><a href=\"https://www.hedgewars.org/\">https://www.hedgewars.org/</a></p></h2>\n\
sv_messageOld = <font color=yellow><h3 align=center>Hedgewars 1.0.0 is out! Please update.</h3><p align=center><a href=https://hedgewars.org/download.html>Download page here</a></font>\n";

        let parsed = parse_ini(sample);
        assert_eq!(parsed.get("dbHost").unwrap(), "localhost");
        assert_eq!(parsed.get("dbPassword").unwrap(), "");
        assert_eq!(parsed.get("sv_latestProto").unwrap(), "59");

        let formatted = format_ini(&parsed);
        assert_eq!(formatted, sample);
    }
}
