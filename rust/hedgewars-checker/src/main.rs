use anyhow::{bail, Result};
use argparse::{ArgumentParser, Store};
use hedgewars_network_protocol::{
    messages::HwProtocolMessage as ClientMessage, messages::HwServerMessage::*, parser,
};
use ini::Ini;
use log::{debug, info, warn};
use netbuf::Buf;
use std::{io::Write, net::TcpStream, process::Command, str::FromStr};

fn check(executable: &str, data_prefix: &str, buffer: &[String]) -> Result<Vec<String>> {
    let mut replay = tempfile::NamedTempFile::new()?;

    for line in buffer.into_iter() {
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
            Some(b"DRAW") => result.push("DRAW".to_owned()),
            Some(b"WINNERS") => {
                result.push("WINNERS".to_owned());
                let winners = engine_lines.next().unwrap();
                let winners_num = u32::from_str(&String::from_utf8(winners.to_vec())?)?;
                result.push(String::from_utf8(winners.to_vec())?);

                for _i in 0..winners_num {
                    result.push(String::from_utf8(engine_lines.next().unwrap().to_vec())?);
                }
            }
            Some(b"GHOST_POINTS") => {
                result.push("GHOST_POINTS".to_owned());
                let points = engine_lines.next().unwrap();
                let points_num = u32::from_str(&String::from_utf8(points.to_vec())?)? * 2;
                result.push(String::from_utf8(points.to_vec())?);

                for _i in 0..points_num {
                    result.push(String::from_utf8(engine_lines.next().unwrap().to_vec())?);
                }
            }
            Some(b"ACHIEVEMENT") => {
                result.push("ACHIEVEMENT".to_owned());
                for _i in 0..4 {
                    result.push(String::from_utf8(engine_lines.next().unwrap().to_vec())?);
                }
            }
            _ => break,
        }
    }

    if result.len() > 0 {
        Ok(result)
    } else {
        bail!("no data from engine")
    }
}

fn connect_and_run(
    username: &str,
    password: &str,
    protocol_number: u16,
    executable: &str,
    data_prefix: &str,
) -> Result<()> {
    info!("Connecting...");

    let mut stream = TcpStream::connect("hedgewars.org:46631")?;
    stream.set_nonblocking(false)?;

    let mut buf = Buf::new();

    loop {
        buf.read_from(&mut stream)?;

        while let Ok((tail, msg)) = parser::server_message(buf.as_ref()) {
            let tail_len = tail.len();
            buf.consume(buf.len() - tail_len);

            match msg {
                Connected(_, _) => {
                    info!("Connected");
                    stream.write(
                        ClientMessage::Checker(
                            protocol_number,
                            username.to_owned(),
                            password.to_owned(),
                        )
                        .to_raw_protocol()
                        .as_bytes(),
                    )?;
                }
                Ping => {
                    stream.write(ClientMessage::Pong.to_raw_protocol().as_bytes())?;
                }
                LogonPassed => {
                    stream.write(ClientMessage::CheckerReady.to_raw_protocol().as_bytes())?;
                }
                Replay(lines) => {
                    info!("Got a replay");
                    match check(executable, data_prefix, &lines) {
                        Ok(result) => {
                            info!("Checked");
                            debug!("Check result: [{:?}]", result);

                            stream.write(
                                ClientMessage::CheckedOk(result)
                                    .to_raw_protocol()
                                    .as_bytes(),
                            )?;
                            stream
                                .write(ClientMessage::CheckerReady.to_raw_protocol().as_bytes())?;
                        }
                        Err(e) => {
                            info!("Check failed: {:?}", e);
                            stream.write(
                                ClientMessage::CheckedFail("error".to_owned())
                                    .to_raw_protocol()
                                    .as_bytes(),
                            )?;
                            stream
                                .write(ClientMessage::CheckerReady.to_raw_protocol().as_bytes())?;
                        }
                    }
                }
                Bye(message) => {
                    warn!("Received BYE: {}", message);
                    return Ok(());
                }
                ChatMsg { nick, msg } => {
                    info!("Chat [{}]: {}", nick, msg);
                }
                RoomAdd(fields) => {
                    let l = fields.into_iter();
                    info!("Room added: {}", l.skip(1).next().unwrap());
                }
                RoomUpdated(name, fields) => {
                    let l = fields.into_iter();
                    let new_name = l.skip(1).next().unwrap();

                    if name != new_name {
                        info!("Room renamed: {}", new_name);
                    }
                }
                RoomRemove(_) => {
                    // ignore
                }
                Error(message) => {
                    warn!("Received ERROR: {}", message);
                    return Ok(());
                }
                something => {
                    warn!("Unexpected protocol command: {:?}", something)
                }
            }
        }
    }
}

fn get_protocol_number(executable: &str) -> std::io::Result<u16> {
    let output = Command::new(executable).arg("--protocol").output()?;

    Ok(u16::from_str(&String::from_utf8(output.stdout).unwrap().trim()).unwrap_or(55))
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

    connect_and_run(&username, &password, protocol_number, &exe, &prefix).unwrap();
}
