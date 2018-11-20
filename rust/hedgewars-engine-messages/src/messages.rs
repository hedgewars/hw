use byteorder::{BigEndian, WriteBytesExt};

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
    CursorMove(i32, i32),
    HighJump,
    LongJump,
    Skip,
    TeamControlGained(String),
    TeamControlLost(String),
    TimeWrap,
    Taunt(u8),
    HogSay(String),
    Heartbeat,
}

#[derive(Debug, PartialEq)]
pub enum UnsyncedEngineMessage {
    TeamControlGained(String),
    TeamControlLost(String),
}

#[derive(Debug, PartialEq)]
pub enum UnorderedEngineMessage {
    Ping,
    Pong,
    ChatMessage(String),
    TeamMessage(String),
    Error(String),
    Warning(String),
    StopSyncing,
    GameOver,
    GameInterrupted,
    GameSetupChecksum(String),
    PauseToggled,
}

#[derive(Debug, PartialEq)]
pub enum ConfigEngineMessage {
    GameType(u8),
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
    Unknown,
    Empty,
    Synced(SyncedEngineMessage, u32),
    Unsynced(UnsyncedEngineMessage),
    Unordered(UnorderedEngineMessage),
    Config(ConfigEngineMessage),
}

macro_rules! em {
    [$msg: expr] => {
        vec![($msg)]
    };
}

macro_rules! ems {
    [$msg: expr, $param: expr] => {
        {
            let mut v = vec![($msg)];
            v.extend(String::into_bytes($param.to_string()).iter());
            v
        }
    };
}

impl SyncedEngineMessage {
    fn to_bytes(&self) -> Vec<u8> {
        use self::KeystrokeAction::*;
        use self::SyncedEngineMessage::*;
        match self {
            Left(Press) => em![b'L'],
            Left(Release) => em![b'l'],
            Right(Press) => em![b'R'],
            Right(Release) => em![b'r'],
            Up(Press) => em![b'U'],
            Up(Release) => em![b'u'],
            Down(Press) => em![b'D'],
            Down(Release) => em![b'd'],
            Precise(Press) => em![b'Z'],
            Precise(Release) => em![b'z'],
            Attack(Press) => em![b'A'],
            Attack(Release) => em![b'a'],
            NextTurn => em![b'N'],
            Switch => em![b'S'],
            Timer(t) => vec![b'0' + t],
            Slot(s) => vec![b'~' , *s],
            SetWeapon(s) => vec![b'~', *s],
            Put(x, y) => {
                let mut v = vec![b'p'];
                v.write_i24::<BigEndian>(*x).unwrap();
                v.write_i24::<BigEndian>(*y).unwrap();

                v
            },
            CursorMove(x, y) => {
                let mut v = vec![b'P'];
                v.write_i24::<BigEndian>(*x).unwrap();
                v.write_i24::<BigEndian>(*y).unwrap();

                v
            },
            HighJump => em![b'J'],
            LongJump => em![b'j'],
            Skip => em![b','],
            TeamControlGained(str) => ems![b'g', str],
            TeamControlLost(str) => ems![b'f', str],
            Taunt(s) => vec![b't', *s],
            HogSay(str) => ems![b'h', str],
            Heartbeat => em![b'+'],
            TimeWrap => unreachable!(),
        }
    }
}

impl UnsyncedEngineMessage {
    fn to_bytes(&self) -> Vec<u8> {
        use self::UnsyncedEngineMessage::*;
        match self {
            TeamControlGained(str) => ems![b'G', str],
            TeamControlLost(str) => ems![b'F', str],
        }
    }
}

impl UnorderedEngineMessage {
    fn to_bytes(&self) -> Vec<u8> {
        use self::UnorderedEngineMessage::*;
        match self {
            Ping => em![b'?'],
            Pong => em![b'!'],
            ChatMessage(str) => ems![b's', str],
            TeamMessage(str) => ems![b'b', str],
            Error(str) => ems![b'E', str],
            Warning(_) => unreachable!(),
            StopSyncing => unreachable!(),
            GameOver => em![b'q'],
            GameInterrupted => em![b'Q'],
            GameSetupChecksum(str) => ems![b'M', str],
            PauseToggled => unreachable!(),
        }
    }
}

impl ConfigEngineMessage {
    fn to_bytes(&self) -> Vec<u8> {
        unreachable!()
    }
}

impl EngineMessage {
    pub const MAX_LEN: u16 = 49215;

    fn to_unwrapped(&self) -> Vec<u8> {
        use self::EngineMessage::*;
        match self {
            Unknown => unreachable!("you're not supposed to construct such messages"),
            Empty => unreachable!("you're not supposed to construct such messages"),
            Synced(SyncedEngineMessage::TimeWrap, _) => vec![b'#', 0xff, 0xff],
            Synced(msg, timestamp) => {
                let mut v = msg.to_bytes();
                v.push((*timestamp / 256) as u8);
                v.push(*timestamp as u8);

                v
            }
            Unsynced(msg) => msg.to_bytes(),
            Unordered(msg) => msg.to_bytes(),
            Config(msg) => msg.to_bytes(),
        }
    }

    pub fn to_bytes(&self) -> Vec<u8> {
        let mut unwrapped = self.to_unwrapped();
        let mut size = unwrapped.len();

        if size > EngineMessage::MAX_LEN as usize - 2 {
            size = EngineMessage::MAX_LEN as usize - 2;
            unwrapped.truncate(size);
        }

        if size < 64 {
            unwrapped.insert(0, size as u8);
        } else {
            size -= 64;
            unwrapped.insert(0, (size / 256 + 64) as u8);
            unwrapped.insert(1, size as u8);
        }

        unwrapped
    }
}

#[test]
fn message_contruction() {
    assert_eq!(
        EngineMessage::Synced(SyncedEngineMessage::TimeWrap, 0).to_bytes(),
        vec![3, b'#', 255, 255]
    );
    assert_eq!(
        EngineMessage::Synced(SyncedEngineMessage::NextTurn, 258).to_bytes(),
        vec![3, b'N', 1, 2]
    );

    assert_eq!(
        EngineMessage::Synced(SyncedEngineMessage::Put(-31337, 65538), 0).to_bytes(),
        vec![9, b'p', 255, 133, 151, 1, 0, 2, 0, 0]
    );
}
