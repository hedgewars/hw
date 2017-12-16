#[derive(PartialEq, Debug)]
pub enum ServerVar {
    MOTDNew(String),
    MOTDOld(String),
    LatestProto(u32),
}

#[derive(PartialEq, Debug)]
pub enum GameCfg {

}

#[derive(PartialEq, Debug)]
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

#[derive(PartialEq, Debug)]
pub struct HedgehogInfo {
    name: String,
    hat: String,
}
