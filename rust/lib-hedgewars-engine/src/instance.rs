use hedgewars_engine_messages::messages::{
    ConfigEngineMessage::*, EngineMessage::*, KeystrokeAction::*, SyncedEngineMessage::*,
    UnorderedEngineMessage::*, UnsyncedEngineMessage::*, *
};

use super::{ipc::IPC, world::World};

#[repr(C)]
pub struct EngineInstance {
    pub world: World,
    pub ipc: IPC,
}

impl EngineInstance {
    pub fn new() -> Self {
        let world = World::new();
        Self {
            world,
            ipc: IPC::new(),
        }
    }

    pub fn render<R, C>(
        &self,
        context: &mut gfx::Encoder<R, C>,
        target: &gfx::handle::RenderTargetView<R, gfx::format::Rgba8>,
    ) where
        R: gfx::Resources,
        C: gfx::CommandBuffer<R>,
    {
        context.clear(target, [0.0, 0.5, 0.0, 1.0]);
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
                Empty => println!("Empty message") ,
                Synced(_, _) => unimplemented!(),
                Unsynced(_) => unimplemented!(),
                Unordered(unordered_message) => self.process_unordered_message(&unordered_message),
                Config(config_message) => self.process_config_message(&config_message)
            }
        }
    }
}
