use std::{
    fs::{File, OpenOptions},
    io::{Error, ErrorKind, Read, Result, Write},
    sync::mpsc,
    thread,
};

use crate::server::{
    database::Database,
    handlers::{IoResult, IoTask},
};
use log::*;
use mio::{Evented, Poll, PollOpt};
use mio_extras::channel;

pub type RequestId = u32;

pub struct IOThread {
    core_tx: mpsc::Sender<(RequestId, IoTask)>,
    core_rx: channel::Receiver<(RequestId, IoResult)>,
}

impl IOThread {
    pub fn new() -> Self {
        let (core_tx, io_rx) = mpsc::channel();
        let (io_tx, core_rx) = channel::channel();

        let mut db = Database::new();
        db.connect("localhost");

        thread::spawn(move || {
            while let Ok((request_id, task)) = io_rx.try_recv() {
                let response = match task {
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
                            Err(..) => {
                                warn!("Unable to get account data: {}", 0);
                                IoResult::Account(None)
                            }
                        }
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

    pub fn register_rx(&self, poll: &mio::Poll, token: mio::Token) -> Result<()> {
        self.core_rx
            .register(poll, token, mio::Ready::readable(), PollOpt::edge())
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
