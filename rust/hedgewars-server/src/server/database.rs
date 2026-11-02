use log::*;
use mysql_async::{self, params, prelude::*, Pool};
use sha1::{Digest, Sha1};

use crate::{
    core::{digest::Sha1Digest, ghosts::sanitize_name, types::Replay},
    handlers::{AccountInfo, IoResult, IoTask},
    server::demo::GameDetails,
};

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

const INSERT_ACHIEVEMENT_QUERY: &str = r"INSERT INTO achievements
      (time, typeid, userid, value, filename, location, protocol)
      VALUES
      (:time, (SELECT id FROM achievement_types WHERE name = :type_name), (SELECT uid FROM users WHERE name = :username),
       :value, :filename, :location, :protocol)";

const INSERT_GAMES_HISTORY_QUERY: &str = r"INSERT INTO rating_games
      (script, protocol, filename, time, vamp, ropes, infattacks)
      VALUES
      (:script, :protocol, :filename, :time, :vamp, :ropes, :infattacks)";

const INSERT_GAMES_PLACES_QUERY: &str = r"INSERT INTO rating_players
      (userid, gameid, place)
      VALUES
      ((SELECT uid FROM users WHERE name = :username), :gameid, :place)";

const GET_BEST_TIME_QUERY: &str = r"SELECT MIN(value) FROM achievements
      WHERE location = :location AND id <> (SELECT MAX(id) FROM achievements)";

pub struct ServerStatistics {
    pub rooms: u32,
    pub players: u32,
}

pub struct Database {
    pool: Pool,
}

impl Database {
    pub fn new(url: &str) -> Self {
        Self {
            pool: Pool::new(url),
        }
    }

    pub async fn execute_task(&mut self, task: IoTask) -> Option<IoResult> {
        match task {
            IoTask::CheckRegistered { nick } => {
                let is_registered = self.get_is_registered(&nick).await.unwrap_or_else(|e| {
                    warn!("Unable to check account's existence: {}", e);
                    false
                });
                Some(IoResult::AccountRegistered(is_registered))
            }
            IoTask::GetAccount {
                nick,
                protocol,
                password_hash,
                client_salt,
                server_salt,
            } => {
                let account = self
                    .get_account(&nick, protocol, &password_hash, &client_salt, &server_salt)
                    .await
                    .unwrap_or_else(|e| {
                        warn!("Unable to get account data: {}", e);
                        None
                    });
                Some(IoResult::Account(account))
            }
            IoTask::GetCheckerAccount { nick, password } => {
                let (is_registered, is_admin) = self
                    .get_checker_account(&nick, &password)
                    .await
                    .unwrap_or_else(|e| {
                        warn!("Unable to get checker account data: {}", e);
                        (false, false)
                    });
                Some(IoResult::CheckerAccount {
                    is_registered,
                    is_admin,
                })
            }
            IoTask::GetReplay { id } => {
                let result = match self.get_replay_name(id).await {
                    Ok(Some(filename)) => {
                        let filename = format!(
                            "checked/{}",
                            filename.strip_prefix("replays/").unwrap_or(&filename)
                        );
                        match Replay::load(&filename) {
                            Ok(replay) => Some(Box::new(replay)),
                            Err(e) => {
                                warn!("Error while reading replay file \"{}\": {}", filename, e);
                                None
                            }
                        }
                    }
                    Ok(None) => None,
                    Err(e) => {
                        warn!("Unable to get replay name: {}", e);
                        None
                    }
                };
                Some(IoResult::Replay(result))
            }
            IoTask::SaveRoom {
                room_id,
                filename,
                contents,
            } => {
                let ok = std::fs::write(&filename, contents).is_ok();
                Some(IoResult::SaveRoom(room_id, ok))
            }
            IoTask::LoadRoom { room_id, filename } => {
                let contents = std::fs::read_to_string(&filename).ok();
                Some(IoResult::LoadRoom(room_id, contents))
            }
            IoTask::StoreAchievements {
                protocol,
                filename,
                teams,
                game_details,
                info,
            } => {
                if let Err(e) = self
                    .store_achievements(protocol, &filename, &teams, &game_details, &info)
                    .await
                {
                    warn!("Unable to store achievements: {}", e);
                }
                None
            }
        }
    }

    pub async fn get_is_registered(&mut self, nick: &str) -> mysql_async::Result<bool> {
        let mut connection = self.pool.get_conn().await?;
        let result: Option<u32> = connection
            .exec_first(CHECK_ACCOUNT_EXISTS_QUERY, params! { "username" => nick })
            .await?;
        Ok(result.is_some())
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
        if let Some((mut password, is_admin, is_contributor)) = connection
            .exec_first::<(String, i32, i32), _, _>(
                GET_ACCOUNT_QUERY,
                params! { "username" => nick },
            )
            .await?
        {
            if password.is_empty() {
                return Ok(None);
            }
            let client_hash = get_hash(protocol, &password, client_salt, server_salt);
            let server_hash = get_hash(protocol, &password, server_salt, client_salt);
            let is_valid = if protocol < 48 {
                password_hash == password
            } else {
                client_hash == password_hash
            };
            password.replace_range(.., "🦔🦔🦔🦔🦔🦔🦔🦔");

            if is_valid {
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
    ) -> mysql_async::Result<(bool, bool)> {
        let mut connection = self.pool.get_conn().await?;
        if let Some((password, is_admin, _)) = connection
            .exec_first::<(String, i32, i32), _, _>(
                GET_ACCOUNT_QUERY,
                params! { "username" => nick },
            )
            .await?
        {
            Ok((
                !password.is_empty() && checker_password == password,
                is_admin == 1,
            ))
        } else {
            Ok((false, false))
        }
    }

    pub async fn store_stats(&mut self, stats: &ServerStatistics) -> mysql_async::Result<()> {
        let mut connection = self.pool.get_conn().await?;
        connection
            .exec_drop(
                STORE_STATS_QUERY,
                params! {
                    "players" => stats.players,
                    "rooms" => stats.rooms,
                },
            )
            .await
    }

    pub async fn store_achievements(
        &mut self,
        protocol: u16,
        filename: &str,
        teams: &[(String, String)],
        details: &GameDetails,
        info: &[String],
    ) -> mysql_async::Result<()> {
        let mut connection = self.pool.get_conn().await?;
        let stripped = filename.strip_prefix("replays/").unwrap_or(filename);
        let time: String = stripped.chars().take(19).collect();

        let mut best_location = String::new();
        let mut best_time = i32::MAX;
        let mut idx = 0;

        while idx < info.len() {
            match info[idx].as_str() {
                "DRAW" => {
                    let _ = connection
                        .exec_drop(
                            INSERT_GAMES_HISTORY_QUERY,
                            params! {
                                "script" => &details.script,
                                "protocol" => protocol as i32,
                                "filename" => filename,
                                "time" => &time,
                                "vamp" => details.vamp,
                                "ropes" => details.inf_ropes,
                                "infattacks" => details.inf_attacks,
                            },
                        )
                        .await;
                    let game_id: i32 = connection
                        .query_first("SELECT LAST_INSERT_ID()")
                        .await
                        .ok()
                        .flatten()
                        .unwrap_or(0);
                    for (_, owner) in teams {
                        let _ = connection
                            .exec_drop(
                                INSERT_GAMES_PLACES_QUERY,
                                params! {
                                    "username" => owner,
                                    "gameid" => game_id,
                                    "place" => 0i32,
                                },
                            )
                            .await;
                    }
                    idx += 1;
                }
                "WINNERS" if idx + 1 < info.len() => {
                    let win_num = info[idx + 1].parse::<usize>().unwrap_or(0);
                    let winners_end = (idx + 2 + win_num).min(info.len());
                    let winners = &info[idx + 2..winners_end];
                    let _ = connection
                        .exec_drop(
                            INSERT_GAMES_HISTORY_QUERY,
                            params! {
                                "script" => &details.script,
                                "protocol" => protocol as i32,
                                "filename" => filename,
                                "time" => &time,
                                "vamp" => details.vamp,
                                "ropes" => details.inf_ropes,
                                "infattacks" => details.inf_attacks,
                            },
                        )
                        .await;
                    let game_id: i32 = connection
                        .query_first("SELECT LAST_INSERT_ID()")
                        .await
                        .ok()
                        .flatten()
                        .unwrap_or(0);
                    for (team_name, owner) in teams {
                        let place = if winners.iter().any(|w| w == team_name) {
                            1i32
                        } else {
                            2i32
                        };
                        let _ = connection
                            .exec_drop(
                                INSERT_GAMES_PLACES_QUERY,
                                params! {
                                    "username" => owner,
                                    "gameid" => game_id,
                                    "place" => place,
                                },
                            )
                            .await;
                    }
                    idx = winners_end;
                }
                "ACHIEVEMENT" if idx + 4 < info.len() => {
                    let typ = &info[idx + 1];
                    let teamname = &info[idx + 2];
                    let location = &info[idx + 3];
                    let value = info[idx + 4].parse::<i32>().unwrap_or(0);
                    let owner = teams
                        .iter()
                        .find(|(tn, _)| tn == teamname)
                        .map(|(_, o)| o.as_str())
                        .unwrap_or("");
                    let _ = connection
                        .exec_drop(
                            INSERT_ACHIEVEMENT_QUERY,
                            params! {
                                "time" => &time,
                                "type_name" => typ,
                                "username" => owner,
                                "value" => value,
                                "filename" => filename,
                                "location" => location,
                                "protocol" => protocol as i32,
                            },
                        )
                        .await;
                    if value < best_time {
                        best_location = location.clone();
                        best_time = value;
                    }
                    idx += 5;
                }
                "GHOST_POINTS" if idx + 1 < info.len() => {
                    let points_num = info[idx + 1].parse::<usize>().unwrap_or(0);
                    let pts_end = (idx + 2 + 2 * points_num).min(info.len());
                    let pts: Vec<i32> = info[idx + 2..pts_end]
                        .iter()
                        .map(|s| s.parse::<i32>().unwrap_or(0))
                        .collect();
                    let db_best: Option<Option<i32>> = connection
                        .exec_first(GET_BEST_TIME_QUERY, params! { "location" => &best_location })
                        .await
                        .ok();
                    let min_prev = db_best.flatten().unwrap_or(i32::MAX);
                    if best_time < min_prev && !best_location.is_empty() {
                        let formatted = format!(
                            "[{}]",
                            pts.iter()
                                .map(|n| n.to_string())
                                .collect::<Vec<_>>()
                                .join(",")
                        );
                        let _ = std::fs::write(
                            format!("ghosts/{}", sanitize_name(&best_location)),
                            formatted,
                        );
                    }
                    idx = pts_end;
                }
                _ => {
                    idx += 1;
                }
            }
        }
        Ok(())
    }

    pub async fn get_replay_name(&mut self, replay_id: u32) -> mysql_async::Result<Option<String>> {
        let mut connection = self.pool.get_conn().await?;
        connection
            .exec_first(GET_REPLAY_NAME_QUERY, params! { "id" => replay_id })
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
    Sha1Digest::new(sha1.finalize().into())
}
