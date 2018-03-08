pub type RoomId = usize;

pub struct HWRoom {
    pub id: RoomId,
    pub name: String,
    pub password: Option<String>,
    pub protocol_number: u32,
    pub ready_players_number: u8,
}

impl HWRoom {
    pub fn new(id: RoomId) -> HWRoom {
        HWRoom {
            id,
            name: String::new(),
            password: None,
            protocol_number: 0,
            ready_players_number: 0,
        }
    }
}