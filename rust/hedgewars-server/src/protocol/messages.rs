use crate::server::coretypes::{GameCfg, HedgehogInfo, ServerVar, TeamInfo, VoteType};
use std::{convert::From, iter::once, ops};

#[derive(PartialEq, Eq, Clone, Debug)]
pub enum HWProtocolMessage {
    // common messages
    Ping,
    Pong,
    Quit(Option<String>),
    Global(String),
    Watch(String),
    ToggleServerRegisteredOnly,
    SuperPower,
    Info(String),
    // anteroom messages
    Nick(String),
    Proto(u16),
    Password(String, String),
    Checker(u16, String, String),
    // lobby messages
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
    // room messages
    Part(Option<String>),
    Cfg(GameCfg),
    AddTeam(Box<TeamInfo>),
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
    CallVote(Option<VoteType>),
    Vote(bool),
    ForceVote(bool),
    Save(String, String),
    Delete(String),
    SaveRoom(String),
    LoadRoom(String),
    Malformed,
    Empty,
}

#[derive(Debug)]
pub enum ProtocolFlags {
    InRoom,
    RoomMaster,
    Ready,
    InGame,
    Authenticated,
    Admin,
    Contributor,
}

impl ProtocolFlags {
    #[inline]
    fn flag_char(&self) -> char {
        match self {
            ProtocolFlags::InRoom => 'i',
            ProtocolFlags::RoomMaster => 'h',
            ProtocolFlags::Ready => 'r',
            ProtocolFlags::InGame => 'g',
            ProtocolFlags::Authenticated => 'u',
            ProtocolFlags::Admin => 'a',
            ProtocolFlags::Contributor => 'c',
        }
    }

    #[inline]
    fn format(prefix: char, flags: &[ProtocolFlags]) -> String {
        once(prefix)
            .chain(flags.iter().map(|f| f.flag_char()))
            .collect()
    }
}

#[inline]
pub fn add_flags(flags: &[ProtocolFlags]) -> String {
    ProtocolFlags::format('+', flags)
}

#[inline]
pub fn remove_flags(flags: &[ProtocolFlags]) -> String {
    ProtocolFlags::format('-', flags)
}

#[derive(Debug)]
pub enum HWServerMessage {
    Ping,
    Pong,
    Bye(String),

    Nick(String),
    Proto(u16),
    AskPassword(String),
    ServerAuth(String),

    LobbyLeft(String, String),
    LobbyJoined(Vec<String>),
    ChatMsg { nick: String, msg: String },
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
    Kicked,
    RunGame,
    ForwardEngineMessage(Vec<String>),
    RoundFinished,

    ServerMessage(String),
    ServerVars(Vec<String>),
    Notice(String),
    Warning(String),
    Error(String),
    Connected(u32),
    Unreachable,

    //Deprecated messages
    LegacyReady(bool, Vec<String>),
}

pub fn server_chat(msg: String) -> HWServerMessage {
    HWServerMessage::ChatMsg {
        nick: "[server]".to_string(),
        msg,
    }
}

impl ServerVar {
    pub fn to_protocol(&self) -> Vec<String> {
        match self {
            ServerVar::MOTDNew(s) => vec!["MOTD_NEW".to_string(), s.clone()],
            ServerVar::MOTDOld(s) => vec!["MOTD_OLD".to_string(), s.clone()],
            ServerVar::LatestProto(n) => vec!["LATEST_PROTO".to_string(), n.to_string()],
        }
    }
}

impl GameCfg {
    pub fn to_protocol(&self) -> (String, Vec<String>) {
        use crate::server::coretypes::GameCfg::*;
        match self {
            FeatureSize(s) => ("FEATURE_SIZE".to_string(), vec![s.to_string()]),
            MapType(t) => ("MAP".to_string(), vec![t.to_string()]),
            MapGenerator(g) => ("MAPGEN".to_string(), vec![g.to_string()]),
            MazeSize(s) => ("MAZE_SIZE".to_string(), vec![s.to_string()]),
            Seed(s) => ("SEED".to_string(), vec![s.to_string()]),
            Template(t) => ("TEMPLATE".to_string(), vec![t.to_string()]),

            Ammo(n, None) => ("AMMO".to_string(), vec![n.to_string()]),
            Ammo(n, Some(s)) => ("AMMO".to_string(), vec![n.to_string(), s.to_string()]),
            Scheme(n, s) if s.is_empty() => ("SCHEME".to_string(), vec![n.to_string()]),
            Scheme(n, s) => ("SCHEME".to_string(), {
                let mut v = vec![n.to_string()];
                v.extend(s.clone().into_iter());
                v
            }),
            Script(s) => ("SCRIPT".to_string(), vec![s.to_string()]),
            Theme(t) => ("THEME".to_string(), vec![t.to_string()]),
            DrawnMap(m) => ("DRAWNMAP".to_string(), vec![m.to_string()]),
        }
    }

    pub fn to_server_msg(&self) -> HWServerMessage {
        use self::HWServerMessage::ConfigEntry;
        let (name, args) = self.to_protocol();
        HWServerMessage::ConfigEntry(name, args)
    }
}

macro_rules! const_braces {
    ($e: expr) => {
        "{}\n"
    };
}

macro_rules! msg {
    [$($part: expr),*] => {
        format!(concat!($(const_braces!($part)),*, "\n"), $($part),*);
    };
}

#[cfg(test)]
macro_rules! several {
    [$part: expr] => { once($part) };
    [$part: expr, $($other: expr),*] => { once($part).chain(several![$($other),*]) };
}

impl HWProtocolMessage {
    /** Converts the message to a raw `String`, which can be sent over the network.
     *
     * This is the inverse of the `message` parser.
     */
    #[cfg(test)]
    pub(crate) fn to_raw_protocol(&self) -> String {
        use self::HWProtocolMessage::*;
        match self {
            Ping => msg!["PING"],
            Pong => msg!["PONG"],
            Quit(None) => msg!["QUIT"],
            Quit(Some(msg)) => msg!["QUIT", msg],
            Global(msg) => msg!["CMD", format!("GLOBAL {}", msg)],
            Watch(name) => msg!["CMD", format!("WATCH {}", name)],
            ToggleServerRegisteredOnly => msg!["CMD", "REGISTERED_ONLY"],
            SuperPower => msg!["CMD", "SUPER_POWER"],
            Info(info) => msg!["CMD", format!("INFO {}", info)],
            Nick(nick) => msg!("NICK", nick),
            Proto(version) => msg!["PROTO", version],
            Password(p, s) => msg!["PASSWORD", p, s],
            Checker(i, n, p) => msg!["CHECKER", i, n, p],
            List => msg!["LIST"],
            Chat(msg) => msg!["CHAT", msg],
            CreateRoom(name, None) => msg!["CREATE_ROOM", name],
            CreateRoom(name, Some(password)) => msg!["CREATE_ROOM", name, password],
            JoinRoom(name, None) => msg!["JOIN_ROOM", name],
            JoinRoom(name, Some(password)) => msg!["JOIN_ROOM", name, password],
            Follow(name) => msg!["FOLLOW", name],
            Rnd(args) => {
                if args.is_empty() {
                    msg!["CMD", "RND"]
                } else {
                    msg!["CMD", format!("RND {}", args.join(" "))]
                }
            }
            Kick(name) => msg!["KICK", name],
            Ban(name, reason, time) => msg!["BAN", name, reason, time],
            BanIP(ip, reason, time) => msg!["BAN_IP", ip, reason, time],
            BanNick(nick, reason, time) => msg!("BAN_NICK", nick, reason, time),
            BanList => msg!["BANLIST"],
            Unban(name) => msg!["UNBAN", name],
            SetServerVar(var) => construct_message(&["SET_SERVER_VAR"], &var.to_protocol()),
            GetServerVar => msg!["GET_SERVER_VAR"],
            RestartServer => msg!["CMD", "RESTART_SERVER YES"],
            Stats => msg!["CMD", "STATS"],
            Part(None) => msg!["PART"],
            Part(Some(msg)) => msg!["PART", msg],
            Cfg(config) => {
                let (name, args) = config.to_protocol();
                msg!["CFG", name, args.join("\n")]
            }
            AddTeam(info) => msg![
                "ADD_TEAM",
                info.name,
                info.color,
                info.grave,
                info.fort,
                info.voice_pack,
                info.flag,
                info.difficulty,
                info.hedgehogs
                    .iter()
                    .flat_map(|h| several![&h.name[..], &h.hat[..]])
                    .collect::<Vec<_>>()
                    .join("\n")
            ],
            RemoveTeam(name) => msg!["REMOVE_TEAM", name],
            SetHedgehogsNumber(team, number) => msg!["HH_NUM", team, number],
            SetTeamColor(team, color) => msg!["TEAM_COLOR", team, color],
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
            MaxTeams(count) => msg!["CMD", format!("MAXTEAMS {}", count)],
            Fix => msg!["CMD", "FIX"],
            Unfix => msg!["CMD", "UNFIX"],
            Greeting(msg) => msg!["CMD", format!("GREETING {}", msg)],
            //CallVote(Option<(String, Option<String>)>) =>, ??
            Vote(msg) => msg!["CMD", format!("VOTE {}", if *msg { "YES" } else { "NO" })],
            ForceVote(msg) => msg!["CMD", format!("FORCE {}", if *msg { "YES" } else { "NO" })],
            Save(name, location) => msg!["CMD", format!("SAVE {} {}", name, location)],
            Delete(name) => msg!["CMD", format!("DELETE {}", name)],
            SaveRoom(name) => msg!["CMD", format!("SAVEROOM {}", name)],
            LoadRoom(name) => msg!["CMD", format!("LOADROOM {}", name)],
            Malformed => msg!["A", "QUICK", "BROWN", "HOG", "JUMPS", "OVER", "THE", "LAZY", "DOG"],
            Empty => msg![""],
            _ => panic!("Protocol message not yet implemented"),
        }
    }
}

fn construct_message(header: &[&str], msg: &[String]) -> String {
    let mut v: Vec<_> = header.iter().cloned().collect();
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
                "Hedgewars server https://www.hedgewars.org/",
                protocol_version
            ],
            Bye(msg) => msg!["BYE", msg],
            Nick(nick) => msg!["NICK", nick],
            Proto(proto) => msg!["PROTO", proto],
            AskPassword(salt) => msg!["ASKPASSWORD", salt],
            ServerAuth(hash) => msg!["SERVER_AUTH", hash],
            LobbyLeft(nick, msg) => msg!["LOBBY:LEFT", nick, msg],
            LobbyJoined(nicks) => construct_message(&["LOBBY:JOINED"], &nicks),
            ClientFlags(flags, nicks) => construct_message(&["CLIENT_FLAGS", flags], &nicks),
            Rooms(info) => construct_message(&["ROOMS"], &info),
            RoomAdd(info) => construct_message(&["ROOM", "ADD"], &info),
            RoomJoined(nicks) => construct_message(&["JOINED"], &nicks),
            RoomLeft(nick, msg) => msg!["LEFT", nick, msg],
            RoomRemove(name) => msg!["ROOM", "DEL", name],
            RoomUpdated(name, info) => construct_message(&["ROOM", "UPD", name], &info),
            TeamAdd(info) => construct_message(&["ADD_TEAM"], &info),
            TeamRemove(name) => msg!["REMOVE_TEAM", name],
            TeamAccepted(name) => msg!["TEAM_ACCEPTED", name],
            TeamColor(name, color) => msg!["TEAM_COLOR", name, color],
            HedgehogsNumber(name, number) => msg!["HH_NUM", name, number],
            ConfigEntry(name, values) => construct_message(&["CFG", name], &values),
            Kicked => msg!["KICKED"],
            RunGame => msg!["RUN_GAME"],
            ForwardEngineMessage(em) => construct_message(&["EM"], &em),
            RoundFinished => msg!["ROUND_FINISHED"],
            ChatMsg { nick, msg } => msg!["CHAT", nick, msg],
            ServerMessage(msg) => msg!["SERVER_MESSAGE", msg],
            ServerVars(vars) => construct_message(&["SERVER_VARS"], &vars),
            Notice(msg) => msg!["NOTICE", msg],
            Warning(msg) => msg!["WARNING", msg],
            Error(msg) => msg!["ERROR", msg],

            LegacyReady(is_ready, nicks) => {
                construct_message(&[if *is_ready { "READY" } else { "NOT_READY" }], &nicks)
            }

            _ => msg!["ERROR", "UNIMPLEMENTED"],
        }
    }
}
