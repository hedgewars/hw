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
    TeamControlGained(String),
    TeamControlLost(String),
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
