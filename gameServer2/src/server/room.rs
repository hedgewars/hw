use std::{iter};
use server::{
    coretypes::{ClientId, RoomId, TeamInfo, GameCfg, GameCfg::*, Voting},
    client::{HWClient}
};

const MAX_HEDGEHOGS_IN_ROOM: u8 = 48;

#[derive(Clone)]
struct Ammo {
    name: String,
    settings: Option<String>
}

#[derive(Clone)]
struct Scheme {
    name: String,
    settings: Option<Vec<String>>
}

#[derive(Clone)]
struct RoomConfig {
    feature_size: u32,
    map_type: String,
    map_generator: u32,
    maze_size: u32,
    seed: String,
    template: u32,

    ammo: Ammo,
    scheme: Scheme,
    script: String,
    theme: String,
    drawn_map: Option<String>
}

impl RoomConfig {
    fn new() -> RoomConfig {
        RoomConfig {
            feature_size: 12,
            map_type: "+rnd+".to_string(),
            map_generator: 0,
            maze_size: 0,
            seed: "seed".to_string(),
            template: 0,

            ammo: Ammo {name: "Default".to_string(), settings: None },
            scheme: Scheme {name: "Default".to_string(), settings: None },
            script: "Normal".to_string(),
            theme: "\u{1f994}".to_string(),
            drawn_map: None
        }
    }
}

fn client_teams_impl(teams: &Vec<(ClientId, TeamInfo)>, client_id: ClientId)
    -> impl Iterator<Item = &TeamInfo> + Clone
{
    teams.iter().filter(move |(id, _)| *id == client_id).map(|(_, t)| t)
}

fn map_config_from(c: &RoomConfig) -> Vec<String> {
    vec![c.feature_size.to_string(), c.map_type.to_string(),
         c.map_generator.to_string(), c.maze_size.to_string(),
         c.seed.to_string(), c.template.to_string()]
}

fn game_config_from(c: &RoomConfig) -> Vec<GameCfg> {
    use server::coretypes::GameCfg::*;
    let mut v = vec![
        Ammo(c.ammo.name.to_string(), c.ammo.settings.clone()),
        Scheme(c.scheme.name.to_string(), c.scheme.settings.clone()),
        Script(c.script.to_string()),
        Theme(c.theme.to_string())];
    if let Some(ref m) = c.drawn_map {
        v.push(DrawnMap(m.to_string()))
    }
    v
}

pub struct GameInfo {
    pub teams_in_game: u8,
    pub teams_at_start: Vec<(ClientId, TeamInfo)>,
    pub left_teams: Vec<String>,
    pub msg_log: Vec<String>,
    pub sync_msg: Option<String>,
    pub is_paused: bool,
    config: RoomConfig
}

impl GameInfo {
    fn new(teams: Vec<(ClientId, TeamInfo)>, config: RoomConfig) -> GameInfo {
        GameInfo {
            left_teams: Vec::new(),
            msg_log: Vec::new(),
            sync_msg: None,
            is_paused: false,
            teams_in_game: teams.len() as u8,
            teams_at_start: teams,
            config
        }
    }

    pub fn client_teams(&self, client_id: ClientId) -> impl Iterator<Item = &TeamInfo> + Clone {
        client_teams_impl(&self.teams_at_start, client_id)
    }
}

pub struct HWRoom {
    pub id: RoomId,
    pub master_id: Option<ClientId>,
    pub name: String,
    pub password: Option<String>,
    pub protocol_number: u32,
    pub greeting: String,
    pub is_fixed: bool,

    pub players_number: u32,
    pub default_hedgehog_number: u8,
    pub team_limit: u8,
    pub ready_players_number: u8,
    pub teams: Vec<(ClientId, TeamInfo)>,
    config: RoomConfig,
    pub voting: Option<Voting>,
    pub game_info: Option<GameInfo>
}

impl HWRoom {
    pub fn new(id: RoomId) -> HWRoom {
        HWRoom {
            id,
            master_id: None,
            name: String::new(),
            password: None,
            greeting: "".to_string(),
            is_fixed: false,
            protocol_number: 0,
            players_number: 0,
            default_hedgehog_number: 4,
            team_limit: 8,
            ready_players_number: 0,
            teams: Vec::new(),
            config: RoomConfig::new(),
            voting: None,
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

    pub fn set_hedgehogs_number(&mut self, n: u8) -> Vec<String> {
        let mut names = Vec::new();
        let teams = match self.game_info {
            Some(ref mut info) => &mut info.teams_at_start,
            None => &mut self.teams
        };

        if teams.len() as u8 * n <= MAX_HEDGEHOGS_IN_ROOM {
            for (_, team) in teams.iter_mut() {
                team.hedgehogs_number = n;
                names.push(team.name.clone())
            };
            self.default_hedgehog_number = n;
        }
        names
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
        client_teams_impl(&self.teams, client_id)
    }

    pub fn client_team_indices(&self, client_id: ClientId) -> Vec<u8> {
        self.teams.iter().enumerate()
            .filter(move |(_, (id, _))| *id == client_id)
            .map(|(i, _)| i as u8).collect()
    }

    pub fn find_team_owner(&self, team_name: &str) -> Option<(ClientId, &str)> {
        self.teams.iter().find(|(_, t)| t.name == team_name)
            .map(|(id, t)| (*id, &t.name[..]))
    }

    pub fn find_team_color(&self, owner_id: ClientId) -> Option<u8> {
        self.client_teams(owner_id).nth(0).map(|t| t.color)
    }

    pub fn has_multiple_clans(&self) -> bool {
        self.teams.iter().min_by_key(|(_, t)| t.color) !=
            self.teams.iter().max_by_key(|(_, t)| t.color)
    }

    pub fn set_config(&mut self, cfg: GameCfg) {
        let c = &mut self.config;
        match cfg {
            FeatureSize(s) => c.feature_size = s,
            MapType(t) => c.map_type = t,
            MapGenerator(g) => c.map_generator = g,
            MazeSize(s) => c.maze_size = s,
            Seed(s) => c.seed = s,
            Template(t) => c.template = t,

            Ammo(n, s) => c.ammo = Ammo {name: n, settings: s},
            Scheme(n, s) => c.scheme = Scheme {name: n, settings: s},
            Script(s) => c.script = s,
            Theme(t) => c.theme = t,
            DrawnMap(m) => c.drawn_map = Some(m)
        };
    }

    pub fn start_round(&mut self) {
        if self.game_info.is_none() {
            self.game_info = Some(GameInfo::new(
                self.teams.clone(), self.config.clone()));
        }
    }

    pub fn info(&self, master: Option<&HWClient>) -> Vec<String> {
        let flags = "-".to_string();
        let c = &self.config;
        vec![
            flags,
            self.name.clone(),
            self.players_number.to_string(),
            self.teams.len().to_string(),
            master.map_or("[]", |c| &c.nick).to_string(),
            c.map_type.to_string(),
            c.script.to_string(),
            c.scheme.name.to_string(),
            c.ammo.name.to_string()
        ]
    }

    pub fn map_config(&self) -> Vec<String> {
        match self.game_info {
            Some(ref info) => map_config_from(&info.config),
            None => map_config_from(&self.config)
        }
    }

    pub fn game_config(&self) -> Vec<GameCfg> {
        match self.game_info {
            Some(ref info) => game_config_from(&info.config),
            None => game_config_from(&self.config)
        }
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