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
    TeamAdd(Vec<String>),
    TeamRemove(String),
    TeamAccepted(String),
    TeamColor(String, u8),
    HedgehogsNumber(String, u8),
    ConfigEntry(String, Vec<String>),
    RunGame,
    ForwardEngineMessage(String),
    RoundFinished,

    ServerMessage(String),
    Warning(String),
    Error(String),
    Connected(u32),
    Unreachable,
}

impl GameCfg {
    pub fn into_server_msg(self) -> HWServerMessage {
        use self::HWServerMessage::ConfigEntry;
        use server::coretypes::GameCfg::*;
        match self {
            FeatureSize(s) => ConfigEntry("FEATURE_SIZE".to_string(), vec![s.to_string()]),
            MapType(t) => ConfigEntry("MAP".to_string(), vec![t.to_string()]),
            MapGenerator(g) => ConfigEntry("MAPGEN".to_string(), vec![g.to_string()]),
            MazeSize(s) => ConfigEntry("MAZE_SIZE".to_string(), vec![s.to_string()]),
            Seed(s) => ConfigEntry("SEED".to_string(), vec![s.to_string()]),
            Template(t) => ConfigEntry("TEMPLATE".to_string(), vec![t.to_string()]),

            Ammo(n, None) => ConfigEntry("AMMO".to_string(), vec![n.to_string()]),
            Ammo(n, Some(s)) => ConfigEntry("AMMO".to_string(), vec![n.to_string(), s.to_string()]),
            Scheme(n, None) => ConfigEntry("SCHEME".to_string(), vec![n.to_string()]),
            Scheme(n, Some(s)) => ConfigEntry("SCHEME".to_string(), {
                let mut v = vec![n.to_string()];
                v.extend(s.into_iter());
                v
            }),
            Script(s) => ConfigEntry("SCRIPT".to_string(), vec![s.to_string()]),
            Theme(t) => ConfigEntry("THEME".to_string(), vec![t.to_string()]),
            DrawnMap(m) => ConfigEntry("DRAWNMAP".to_string(), vec![m.to_string()])
        }
    }
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

fn construct_message(header: &[&str], msg: &Vec<String>) -> String {
    let mut v: Vec<_> = header.iter().map(|s| *s).collect();
    v.extend(msg.iter().map(|s| &s[..]));
    v.push("\n");
    v.join("\n")
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
            LobbyJoined(nicks) =>
                construct_message(&["LOBBY:JOINED"], &nicks),
            ClientFlags(flags, nicks) =>
                construct_message(&["CLIENT_FLAGS", flags], &nicks),
            Rooms(info) =>
                construct_message(&["ROOMS"], &info),
            RoomAdd(info) =>
                construct_message(&["ROOM", "ADD"], &info),
            RoomJoined(nicks) =>
                construct_message(&["JOINED"], &nicks),
            RoomLeft(nick, msg) => msg!["LEFT", nick, msg],
            RoomRemove(name) => msg!["ROOM", "DEL", name],
            RoomUpdated(name, info) =>
                construct_message(&["ROOM", "UPD", name], &info),
            TeamAdd(info) =>
                construct_message(&["ADD_TEAM"], &info),
            TeamRemove(name) => msg!["REMOVE_TEAM", name],
            TeamAccepted(name) => msg!["TEAM_ACCEPTED", name],
            TeamColor(name, color) => msg!["TEAM_COLOR", name, color],
            HedgehogsNumber(name, number) => msg!["HH_NUM", name, number],
            ConfigEntry(name, values) =>
                construct_message(&["CFG", name], &values),
            RunGame => msg!["RUN_GAME"],
            ForwardEngineMessage(em) => msg!["EM", em],
            RoundFinished => msg!["ROUND_FINISHED"],
            ChatMsg(nick, msg) => msg!["CHAT", nick, msg],
            ServerMessage(msg) => msg!["SERVER_MESSAGE", msg],
            Warning(msg) => msg!["WARNING", msg],
            Error(msg) => msg!["ERROR", msg],
            _ => msg!["ERROR", "UNIMPLEMENTED"],
        }
    }
}
