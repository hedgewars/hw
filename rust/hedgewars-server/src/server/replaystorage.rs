use crate::core::types::Replay;
use log::*;
use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ReplayDestination {
    Checked,
    Failed,
}

impl ReplayDestination {
    pub fn base_dir(self) -> &'static str {
        match self {
            Self::Checked => "checked",
            Self::Failed => "failed",
        }
    }
}

pub struct ReplayStorage {
    borrowed_replays: Vec<ReplayId>,
}

#[derive(Clone, PartialEq)]
pub struct ReplayId {
    path: PathBuf,
}

impl ReplayId {
    pub fn filename(&self) -> String {
        self.path.to_string_lossy().to_string()
    }
}

/// Extracts `(protocol, yyyymmdd)` subdirectory components from a replay filename
/// formatted like `"YYYY-MM-DD HH:MM:SS... .PP"`.
fn parse_replay_subdir(file_name: &str) -> Option<(&str, String)> {
    let bytes = file_name.as_bytes();
    if bytes.len() < 10
        || !bytes[0..4].iter().all(u8::is_ascii_digit)
        || bytes[4] != b'-'
        || !bytes[5..7].iter().all(u8::is_ascii_digit)
        || bytes[7] != b'-'
        || !bytes[8..10].iter().all(u8::is_ascii_digit)
    {
        return None;
    }

    let (prefix, proto) = file_name.rsplit_once('.')?;
    if prefix.len() <= 10 || proto.is_empty() || proto.parse::<u16>().is_err() {
        return None;
    }

    let day = format!(
        "{}{}{}",
        &file_name[0..4],
        &file_name[5..7],
        &file_name[8..10]
    );
    Some((proto, day))
}

fn destination_path(base_dir: &Path, file_name: &str) -> PathBuf {
    if let Some((proto, day)) = parse_replay_subdir(file_name) {
        base_dir.join(proto).join(day).join(file_name)
    } else {
        base_dir.join(file_name)
    }
}

/// Resolves a replay path inside `base_dir` from a database filename (which may use
/// the old `"replays/<name>"` format, a bare filename, or a relative subpath).
pub fn resolve_checked_replay_path(base_dir: &Path, db_filename: &str) -> PathBuf {
    let stripped = db_filename
        .strip_prefix("replays/")
        .or_else(|| db_filename.strip_prefix("checked/"))
        .unwrap_or(db_filename);
    let direct = base_dir.join(stripped);

    if let Some(file_name) = Path::new(stripped).file_name().and_then(|f| f.to_str()) {
        let organized = destination_path(base_dir, file_name);
        if organized.exists() {
            return organized;
        }
        if direct.exists() {
            return direct;
        }
        return organized;
    }

    direct
}

pub fn checked_replay_path(db_filename: &str) -> PathBuf {
    resolve_checked_replay_path(
        Path::new(ReplayDestination::Checked.base_dir()),
        db_filename,
    )
}

impl ReplayStorage {
    pub fn new() -> Self {
        ReplayStorage {
            borrowed_replays: vec![],
        }
    }

    /// Reorganizes flat replay files in `checked/` and `failed/` into `PP/YYYYMMDD/` subdirectories.
    pub fn reorganize() {
        for destination in [ReplayDestination::Checked, ReplayDestination::Failed] {
            Self::reorganize_dir(Path::new(destination.base_dir()));
        }
    }

    pub fn reorganize_dir(base_dir: &Path) {
        let Ok(entries) = fs::read_dir(base_dir) else {
            return;
        };

        let mut created_dirs = HashSet::new();
        let mut moved_count = 0usize;

        for entry in entries.flatten() {
            let Ok(file_type) = entry.file_type() else {
                continue;
            };
            if !file_type.is_file() {
                continue;
            }
            let src_path = entry.path();
            let Some(file_name) = src_path.file_name().and_then(|f| f.to_str()) else {
                continue;
            };
            let Some((proto, day)) = parse_replay_subdir(file_name) else {
                continue;
            };

            let target_dir = base_dir.join(proto).join(&day);
            let dir_key = (proto.to_string(), day);
            if !created_dirs.contains(&dir_key) {
                if let Err(e) = fs::create_dir_all(&target_dir) {
                    warn!(
                        "Unable to create replay directory \"{}\": {}",
                        target_dir.display(),
                        e
                    );
                    continue;
                }
                created_dirs.insert(dir_key);
            }

            let dst_path = target_dir.join(file_name);
            if let Err(e) = fs::rename(&src_path, &dst_path) {
                warn!(
                    "Unable to move replay \"{}\" to \"{}\": {}",
                    src_path.display(),
                    dst_path.display(),
                    e
                );
            } else {
                moved_count += 1;
            }
        }

        if moved_count > 0 {
            info!(
                "Reorganized {} replay file(s) in \"{}\" into PP/YYYYMMDD directories",
                moved_count,
                base_dir.display()
            );
        }
    }

    pub fn pick_replay(&mut self, protocol: u16) -> Option<(ReplayId, Replay)> {
        let protocol_suffix = format!(".{}", protocol);
        let dir = match fs::read_dir("replays") {
            Ok(dir) => dir,
            Err(e) => {
                warn!("Unable to read replays directory: {}", e);
                return None;
            }
        };

        for entry in dir.flatten() {
            let path = entry.path();
            if path.to_str().is_some_and(|s| s.ends_with(&protocol_suffix))
                && !self.borrowed_replays.iter().any(|e| e.path == path)
            {
                let Some(path_str) = path.to_str() else {
                    continue;
                };
                let replay_id = ReplayId { path: path.clone() };
                match Replay::load(path_str) {
                    Ok(replay) => {
                        self.borrowed_replays.push(replay_id.clone());
                        return Some((replay_id, replay));
                    }
                    Err(e) => {
                        warn!("Unable to load replay file \"{}\": {}", path_str, e);
                        let _ = self.move_file(ReplayDestination::Failed, &replay_id);
                    }
                }
            }
        }

        None
    }

    pub fn requeue_replay(&mut self, id: &ReplayId) {
        self.unborrow(id)
    }

    fn unborrow(&mut self, id: &ReplayId) {
        self.borrowed_replays.retain(|i| i != id)
    }

    pub fn move_file(
        &mut self,
        destination: ReplayDestination,
        id: &ReplayId,
    ) -> std::io::Result<()> {
        self.unborrow(id);
        self.move_to_base(Path::new(destination.base_dir()), id)
    }

    fn move_to_base(&self, base_dir: &Path, id: &ReplayId) -> std::io::Result<()> {
        let file_name = id
            .path
            .file_name()
            .and_then(|f| f.to_str())
            .expect("What's up with your file name?");
        let new_path = destination_path(base_dir, file_name);
        if let Some(parent) = new_path.parent() {
            fs::create_dir_all(parent)?;
        }

        match fs::rename(&id.path, &new_path) {
            Ok(()) => {
                info!(
                    "Moved replay \"{}\" to \"{}\"",
                    id.filename(),
                    new_path.display()
                );
                Ok(())
            }
            Err(e) => {
                warn!(
                    "Unable to move replay \"{}\" to \"{}\": {}",
                    id.filename(),
                    new_path.display(),
                    e
                );
                Err(e)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::{SystemTime, UNIX_EPOCH};

    fn make_temp_dir(name: &str) -> PathBuf {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let dir = std::env::temp_dir().join(format!("hw_replaystorage_{}_{}", name, nanos));
        fs::create_dir_all(&dir).unwrap();
        dir
    }

    #[test]
    fn test_parse_replay_subdir() {
        assert_eq!(
            parse_replay_subdir("2019-05-12 19:24:22.615024409 UTC-74378.57"),
            Some(("57", "20190512".to_string()))
        );
        assert_eq!(
            parse_replay_subdir("2026-11-18 23:21:44.622467555 UTC-75481.59"),
            Some(("59", "20261118".to_string()))
        );
        assert_eq!(parse_replay_subdir("invalid_name.59"), None);
        assert_eq!(parse_replay_subdir("2019-05-12 19:24:22.615024409"), None);
        assert_eq!(parse_replay_subdir("2019-05-12.59"), None);
    }

    #[test]
    fn test_move_to_base_creates_pp_yyyymmdd_subdirs_and_unborrows() {
        let root = make_temp_dir("move");
        let replays_dir = root.join("replays");
        let checked_dir = root.join("checked");
        let failed_dir = root.join("failed");
        fs::create_dir_all(&replays_dir).unwrap();

        let ok_src = replays_dir.join("2026-11-18 10:00:00.123 UTC-11111.59");
        let bad_src = replays_dir.join("2026-11-18 10:05:00.456 UTC-22222.60");
        fs::write(&ok_src, b"ok").unwrap();
        fs::write(&bad_src, b"bad").unwrap();

        let ok_id = ReplayId {
            path: ok_src.clone(),
        };
        let bad_id = ReplayId {
            path: bad_src.clone(),
        };

        let mut storage = ReplayStorage::new();
        storage.borrowed_replays.push(ok_id.clone());
        storage.borrowed_replays.push(bad_id.clone());

        storage.unborrow(&ok_id);
        storage.move_to_base(&checked_dir, &ok_id).unwrap();
        storage.unborrow(&bad_id);
        storage.move_to_base(&failed_dir, &bad_id).unwrap();

        assert!(storage.borrowed_replays.is_empty());
        assert!(!ok_src.exists());
        assert!(!bad_src.exists());
        assert!(checked_dir
            .join("59/20261118/2026-11-18 10:00:00.123 UTC-11111.59")
            .exists());
        assert!(failed_dir
            .join("60/20261118/2026-11-18 10:05:00.456 UTC-22222.60")
            .exists());

        let _ = fs::remove_dir_all(&root);
    }

    #[test]
    fn test_reorganize_dir_and_resolve_old_db_paths() {
        let root = make_temp_dir("reorg");
        let checked_dir = root.join("checked");
        fs::create_dir_all(&checked_dir).unwrap();

        let old_name = "2019-05-12 19:24:22.615024409 UTC-74378.57";
        let old_file = checked_dir.join(old_name);
        let unparsed_file = checked_dir.join("keep_me.txt");
        fs::write(&old_file, b"legacy").unwrap();
        fs::write(&unparsed_file, b"other").unwrap();

        // Pre-reorg lookup still finds flat file
        assert_eq!(
            resolve_checked_replay_path(&checked_dir, &format!("replays/{}", old_name)),
            old_file
        );

        ReplayStorage::reorganize_dir(&checked_dir);

        let moved_file = checked_dir.join("57/20190512").join(old_name);
        assert!(!old_file.exists());
        assert!(moved_file.exists());
        assert!(unparsed_file.exists());

        // Post-reorg lookup finds organized file from both old DB formats and relative paths
        assert_eq!(
            resolve_checked_replay_path(&checked_dir, &format!("replays/{}", old_name)),
            moved_file
        );
        assert_eq!(
            resolve_checked_replay_path(&checked_dir, old_name),
            moved_file
        );
        assert_eq!(
            resolve_checked_replay_path(&checked_dir, &format!("57/20190512/{}", old_name)),
            moved_file
        );
        assert_eq!(
            resolve_checked_replay_path(&checked_dir, &format!("checked/57/20190512/{}", old_name)),
            moved_file
        );

        // Idempotent second run
        ReplayStorage::reorganize_dir(&checked_dir);
        assert!(moved_file.exists());

        let _ = fs::remove_dir_all(&root);
    }
}
