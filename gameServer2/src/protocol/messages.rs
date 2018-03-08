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

pub enum HWServerMessage {
    Ping,
    Pong,
    Bye(String),
    Nick(String),
    LobbyLeft(String),
    LobbyJoined(Vec<String>),
    ChatMsg(String, String),
    ClientFlags(String, Vec<String>),

    Warning(String),
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

impl<'a> HWProtocolMessage {
    pub fn to_raw_protocol(&self) -> String {
        use self::HWProtocolMessage::*;
        match *self {
            Ping => "PING\n\n".to_string(),
            Pong => "PONG\n\n".to_string(),
            Quit(None) => format!("QUIT\n\n"),
            Quit(Some(ref msg)) => format!("QUIT\n{}\n\n", msg),
            Global(ref msg) => format!("CMD\nGLOBAL\n{}\n\n", msg),
            Watch(ref name) => format!("CMD\nWATCH\n{}\n\n", name),
            ToggleServerRegisteredOnly => "CMD\nREGISTERED_ONLY\n\n".to_string(),
            SuperPower => "CMD\nSUPER_POWER\n\n".to_string(),
            Info(ref info) => format!("CMD\nINFO\n{}\n\n", info),
            Nick(ref nick) => format!("NICK\n{}\n\n", nick),
            Proto(version) => format!("PROTO\n{}\n\n", version),
            Password(ref p, ref s) => format!("PASSWORD\n{}\n{}\n\n", p, s), //?
            Checker(i, ref n, ref p) =>
                format!("CHECKER\n{}\n{}\n{}\n\n", i, n, p), //?,
            List => "LIST\n\n".to_string(),
            Chat(ref msg) => format!("CHAT\n{}\n\n", msg),
            CreateRoom(ref name, None) =>
                format!("CREATE_ROOM\n{}\n\n", name),
            CreateRoom(ref name, Some(ref password)) =>
                format!("CREATE_ROOM\n{}\n{}\n\n", name, password),
            Join(ref name, None) =>
                format!("JOIN\n{}\n\n", name),
            Join(ref name, Some(ref arg)) =>
                format!("JOIN\n{}\n{}\n\n", name, arg),
            Follow(ref name) =>
                format!("FOLLOW\n{}\n\n", name),
            //Rnd(Vec<String>), ???
            Kick(ref name) => format!("KICK\n{}\n\n", name),
            Ban(ref name, ref reason, time) =>
                format!("BAN\n{}\n{}\n{}\n\n", name, reason, time),
            BanIP(ref ip, ref reason, time) =>
                format!("BAN_IP\n{}\n{}\n{}\n\n", ip, reason, time),
            BanNick(ref nick, ref reason, time) =>
                format!("BAN_NICK\n{}\n{}\n{}\n\n", nick, reason, time),
            BanList => "BANLIST\n\n".to_string(),
            Unban(ref name) => format!("UNBAN\n{}\n\n", name),
            //SetServerVar(ServerVar), ???
            GetServerVar => "GET_SERVER_VAR\n\n".to_string(),
            RestartServer => "CMD\nRESTART_SERVER\nYES\n\n".to_string(),
            Stats => "CMD\nSTATS\n\n".to_string(),
            Part(None) => "CMD\nPART\n\n".to_string(),
            Part(Some(ref msg)) => format!("CMD\nPART\n{}\n\n", msg),
            //Cfg(GameCfg) ??
            //AddTeam(TeamInfo) ??,
            RemoveTeam(ref name) => format!("REMOVE_TEAM\n{}\n\n", name),
            //SetHedgehogsNumber(String, u8), ??
            //SetTeamColor(String, u8), ??
            ToggleReady => "TOGGLE_READY\n\n".to_string(),
            StartGame => "START_GAME\n\n".to_string(),
            EngineMessage(ref msg) => format!("EM\n{}\n\n", msg),
            RoundFinished => "ROUNDFINISHED\n\n".to_string(),
            ToggleRestrictJoin => "TOGGLE_RESTRICT_JOINS\n\n".to_string(),
            ToggleRestrictTeams => "TOGGLE_RESTRICT_TEAMS\n\n".to_string(),
            ToggleRegisteredOnly => "TOGGLE_REGISTERED_ONLY\n\n".to_string(),
            RoomName(ref name) => format!("ROOM_NAME\n{}\n\n", name),
            Delegate(ref name) => format!("CMD\nDELEGATE\n{}\n\n", name),
            TeamChat(ref msg) => format!("TEAMCHAT\n{}\n\n", msg),
            MaxTeams(count) => format!("CMD\nMAXTEAMS\n{}\n\n", count) ,
            Fix => "CMD\nFIX\n\n".to_string(),
            Unfix => "CMD\nUNFIX\n\n".to_string(),
            Greeting(ref msg) => format!("CMD\nGREETING\n{}\n\n", msg),
            //CallVote(Option<(String, Option<String>)>) =>, ??
            Vote(ref msg) => format!("CMD\nVOTE\n{}\n\n", msg),
            ForceVote(ref msg) => format!("CMD\nFORCE\n{}\n\n", msg),
            //Save(String, String), ??
            Delete(ref room) => format!("CMD\nDELETE\n{}\n\n", room),
            SaveRoom(ref room) => format!("CMD\nSAVEROOM\n{}\n\n", room),
            LoadRoom(ref room) => format!("CMD\nLOADROOM\n{}\n\n", room),
            Malformed => "A\nQUICK\nBROWN\nHOG\nJUMPS\nOVER\nTHE\nLAZY\nDOG\n\n".to_string(),
            Empty => "\n\n".to_string(),
            _ => panic!("Protocol message not yet implemented")
        }
    }
}

impl HWServerMessage {
    pub fn to_raw_protocol(&self) -> String {
        use self::HWServerMessage::*;
        match self {
            &Ping => "PING\n\n".to_string(),
            &Pong => "PONG\n\n".to_string(),
            &Connected(protocol_version)
                => construct_message(&[
                    "CONNECTED",
                    "Hedgewars server http://www.hedgewars.org/",
                    &protocol_version.to_string()
                ]),
            &Bye(ref msg) => construct_message(&["BYE", &msg]),
            &Nick(ref nick) => construct_message(&["NICK", &nick]),
            &LobbyLeft(ref nick)
                => construct_message(&["LOBBY_LEFT", &nick]),
            &LobbyJoined(ref nicks)
                => {
                let mut v = vec!["LOBBY:JOINED"];
                v.extend(nicks.iter().map(|n| { &n[..] }));
                construct_message(&v)
            },
            &ClientFlags(ref flags, ref nicks)
                => {
                let mut v = vec!["CLIENT_FLAGS"];
                v.push(&flags[..]);
                v.extend(nicks.iter().map(|n| { &n[..] }));
                construct_message(&v)
            },
            &ChatMsg(ref nick, ref msg)
                => construct_message(&["CHAT", &nick, &msg]),
            &Warning(ref msg)
                => construct_message(&["WARNING", &msg]),
            _ => construct_message(&["ERROR", "UNIMPLEMENTED"]),
        }
    }
}
