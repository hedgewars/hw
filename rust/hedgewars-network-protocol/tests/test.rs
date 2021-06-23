use proptest::{
    arbitrary::any,
    proptest,
    strategy::{BoxedStrategy, Just, Strategy},
};

use hedgewars_network_protocol::messages::{HwProtocolMessage, HwProtocolMessage::*};
use hedgewars_network_protocol::parser::message;
use hedgewars_network_protocol::types::{GameCfg, ServerVar, TeamInfo, VoteType};

use hedgewars_network_protocol::types::testing::*;
use hedgewars_network_protocol::{proto_msg_case, proto_msg_match};

pub fn gen_proto_msg() -> BoxedStrategy<HwProtocolMessage> where {
    let res = (0..=55).no_shrink().prop_flat_map(|i| {
        proto_msg_match!(i, def = Ping,
            0 => Ping(),
            1 => Pong(),
            2 => Quit(Option<Ascii>),
            4 => Global(Ascii),
            5 => Watch(u32),
            6 => ToggleServerRegisteredOnly(),
            7 => SuperPower(),
            8 => Info(Ascii),
            9 => Nick(Ascii),
            10 => Proto(u16),
            11 => Password(Ascii, Ascii),
            12 => Checker(u16, Ascii, Ascii),
            13 => List(),
            14 => Chat(Ascii),
            15 => CreateRoom(Ascii, Option<Ascii>),
            16 => JoinRoom(Ascii, Option<Ascii>),
            17 => Follow(Ascii),
            18 => Rnd(Vec<Ascii>),
            19 => Kick(Ascii),
            20 => Ban(Ascii, Ascii, u32),
            21 => BanIp(Ascii, Ascii, u32),
            22 => BanNick(Ascii, Ascii, u32),
            23 => BanList(),
            24 => Unban(Ascii),
            25 => SetServerVar(ServerVar),
            26 => GetServerVar(),
            27 => RestartServer(),
            28 => Stats(),
            29 => Part(Option<Ascii>),
            30 => Cfg(GameCfg),
            31 => AddTeam(Box<TeamInfo>),
            32 => RemoveTeam(Ascii),
            33 => SetHedgehogsNumber(Ascii, u8),
            34 => SetTeamColor(Ascii, u8),
            35 => ToggleReady(),
            36 => StartGame(),
            37 => EngineMessage(Ascii),
            38 => RoundFinished(),
            39 => ToggleRestrictJoin(),
            40 => ToggleRestrictTeams(),
            41 => ToggleRegisteredOnly(),
            42 => RoomName(Ascii),
            43 => Delegate(Ascii),
            44 => TeamChat(Ascii),
            45 => MaxTeams(u8),
            46 => Fix(),
            47 => Unfix(),
            48 => Greeting(Option<Ascii>),
            49 => CallVote(Option<VoteType>),
            50 => Vote(bool),
            51 => ForceVote(bool),
            52 => Save(Ascii, Ascii),
            53 => Delete(Ascii),
            54 => SaveRoom(Ascii),
            55 => LoadRoom(Ascii)
        )
    });
    res.boxed()
}

proptest! {
    #[test]
    fn is_parser_composition_idempotent(ref msg in gen_proto_msg()) {
        println!("!! Msg: {:?}, Bytes: {:?} !!", msg, msg.to_raw_protocol().as_bytes());
        assert_eq!(message(msg.to_raw_protocol().as_bytes()), Ok((&b""[..], msg.clone())))
    }
}
