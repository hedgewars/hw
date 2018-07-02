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
    ForwardEngineMessage(Vec<String>),
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

macro_rules! const_braces {
    ($e: expr) => { "{}\n" }
}

macro_rules! msg {
    [$($part: expr),*] => {
        format!(concat!($(const_braces!($part)),*, "\n"), $($part),*);
    };
}

impl<'a> HWProtocolMessage {
    pub fn to_raw_protocol(&self) -> String {
        use self::HWProtocolMessage::*;
        match self {
            Ping => msg!["PING"],
            Pong => msg!["PONG"],
            Quit(None) => msg!["QUIT"],
            Quit(Some(msg)) => msg!["QUIT", msg],
            Global(msg) => msg!["CMD", format!("GLOBAL {}", msg)],
            Watch(name) => msg!["CMD", format!("WATCH {}", name)],
            ToggleServerRegisteredOnly => msg!["CMD", "REGISTERED_ONLY"],
            SuperPower =>  msg!["CMD", "SUPER_POWER"],
            Info(info) => msg!["CMD", format!("INFO {}", info)],
            Nick(nick) => msg!("NICK", nick),
            Proto(version) => msg!["PROTO", version],
            Password(p, s) => msg!["PASSWORD", p, s],
            Checker(i, n, p) => msg!["CHECKER", i, n, p],
            List => msg!["LIST"],
            Chat(msg) => msg!["CHAT", msg],
            CreateRoom(name, None) => msg!["CREATE_ROOM", name],
            CreateRoom(name, Some(password)) =>
                msg!["CREATE_ROOM", name, password],
            JoinRoom(name, None) => msg!["JOIN_ROOM", name],
            JoinRoom(name, Some(password)) =>
                msg!["JOIN_ROOM", name, password],
            Follow(name) => msg!["FOLLOW", name],
            Rnd(args) => msg!["RND", args.join(" ")],
            Kick(name) => msg!["KICK", name],
            Ban(name, reason, time) => msg!["BAN", name, reason, time],
            BanIP(ip, reason, time) => msg!["BAN_IP", ip, reason, time],
            BanNick(nick, reason, time) =>
                msg!("BAN_NICK", nick, reason, time),
            BanList => msg!["BANLIST"],
            Unban(name) => msg!["UNBAN", name],
            //SetServerVar(ServerVar), ???
            GetServerVar => msg!["GET_SERVER_VAR"],
            RestartServer => msg!["CMD", "RESTART_SERVER YES"],
            Stats => msg!["CMD", "STATS"],
            Part(None) => msg!["PART"],
            Part(Some(msg)) => msg!["PART", msg],
            //Cfg(GameCfg) =>
            //AddTeam(info) =>
            RemoveTeam(name) => msg!["REMOVE_TEAM", name],
            //SetHedgehogsNumber(team, number), ??
            //SetTeamColor(team, color), ??
            ToggleReady => msg!["TOGGLE_READY"],
            StartGame => msg!["START_GAME"],
            EngineMessage(msg) => msg!["EM", msg],
            RoundFinished => msg!["ROUNDFINISHED"],
            ToggleRestrictJoin => msg!["TOGGLE_RESTRICT_JOINS"],
            ToggleRestrictTeams => msg!["TOGGLE_RESTRICT_TEAMS"],
            ToggleRegisteredOnly => msg!["TOGGLE_REGISTERED_ONLY"],
            RoomName(name) => msg!["ROOM_NAME", name],
            Delegate(name) => msg!["CMD", format!("DELEGATE {}", name)],
            TeamChat(msg) => msg!["TEAMCHAT", msg],
            MaxTeams(count) => msg!["CMD", format!("MAXTEAMS {}", count)] ,
            Fix => msg!["CMD", "FIX"],
            Unfix => msg!["CMD", "UNFIX"],
            Greeting(msg) => msg!["CMD", format!("GREETING {}", msg)],
            //CallVote(Option<(String, Option<String>)>) =>, ??
            Vote(msg) => msg!["CMD", format!("VOTE {}", msg)],
            ForceVote(msg) => msg!["CMD", format!("FORCE {}", msg)],
            //Save(String, String), ??
            Delete(room) => msg!["CMD", format!("DELETE {}", room)],
            SaveRoom(room) => msg!["CMD", format!("SAVEROOM {}", room)],
            LoadRoom(room) => msg!["CMD", format!("LOADROOM {}", room)],
            Malformed => msg!["A", "QUICK", "BROWN", "HOG", "JUMPS", "OVER", "THE", "LAZY", "DOG"],
            Empty => msg![""],
            _ => panic!("Protocol message not yet implemented")
        }
    }
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
            ForwardEngineMessage(em) =>
                construct_message(&["EM"], &em),
            RoundFinished => msg!["ROUND_FINISHED"],
            ChatMsg(nick, msg) => msg!["CHAT", nick, msg],
            ServerMessage(msg) => msg!["SERVER_MESSAGE", msg],
            Warning(msg) => msg!["WARNING", msg],
            Error(msg) => msg!["ERROR", msg],
            _ => msg!["ERROR", "UNIMPLEMENTED"],
        }
    }
}
