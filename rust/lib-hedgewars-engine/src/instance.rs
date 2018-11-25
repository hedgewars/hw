use hedgewars_engine_messages::messages::{
    ConfigEngineMessage::*, EngineMessage::*, KeystrokeAction::*, SyncedEngineMessage::*,
    UnorderedEngineMessage::*, UnsyncedEngineMessage::*, *
};

use gfx::{
    format::{R8_G8_B8_A8, D24, Unorm}
};
use gfx_device_gl as gfx_gl;
use self::gfx_gl::{
    Resources,
    CommandBuffer
};

use super::{ipc::IPC, world::World};

pub struct EngineGlContext {
    pub device: gfx_gl::Device,
    pub factory: gfx_gl::Factory,
    pub render_target: gfx::handle::RenderTargetView<Resources, (R8_G8_B8_A8, Unorm)>,
    pub depth_buffer: gfx::handle::DepthStencilView<Resources, (D24, Unorm)>,
    pub command_buffer: gfx::Encoder<Resources, CommandBuffer>
}

pub struct EngineInstance {
    pub world: World,
    pub ipc: IPC,
    pub gl_context: Option<EngineGlContext>
}

impl EngineInstance {
    pub fn new() -> Self {
        let world = World::new();
        Self {
            world,
            ipc: IPC::new(),
            gl_context: None
        }
    }

    pub fn render<R, C>(
        &self,
        command_buffer: &mut gfx::Encoder<R, C>,
        render_target: &gfx::handle::RenderTargetView<R, gfx::format::Rgba8>,
    ) where
        R: gfx::Resources,
        C: gfx::CommandBuffer<R>,
    {
        command_buffer.clear(render_target, [0.0, 0.5, 0.0, 1.0]);
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
