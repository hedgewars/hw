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
    Checker(u32, String, String),
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
    EngineMessage(String),
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
    Delete(String),
    SaveRoom(String),
    LoadRoom(String),
    Malformed,
    Empty,
}

pub enum HWServerMessage<'a> {
    Ping,
    Pong,
    Bye(&'a str),
    Nick(&'a str),
    LobbyLeft(&'a str),

    Connected(u32),
    Unreachable,
}

fn construct_message(msg: & [&str]) -> String {
    let mut m = String::with_capacity(64);

    for s in msg {
        m.push_str(s);
        m.push('\n');
    }
    m.push('\n');

    m
}

impl<'a> HWServerMessage<'a> {
    pub fn to_raw_protocol(&self) -> String {
        match self {
            &HWServerMessage::Ping
                => "PING\n\n".to_string(),
            &HWServerMessage::Pong
                => "PONG\n\n".to_string(),
            &HWServerMessage::Connected(protocol_version)
                => construct_message(&[
                    "CONNECTED",
                    "Hedgewars server http://www.hedgewars.org/",
                    &protocol_version.to_string()
                ]),
            &HWServerMessage::Bye(msg)
                => construct_message(&["BYE", &msg]),
            &HWServerMessage::Nick(nick)
            => construct_message(&["NICK", &nick]),
            &HWServerMessage::LobbyLeft(msg)
                => construct_message(&["LOBBY_LEFT", &msg]),
            _ => construct_message(&["ERROR", "UNIMPLEMENTED"]),
        }
    }
}
