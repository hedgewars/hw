#[derive(PartialEq, Eq, Clone, Debug)]
pub enum ServerVar {
    MOTDNew(String),
    MOTDOld(String),
    LatestProto(u32),
}

#[derive(PartialEq, Eq, Clone, Debug)]
pub enum GameCfg {

}

#[derive(PartialEq, Eq, Clone, Debug)]
pub struct TeamInfo {
    pub name: String,
    pub color: u8,
    pub grave: String,
    pub fort: String,
    pub voice_pack: String,
    pub flag: String,
    pub difficulty: u8,
    pub hedgehogs_number: u8,
    pub hedgehogs: [HedgehogInfo; 8],
}

#[derive(PartialEq, Eq, Clone, Debug)]
pub struct HedgehogInfo {
    pub name: String,
    pub hat: String,
}
