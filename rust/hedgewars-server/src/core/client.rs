use super::types::ClientId;
use bitflags::*;
use std::ops::Deref;

bitflags! {
    pub struct ClientFlags: u16 {
        const IS_ADMIN = 0b0000_0001;
        const IS_MASTER = 0b0000_0010;
        const IS_READY = 0b0000_0100;
        const IS_IN_GAME = 0b0000_1000;
        const IS_CONTRIBUTOR = 0b0001_0000;
        const HAS_SUPER_POWER = 0b0010_0000;
        const IS_REGISTERED = 0b0100_0000;
        const IS_MODERATOR = 0b1000_0000;
        const IS_REJOINED = 0b1_0000_0000;

        const NONE = 0b0000_0000;
        const DEFAULT = Self::NONE.bits;
    }
}

pub struct HwClient {
    pub id: ClientId,
    pub room_id: Option<usize>,
    pub nick: String,
    pub protocol_number: u16,
    pub flags: ClientFlags,
    pub teams_in_game: u8,
    pub team_indices: Vec<u8>,
    pub clan: Option<u8>,
}

impl HwClient {
    pub fn new(id: ClientId, protocol_number: u16, nick: String) -> HwClient {
        //todo!("add quiet flag");
        HwClient {
            id,
            nick,
            protocol_number,
            room_id: None,
            flags: ClientFlags::DEFAULT,
            teams_in_game: 0,
            team_indices: Vec::new(),
            clan: None,
        }
    }

    fn contains(&self, mask: ClientFlags) -> bool {
        self.flags.contains(mask)
    }

    fn set(&mut self, mask: ClientFlags, value: bool) {
        self.flags.set(mask, value);
    }

    pub fn is_admin(&self) -> bool {
        self.contains(ClientFlags::IS_ADMIN)
    }
    pub fn is_master(&self) -> bool {
        self.contains(ClientFlags::IS_MASTER)
    }
    pub fn is_ready(&self) -> bool {
        self.contains(ClientFlags::IS_READY)
    }
    pub fn is_in_game(&self) -> bool {
        self.contains(ClientFlags::IS_IN_GAME)
    }
    pub fn is_contributor(&self) -> bool {
        self.contains(ClientFlags::IS_CONTRIBUTOR)
    }
    pub fn has_super_power(&self) -> bool {
        self.contains(ClientFlags::HAS_SUPER_POWER)
    }
    pub fn is_registered(&self) -> bool {
        self.contains(ClientFlags::IS_REGISTERED)
    }
    pub fn is_rejoined(&self) -> bool {
        self.contains(ClientFlags::IS_REJOINED)
    }

    pub fn set_is_admin(&mut self, value: bool) {
        self.set(ClientFlags::IS_ADMIN, value)
    }
    pub fn set_is_master(&mut self, value: bool) {
        self.set(ClientFlags::IS_MASTER, value)
    }
    pub fn set_is_ready(&mut self, value: bool) {
        self.set(ClientFlags::IS_READY, value)
    }
    pub fn set_is_in_game(&mut self, value: bool) {
        self.set(ClientFlags::IS_IN_GAME, value)
    }
    pub fn set_is_contributor(&mut self, value: bool) {
        self.set(ClientFlags::IS_CONTRIBUTOR, value)
    }
    pub fn set_has_super_power(&mut self, value: bool) {
        self.set(ClientFlags::HAS_SUPER_POWER, value)
    }
    pub fn set_is_registered(&mut self, value: bool) {
        self.set(ClientFlags::IS_REGISTERED, value)
    }
    pub fn set_is_rejoined(&mut self, value: bool) {
        self.set(ClientFlags::IS_REJOINED, value)
    }
}
