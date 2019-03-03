use std::io::Read;
use std::path::Path;

use physfs::{ PhysFSContext, file };

#[test]
fn read_file_from_directory() {
    let con = match PhysFSContext::new() {
        Err(e) => panic!(e),
        Ok(con) => con
    };

    assert!(PhysFSContext::is_init());

    match con.mount(&Path::new(super::PATH_TO_HERE), "/test/".to_string(), true) {
        Err(e) => panic!(e),
        _ => ()
    }

    let mut file = match file::File::open(&con, "/test/directory/read.txt".to_string(), file::Mode::Read) {
        Ok(f) => f,
        Err(e) => panic!(e)
    };

    let buf = &mut [0; 32];

    match file.read(buf) {
        Err(e) => panic!(e),
        _ => ()
    }

    let mut contents = String::new();
    for &mut byte in buf {
        if byte == 0 { break }
        contents.push(byte as char);
    }

    assert!(contents == "Read from me.");
}

