extern crate libloading;

use libloading::{Library, Symbol};
use std::ops::Deref;
use std::cmp::{min,max};
use std::env;
use getopts::Options;
use std::io::prelude::*;
use std::io::{self, Read};
use std::net::{Shutdown, TcpStream};

struct EngineInstance {}

struct Engine<'a> {
    protocol_version: Symbol<'a, unsafe fn() -> u32>,
    start_engine: Symbol<'a, unsafe fn() -> *mut EngineInstance>,
    generate_preview: Symbol<'a, unsafe fn(engine_state: &mut EngineInstance, preview: &mut PreviewInfo)>,
    dispose_preview: Symbol<'a, unsafe fn(engine_state: &mut EngineInstance, preview: &mut PreviewInfo)>,
    cleanup: Symbol<'a, unsafe fn(engine_state: *mut EngineInstance)>,
    send_ipc: Symbol<'a, unsafe fn(engine_state: &mut EngineInstance, buf: *const u8, size: usize)>,
    read_ipc: Symbol<'a, unsafe fn(engine_state: &mut EngineInstance, buf: *mut u8, size: usize) -> usize>,
}

#[repr(C)]
#[derive(Copy, Clone)]
struct PreviewInfo {
  width: u32,
  height: u32,
  hedgehogs_number: u8,
  land: *const u8,
}

const PREVIEW_WIDTH: u32 = 256;
const PREVIEW_HEIGHT: u32 = 128;
const PREVIEW_NPIXELS: usize = (PREVIEW_WIDTH * PREVIEW_HEIGHT) as usize;
const SCALE_FACTOR: u32 = 16;
const VALUE_PER_INPIXEL: u8 = 1;

fn resize_mono_preview(mono_pixels: &[u8], in_width: u32, in_height: u32, preview_pixels: &mut [u8]) {

    assert!(mono_pixels.len() == (in_width * in_height) as usize);

    let v_offset: u32 = max(0, PREVIEW_HEIGHT as i64 - (in_height / SCALE_FACTOR) as i64) as u32;
    let h_offset: u32 = max(0, (PREVIEW_WIDTH as i64 / 2) - (in_width / SCALE_FACTOR / 2) as i64) as u32;

    for y in v_offset..PREVIEW_HEIGHT {

        let in_y = v_offset + (y * SCALE_FACTOR);

        for x in h_offset..(PREVIEW_WIDTH - h_offset) {

            let in_x = h_offset + (x * SCALE_FACTOR);

            let out_px_address = (PREVIEW_WIDTH * y + x) as usize;

            let mut in_px_address = (in_width * in_y + in_x) as usize;

            let mut value = 0;

            for i in 0..SCALE_FACTOR as usize {
                for j in 0..SCALE_FACTOR as usize {
                    if (value < 0xff) && (mono_pixels[in_px_address + j] != 0) {
                        value += VALUE_PER_INPIXEL;
                    }
                }
                in_px_address += in_width as usize;
            }

            preview_pixels[out_px_address] = value;
        }
    }
}

fn main() {
    let hwlib = Library::new("libhedgewars_engine.so").unwrap();

    unsafe {
        let engine = Engine {
            protocol_version: hwlib.get(b"hedgewars_engine_protocol_version").unwrap(),
            start_engine: hwlib.get(b"start_engine").unwrap(),
            generate_preview: hwlib.get(b"generate_preview").unwrap(),
            dispose_preview: hwlib.get(b"dispose_preview").unwrap(),
            cleanup: hwlib.get(b"cleanup").unwrap(),
            send_ipc: hwlib.get(b"send_ipc").unwrap(),
            read_ipc: hwlib.get(b"read_ipc").unwrap(),
        };

        println!("Hedgewars engine, protocol version {}", engine.protocol_version.deref()());

        let args: Vec<String> = env::args().collect();

        let mut opts = getopts::Options::new();
        opts.optflag("", "internal", "[internal]");
        opts.optflag("", "landpreview", "[internal]");
        opts.optflag("", "recorder", "[internal]");
        opts.optopt("", "port", "[internal]", "PORT");
        opts.optopt("", "user-prefix", "Set the path to the custom data folder to find game content", "PATH_TO_FOLDER");
        opts.optopt("", "prefix", "Set the path to the system game data folder", "PATH_TO_FOLDER");

        let matches = match opts.parse(&args[1..]) {
            Ok(m) => { m }
            Err(f) => { panic!(f.to_string()) }
        };

        let engine_state = &mut *engine.start_engine.deref()();

        let port: String = matches.opt_str("port").unwrap();

        println!("PORT: {}", port);

        if matches.opt_present("landpreview") {

            let mut stream = TcpStream::connect(format!("127.0.0.1:{}", port)).expect("Failed to connect to IPC port. Feelsbadman.");

            //stream.write(b"\x01C").unwrap(); // config
            //stream.write(b"\x01?").unwrap(); // ping

            let mut buf = [0;1];
            loop {
                let bytes_read = stream.read(&mut buf).unwrap();
                if bytes_read == 0 {
                    break;
                }
                engine.send_ipc.deref()(engine_state, &buf[0], buf.len());
                // this looks like length 1 is being announced
                if buf[0] == 1 {
                    let bytes_read = stream.read(&mut buf).unwrap();
                    if bytes_read == 0 {
                        break;
                    }
                    if buf[0] == 33 {
                        println!("Ping? Pong!");
                        break;
                    }
                }
            };

            let preview_info = &mut PreviewInfo {
                width: 0,
                height: 0,
                hedgehogs_number: 0,
                land: std::ptr::null(),
            };

            println!("Generating preview...");

            engine.generate_preview.deref()(engine_state, preview_info);

            //println!("Preview: w = {}, h = {}, n = {}", preview_info.width, preview_info.height, preview_info.hedgehogs_number);

            let land_size: usize = (preview_info.width * preview_info.height) as usize;

            let land_array: &[u8] = std::slice::from_raw_parts(preview_info.land, land_size);

            const PREVIEW_WIDTH: u32 = 256;
            const PREVIEW_HEIGHT: u32 = 128;

            println!("Resizing preview...");

            let preview_image: &mut [u8] = &mut [0; PREVIEW_NPIXELS];
            resize_mono_preview(land_array, preview_info.width, preview_info.height, preview_image);

            println!("Sending preview...");

            stream.write(preview_image).unwrap();
            stream.flush().unwrap();
            stream.write(&[preview_info.hedgehogs_number]).unwrap();
            stream.flush().unwrap();

            println!("Preview sent, disconnect");

            stream.shutdown(Shutdown::Both).expect("IPC shutdown call failed");

            engine.dispose_preview.deref()(engine_state, preview_info);
        }

        engine.cleanup.deref()(engine_state);
    }
}
