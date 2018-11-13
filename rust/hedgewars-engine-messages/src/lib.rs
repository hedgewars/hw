use nom::*;
use std::str;

#[derive(Debug, PartialEq)]
pub enum KeystrokeAction {
    Press,
    Release,
}

#[derive(Debug, PartialEq)]
pub enum SyncedEngineMessage {
    Left(KeystrokeAction),
    Right(KeystrokeAction),
    Up(KeystrokeAction),
    Down(KeystrokeAction),
    Precise(KeystrokeAction),
    Attack(KeystrokeAction),
    NextTurn,
    Switch,
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

#[derive(Debug, PartialEq)]
pub enum UnsyncedEngineMessage {
    Ping,
    Pong,
    Say(String),
    Taunt(u8),
    GameType(u8),
    Warning(String),
    StopSyncing,
    GameOver,
    GameInterrupted,
    GameSetupChecksum(String),
}

#[derive(Debug, PartialEq)]
pub enum ConfigEngineMessage {
    ConfigRequest,
    SetAmmo(String),
    SetScript(String),
    SetScriptParam(String),
    Spectate,
    TeamLocality(bool),
    SetMap(String),
    SetTheme(String),
    SetSeed(String),
    SetTemplateFilter(String),
    SetMapGenerator(String),
    SetFeatureSize(u8),
    SetDelay(u32),
    SetReadyDelay(u32),
    SetCratesFrequency(u8),
    SetHealthCrateProbability(u8),
    SetHealthCratesNumber(u8),
    SetRoundsTilSuddenDeath(u8),
    SetSuddenDeathWaterRiseSpeed(u8),
    SetSuddenDeathHealthDecreaseRate(u8),
    SetDamageMultiplier(u32),
    SetRopeLength(u32),
    SetGetawayTime(u32),
    SetDudMinesPercent(u8),
    SetMinesNumber(u32),
    SetAirMinesNumber(u32),
    SetBarrelsNumber(u32),
    SetTurnTime(u32),
    SetMinesTime(u32),
    SetWorldEdge(u8),
    Draw,
    // TODO
    SetVoicePack(String),
    AddHedgehog(String, u8, u32),
    AddTeam(String, u8),
    SetHedgehogCoordinates(i32, i32),
    SetFort(String),
    SetGrave(String),
    SetHat(String),
    SetFlag(String),
    SetOwner(String),
    SetOneClanMode(bool),
    SetMultishootMode(bool),
    SetSolidLand(bool),
    SetBorders(bool),
    SetDivideTeams(bool),
    SetLowGravity(bool),
    SetLaserSight(bool),
    SetInvulnerability(bool),
    SetHealthReset(bool),
    SetVampiric(bool),
    SetKarma(bool),
    SetArtilleryMode(bool),
    SetHedgehogSwitch(bool),
    SetRandomOrder(bool),
    SetKingMode(bool),
    SetPlaceHedgehog(bool),
    SetSharedAmmo(bool),
    SetGirdersEnabled(bool),
    SetLandObjectsEnabled(bool),
    SetAISurvivalMode(bool),
    SetInfiniteAttack(bool),
    SetResetWeapons(bool),
    SetAmmoPerHedgehog(bool),
    SetWindMode(u8),
    SetTagTeam(bool),
    SetBottomBorder(bool),
    SetShoppaBorder(bool),
}

#[derive(Debug, PartialEq)]
pub enum EngineMessage {
    Synced(SyncedEngineMessage, u32),
    Unsynced(UnsyncedEngineMessage),
    Config(ConfigEngineMessage),
    Unknown,
    Empty,
}

impl EngineMessage {
    fn from_bytes(buf: &[u8]) -> Self {
        unimplemented!()
    }

    fn to_bytes(&self) -> Vec<u8> {
        unimplemented!()
    }
}

named!(length_specifier<&[u8], u16>, alt!(
    verify!(map!(take!(1), |a : &[u8]| a[0] as u16), |l| l < 64)
    | map!(take!(2), |a| (a[0] as u16 - 64) * 256 + a[1] as u16 + 64)
    )
);

named!(unrecognized_message<&[u8], EngineMessage>,
    do_parse!(rest >> (EngineMessage::Unknown))
);

named!(string_tail<&[u8], String>, map!(map_res!(rest, str::from_utf8), String::from));

named!(synced_message<&[u8], SyncedEngineMessage>, alt!(
      do_parse!(tag!("+l") >> (SyncedEngineMessage::Left(KeystrokeAction::Press)))
));

named!(unsynced_message<&[u8], UnsyncedEngineMessage>, alt!(
      do_parse!(tag!("?") >> (UnsyncedEngineMessage::Ping))
    | do_parse!(tag!("!") >> (UnsyncedEngineMessage::Ping))
    | do_parse!(tag!("esay ") >> s: string_tail  >> (UnsyncedEngineMessage::Say(s)))
));

named!(config_message<&[u8], ConfigEngineMessage>, alt!(
    do_parse!(tag!("C") >> (ConfigEngineMessage::ConfigRequest))
));

named!(empty_message<&[u8], EngineMessage>,
    do_parse!(tag!("\0") >> (EngineMessage::Empty))
);

named!(non_empty_message<&[u8], EngineMessage>, length_value!(length_specifier,
    alt!(
          map!(synced_message, |m| EngineMessage::Synced(m, 0))
        | map!(unsynced_message, |m| EngineMessage::Unsynced(m))
        | map!(config_message, |m| EngineMessage::Config(m))
        | unrecognized_message
    )
));

named!(message<&[u8], EngineMessage>, alt!(
      empty_message
    | non_empty_message
    )
);

named!(pub extract_messages<&[u8], Vec<EngineMessage> >, many0!(complete!(message)));

#[test]
fn parse_length() {
    assert_eq!(length_specifier(b"\x01"), Ok((&b""[..], 1)));
    assert_eq!(length_specifier(b"\x00"), Ok((&b""[..], 0)));
    assert_eq!(length_specifier(b"\x3f"), Ok((&b""[..], 63)));
    assert_eq!(length_specifier(b"\x40\x00"), Ok((&b""[..], 64)));
    assert_eq!(length_specifier(b"\xff\xff"), Ok((&b""[..], 49215)));
}

#[test]
fn parse_synced_messages() {
    assert_eq!(message(b"\x02+l"), Ok((&b""[..], EngineMessage::Synced(SyncedEngineMessage::Left(KeystrokeAction::Press), 0))));
}

#[test]
fn parse_unsynced_messages() {
    assert_eq!(message(b"\x0aesay hello"), Ok((&b""[..], EngineMessage::Unsynced(UnsyncedEngineMessage::Say(String::from("hello"))))));
}

#[test]
fn parse_incorrect_messages() {
    assert_eq!(message(b"\x00"), Ok((&b""[..], EngineMessage::Empty)));
    assert_eq!(message(b"\x01\x00"), Ok((&b""[..], EngineMessage::Unknown)));
}

#[test]
fn parse_config_messages() {
    assert_eq!(
        message(b"\x01C"),
        Ok((
            &b""[..],
            EngineMessage::Config(ConfigEngineMessage::ConfigRequest)
        ))
    );
}
#[test]
fn parse_test_general() {
    assert_eq!(string_tail(b"abc"), Ok((&b""[..], String::from("abc"))));
}
