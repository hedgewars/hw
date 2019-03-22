use hedgewars_engine_messages::messages::{
    ConfigEngineMessage::*, EngineMessage::*, KeystrokeAction::*, SyncedEngineMessage::*,
    UnorderedEngineMessage::*, UnsyncedEngineMessage::*, *,
};

use landgen::outline_template::OutlineTemplate;
use integral_geometry::{Point, Rect, Size};

use super::{ipc::IPC, world::World};

pub struct EngineInstance {
    pub world: World,
    pub ipc: IPC,
}

impl EngineInstance {
    pub fn new() -> Self {
        let mut world = World::new();

        fn template() -> OutlineTemplate {
            let mut template = OutlineTemplate::new(Size::new(4096*1, 2048*1));
            template.islands = vec![vec![
                Rect::from_size_coords(100, 2050, 1, 1),
                Rect::from_size_coords(100, 500, 400, 1200),
                Rect::from_size_coords(3600, 500, 400, 1200),
                Rect::from_size_coords(3900, 2050, 1, 1),
            ]];
            template.fill_points = vec![Point::new(1, 0)];

            template
        }
        
        world.init(template());
        
        Self {
            world,
            ipc: IPC::new(),
        }
    }

    pub fn render(&mut self) {
        self.world.render();
    }

    fn process_unordered_message(&mut self, message: &UnorderedEngineMessage) {
        match message {
            Pong => println!("Pong!"),
            _ => unimplemented!(),
        }
    }

    fn process_config_message(&mut self, message: &ConfigEngineMessage) {
        match message {
            SetSeed(seed) => self.world.set_seed(seed.as_bytes()),
            _ => unimplemented!(),
        }
    }

    pub fn process_ipc_queue(&mut self) {
        let messages: Vec<EngineMessage> = self.ipc.iter().collect();

        for message in messages {
            println!("Processing message: {:?}", message);
            match message {
                Unknown => println!("Unknown message"),
                Empty => println!("Empty message"),
                Synced(_, _) => unimplemented!(),
                Unsynced(_) => unimplemented!(),
                Unordered(unordered_message) => self.process_unordered_message(&unordered_message),
                Config(config_message) => self.process_config_message(&config_message),
            }
        }
    }
}
