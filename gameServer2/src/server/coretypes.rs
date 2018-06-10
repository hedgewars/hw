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
    name: String,
    color: u8,
    grave: String,
    fort: String,
    voice_pack: String,
    flag: String,
    difficulty: u8,
    hedgehogs_number: u8,
    hedgehogs: [HedgehogInfo; 8],
}

#[derive(PartialEq, Eq, Clone, Debug)]
pub struct HedgehogInfo {
    name: String,
    hat: String,
}
