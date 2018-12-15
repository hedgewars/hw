use mysql;
use mysql::{params, error::Error, error::DriverError};

struct AccountInfo {
    is_registered: bool,
    is_admin: bool,
    is_contributor: bool,
}

struct ServerStatistics {
    rooms: u32,
    players: u32,
}

struct Achievements {}

trait DatabaseInterface {
    fn check_account(username: &str, password: &str) -> AccountInfo;
    fn store_stats(stats: &ServerStatistics) -> Result<(), ()>;
    fn store_achievements(achievements: &Achievements) -> Result<(), ()>;
    fn get_replay_name(replay_id: u32) -> Result<String, ()>;
}

struct Database {
    pool: Option<mysql::Pool>,
}

impl Database {
    fn new() -> Self {
        Self { pool: None }
    }

    fn connect(&mut self, url: &str) -> Result<(), Error> {
        self.pool = Some(mysql::Pool::new(url)?);

        Ok(())
    }

    fn check_account(&mut self, username: &str, password: &str) -> AccountInfo {
        AccountInfo {
            is_registered: false,
            is_admin: false,
            is_contributor: false,
        }
    }

    fn store_stats(&mut self, stats: &ServerStatistics) -> Result<(), Error> {
        if let Some(pool) = &self.pool {
        for mut stmt in pool.prepare(r"INSERT INTO gameserver_stats (players, rooms, last_update) VALUES (:players, :rooms, UNIX_TIMESTAMP())").into_iter() {
                stmt.execute(params!{
                "players" => stats.players,
                "rooms" => stats.rooms,
            })?;
        }
            Ok(())
        } else {
            Err(DriverError::SetupError.into())
        }

    }

    fn store_achievements(&mut self, achievements: &Achievements) -> Result<(), ()> {
        Ok(())
    }

    fn get_replay_name(&mut self, replay_id: u32) -> Result<String, ()> {
        Err(())
    }
}
