use crate::core::types::Replay;
//use super::demo::load;
use std::fs;
use std::path::PathBuf;

pub struct ReplayStorage {
    borrowed_replays: Vec<ReplayId>,
}

#[derive(Clone, PartialEq)]
pub struct ReplayId {
    path: PathBuf,
}

impl ReplayStorage {
    pub fn new() -> Self {
        ReplayStorage {
            borrowed_replays: vec![],
        }
    }

    pub fn pick_replay(&mut self, protocol: u16) -> Option<(ReplayId, Replay)> {
        let protocol_suffix = format!(".{}", protocol);
        let result = fs::read_dir("replays")
            .ok()?
            .flat_map(|f| Some(f.ok()?.path()))
            .filter(|f| {
                f.ends_with(&protocol_suffix) && !self.borrowed_replays.iter().any(|e| &e.path == f)
            })
            .next()
            .and_then(|f| {
                Some((
                    ReplayId { path: f.clone() },
                    Replay::load(f.to_str()?).ok()?,
                ))
            });

        if let Some((ref replay_id, _)) = result {
            self.borrowed_replays.push((*replay_id).clone());
        }

        result
    }

    pub fn move_failed_replay(&mut self, id: &ReplayId) -> std::io::Result<()> {
        self.unborrow(id);
        self.move_file("failed", id)
    }

    pub fn move_checked_replay(&mut self, id: &ReplayId) -> std::io::Result<()> {
        self.unborrow(id);
        self.move_file("checked", id)
    }

    pub fn requeue_replay(&mut self, id: &ReplayId) {
        self.unborrow(id)
    }

    fn unborrow(&mut self, id: &ReplayId) {
        self.borrowed_replays.retain(|i| i != id)
    }

    fn move_file(&self, dir: &str, id: &ReplayId) -> std::io::Result<()> {
        let new_name = format!(
            "{}/{}",
            dir,
            id.path
                .file_name()
                .and_then(|f| f.to_str())
                .expect("What's up with your file name?")
        );

        fs::rename(&id.path, new_name)
    }
}
