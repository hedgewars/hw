use server::coretypes::{ServerVar, GameCfg, TeamInfo, HedgehogInfo};
use std;
use std::ops;
use std::convert::From;

#[derive(PartialEq, Debug)]
pub enum HWProtocolMessage {
    // core
    Ping,
    Pong,
    Quit(Option<String>),
    //Cmd(String, Vec<String>),
    Global(String),
    Watch(String),
    ToggleServerRegisteredOnly,
    SuperPower,
    Info(String),
    // not entered state
    Nick(String),
    Proto(u32),
    Password(String, String),
    Checker(String),
    // lobby
    List,
    Chat(String),
    CreateRoom(String, Option<String>),
    Join(String, Option<String>),
    Follow(String),
    Rnd(Vec<String>),
    Kick(String),
    Ban(String, String, u32),
    BanIP(String, String, u32),
    BanNick(String, String, u32),
    BanList,
    Unban(String),
    SetServerVar(ServerVar),
    GetServerVar,
    RestartServer,
    Stats,
    // in room
    Part(Option<String>),
    Cfg(GameCfg),
    AddTeam(TeamInfo),
    RemoveTeam(String),
    SetHedgehogsNumber(String, u8),
    SetTeamColor(String, u8),
    ToggleReady,
    StartGame,
    EngineMessage,
    RoundFinished,
    ToggleRestrictJoin,
    ToggleRestrictTeams,
    ToggleRegisteredOnly,
    RoomName(String),
    Delegate(String),
    TeamChat(String),
    MaxTeams(u8),
    Fix,
    Unfix,
    Greeting(String),
    CallVote(Option<(String, Option<String>)>),
    Vote(String),
    ForceVote(String),
    Save(String, String),
    Delete(String, String),
    SaveRoom(String),
    LoadRoom(String),
}

pub fn number<T: From<u8>
                + std::default::Default
                + std::ops::MulAssign
                + std::ops::AddAssign>
    (digits: Vec<u8>) -> T {
    let mut value: T = T::default();
    for digit in digits {
        value *= T::from(10);
        value += T::from(digit);
    }
    value
}
