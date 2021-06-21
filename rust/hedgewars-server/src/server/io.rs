use std::{
    fs::{File, OpenOptions},
    io::{Error, ErrorKind, Read, Result, Write},
    sync::{mpsc, Arc},
    thread,
};

use crate::{
    handlers::{IoResult, IoTask},
    server::database::Database,
};
use log::*;
use mio::{Poll, Waker};

pub type RequestId = u32;

pub struct IoThread {
    core_tx: mpsc::Sender<(RequestId, IoTask)>,
    core_rx: mpsc::Receiver<(RequestId, IoResult)>,
}

impl IoThread {
    pub fn new(waker: Waker) -> Self {
        let (core_tx, io_rx) = mpsc::channel();
        let (io_tx, core_rx) = mpsc::channel();

        let mut db = Database::new();
        db.connect("localhost");

        thread::spawn(move || {
            while let Ok((request_id, task)) = io_rx.recv() {
                let response = match task {
                    IoTask::CheckRegistered { nick } => match db.is_registered(&nick) {
                        Ok(is_registered) => IoResult::AccountRegistered(is_registered),
                        Err(e) => {
                            warn!("Unable to check account's existence: {}", e);
                            IoResult::AccountRegistered(false)
                        }
                    },

                    IoTask::GetAccount {
                        nick,
                        protocol,
                        password_hash,
                        client_salt,
                        server_salt,
                    } => {
                        match db.get_account(
                            &nick,
                            protocol,
                            &password_hash,
                            &client_salt,
                            &server_salt,
                        ) {
                            Ok(account) => IoResult::Account(account),
                            Err(e) => {
                                warn!("Unable to get account data: {}", e);
                                IoResult::Account(None)
                            }
                        }
                    }

                    IoTask::GetCheckerAccount { nick, password } => {
                        match db.get_checker_account(&nick, &password) {
                            Ok(is_registered) => IoResult::CheckerAccount { is_registered },
                            Err(e) => {
                                warn!("Unable to get checker account data: {}", e);
                                IoResult::CheckerAccount {
                                    is_registered: false,
                                }
                            }
                        }
                    }

                    IoTask::GetReplay { id } => {
                        let result = match db.get_replay_name(id) {
                            Ok(Some(filename)) => {
                                let filename = format!(
                                    "checked/{}",
                                    if filename.starts_with("replays/") {
                                        &filename[8..]
                                    } else {
                                        &filename
                                    }
                                );

                                match crate::core::types::Replay::load(&filename) {
                                    Ok(replay) => Some(replay),
                                    Err(e) => {
                                        warn!(
                                            "Error while reading replay file \"{}\": {}",
                                            filename, e
                                        );
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
                        IoResult::Replay(result)
                    }

                    IoTask::SaveRoom {
                        room_id,
                        filename,
                        contents,
                    } => {
                        let result = match save_file(&filename, &contents) {
                            Ok(()) => true,
                            Err(e) => {
                                warn!(
                                    "Error while writing the room config file \"{}\": {}",
                                    filename, e
                                );
                                false
                            }
                        };
                        IoResult::SaveRoom(room_id, result)
                    }

                    IoTask::LoadRoom { room_id, filename } => {
                        let result = match load_file(&filename) {
                            Ok(contents) => Some(contents),
                            Err(e) => {
                                warn!(
                                    "Error while writing the room config file \"{}\": {}",
                                    filename, e
                                );
                                None
                            }
                        };
                        IoResult::LoadRoom(room_id, result)
                    }
                };
                io_tx.send((request_id, response));
                waker.wake();
            }
        });

        Self { core_rx, core_tx }
    }

    pub fn send(&self, request_id: RequestId, task: IoTask) {
        self.core_tx.send((request_id, task)).unwrap();
    }

    pub fn try_recv(&self) -> Option<(RequestId, IoResult)> {
        match self.core_rx.try_recv() {
            Ok(result) => Some(result),
            Err(mpsc::TryRecvError::Empty) => None,
            Err(mpsc::TryRecvError::Disconnected) => unreachable!(),
        }
    }
}

fn save_file(filename: &str, contents: &str) -> Result<()> {
    let mut writer = OpenOptions::new().create(true).write(true).open(filename)?;
    writer.write_all(contents.as_bytes())
}

fn load_file(filename: &str) -> Result<String> {
    let mut reader = File::open(filename)?;
    let mut result = String::new();
    reader.read_to_string(&mut result)?;
    Ok(result)
}
