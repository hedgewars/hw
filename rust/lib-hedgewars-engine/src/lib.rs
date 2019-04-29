pub mod instance;
pub mod ipc;
mod render;
mod world;

use std::{
    ffi::CString,
    io::{Read, Write},
    mem::replace,
    os::raw::{c_char, c_void},
};

use integral_geometry::Point;

use self::instance::EngineInstance;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct PreviewInfo {
    width: u32,
    height: u32,
    hedgehogs_number: u8,
    land: *const u8,
}

#[repr(C)]
#[derive(Debug, PartialEq, Clone)]
pub enum SimpleEventType {
    SwitchHedgehog,
    Timer,
    LongJump,
    HighJump,
    Accept,
    Deny,
}

#[repr(C)]
#[derive(Debug, PartialEq, Clone)]
pub enum LongEventType {
    ArrowUp,
    ArrowDown,
    ArrowLeft,
    ArrowRight,
    Precision,
    Attack,
}

#[repr(C)]
#[derive(Debug, PartialEq, Clone)]
pub enum LongEventState {
    Set,
    Unset,
}

#[repr(C)]
#[derive(Debug, PartialEq, Clone)]
pub enum PositionedEventType {
    CursorMove,
    CursorClick,
}

#[no_mangle]
pub extern "C" fn simple_event(engine_state: &mut EngineInstance, event_type: SimpleEventType) {}

#[no_mangle]
pub extern "C" fn long_event(
    engine_state: &mut EngineInstance,
    event_type: LongEventType,
    state: LongEventState,
) {
    println!("{:?}: {:?}", event_type, state);
}

#[no_mangle]
pub extern "C" fn positioned_event(
    engine_state: &mut EngineInstance,
    event_type: PositionedEventType,
    x: i32,
    y: i32,
) {

}

#[no_mangle]
pub extern "C" fn hedgewars_engine_protocol_version() -> u32 {
    58
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

    if let Some(land_preview) = (*engine_state).world.preview() {
        *preview = PreviewInfo {
            width: land_preview.width() as u32,
            height: land_preview.height() as u32,
            hedgehogs_number: 0,
            land: land_preview.raw_pixels().as_ptr(),
        };
    }
}

#[no_mangle]
pub extern "C" fn dispose_preview(engine_state: &mut EngineInstance, preview: &mut PreviewInfo) {
    (*engine_state).world.dispose_preview();
}

#[no_mangle]
pub extern "C" fn send_ipc(engine_state: &mut EngineInstance, buf: *const u8, size: usize) {
    unsafe {
        (*engine_state)
            .ipc
            .write(std::slice::from_raw_parts(buf, size))
            .unwrap();
    }
}

#[no_mangle]
pub extern "C" fn read_ipc(engine_state: &mut EngineInstance, buf: *mut u8, size: usize) -> usize {
    unsafe {
        (*engine_state)
            .ipc
            .read(std::slice::from_raw_parts_mut(buf, size))
            .unwrap_or(0)
    }
}

#[no_mangle]
pub extern "C" fn setup_current_gl_context(
    engine_state: &mut EngineInstance,
    width: u16,
    height: u16,
    gl_loader: extern "C" fn(*const c_char) -> *const c_void,
) {
    gl::load_with(|name| {
        let c_name = CString::new(name).unwrap();
        gl_loader(c_name.as_ptr())
    });
    unsafe {
        gl::Viewport(0, 0, width as i32, height as i32);
    }
    engine_state.world.create_renderer(width, height);
}

#[no_mangle]
pub extern "C" fn render_frame(engine_state: &mut EngineInstance) {
    engine_state.render()
}

#[no_mangle]
pub extern "C" fn advance_simulation(engine_state: &mut EngineInstance, ticks: u32) -> bool {
    engine_state.world.step();
    true
}

#[no_mangle]
pub extern "C" fn move_camera(engine_state: &mut EngineInstance, delta_x: i32, delta_y: i32) {
    engine_state
        .world
        .move_camera(Point::new(delta_x, delta_y), 0.0);
}

#[no_mangle]
pub extern "C" fn cleanup(engine_state: *mut EngineInstance) {
    unsafe {
        Box::from_raw(engine_state);
    }
}
