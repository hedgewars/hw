#[macro_use]
extern crate log;
extern crate argparse;
extern crate base64;
extern crate dirs;
extern crate ini;
extern crate netbuf;
extern crate stderrlog;
extern crate tempfile;

use argparse::{ArgumentParser, Store};
use ini::Ini;
use netbuf::Buf;
use std::io::Write;
use std::net::TcpStream;
use std::process::Command;
use std::str::FromStr;

type CheckError = Box<std::error::Error>;

fn extract_packet(buf: &mut Buf) -> Option<netbuf::Buf> {
    let packet_end = (&buf[..]).windows(2).position(|window| window == b"\n\n")?;

    let mut tail = buf.split_off(packet_end);

    std::mem::swap(&mut tail, buf);

    buf.consume(2);

    Some(tail)
}

fn check(executable: &str, data_prefix: &str, buffer: &[u8]) -> Result<Vec<Vec<u8>>, CheckError> {
    let mut replay = tempfile::NamedTempFile::new()?;

    for line in buffer.split(|b| *b == '\n' as u8) {
        replay.write(&base64::decode(line)?)?;
    }

    let temp_file_path = replay.path();

    let mut home_dir = dirs::home_dir().unwrap();
    home_dir.push(".hedgewars");

    debug!("Checking replay in {}", temp_file_path.to_string_lossy());

    let output = Command::new(executable)
        .arg("--user-prefix")
        .arg(&home_dir)
        .arg("--prefix")
        .arg(data_prefix)
        .arg("--nomusic")
        .arg("--nosound")
        .arg("--stats-only")
        .arg(temp_file_path)
        .output()?;

    let mut result = Vec::new();

    let mut engine_lines = output
        .stderr
        .split(|b| *b == '\n' as u8)
        .skip_while(|l| *l != b"WINNERS" && *l != b"DRAW");

    loop {
        match engine_lines.next() {
            Some(b"DRAW") => result.push(b"DRAW".to_vec()),
            Some(b"WINNERS") => {
                result.push(b"WINNERS".to_vec());
                let winners = engine_lines.next().unwrap();
                let winners_num = u32::from_str(&String::from_utf8(winners.to_vec())?)?;
                result.push(winners.to_vec());

                for _i in 0..winners_num {
                    result.push(engine_lines.next().unwrap().to_vec());
                }
            }
            Some(b"GHOST_POINTS") => {
                result.push(b"GHOST_POINTS".to_vec());
                let points = engine_lines.next().unwrap();
                let points_num = u32::from_str(&String::from_utf8(points.to_vec())?)? * 2;
                result.push(points.to_vec());

                for _i in 0..points_num {
                    result.push(engine_lines.next().unwrap().to_vec());
                }
            }
            Some(b"ACHIEVEMENT") => {
                result.push(b"ACHIEVEMENT".to_vec());
                for _i in 0..4 {
                    result.push(engine_lines.next().unwrap().to_vec());
                }
            }
            _ => break,
        }
    }

    if result.len() > 0 {
        Ok(result)
    } else {
        Err("no data from engine".into())
    }
}

fn connect_and_run(
    username: &str,
    password: &str,
    protocol_number: u32,
    executable: &str,
    data_prefix: &str,
) -> Result<(), CheckError> {
    info!("Connecting...");

    let mut stream = TcpStream::connect("hedgewars.org:46631")?;
    stream.set_nonblocking(false)?;

    let mut buf = Buf::new();

    loop {
        buf.read_from(&mut stream)?;

        while let Some(msg) = extract_packet(&mut buf) {
            if msg[..].starts_with(b"CONNECTED") {
                info!("Connected");
                let p = format!(
                    "CHECKER\n{}\n{}\n{}\n\n",
                    protocol_number, username, password
                );
                stream.write(p.as_bytes())?;
            } else if msg[..].starts_with(b"PING") {
                stream.write(b"PONG\n\n")?;
            } else if msg[..].starts_with(b"LOGONPASSED") {
                info!("Logged in");
                stream.write(b"READY\n\n")?;
            } else if msg[..].starts_with(b"REPLAY") {
                info!("Got a replay");
                match check(executable, data_prefix, &msg[7..]) {
                    Ok(result) => {
                        info!("Checked");
                        debug!(
                            "Check result: [{}]",
                            String::from_utf8_lossy(&result.join(&(',' as u8)))
                        );

                        stream.write(b"CHECKED\nOK\n")?;
                        stream.write(&result.join(&('\n' as u8)))?;
                        stream.write(b"\n\nREADY\n\n")?;
                    }
                    Err(e) => {
                        info!("Check failed: {:?}", e);
                        stream.write(b"CHECKED\nFAIL\nerror\n\nREADY\n\n")?;
                    }
                }
            } else if msg[..].starts_with(b"BYE") {
                warn!("Received BYE: {}", String::from_utf8_lossy(&msg[..]));
                return Ok(());
            } else if msg[..].starts_with(b"ERROR") {
                warn!("Received ERROR: {}", String::from_utf8_lossy(&msg[..]));
                return Ok(());
            } else {
                warn!(
                    "Unknown protocol command: {}",
                    String::from_utf8_lossy(&msg[..])
                )
            }
        }
    }
}

fn get_protocol_number(executable: &str) -> std::io::Result<u32> {
    let output = Command::new(executable).arg("--protocol").output()?;

    Ok(u32::from_str(&String::from_utf8(output.stdout).unwrap().as_str()).unwrap_or(55))
}

fn main() {
    stderrlog::new()
        .verbosity(3)
        .timestamp(stderrlog::Timestamp::Second)
        .module(module_path!())
        .init()
        .unwrap();

    let mut frontend_settings = dirs::home_dir().unwrap();
    frontend_settings.push(".hedgewars/settings.ini");

    let i = Ini::load_from_file(frontend_settings.to_str().unwrap()).unwrap();
    let username = i.get_from(Some("net"), "nick").unwrap();
    let password = i.get_from(Some("net"), "passwordhash").unwrap();

    let mut exe = "/usr/local/bin/hwengine".to_string();
    let mut prefix = "/usr/local/share/hedgewars/Data".to_string();
    {
        let mut ap = ArgumentParser::new();
        ap.set_description("Game replay checker for hedgewars.");
        ap.refer(&mut exe)
            .add_option(&["--exe"], Store, "Path to hwengine executable");
        ap.refer(&mut prefix)
            .add_option(&["--prefix"], Store, "Path main Data dir");
        ap.parse_args_or_exit();
    }

    info!("Executable: {}", exe);
    info!("Data dir: {}", prefix);

    let protocol_number = get_protocol_number(&exe.as_str()).unwrap_or_default();

    info!("Using protocol number {}", protocol_number);

    connect_and_run(&username, &password, protocol_number, &exe, &prefix);
}

#[cfg(test)]
#[test]
fn test() {
    let mut buf = Buf::new();
    buf.extend(b"Hell");
    if let Some(_) = extract_packet(&mut buf) {
        assert!(false)
    }

    buf.extend(b"o\n\nWorld");

    let packet2 = extract_packet(&mut buf).unwrap();
    assert_eq!(&buf[..], b"World");
    assert_eq!(&packet2[..], b"Hello");

    if let Some(_) = extract_packet(&mut buf) {
        assert!(false)
    }
}
