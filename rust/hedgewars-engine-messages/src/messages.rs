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
        vec![($msg) as u8]
    };
}

macro_rules! ems {
    [$msg: expr, $param: expr] => {
        {
            let mut v = vec![($msg) as u8];
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
            Left(Press) => em!['L'],
            Left(Release) => em!['l'],
            Right(Press) => em!['R'],
            Right(Release) => em!['r'],
            Up(Press) => em!['U'],
            Up(Release) => em!['u'],
            Down(Press) => em!['D'],
            Down(Release) => em!['d'],
            Precise(Press) => em!['Z'],
            Precise(Release) => em!['z'],
            Attack(Press) => em!['A'],
            Attack(Release) => em!['a'],
            NextTurn => em!['N'],
            Switch => em!['S'],
            Timer(t) => vec!['0' as u8 + t],
            Slot(s) => vec!['~' as u8, *s],
            SetWeapon(s) => vec!['~' as u8, *s],
            Put(x, y) => unimplemented!(),
            CursorMove(x, y) => unimplemented!(),
            HighJump => em!['J'],
            LongJump => em!['j'],
            Skip => em![','],
            TeamControlGained(str) => ems!['g', str],
            TeamControlLost(str) => ems!['f', str],
            Taunt(s) => vec!['t' as u8, *s],
            HogSay(str) => ems!['h', str],
            Heartbeat => em!['+'],
            TimeWrap => unreachable!(),
        }
    }
}

impl UnsyncedEngineMessage {
    fn to_bytes(&self) -> Vec<u8> {
        use self::UnsyncedEngineMessage::*;
        match self {
            TeamControlGained(str) => ems!['G', str],
            TeamControlLost(str) => ems!['F', str],
        }
    }
}

impl UnorderedEngineMessage {
    fn to_bytes(&self) -> Vec<u8> {
        unimplemented!()
    }
}

impl ConfigEngineMessage {
    fn to_bytes(&self) -> Vec<u8> {
        unimplemented!()
    }
}

impl EngineMessage {
    pub const MAX_LEN: u16 = 49215;

    fn to_unwrapped(&self) -> Vec<u8> {
        use self::EngineMessage::*;
        match self {
            Unknown => unreachable!("you're not supposed to construct such messages"),
            Empty => unreachable!("you're not supposed to construct such messages"),
            Synced(SyncedEngineMessage::TimeWrap, _) => vec!['#' as u8, 0xff, 0xff],
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
        vec![3, '#' as u8, 255, 255]
    );
    assert_eq!(
        EngineMessage::Synced(SyncedEngineMessage::NextTurn, 258).to_bytes(),
        vec![3, 'N' as u8, 1, 2]
    );
}
