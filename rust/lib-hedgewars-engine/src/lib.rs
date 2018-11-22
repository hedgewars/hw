mod ipc;
mod world;
mod instance;

use std::io::{Read, Write};

use self::instance::EngineInstance;

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
pub extern "C" fn cleanup(engine_state: *mut EngineInstance) {
    unsafe {
        Box::from_raw(engine_state);
    }
}
