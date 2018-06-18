use server::coretypes::{ServerVar, GameCfg, TeamInfo, HedgehogInfo};
use std;
use std::ops;
use std::convert::From;

#[derive(PartialEq, Eq, Clone, Debug)]
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
    JoinRoom(String, Option<String>),
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

#[derive(Debug)]
pub enum HWServerMessage {
    Ping,
    Pong,
    Bye(String),
    Nick(String),
    Proto(u32),
    LobbyLeft(String, String),
    LobbyJoined(Vec<String>),
    ChatMsg(String, String),
    ClientFlags(String, Vec<String>),
    Rooms(Vec<String>),
    RoomAdd(Vec<String>),
    RoomJoined(Vec<String>),
    RoomLeft(String, String),
    RoomRemove(String),
    RoomUpdated(String, Vec<String>),
    ServerMessage(String),

    Warning(String),
    Error(String),
    Connected(u32),
    Unreachable,
}

impl<'a> HWProtocolMessage {
    pub fn to_raw_protocol(&self) -> String {
        use self::HWProtocolMessage::*;
        match self {
            Ping => "PING\n\n".to_string(),
            Pong => "PONG\n\n".to_string(),
            Quit(None) => format!("QUIT\n\n"),
            Quit(Some(msg)) => format!("QUIT\n{}\n\n", msg),
            Global(msg) => format!("CMD\nGLOBAL\n{}\n\n", msg),
            Watch(name) => format!("CMD\nWATCH\n{}\n\n", name),
            ToggleServerRegisteredOnly => "CMD\nREGISTERED_ONLY\n\n".to_string(),
            SuperPower => "CMD\nSUPER_POWER\n\n".to_string(),
            Info(info) => format!("CMD\nINFO\n{}\n\n", info),
            Nick(nick) => format!("NICK\n{}\n\n", nick),
            Proto(version) => format!("PROTO\n{}\n\n", version),
            Password(p, s) => format!("PASSWORD\n{}\n{}\n\n", p, s), //?
            Checker(i, n, p) =>
                format!("CHECKER\n{}\n{}\n{}\n\n", i, n, p), //?,
            List => "LIST\n\n".to_string(),
            Chat(msg) => format!("CHAT\n{}\n\n", msg),
            CreateRoom(name, None) =>
                format!("CREATE_ROOM\n{}\n\n", name),
            CreateRoom(name, Some(password)) =>
                format!("CREATE_ROOM\n{}\n{}\n\n", name, password),
            JoinRoom(name, None) =>
                format!("JOIN\n{}\n\n", name),
            JoinRoom(name, Some(arg)) =>
                format!("JOIN\n{}\n{}\n\n", name, arg),
            Follow(name) =>
                format!("FOLLOW\n{}\n\n", name),
            //Rnd(Vec<String>), ???
            Kick(name) => format!("KICK\n{}\n\n", name),
            Ban(name, reason, time) =>
                format!("BAN\n{}\n{}\n{}\n\n", name, reason, time),
            BanIP(ip, reason, time) =>
                format!("BAN_IP\n{}\n{}\n{}\n\n", ip, reason, time),
            BanNick(nick, reason, time) =>
                format!("BAN_NICK\n{}\n{}\n{}\n\n", nick, reason, time),
            BanList => "BANLIST\n\n".to_string(),
            Unban(name) => format!("UNBAN\n{}\n\n", name),
            //SetServerVar(ServerVar), ???
            GetServerVar => "GET_SERVER_VAR\n\n".to_string(),
            RestartServer => "CMD\nRESTART_SERVER\nYES\n\n".to_string(),
            Stats => "CMD\nSTATS\n\n".to_string(),
            Part(None) => "CMD\nPART\n\n".to_string(),
            Part(Some(msg)) => format!("CMD\nPART\n{}\n\n", msg),
            //Cfg(GameCfg) ??
            //AddTeam(TeamInfo) ??,
            RemoveTeam(name) => format!("REMOVE_TEAM\n{}\n\n", name),
            //SetHedgehogsNumber(String, u8), ??
            //SetTeamColor(String, u8), ??
            ToggleReady => "TOGGLE_READY\n\n".to_string(),
            StartGame => "START_GAME\n\n".to_string(),
            EngineMessage(msg) => format!("EM\n{}\n\n", msg),
            RoundFinished => "ROUNDFINISHED\n\n".to_string(),
            ToggleRestrictJoin => "TOGGLE_RESTRICT_JOINS\n\n".to_string(),
            ToggleRestrictTeams => "TOGGLE_RESTRICT_TEAMS\n\n".to_string(),
            ToggleRegisteredOnly => "TOGGLE_REGISTERED_ONLY\n\n".to_string(),
            RoomName(name) => format!("ROOM_NAME\n{}\n\n", name),
            Delegate(name) => format!("CMD\nDELEGATE\n{}\n\n", name),
            TeamChat(msg) => format!("TEAMCHAT\n{}\n\n", msg),
            MaxTeams(count) => format!("CMD\nMAXTEAMS\n{}\n\n", count) ,
            Fix => "CMD\nFIX\n\n".to_string(),
            Unfix => "CMD\nUNFIX\n\n".to_string(),
            Greeting(msg) => format!("CMD\nGREETING\n{}\n\n", msg),
            //CallVote(Option<(String, Option<String>)>) =>, ??
            Vote(msg) => format!("CMD\nVOTE\n{}\n\n", msg),
            ForceVote(msg) => format!("CMD\nFORCE\n{}\n\n", msg),
            //Save(String, String), ??
            Delete(room) => format!("CMD\nDELETE\n{}\n\n", room),
            SaveRoom(room) => format!("CMD\nSAVEROOM\n{}\n\n", room),
            LoadRoom(room) => format!("CMD\nLOADROOM\n{}\n\n", room),
            Malformed => "A\nQUICK\nBROWN\nHOG\nJUMPS\nOVER\nTHE\nLAZY\nDOG\n\n".to_string(),
            Empty => "\n\n".to_string(),
            _ => panic!("Protocol message not yet implemented")
        }
    }
}

macro_rules! const_braces {
    ($e: expr) => { "{}\n" }
}

macro_rules! msg {
    [$($part: expr),*] => {
        format!(concat!($(const_braces!($part)),*, "\n"), $($part),*);
    };
}

fn construct_message(mut msg: Vec<&str>) -> String {
    msg.push("\n");
    msg.join("\n")
}

impl HWServerMessage {
    pub fn to_raw_protocol(&self) -> String {
        use self::HWServerMessage::*;
        match self {
            Ping => msg!["PING"],
            Pong => msg!["PONG"],
            Connected(protocol_version) => msg![
                "CONNECTED",
                "Hedgewars server http://www.hedgewars.org/",
                protocol_version],
            Bye(msg) => msg!["BYE", msg],
            Nick(nick) => msg!["NICK", nick],
            Proto(proto) => msg!["PROTO", proto],
            LobbyLeft(nick, msg) => msg!["LOBBY:LEFT", nick, msg],
            LobbyJoined(nicks) => {
                let mut v = vec!["LOBBY:JOINED"];
                v.extend(nicks.iter().map(|n| { &n[..] }));
                construct_message(v)
            },
            ClientFlags(flags, nicks)
                => {
                let mut v = vec!["CLIENT_FLAGS"];
                v.push(&flags[..]);
                v.extend(nicks.iter().map(|n| { &n[..] }));
                construct_message(v)
            },
            Rooms(info) => {
                let mut v = vec!["ROOMS"];
                v.extend(info.iter().map(|n| { &n[..] }));
                construct_message(v)
            },
            RoomAdd(info) => {
                let mut v = vec!["ROOM", "ADD"];
                v.extend(info.iter().map(|n| { &n[..] }));
                construct_message(v)
            },
            RoomJoined(nicks) => {
                let mut v = vec!["JOINED"];
                v.extend(nicks.iter().map(|n| { &n[..] }));
                construct_message(v)
            },
            RoomLeft(nick, msg) => msg!["LEFT", nick, msg],
            RoomRemove(name) => msg!["ROOM", "DEL", name],
            RoomUpdated(name, info) => {
                let mut v = vec!["ROOM", "UPD", name];
                v.extend(info.iter().map(|n| { &n[..] }));
                construct_message(v)
            }
            ChatMsg(nick, msg) => msg!["CHAT", nick, msg],
            ServerMessage(msg) => msg!["SERVER_MESSAGE", msg],
            Warning(msg) => msg!["WARNING", msg],
            Error(msg) => msg!["ERROR", msg],
            _ => msg!["ERROR", "UNIMPLEMENTED"],
        }
    }
}
