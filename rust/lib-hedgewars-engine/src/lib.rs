mod world;
mod ipc;

#[repr(C)]
pub struct EngineInstance {
    world: world::World,
}

impl EngineInstance {
    pub fn new() -> Self {
        let world = world::World::new();
        Self { world }
    }

    pub fn render<R, C>(
        &self,
        context: &mut gfx::Encoder<R, C>,
        target: &gfx::handle::RenderTargetView<R, gfx::format::Rgba8>)
        where R: gfx::Resources,
              C: gfx::CommandBuffer<R>
    {
        context.clear(target, [0.0, 0.5, 0.0, 1.0]);
    }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct PreviewInfo {
    width: u32,
    height: u32,
    hedgehogs_number: u8,
    land: *const u8,
}

#[no_mangle]
pub extern "C" fn protocol_version() -> u32 {
    56
}

#[no_mangle]
pub extern "C" fn start_engine() -> *mut EngineInstance {
    let engine_state = Box::new(EngineInstance {
        world: world::World::new(),
    });

    Box::leak(engine_state)
}

#[no_mangle]
pub extern "C" fn generate_preview(engine_state: &mut EngineInstance, preview: &mut PreviewInfo) {
    (*engine_state).world.generate_preview();

    let land_preview = (*engine_state).world.preview();

    *preview = PreviewInfo {
        width: land_preview.width() as u32,
        height: land_preview.height() as u32,
        hedgehogs_number: 0,
        land: land_preview.raw_pixels().as_ptr(),
    };
}

#[no_mangle]
pub extern "C" fn cleanup(engine_state: *mut EngineInstance) {
    unsafe {
        Box::from_raw(engine_state);
    }
}
