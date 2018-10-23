#[macro_use]
extern crate log;
extern crate argparse;
extern crate dirs;
extern crate ini;
extern crate netbuf;
extern crate stderrlog;

use argparse::{ArgumentParser, Store};
use ini::Ini;
use netbuf::Buf;
use std::io::{Result, Write};
use std::net::TcpStream;
use std::process::Command;
use std::str::FromStr;

fn extract_packet(buf: &mut Buf) -> Option<netbuf::Buf> {
    let packet_end = (&buf[..]).windows(2).position(|window| window == b"\n\n")?;

    let mut tail = buf.split_off(packet_end);

    std::mem::swap(&mut tail, buf);

    buf.consume(2);

    Some(tail)
}

fn connect_and_run(
    username: &str,
    password: &str,
    protocol_number: u32,
    executable: &str,
    data_prefix: &str,
) -> Result<()> {
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
            } else if msg[..].starts_with(b"BYE") {
                warn!("Received BYE: {}", String::from_utf8_lossy(&msg[..]));
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

fn get_protocol_number(executable: &str) -> Result<u32> {
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
