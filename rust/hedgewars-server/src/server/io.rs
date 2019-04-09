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
                match task {
                    IoTask::GetAccount {
                        nick,
                        protocol,
                        password_hash,
                        client_salt,
                        server_salt,
                    } => {
                        if let Ok(account) = db.get_account(
                            &nick,
                            protocol,
                            &password_hash,
                            &client_salt,
                            &server_salt,
                        ) {
                            io_tx.send((request_id, IoResult::Account(account)));
                        }
                    }
                }
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
