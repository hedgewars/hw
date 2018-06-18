use server::{
    coretypes::TeamInfo,
    client::{ClientId, HWClient}
};

pub type RoomId = usize;

pub struct HWRoom {
    pub id: RoomId,
    pub master_id: Option<ClientId>,
    pub name: String,
    pub password: Option<String>,
    pub protocol_number: u32,

    pub players_number: u32,
    pub ready_players_number: u8,
    pub teams: Vec<TeamInfo>,
}

impl HWRoom {
    pub fn new(id: RoomId) -> HWRoom {
        HWRoom {
            id,
            master_id: None,
            name: String::new(),
            password: None,
            protocol_number: 0,
            players_number: 0,
            ready_players_number: 0,
            teams: Vec::new()
        }
    }

    pub fn info(&self, master: Option<&HWClient>) -> Vec<String> {
        let flags = "-".to_string();
        vec![
            flags,
            self.name.clone(),
            self.players_number.to_string(),
            self.teams.len().to_string(),
            master.map_or("?", |c| &c.nick).to_string(),
            "Default".to_string(),
            "Default".to_string(),
            "Default".to_string(),
            "Default".to_string(),
        ]
    }
}