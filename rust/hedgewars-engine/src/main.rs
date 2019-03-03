extern crate libloading;

use libloading::{Library, Symbol};
use std::ops::Deref;

struct EngineInstance {}

struct Engine<'a> {
    protocol_version: Symbol<'a, unsafe fn() -> u32>,
    start_engine: Symbol<'a, unsafe fn() -> *mut EngineInstance>,
    cleanup: Symbol<'a, unsafe fn(engine_state: *mut EngineInstance)>,
}

fn main() {
    let hwlib = Library::new("libhedgewars_engine.so").unwrap();

    unsafe {
        let engine = Engine {
            protocol_version: hwlib.get(b"protocol_version").unwrap(),
            start_engine: hwlib.get(b"start_engine").unwrap(),
            cleanup: hwlib.get(b"cleanup").unwrap(),
        };

        println!("Hedgewars engine, protocol version {}", engine.protocol_version.deref()());
    }
}
