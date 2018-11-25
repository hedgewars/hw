mod ipc;
mod world;
pub mod instance;

use std::{
    io::{Read, Write},
    ffi::{CString},
    os::raw::{c_void, c_char},
    mem::replace
};
use gfx::{
    Encoder,
    format::Formatted,
};

use gfx_device_gl as gfx_gl;

use self::instance::{
    EngineInstance,
    EngineGlContext
};

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
    let engine_state = Box::new(EngineInstance::new());

    Box::leak(engine_state)
}

#[no_mangle]
pub extern "C" fn generate_preview(engine_state: &mut EngineInstance, preview: &mut PreviewInfo) {
    (*engine_state).process_ipc_queue();

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
pub extern "C" fn send_ipc(engine_state: &mut EngineInstance, buf: *const u8, size: usize) {
    unsafe {
        (*engine_state).ipc.write(std::slice::from_raw_parts(buf, size)).unwrap();
    }
}

#[no_mangle]
pub extern "C" fn read_ipc(
    engine_state: &mut EngineInstance,
    buf: *mut u8,
    size: usize,
) -> usize {
    unsafe { (*engine_state).ipc.read(std::slice::from_raw_parts_mut(buf, size)).unwrap_or(0) }
}

#[no_mangle]
pub extern "C" fn setup_current_gl_context(
    engine_state: &mut EngineInstance,
    width: u16,
    height: u16,
    gl_loader: extern "C" fn (*const c_char) -> *const c_void
) {
    let (device, mut factory) = gfx_gl::create(|name| {
        let c_name = CString::new(name).unwrap();
        gl_loader(c_name.as_ptr())
    });

    let dimensions = (width, height, 1u16, gfx::texture::AaMode::Single);
    let (render_target, depth_buffer) = gfx_gl::create_main_targets_raw(
        dimensions,
        gfx::format::Rgba8::get_format().0,
        gfx::format::Depth::get_format().0
    );

    let mut command_buffer: Encoder<_, _> = factory.create_command_buffer().into();

    engine_state.gl_context = Some(EngineGlContext {
        device,
        factory,
        render_target: gfx::memory::Typed::new(render_target),
        depth_buffer: gfx::memory::Typed::new(depth_buffer),
        command_buffer
    })
}

#[no_mangle]
pub extern "C" fn render_frame(engine_state: &mut EngineInstance) {
    let mut context = replace(&mut engine_state.gl_context, None);
    if let Some(ref mut c) = context {
        engine_state.render(&mut c.command_buffer, &mut c.render_target)
    }
    replace(&mut engine_state.gl_context, context);
}

#[no_mangle]
pub extern "C" fn cleanup(engine_state: *mut EngineInstance) {
    unsafe {
        Box::from_raw(engine_state);
    }
}
