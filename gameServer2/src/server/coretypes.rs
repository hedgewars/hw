pub enum ServerVar {
    MOTDNew(String),
    MOTDOld(String),
    LatestProto(u32),
}

pub enum GameCfg {

}

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

pub struct HedgehogInfo {
    name: String,
    hat: String,
}
