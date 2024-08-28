use crate::{core::types::Replay, server::haskell::HaskellValue};
use hedgewars_network_protocol::types::{
    Ammo, GameCfg, HedgehogInfo, RoomConfig, Scheme, TeamInfo,
};
use std::{
    collections::HashMap,
    fs,
    io::{self, BufReader, Read, Write},
    str::FromStr,
};

#[derive(PartialEq, Debug)]
pub struct Demo {
    teams: Vec<TeamInfo>,
    config: Vec<GameCfg>,
    messages: Vec<String>,
}

impl Demo {
    fn load_hwd(filename: String) -> io::Result<Self> {
        let file = fs::File::open(filename)?;
        let mut reader = io::BufReader::new(file);

        #[inline]
        fn error<T>(cause: &str) -> io::Result<T> {
            Err(io::Error::new(io::ErrorKind::InvalidData, cause))
        }

        fn read_command<'a>(
            reader: &mut BufReader<fs::File>,
            buffer: &'a mut [u8],
        ) -> io::Result<Option<&'a str>> {
            use io::BufRead;

            let mut size = [0u8; 1];
            if reader.read(&mut size)? == 0 {
                Ok(None)
            } else {
                let text = &mut buffer[0..size[0] as _];

                if reader.read(text)? < text.len() {
                    Err(io::Error::new(
                        io::ErrorKind::UnexpectedEof,
                        "Incomplete command",
                    ))
                } else {
                    std::str::from_utf8(text).map(Some).map_err(|e| {
                        io::Error::new(io::ErrorKind::InvalidInput, "The string is not UTF8")
                    })
                }
            }
        }

        fn get_script_name(arg: &str) -> io::Result<String> {
            const PREFIX: &str = "Scripts/Multiplayer/";
            const SUFFIX: &str = ".lua";
            if arg.starts_with(PREFIX) && arg.ends_with(SUFFIX) {
                let script = arg[PREFIX.len()..arg.len() - SUFFIX.len()].to_string();
                Ok(script.replace('_', " "))
            } else {
                error("Script is not multiplayer")
            }
        }

        fn get_game_flags(arg: &str) -> io::Result<Vec<String>> {
            const FLAGS: &[u32] = &[
                0x0000_1000,
                0x0000_0010,
                0x0000_0004,
                0x0000_0008,
                0x0000_0020,
                0x0000_0040,
                0x0000_0080,
                0x0000_0100,
                0x0000_0200,
                0x0000_0400,
                0x0000_0800,
                0x0000_2000,
                0x0000_4000,
                0x0000_8000,
                0x0001_0000,
                0x0002_0000,
                0x0004_0000,
                0x0008_0000,
                0x0010_0000,
                0x0020_0000,
                0x0040_0000,
                0x0080_0000,
                0x0100_0000,
                0x0200_0000,
                0x0400_0000,
            ];

            let flags = u32::from_str(arg).unwrap_or_default();
            let game_flags = FLAGS
                .iter()
                .map(|flag| (flag & flags != 0).to_string())
                .collect();

            Ok(game_flags)
        }

        let mut config = Vec::new();
        let mut buffer = [0u8; u8::max_value() as _];

        let mut game_flags = vec![];
        let mut scheme_properties: Vec<_> = [
            "1", "1000", "100", "1", "1", "1000", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1",
            "1", "",
        ]
        .iter()
        .map(|p| p.to_string())
        .collect();
        const SCHEME_PROPERTY_NAMES: &[&str] = &[
            "$damagepct",
            "$turntime",
            "",
            "$sd_turns",
            "$casefreq",
            "$minestime",
            "$minesnum",
            "$minedudpct",
            "$explosives",
            "$airmines",
            "$healthprob",
            "$hcaseamount",
            "$waterrise",
            "$healthdec",
            "$ropepct",
            "$getawaytime",
            "$worldedge",
        ];
        const AMMO_PROPERTY_NAMES: &[&str] = &["eammloadt", "eammprob", "eammdelay", "eammreinf"];
        let mut ammo_settings = vec![String::new(); AMMO_PROPERTY_NAMES.len()];
        let mut teams = vec![];
        let mut hog_index = 7usize;

        //todo!("read messages from file");
        let messages = vec![];

        while let Some(cmd) = read_command(&mut reader, &mut buffer)? {
            if let Some(index) = cmd.find(' ') {
                match cmd.chars().next().unwrap_or_default() {
                    'T' => {
                        if cmd != "TD" {
                            let () = error("Not a demo file")?;
                        }
                    }
                    'e' => {
                        if let Some(index) = cmd.find(' ') {
                            let (name, arg) = cmd.split_at(index);
                            match name {
                                "script" => config.push(GameCfg::Script(get_script_name(arg)?)),
                                "map" => config.push(GameCfg::MapType(arg.to_string())),
                                "theme" => config.push(GameCfg::Theme(arg.to_string())),
                                "seed" => config.push(GameCfg::Seed(arg.to_string())),
                                "$gmflags" => game_flags = get_game_flags(arg)?,
                                "$scriptparam" => {
                                    *scheme_properties.last_mut().unwrap() = arg.to_string()
                                }
                                "$template_filter" => config.push(GameCfg::Template(
                                    u32::from_str(arg).unwrap_or_default(),
                                )),
                                "$feature_size" => config.push(GameCfg::FeatureSize(
                                    u32::from_str(arg).unwrap_or_default(),
                                )),
                                "$map_gen" => config.push(GameCfg::MapGenerator(
                                    u32::from_str(arg).unwrap_or_default(),
                                )),
                                "$maze_size" => config.push(GameCfg::MazeSize(
                                    u32::from_str(arg).unwrap_or_default(),
                                )),
                                "addteam" => {
                                    let parts = arg.splitn(3, ' ').collect::<Vec<_>>();
                                    let color = parts.get(1).unwrap_or(&"1");
                                    let name = parts.get(2).unwrap_or(&"Unnamed");
                                    teams.push(TeamInfo {
                                        color: (u32::from_str(color).unwrap_or(2113696) / 2113696
                                            - 1)
                                            as u8,
                                        name: name.to_string(),
                                        ..TeamInfo::default()
                                    });
                                }
                                "fort" => teams
                                    .last_mut()
                                    .iter_mut()
                                    .for_each(|t| t.fort = arg.to_string()),
                                "grave" => teams
                                    .last_mut()
                                    .iter_mut()
                                    .for_each(|t| t.grave = arg.to_string()),
                                "addhh" => {
                                    hog_index = (hog_index + 1) % 8;
                                    let parts = arg.splitn(3, ' ').collect::<Vec<_>>();
                                    let health = parts.get(1).unwrap_or(&"100");
                                    teams.last_mut().iter_mut().for_each(|t| {
                                        if let Some(difficulty) = parts.get(0) {
                                            t.difficulty = u8::from_str(difficulty).unwrap_or(0);
                                        }
                                        if let Some(init_health) = parts.get(1) {
                                            scheme_properties[2] = init_health.to_string();
                                        }
                                        t.hedgehogs_number = (hog_index + 1) as u8;
                                        t.hedgehogs[hog_index].name =
                                            parts.get(2).unwrap_or(&"Unnamed").to_string();
                                    });
                                }
                                "hat" => {
                                    teams
                                        .last_mut()
                                        .iter_mut()
                                        .for_each(|t| t.hedgehogs[hog_index].hat = arg.to_string());
                                }
                                name => {
                                    if let Some(index) =
                                        SCHEME_PROPERTY_NAMES.iter().position(|n| *n == name)
                                    {
                                        scheme_properties[index] = arg.to_string();
                                    } else if let Some(index) =
                                        AMMO_PROPERTY_NAMES.iter().position(|n| *n == name)
                                    {
                                        ammo_settings[index] = arg.to_string();
                                    }
                                }
                            }
                        }
                    }
                    '+' => {}
                    _ => (),
                }
            }
        }

        game_flags.append(&mut scheme_properties);
        config.push(GameCfg::Scheme("ADHOG_SCHEME".to_string(), game_flags));
        config.push(GameCfg::Ammo(
            "ADHOG_AMMO".to_string(),
            Some(ammo_settings.concat()),
        ));

        Ok(Demo {
            teams,
            config,
            messages,
        })
    }
}

fn replay_to_haskell(mut replay: Replay) -> HaskellValue {
    use HaskellValue as Hs;

    let mut teams = Vec::with_capacity(replay.teams.len());
    for team in replay.teams {
        let mut fields = HashMap::<String, HaskellValue>::new();

        fields.insert("teamowner".to_string(), Hs::String(team.owner));
        fields.insert("teamname".to_string(), Hs::String(team.name));
        fields.insert("teamcolor".to_string(), Hs::Number(team.color));
        fields.insert("teamgrave".to_string(), Hs::String(team.grave));
        fields.insert("teamvoicepack".to_string(), Hs::String(team.voice_pack));
        fields.insert("teamflag".to_string(), Hs::String(team.flag));
        fields.insert("difficulty".to_string(), Hs::Number(team.difficulty));
        fields.insert("hhnum".to_string(), Hs::Number(team.hedgehogs_number));

        let hogs = team
            .hedgehogs
            .iter()
            .map(|hog| Hs::AnonStruct {
                name: "HedgehogInfo".to_string(),
                fields: vec![Hs::String(hog.name.clone()), Hs::String(hog.hat.clone())],
            })
            .collect();

        fields.insert("hedgehogs".to_string(), Hs::List(hogs));

        teams.push(Hs::Struct {
            name: "TeamInfo".to_string(),
            fields,
        })
    }

    let mut map_config = vec![];
    let mut game_config = vec![];

    let mut save_map_config = |name: &str, value: String| {
        map_config.push(Hs::Tuple(vec![
            Hs::String(name.to_string()),
            Hs::String(value),
        ]));
    };

    let config = replay.config;

    save_map_config("FEATURE_SIZE", config.feature_size.to_string());
    save_map_config("MAP", config.map_type);
    save_map_config("MAPGEN", config.map_generator.to_string());
    save_map_config("MAZE_SIZE", config.maze_size.to_string());
    save_map_config("SEED", config.seed);
    save_map_config("TEMPLATE", config.template.to_string());
    if let Some(drawn_map) = config.drawn_map {
        save_map_config("DRAWNMAP", drawn_map);
    }

    let mut save_game_config = |name: &str, mut value: Vec<String>| {
        game_config.push(Hs::Tuple(vec![
            Hs::String(name.to_string()),
            Hs::List(value.drain(..).map(Hs::String).collect()),
        ]));
    };

    match config.ammo {
        Ammo {
            name,
            settings: Some(settings),
        } => save_game_config("AMMO", vec![name, settings.clone()]),
        Ammo { name, .. } => save_game_config("AMMO", vec![name.clone()]),
    }

    match config.scheme {
        Scheme { name, settings } => {
            let mut values = vec![name];
            values.extend_from_slice(&settings);
            save_game_config("SCHEME", values);
        }
    }

    save_game_config("SCRIPT", vec![config.script]);
    save_game_config("THEME", vec![config.theme]);

    Hs::Tuple(vec![
        Hs::List(teams),
        Hs::List(map_config),
        Hs::List(game_config),
        Hs::List(replay.message_log.drain(..).map(Hs::String).collect()),
    ])
}

fn haskell_to_replay(value: HaskellValue) -> Option<Replay> {
    use HaskellValue::*;
    let mut config = RoomConfig::new();
    let mut lists = value.into_tuple()?;
    let mut lists_iter = lists.drain(..);

    let teams_list = lists_iter.next()?.into_list()?;
    let map_config = lists_iter.next()?.into_list()?;
    let game_config = lists_iter.next()?.into_list()?;
    let engine_messages = lists_iter.next()?.into_list()?;

    let mut teams = Vec::with_capacity(teams_list.len());

    for team in teams_list {
        let (_, mut fields) = team.into_struct()?;

        let mut team_info = TeamInfo::default();
        for (name, value) in fields.drain() {
            match &name[..] {
                "teamowner" => team_info.owner = value.into_string()?,
                "teamname" => team_info.name = value.into_string()?,
                "teamcolor" => team_info.color = u8::from_str(&value.into_string()?).ok()?,
                "teamgrave" => team_info.grave = value.into_string()?,
                "teamfort" => team_info.fort = value.into_string()?,
                "teamvoicepack" => team_info.voice_pack = value.into_string()?,
                "teamflag" => team_info.flag = value.into_string()?,
                "difficulty" => team_info.difficulty = value.into_number()?,
                "hhnum" => team_info.hedgehogs_number = value.into_number()?,
                "hedgehogs" => {
                    for (index, hog) in value
                        .into_list()?
                        .drain(..)
                        .enumerate()
                        .take(team_info.hedgehogs.len())
                    {
                        let (_, mut fields) = hog.into_anon_struct()?;
                        let mut fields_iter = fields.drain(..);
                        team_info.hedgehogs[index] = HedgehogInfo {
                            name: fields_iter.next()?.into_string()?,
                            hat: fields_iter.next()?.into_string()?,
                        }
                    }
                }
                _ => (),
            }
        }
        teams.push(team_info)
    }

    for item in map_config {
        let mut tuple = item.into_tuple()?;
        let mut tuple_iter = tuple.drain(..);
        let name = tuple_iter.next()?.into_string()?;
        let value = tuple_iter.next()?.into_string()?;

        match &name[..] {
            "FEATURE_SIZE" => config.feature_size = u32::from_str(&value).ok()?,
            "MAP" => config.map_type = value,
            "MAPGEN" => config.map_generator = u32::from_str(&value).ok()?,
            "MAZE_SIZE" => config.maze_size = u32::from_str(&value).ok()?,
            "SEED" => config.seed = value,
            "TEMPLATE" => config.template = u32::from_str(&value).ok()?,
            "DRAWNMAP" => config.drawn_map = Some(value),
            _ => {}
        };
    }

    for item in game_config {
        let mut tuple = item.into_tuple()?;
        let mut tuple_iter = tuple.drain(..);
        let name = tuple_iter.next()?.into_string()?;
        let mut value = tuple_iter.next()?.into_list()?;
        let mut value_iter = value.drain(..);

        let config_item = match &name[..] {
            "AMMO" => {
                config.ammo = Ammo {
                    name: value_iter.next()?.into_string()?,
                    settings: value_iter.next().and_then(|v| v.into_string()),
                }
            }
            "SCHEME" => {
                config.scheme = Scheme {
                    name: value_iter.next()?.into_string()?,
                    settings: value_iter.filter_map(|v| v.into_string()).collect(),
                }
            }
            "SCRIPT" => config.script = value_iter.next()?.into_string()?,
            "THEME" => config.theme = value_iter.next()?.into_string()?,
            _ => None?,
        };
    }

    let mut messages = Vec::with_capacity(engine_messages.len());

    for message in engine_messages {
        messages.push(message.into_string()?);
    }

    Some(Replay {
        config,
        teams,
        message_log: messages,
    })
}

impl Replay {
    pub fn save(self, filename: String) -> io::Result<()> {
        let text = format!("{}", replay_to_haskell(self));
        let mut file = fs::File::open(filename)?;
        file.write(text.as_bytes())?;
        Ok(())
    }

    pub fn load(filename: &str) -> io::Result<Self> {
        let mut file = fs::File::open(filename)?;
        let mut bytes = vec![];
        file.read_to_end(&mut bytes)?;
        match super::haskell::parse(&bytes[..]) {
            Ok((_, value)) => haskell_to_replay(value).ok_or(io::Error::new(
                io::ErrorKind::InvalidData,
                "Invalid replay structure",
            )),
            Err(_) => Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "Unable to parse file",
            )),
        }
    }
}
