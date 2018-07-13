use super::coretypes::ClientId;

const IS_ADMIN: u8 = 0b0000_0001;
const IS_MASTER: u8 = 0b0000_0010;
const IS_READY: u8 = 0b0000_0100;
const IS_IN_GAME: u8 = 0b0000_1000;
const IS_JOINED_MID_GAME: u8 = 0b0001_0000;

pub struct HWClient {
    pub id: ClientId,
    pub room_id: Option<usize>,
    pub nick: String,
    pub protocol_number: u16,
    flags: u8,
    pub teams_in_game: u8,
    pub team_indices: Vec<u8>,
    pub clan: Option<u8>
}

impl HWClient {
    pub fn new(id: ClientId) -> HWClient {
        HWClient {
            id,
            room_id: None,
            nick: String::new(),
            protocol_number: 0,
            flags: 0,
            teams_in_game: 0,
            team_indices: Vec::new(),
            clan: None,
        }
    }

    fn set(&mut self, mask: u8, value: bool) {
        if value { self.flags |= mask } else { self.flags &= !mask }
    }

    pub fn is_admin(&self)-> bool { self.flags & IS_ADMIN != 0 }
    pub fn is_master(&self)-> bool { self.flags & IS_MASTER != 0 }
    pub fn is_ready(&self)-> bool { self.flags & IS_READY != 0 }
    pub fn is_in_game(&self)-> bool { self.flags & IS_IN_GAME != 0 }
    pub fn is_joined_mid_game(&self)-> bool { self.flags & IS_JOINED_MID_GAME != 0 }

    pub fn set_is_admin(&mut self, value: bool) { self.set(IS_ADMIN, value) }
    pub fn set_is_master(&mut self, value: bool) { self.set(IS_MASTER, value) }
    pub fn set_is_ready(&mut self, value: bool) { self.set(IS_READY, value) }
    pub fn set_is_in_game(&mut self, value: bool) { self.set(IS_IN_GAME, value) }
    pub fn set_is_joined_mid_game(&mut self, value: bool) { self.set(IS_JOINED_MID_GAME, value) }
}