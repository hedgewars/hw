use crate::command::Command;

pub enum KeystrokeAction {
    Press,
    Release,
}

pub enum SyncedEngineMessage {
    Left(KeystrokeAction),
    Right(KeystrokeAction),
    Up(KeystrokeAction),
    Down(KeystrokeAction),
    Precise(KeystrokeAction),
    NextTurn,
    Switch,
    Empty,
    Timer(u8),
    Slot(u8),
    SetWeapon(u8),
    Put(i32, i32),
    HighJump,
    LowJump,
    Skip,
    TeamControlGained(String),
    TeamControlLost(String),
}

pub enum UnsyncedEngineMessage {
    Ping,
    Pong,
    Say(String),
    Taunt(u8),
    ExecCommand(Command),
    GameType(u8),// TODO: use enum
    Warning(String),
    StopSyncing,
    ConfigRequest,
    GameOver,
    GameInterrupted,
}

pub enum EngineMessage {
    Synced(SyncedEngineMessage, u32),
    Unsynced(UnsyncedEngineMessage),
}

impl EngineMessage {
    fn from_bytes(buf: &[u8]) -> Self {
        unimplemented!()
    }

    fn to_bytes(&self) -> Vec<u8> {
        unimplemented!()
    }
}
