pub type ClientId = usize;

pub struct HWClient {
    pub id: ClientId,
    pub room_id: Option<usize>,
    pub nick: String,
    pub protocol_number: u32,
    pub is_master: bool,
    pub is_ready: bool,
    pub is_joined_mid_game: bool,
}

impl HWClient {
    pub fn new(id: ClientId) -> HWClient {
        HWClient {
            id,
            room_id: None,
            nick: String::new(),
            protocol_number: 0,
            is_master: false,
            is_ready: false,
            is_joined_mid_game: false,
        }
    }
}