use std::iter;
use server::{
    coretypes::{TeamInfo, GameCfg},
    client::{ClientId, HWClient}
};

const MAX_HEDGEHOGS_IN_ROOM: u8 = 48;
pub type RoomId = usize;

pub struct HWRoom {
    pub id: RoomId,
    pub master_id: Option<ClientId>,
    pub name: String,
    pub password: Option<String>,
    pub protocol_number: u32,

    pub players_number: u32,
    pub default_hedgehog_number: u8,
    pub team_limit: u8,
    pub ready_players_number: u8,
    pub teams: Vec<(ClientId, TeamInfo)>,
    pub game_info: Option<()>
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
            default_hedgehog_number: 4,
            team_limit: 8,
            ready_players_number: 0,
            teams: Vec::new(),
            game_info: None
        }
    }

    pub fn hedgehogs_number(&self) -> u8 {
        self.teams.iter().map(|(_, t)| t.hedgehogs_number).sum()
    }

    pub fn addable_hedgehogs(&self) -> u8 {
        MAX_HEDGEHOGS_IN_ROOM - self.hedgehogs_number()
    }

    pub fn add_team(&mut self, owner_id: ClientId, mut team: TeamInfo) -> &TeamInfo {
        team.color = iter::repeat(()).enumerate()
            .map(|(i, _)| i as u8).take(u8::max_value() as usize + 1)
            .find(|i| self.teams.iter().all(|(_, t)| t.color != *i ))
            .unwrap_or(0u8);
        team.hedgehogs_number = if self.teams.is_empty() {
            self.default_hedgehog_number
        } else {
            self.teams[0].1.hedgehogs_number.min(self.addable_hedgehogs())
        };
        self.teams.push((owner_id, team));
        &self.teams.last().unwrap().1
    }

    pub fn remove_team(&mut self, name: &str) {
        if let Some(index) = self.teams.iter().position(|(_, t)| t.name == name) {
            self.teams.remove(index);
        }
    }

    pub fn find_team_and_owner_mut<F>(&mut self, f: F) -> Option<(ClientId, &mut TeamInfo)>
        where F: Fn(&TeamInfo) -> bool {
        self.teams.iter_mut().find(|(_, t)| f(t)).map(|(id, t)| (*id, t))
    }

    pub fn find_team<F>(&self, f: F) -> Option<&TeamInfo>
        where F: Fn(&TeamInfo) -> bool {
        self.teams.iter().map(|(_, t)| t).find(|t| f(*t))
    }

    pub fn client_teams(&self, client_id: ClientId) -> impl Iterator<Item = &TeamInfo> {
        self.teams.iter().filter(move |(id, _)| *id == client_id).map(|(_, t)| t)
    }

    pub fn find_team_owner(&self, team_name: &str) -> Option<(ClientId, &str)> {
        self.teams.iter().find(|(_, t)| t.name == team_name)
            .map(|(id, t)| (*id, &t.name[..]))
    }

    pub fn find_team_color(&self, owner_id: ClientId) -> Option<u8> {
        self.client_teams(owner_id).nth(0).map(|t| t.color)
    }

    pub fn info(&self, master: Option<&HWClient>) -> Vec<String> {
        let flags = "-".to_string();
        vec![
            flags,
            self.name.clone(),
            self.players_number.to_string(),
            self.teams.len().to_string(),
            master.map_or("?", |c| &c.nick).to_string(),
            "Normal".to_string(),
            "Default".to_string(),
            "Default".to_string(),
            "Default".to_string(),
        ]
    }

    pub fn team_info(owner: &HWClient, team: &TeamInfo) -> Vec<String> {
        let mut info = vec![
            team.name.clone(),
            team.grave.clone(),
            team.fort.clone(),
            team.voice_pack.clone(),
            team.flag.clone(),
            owner.nick.clone(),
            team.difficulty.to_string()];
        let hogs = team.hedgehogs.iter().flat_map(|h|
            iter::once(h.name.clone()).chain(iter::once(h.hat.clone())));
        info.extend(hogs);
        info
    }
}