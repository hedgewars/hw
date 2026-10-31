use std::{
    collections::HashMap,
    time::{Duration, Instant},
};

pub struct JoinsMonitor {
    joins: HashMap<[u8; 4], Vec<Instant>>,
}

impl JoinsMonitor {
    pub fn new() -> Self {
        Self {
            joins: HashMap::new(),
        }
    }

    pub fn check_and_record(&mut self, host: [u8; 4]) -> bool {
        let now = Instant::now();
        let timestamps = self.joins.entry(host).or_default();

        let last_30_sec = timestamps
            .iter()
            .take_while(|&&t| now.duration_since(t) < Duration::from_secs(30))
            .count();
        let last_2_min = timestamps
            .iter()
            .take_while(|&&t| now.duration_since(t) < Duration::from_secs(120))
            .count();
        let last_10_min = timestamps
            .iter()
            .take_while(|&&t| now.duration_since(t) < Duration::from_secs(600))
            .count();

        let pass = last_30_sec < 2 && last_2_min < 3 && last_10_min < 5;
        if pass {
            timestamps.insert(0, now);
        }
        pass
    }

    pub fn cleanup(&mut self) {
        let now = Instant::now();
        self.joins.retain(|_, v| {
            v.retain(|&t| now.duration_since(t) < Duration::from_secs(3600));
            !v.is_empty()
        });
    }
}
