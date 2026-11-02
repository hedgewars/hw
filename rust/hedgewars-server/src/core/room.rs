use super::{
    client::HwClient,
    types::{ClientId, RoomId, Voting},
};
use bitflags::*;
use hedgewars_network_protocol::types::{
    GameCfg, GameCfg::*, RoomConfig, TeamInfo, MAX_HEDGEHOGS_PER_TEAM,
};
use serde_derive::{Deserialize, Serialize};
use serde_yaml;
use std::{collections::HashMap, iter};

pub const MAX_TEAMS_IN_ROOM: u8 = 8;
pub const MAX_HEDGEHOGS_IN_ROOM: u8 = MAX_TEAMS_IN_ROOM * MAX_HEDGEHOGS_PER_TEAM;

#[derive(Clone, Debug)]
pub struct OwnedTeam {
    pub owner_id: ClientId,
    pub owner_nick: String,
    pub info: TeamInfo,
}

fn client_teams_impl(
    teams: &[OwnedTeam],
    owner_id: ClientId,
) -> impl Iterator<Item = &TeamInfo> + Clone {
    teams
        .iter()
        .filter(move |team| team.owner_id == owner_id)
        .map(|team| &team.info)
}

pub struct GameInfo {
    pub original_teams: Vec<OwnedTeam>,
    pub left_teams: Vec<String>,
    pub rejoined_teams: Vec<String>,
    pub msg_log: Vec<String>,
    pub sync_msg: Option<String>,
    pub is_paused: bool,
    pub teams_in_game: u8,
    pub all_players_registered: bool,
    original_config: RoomConfig,
}

impl GameInfo {
    fn new(teams: Vec<OwnedTeam>, config: RoomConfig, all_players_registered: bool) -> GameInfo {
        let teams_in_game = teams.len() as u8;
        GameInfo {
            left_teams: Vec::new(),
            rejoined_teams: Vec::new(),
            msg_log: Vec::new(),
            sync_msg: None,
            is_paused: false,
            teams_in_game,
            all_players_registered,
            original_teams: teams,
            original_config: config,
        }
    }

    pub fn client_teams(&self, owner_id: ClientId) -> impl Iterator<Item = &TeamInfo> + Clone {
        client_teams_impl(&self.original_teams, owner_id)
    }

    pub fn client_teams_by_nick<'a>(
        &'a self,
        owner_nick: &'a str,
    ) -> impl Iterator<Item = &'a TeamInfo> + Clone + 'a {
        self.original_teams
            .iter()
            .filter(move |team| team.owner_nick == owner_nick)
            .map(|team| &team.info)
    }

    pub fn log_team_removal<'a, I>(&mut self, team_names: I)
    where
        I: Iterator<Item = &'a String>,
    {
        for team_name in team_names {
            if let Some(m) = self.sync_msg.take() {
                self.msg_log.push(m);
            }
            let remove_msg = crate::utils::to_engine_msg(iter::once(b'F').chain(team_name.bytes()));
            self.msg_log.push(remove_msg);
            self.teams_in_game = self.teams_in_game.saturating_sub(1);
        }
    }

    pub fn mark_left_teams<'a, I>(&mut self, was_in_game: bool, team_names: I)
    where
        I: Iterator<Item = &'a String> + Clone,
    {
        for team_name in team_names.clone() {
            self.left_teams.push(team_name.clone());
        }
        if was_in_game {
            self.log_team_removal(team_names);
        }
    }
}

#[derive(Serialize, Deserialize)]
pub struct RoomSave {
    pub location: String,
    config: RoomConfig,
}

bitflags! {
    pub struct RoomFlags: u8 {
        const FIXED = 0b0000_0001;
        const RESTRICTED_JOIN = 0b0000_0010;
        const RESTRICTED_TEAM_ADD = 0b0000_0100;
        const REGISTRATION_REQUIRED = 0b0000_1000;
    }
}

pub struct HwRoom {
    pub id: RoomId,
    pub master_id: Option<ClientId>,
    pub name: String,
    pub password: Option<String>,
    pub greeting: String,
    pub protocol_number: u16,
    pub flags: RoomFlags,

    pub players_number: u8,
    pub default_hedgehog_number: u8,
    pub max_teams: u8,
    pub ready_players_number: u8,
    pub teams: Vec<OwnedTeam>,
    config: RoomConfig,
    pub voting: Option<Voting>,
    pub saves: HashMap<String, RoomSave>,
    pub game_info: Option<GameInfo>,
    pub bans: Vec<String>,
}

impl HwRoom {
    pub fn new(id: RoomId) -> HwRoom {
        HwRoom {
            id,
            master_id: None,
            name: String::new(),
            password: None,
            greeting: "".to_string(),
            flags: RoomFlags::empty(),
            protocol_number: 0,
            players_number: 0,
            default_hedgehog_number: 4,
            max_teams: MAX_TEAMS_IN_ROOM,
            ready_players_number: 0,
            teams: Vec::new(),
            config: RoomConfig::new(),
            voting: None,
            saves: HashMap::new(),
            game_info: None,
            bans: Vec::new(),
        }
    }

    pub fn hedgehogs_number(&self) -> u8 {
        self.teams
            .iter()
            .map(|team| team.info.hedgehogs_number)
            .sum()
    }

    pub fn addable_hedgehogs(&self) -> u8 {
        MAX_HEDGEHOGS_IN_ROOM - self.hedgehogs_number()
    }

    pub fn add_team(
        &mut self,
        owner: &HwClient,
        mut team: TeamInfo,
        preserve_color: bool,
    ) -> &TeamInfo {
        if !preserve_color {
            team.color = iter::repeat(())
                .enumerate()
                .map(|(i, _)| i as u8)
                .take(u8::MAX as usize + 1)
                .find(|i| self.teams.iter().all(|team| team.info.color != *i))
                .unwrap_or(0u8)
        };
        team.hedgehogs_number = if self.teams.is_empty() {
            self.default_hedgehog_number
        } else {
            self.teams[0]
                .info
                .hedgehogs_number
                .min(self.addable_hedgehogs())
        };
        self.teams.push(OwnedTeam {
            owner_id: owner.id,
            owner_nick: owner.nick.clone(),
            info: team,
        });
        &self.teams.last().unwrap().info
    }

    pub fn remove_team(&mut self, team_name: &str) {
        if let Some(index) = self
            .teams
            .iter()
            .position(|team| team.info.name == team_name)
        {
            self.teams.remove(index);
        }
    }

    pub fn set_hedgehogs_number(&mut self, n: u8) -> Vec<String> {
        let mut names = Vec::new();
        let teams = &mut self.teams;

        if teams.len() as u8 * n <= MAX_HEDGEHOGS_IN_ROOM {
            for team in teams.iter_mut() {
                team.info.hedgehogs_number = n;
                names.push(team.info.name.clone())
            }
            self.default_hedgehog_number = n;
        }
        names
    }

    pub fn teams_in_game(&self) -> Option<u8> {
        self.game_info.as_ref().map(|info| info.teams_in_game)
    }

    pub fn find_team_and_owner_mut<F>(&mut self, f: F) -> Option<(ClientId, &mut TeamInfo)>
    where
        F: Fn(&TeamInfo) -> bool,
    {
        self.teams
            .iter_mut()
            .find(|team| f(&team.info))
            .map(|team| (team.owner_id, &mut team.info))
    }

    pub fn find_team<F>(&self, f: F) -> Option<&TeamInfo>
    where
        F: Fn(&TeamInfo) -> bool,
    {
        self.teams
            .iter()
            .find_map(|team| Some(&team.info).filter(|t| f(t)))
    }

    pub fn client_teams(&self, owner_id: ClientId) -> impl Iterator<Item = &TeamInfo> {
        client_teams_impl(&self.teams, owner_id)
    }

    pub fn client_team_indices(&self, client_id: ClientId) -> Vec<u8> {
        self.teams
            .iter()
            .enumerate()
            .filter(move |(_, team)| team.owner_id == client_id)
            .map(|(i, _)| i as u8)
            .collect()
    }

    pub fn clan_team_owners(&self, color: u8) -> impl Iterator<Item = ClientId> + '_ {
        self.teams
            .iter()
            .filter(move |team| team.info.color == color)
            .map(|team| team.owner_id)
    }

    pub fn find_team_owner(&self, team_name: &str) -> Option<(ClientId, &str)> {
        self.teams
            .iter()
            .find(|team| team.info.name == team_name)
            .map(|team| (team.owner_id, &team.info.name[..]))
    }

    pub fn find_team_color(&self, owner_id: ClientId) -> Option<u8> {
        self.client_teams(owner_id).nth(0).map(|t| t.color)
    }

    pub fn has_multiple_clans(&self) -> bool {
        let colors = self.teams.iter().map(|team| team.info.color);
        colors.clone().min() != colors.max()
    }

    pub fn set_config(&mut self, cfg: GameCfg) {
        self.config.set_config(cfg);
    }

    pub fn start_round(&mut self, all_players_registered: bool) {
        if self.game_info.is_none() {
            self.game_info = Some(GameInfo::new(
                self.teams.clone(),
                self.config.clone(),
                all_players_registered,
            ));
        }
    }

    pub fn is_fixed(&self) -> bool {
        self.flags.contains(RoomFlags::FIXED)
    }
    pub fn is_join_restricted(&self) -> bool {
        self.flags.contains(RoomFlags::RESTRICTED_JOIN)
    }
    pub fn is_team_add_restricted(&self) -> bool {
        self.flags.contains(RoomFlags::RESTRICTED_TEAM_ADD)
    }
    pub fn is_registration_required(&self) -> bool {
        self.flags.contains(RoomFlags::REGISTRATION_REQUIRED)
    }

    pub fn set_is_fixed(&mut self, value: bool) {
        self.flags.set(RoomFlags::FIXED, value)
    }
    pub fn set_join_restriction(&mut self, value: bool) {
        self.flags.set(RoomFlags::RESTRICTED_JOIN, value)
    }
    pub fn set_team_add_restriction(&mut self, value: bool) {
        self.flags.set(RoomFlags::RESTRICTED_TEAM_ADD, value)
    }
    pub fn set_unregistered_players_restriction(&mut self, value: bool) {
        self.flags.set(RoomFlags::REGISTRATION_REQUIRED, value)
    }

    fn flags_string(&self) -> String {
        let mut result = "-".to_string();
        if self.game_info.is_some() {
            result += "g"
        }
        if self.password.is_some() {
            result += "p"
        }
        if self.is_join_restricted() {
            result += "j"
        }
        if self.is_registration_required() {
            result += "r"
        }
        result
    }

    pub fn get_name(&self, protocol: u16) -> String {
        if protocol < 60 && protocol != self.protocol_number {
            format!(
                "[v{}] {}",
                crate::utils::protocol_version_string(self.protocol_number),
                self.name
            )
        } else {
            self.name.clone()
        }
    }

    pub fn info(&self, master: Option<&HwClient>, protocol: u16) -> Vec<String> {
        let c = &self.config;
        let mut info = vec![
            self.flags_string(),
            self.get_name(protocol),
            self.players_number.to_string(),
            self.teams.len().to_string(),
            master.map_or("[]", |c| &c.nick).to_string(),
            c.map_type.to_string(),
            c.script.to_string(),
            c.scheme.name.to_string(),
            c.ammo.name.to_string(),
        ];

        if protocol >= 60 {
            info.push(self.protocol_number.to_string());
        }

        info
    }

    pub fn config(&self) -> &RoomConfig {
        &self.config
    }

    pub fn active_config(&self) -> &RoomConfig {
        match self.game_info {
            Some(ref info) => &info.original_config,
            None => &self.config,
        }
    }

    pub fn map_config(&self) -> Vec<String> {
        match self.game_info {
            Some(ref info) => info.original_config.to_map_config(),
            None => self.config.to_map_config(),
        }
    }

    pub fn game_config(&self) -> Vec<GameCfg> {
        match self.game_info {
            Some(ref info) => info.original_config.to_game_config(),
            None => self.config.to_game_config(),
        }
    }

    pub fn save_config(&mut self, name: String, location: String) {
        self.saves.insert(
            name,
            RoomSave {
                location,
                config: self.config.clone(),
            },
        );
    }

    pub fn load_config(&mut self, name: &str) -> Option<&str> {
        if let Some(save) = self.saves.get(name) {
            self.config = save.config.clone();
            Some(&save.location[..])
        } else {
            None
        }
    }

    pub fn delete_config(&mut self, name: &str) -> bool {
        self.saves.remove(name).is_some()
    }

    pub fn get_saves(&self) -> Result<String, serde_yaml::Error> {
        let mut hs_saves: HashMap<
            String,
            (String, HashMap<String, String>, HashMap<String, Vec<String>>),
        > = HashMap::new();
        for (name, save) in &self.saves {
            let (mp, p) = room_config_to_maps(&save.config);
            hs_saves.insert(name.clone(), (save.location.clone(), mp, p));
        }
        serde_yaml::to_string(&(&self.greeting, &hs_saves))
    }

    pub fn set_saves(&mut self, text: &str) -> Result<(), serde_yaml::Error> {
        let raw_val: serde_yaml::Value = serde_yaml::from_str(text)?;
        let untagged = strip_yaml_tags(raw_val);
        if let Ok((greeting, hs_saves)) = serde_yaml::from_value::<(
            String,
            HashMap<
                String,
                (String, HashMap<String, String>, HashMap<String, Vec<String>>),
            >,
        )>(untagged.clone())
        {
            self.greeting = greeting;
            self.saves = hs_saves
                .into_iter()
                .map(|(k, (location, mp, p))| {
                    (
                        k,
                        RoomSave {
                            location,
                            config: room_config_from_maps(&mp, &p),
                        },
                    )
                })
                .collect();
            Ok(())
        } else {
            serde_yaml::from_value::<(String, HashMap<String, RoomSave>)>(untagged).map(
                |(greeting, saves)| {
                    self.greeting = greeting;
                    self.saves = saves;
                },
            )
        }
    }
}

fn strip_yaml_tags(val: serde_yaml::Value) -> serde_yaml::Value {
    use serde_yaml::Value;
    match val {
        Value::Tagged(tagged) => strip_yaml_tags(tagged.value),
        Value::Sequence(seq) => Value::Sequence(seq.into_iter().map(strip_yaml_tags).collect()),
        Value::Mapping(map) => Value::Mapping(
            map.into_iter()
                .map(|(k, v)| (strip_yaml_tags(k), strip_yaml_tags(v)))
                .collect(),
        ),
        other => other,
    }
}

pub fn room_config_to_maps(
    c: &RoomConfig,
) -> (HashMap<String, String>, HashMap<String, Vec<String>>) {
    let mut mp = HashMap::new();
    mp.insert("FEATURE_SIZE".to_string(), c.feature_size.to_string());
    mp.insert("MAP".to_string(), c.map_type.clone());
    mp.insert("MAPGEN".to_string(), c.map_generator.to_string());
    mp.insert("MAZE_SIZE".to_string(), c.maze_size.to_string());
    mp.insert("SEED".to_string(), c.seed.clone());
    mp.insert("TEMPLATE".to_string(), c.template.to_string());

    let mut p = HashMap::new();
    let ammo_vec = match &c.ammo.settings {
        Some(s) => vec![c.ammo.name.clone(), s.clone()],
        None => vec![c.ammo.name.clone()],
    };
    p.insert("AMMO".to_string(), ammo_vec);
    let mut scheme_vec = vec![c.scheme.name.clone()];
    scheme_vec.extend(c.scheme.settings.iter().cloned());
    p.insert("SCHEME".to_string(), scheme_vec);
    p.insert("SCRIPT".to_string(), vec![c.script.clone()]);
    p.insert("THEME".to_string(), vec![c.theme.clone()]);
    if let Some(ref dm) = c.drawn_map {
        p.insert("DRAWNMAP".to_string(), vec![dm.clone()]);
    }
    (mp, p)
}

pub fn room_config_from_maps(
    mp: &HashMap<String, String>,
    p: &HashMap<String, Vec<String>>,
) -> RoomConfig {
    let mut c = RoomConfig::new();
    if let Some(v) = mp.get("FEATURE_SIZE").and_then(|s| s.parse().ok()) {
        c.feature_size = v;
    }
    if let Some(v) = mp.get("MAP") {
        c.map_type = v.clone();
    }
    if let Some(v) = mp.get("MAPGEN").and_then(|s| s.parse().ok()) {
        c.map_generator = v;
    }
    if let Some(v) = mp.get("MAZE_SIZE").and_then(|s| s.parse().ok()) {
        c.maze_size = v;
    }
    if let Some(v) = mp.get("SEED") {
        c.seed = v.clone();
    }
    if let Some(v) = mp.get("TEMPLATE").and_then(|s| s.parse().ok()) {
        c.template = v;
    }
    if let Some(v) = p.get("AMMO") {
        if let Some(name) = v.first() {
            c.ammo.name = name.clone();
            c.ammo.settings = v.get(1).cloned();
        }
    }
    if let Some(v) = p.get("SCHEME") {
        if let Some(name) = v.first() {
            c.scheme.name = name.clone();
            c.scheme.settings = v[1..].to_vec();
        }
    }
    if let Some(v) = p.get("SCRIPT").and_then(|v| v.first()) {
        c.script = v.clone();
    }
    if let Some(v) = p.get("THEME").and_then(|v| v.first()) {
        c.theme = v.clone();
    }
    if let Some(v) = p.get("DRAWNMAP").and_then(|v| v.first()) {
        c.drawn_map = Some(v.clone());
    }
    c
}
