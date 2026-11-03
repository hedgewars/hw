use log::*;
use std::fs;
use std::net::Ipv4Addr;
use std::path::Path;
use std::str::FromStr;

pub const NO_ANON_FILE_NAME: &str = "no_anon.txt";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Ipv4Net {
    network: u32,
    mask: u32,
}

impl Ipv4Net {
    pub fn new(ip: Ipv4Addr, prefix: u8) -> Option<Self> {
        if prefix > 32 {
            return None;
        }
        let mask = if prefix == 0 {
            0
        } else {
            !((1u64 << (32 - prefix)) - 1) as u32
        };
        let network = u32::from(ip) & mask;
        Some(Self { network, mask })
    }

    pub fn from_netmask(ip: Ipv4Addr, mask: Ipv4Addr) -> Self {
        let mask = u32::from(mask);
        let network = u32::from(ip) & mask;
        Self { network, mask }
    }

    pub fn contains(&self, ip: Ipv4Addr) -> bool {
        (u32::from(ip) & self.mask) == self.network
    }
}

impl FromStr for Ipv4Net {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let s = s.trim();
        if let Some((ip_part, mask_part)) = s.split_once('/') {
            let ip = Ipv4Addr::from_str(ip_part.trim()).map_err(|e| format!("Invalid IP: {}", e))?;
            let mask_part = mask_part.trim();
            if let Ok(prefix) = mask_part.parse::<u8>() {
                Ipv4Net::new(ip, prefix).ok_or_else(|| format!("Invalid prefix length: {}", prefix))
            } else if let Ok(mask_ip) = Ipv4Addr::from_str(mask_part) {
                Ok(Ipv4Net::from_netmask(ip, mask_ip))
            } else {
                Err(format!("Invalid mask: {}", mask_part))
            }
        } else {
            let ip = Ipv4Addr::from_str(s).map_err(|e| format!("Invalid IP: {}", e))?;
            Ok(Ipv4Net::new(ip, 32).unwrap())
        }
    }
}

#[derive(Debug, Clone, Default)]
pub struct NoAnonList {
    entries: Vec<Ipv4Net>,
}

impl NoAnonList {
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
        }
    }

    pub fn load() -> Self {
        Self::load_from_file(NO_ANON_FILE_NAME)
    }

    pub fn load_from_file<P: AsRef<Path>>(path: P) -> Self {
        let path_ref = path.as_ref();
        let content = match fs::read_to_string(path_ref) {
            Ok(c) => {
                info!("Loaded {} configuration", path_ref.display());
                c
            }
            Err(_) => return Self::new(),
        };
        Self::from_str(&content)
    }

    pub fn from_str(content: &str) -> Self {
        let mut entries = Vec::new();
        for (line_num, line) in content.lines().enumerate() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') || line.starts_with("//") {
                continue;
            }
            match line.parse::<Ipv4Net>() {
                Ok(net) => entries.push(net),
                Err(err) => warn!("no_anon line {}: {}", line_num + 1, err),
            }
        }
        Self { entries }
    }

    pub fn matches(&self, ip: [u8; 4]) -> bool {
        let ip = Ipv4Addr::from(ip);
        self.entries.iter().any(|net| net.contains(ip))
    }

    pub fn matches_opt(&self, ip_opt: Option<[u8; 4]>) -> bool {
        match ip_opt {
            Some(ip) => self.matches(ip),
            None => false,
        }
    }

    pub fn len(&self) -> usize {
        self.entries.len()
    }

    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_single_ip() {
        let net: Ipv4Net = "192.168.1.10".parse().unwrap();
        assert!(net.contains(Ipv4Addr::new(192, 168, 1, 10)));
        assert!(!net.contains(Ipv4Addr::new(192, 168, 1, 11)));
        assert!(!net.contains(Ipv4Addr::new(192, 168, 2, 10)));
    }

    #[test]
    fn test_cidr_prefix() {
        let net: Ipv4Net = "10.0.0.0/8".parse().unwrap();
        assert!(net.contains(Ipv4Addr::new(10, 0, 0, 1)));
        assert!(net.contains(Ipv4Addr::new(10, 255, 255, 255)));
        assert!(!net.contains(Ipv4Addr::new(11, 0, 0, 1)));

        let net24: Ipv4Net = "192.168.5.0/24".parse().unwrap();
        assert!(net24.contains(Ipv4Addr::new(192, 168, 5, 0)));
        assert!(net24.contains(Ipv4Addr::new(192, 168, 5, 254)));
        assert!(!net24.contains(Ipv4Addr::new(192, 168, 6, 1)));
    }

    #[test]
    fn test_dotted_netmask() {
        let net: Ipv4Net = "172.16.0.0/255.240.0.0".parse().unwrap();
        assert!(net.contains(Ipv4Addr::new(172, 16, 1, 1)));
        assert!(net.contains(Ipv4Addr::new(172, 31, 255, 255)));
        assert!(!net.contains(Ipv4Addr::new(172, 32, 0, 1)));
    }

    #[test]
    fn test_list_parsing() {
        let config = "
            # Comment line
            // Another comment
            127.0.0.1
            192.168.1.0/24
            10.20.30.0/255.255.255.0
        ";
        let list = NoAnonList::from_str(config);
        assert_eq!(list.len(), 3);
        assert!(list.matches([127, 0, 0, 1]));
        assert!(!list.matches([127, 0, 0, 2]));
        assert!(list.matches([192, 168, 1, 55]));
        assert!(!list.matches([192, 168, 2, 55]));
        assert!(list.matches([10, 20, 30, 99]));
    }

    #[test]
    fn test_missing_file() {
        let list = NoAnonList::load_from_file("nonexistent_no_anon_file_12345.txt");
        assert!(list.is_empty());
        assert!(!list.matches([127, 0, 0, 1]));
    }
}
