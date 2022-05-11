use mysql_async::{self, from_row_opt, params, prelude::*, Pool};
use sha1::{Digest, Sha1};

use crate::handlers::{AccountInfo, Sha1Digest};

const CHECK_ACCOUNT_EXISTS_QUERY: &str =
    r"SELECT 1 FROM users WHERE users.name = :username LIMIT 1";

const GET_ACCOUNT_QUERY: &str = r"SELECT CASE WHEN users.status = 1 THEN users.pass ELSE '' END,
     (SELECT COUNT(users_roles.rid) FROM users_roles WHERE users.uid = users_roles.uid AND users_roles.rid = 3),
     (SELECT COUNT(users_roles.rid) FROM users_roles WHERE users.uid = users_roles.uid AND users_roles.rid = 13)
     FROM users WHERE users.name = :username";

const STORE_STATS_QUERY: &str = r"INSERT INTO gameserver_stats
      (players, rooms, last_update)
      VALUES
      (:players, :rooms, UNIX_TIMESTAMP())";

const GET_REPLAY_NAME_QUERY: &str = r"SELECT filename FROM achievements WHERE id = :id";

pub struct ServerStatistics {
    rooms: u32,
    players: u32,
}

pub struct Achievements {}

pub struct Database {
    pool: Pool,
}

impl Database {
    pub fn new(url: &str) -> Self {
        Self {
            pool: Pool::new(url),
        }
    }

    pub async fn get_is_registered(&mut self, nick: &str) -> mysql_async::Result<bool> {
        let mut connection = self.pool.get_conn().await?;
        let result = CHECK_ACCOUNT_EXISTS_QUERY
            .with(params! { "username" => nick })
            .first(&mut connection)
            .await?;
        Ok(!result.is_empty())
    }

    pub async fn get_account(
        &mut self,
        nick: &str,
        protocol: u16,
        password_hash: &str,
        client_salt: &str,
        server_salt: &str,
    ) -> mysql_async::Result<Option<AccountInfo>> {
        let mut connection = self.pool.get_conn().await?;
        if let Some((mut password, is_admin, is_contributor)) = GET_ACCOUNT_QUERY
            .with(params! { "username" => nick })
            .first::<(String, i32, i32), _>(&mut connection)
            .await?
        {
            let client_hash = get_hash(protocol, &password, &client_salt, &server_salt);
            let server_hash = get_hash(protocol, &password, &server_salt, &client_salt);
            password.replace_range(.., "🦔🦔🦔🦔🦔🦔🦔🦔");

            if client_hash == password_hash {
                Ok(Some(AccountInfo {
                    is_registered: true,
                    is_admin: is_admin == 1,
                    is_contributor: is_contributor == 1,
                    server_hash,
                }))
            } else {
                Ok(None)
            }
        } else {
            Ok(None)
        }
    }

    pub async fn get_checker_account(
        &mut self,
        nick: &str,
        checker_password: &str,
    ) -> mysql_async::Result<bool> {
        let mut connection = self.pool.get_conn().await?;
        if let Some((password, _, _)) = GET_ACCOUNT_QUERY
            .with(params! { "username" => nick })
            .first::<(String, i32, i32), _>(&mut connection)
            .await?
        {
            Ok(checker_password == password)
        } else {
            Ok(false)
        }
    }

    pub async fn store_stats(&mut self, stats: &ServerStatistics) -> mysql_async::Result<()> {
        let mut connection = self.pool.get_conn().await?;
        STORE_STATS_QUERY
            .with(params! {
                "players" => stats.players,
                "rooms" => stats.rooms,
            })
            .ignore(&mut connection)
            .await
    }

    pub async fn store_achievements(
        &mut self,
        achievements: &Achievements,
    ) -> mysql_async::Result<()> {
        Ok(())
    }

    pub async fn get_replay_name(&mut self, replay_id: u32) -> mysql_async::Result<Option<String>> {
        let mut connection = self.pool.get_conn().await?;
        GET_REPLAY_NAME_QUERY
            .with(params! { "id" => replay_id })
            .first::<String, _>(&mut connection)
            .await
    }
}

fn get_hash(protocol_number: u16, web_password: &str, salt1: &str, salt2: &str) -> Sha1Digest {
    let data = format!(
        "{}{}{}{}{}",
        salt1, salt2, web_password, protocol_number, "!hedgewars"
    );

    let mut sha1 = Sha1::new();
    sha1.update(&data);
    Sha1Digest::new(sha1.finalize().try_into().unwrap())
}
