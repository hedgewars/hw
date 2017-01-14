use server::coretypes::{ServerVar, GameCfg, TeamInfo, HedgehogInfo};
use std;
use std::ops;
use std::convert::From;

#[derive(PartialEq, Debug)]
pub enum HWProtocolMessage<'a> {
    // core
    Ping,
    Pong,
    Quit(Option<&'a str>),
    Bye(&'a str),
    LobbyLeft(&'a str),
    //Cmd(&'a str, Vec<&'a str>),
    Global(&'a str),
    Watch(&'a str),
    ToggleServerRegisteredOnly,
    SuperPower,
    Info(&'a str),
    // not entered state
    Nick(&'a str),
    Proto(u32),
    Password(&'a str, &'a str),
    Checker(u32, &'a str, &'a str),
    // lobby
    List,
    Chat(&'a str),
    CreateRoom(&'a str, Option<&'a str>),
    Join(&'a str, Option<&'a str>),
    Follow(&'a str),
    Rnd(Vec<&'a str>),
    Kick(&'a str),
    Ban(&'a str, &'a str, u32),
    BanIP(&'a str, &'a str, u32),
    BanNick(&'a str, &'a str, u32),
    BanList,
    Unban(&'a str),
    SetServerVar(ServerVar),
    GetServerVar,
    RestartServer,
    Stats,
    // in room
    Part(Option<&'a str>),
    Cfg(GameCfg),
    AddTeam(TeamInfo),
    RemoveTeam(&'a str),
    SetHedgehogsNumber(&'a str, u8),
    SetTeamColor(&'a str, u8),
    ToggleReady,
    StartGame,
    EngineMessage(&'a str),
    RoundFinished,
    ToggleRestrictJoin,
    ToggleRestrictTeams,
    ToggleRegisteredOnly,
    RoomName(&'a str),
    Delegate(&'a str),
    TeamChat(&'a str),
    MaxTeams(u8),
    Fix,
    Unfix,
    Greeting(&'a str),
    CallVote(Option<(&'a str, Option<&'a str>)>),
    Vote(&'a str),
    ForceVote(&'a str),
    Save(&'a str, &'a str),
    Delete(&'a str),
    SaveRoom(&'a str),
    LoadRoom(&'a str),
    Connected(u32),
    Malformed,
    Empty,
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

fn construct_message(msg: & [&str]) -> String {
    let mut m = String::with_capacity(64);

    for s in msg {
        m.push_str(s);
        m.push('\n');
    }
    m.push('\n');

    m
}

impl<'a> HWProtocolMessage<'a> {
    pub fn to_raw_protocol(&self) -> String {
        match self {
            &HWProtocolMessage::Ping
                => "PING\n\n".to_string(),
            &HWProtocolMessage::Pong
                => "PONG\n\n".to_string(),
            &HWProtocolMessage::Connected(protocol_version)
                => construct_message(&[
                    "CONNECTED",
                    "Hedgewars server http://www.hedgewars.org/",
                    &protocol_version.to_string()
                ]),
            &HWProtocolMessage::Bye(msg)
                => construct_message(&["BYE", msg]),
            &HWProtocolMessage::LobbyLeft(msg)
                => construct_message(&["LOBBY_LEFT", msg]),
            _ => String::new()
        }
    }
}
