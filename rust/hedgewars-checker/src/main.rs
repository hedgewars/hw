use anyhow::{anyhow, bail, Result};
use argparse::{ArgumentParser, Store};
use base64::{engine::general_purpose, Engine};
use hedgewars_network_protocol::{
    messages::HwProtocolMessage as ClientMessage, messages::HwServerMessage::*, parser,
};
use ini::Ini;
use log::{debug, info, warn};
use netbuf::Buf;
use std::{io::Write, str::FromStr};
use tokio::time::MissedTickBehavior;
use tokio::{io, io::AsyncWriteExt, net::TcpStream, process::Command, sync::mpsc};

async fn check(executable: &str, data_prefix: &str, buffer: &[String]) -> Result<Vec<String>> {
    let mut replay = tempfile::NamedTempFile::new()?;

    for line in buffer.iter() {
        replay.write_all(&general_purpose::STANDARD.decode(line)?)?;
    }

    let temp_file_path = replay.path();

    let mut home_dir = dirs::home_dir().ok_or(anyhow!("Home path not detected"))?;
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
        //.spawn()?
        //.wait_with_output()
        .output()
        .await?;

    debug!("Engine finished!");

    let mut result = Vec::new();

    let mut engine_lines = output
        .stderr
        .split(|b| *b == b'\n')
        .skip_while(|l| *l != b"WINNERS" && *l != b"DRAW");

    // debug!("Engine lines: {:?}", &engine_lines);

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

    // println!("Engine lines: {:?}", &result);

    if !result.is_empty() {
        Ok(result)
    } else {
        bail!("no data from engine")
    }
}

async fn check_loop(
    executable: &str,
    data_prefix: &str,
    results_sender: mpsc::Sender<Result<Vec<String>>>,
    mut replay_receiver: mpsc::Receiver<Vec<String>>,
) -> Result<()> {
    while let Some(replay) = replay_receiver.recv().await {
        results_sender
            .send(check(executable, data_prefix, &replay).await)
            .await?;
    }

    Ok(())
}

async fn connect_and_run(
    username: &str,
    password: &str,
    protocol_number: u16,
    replay_sender: mpsc::Sender<Vec<String>>,
    mut results_receiver: mpsc::Receiver<Result<Vec<String>>>,
) -> Result<()> {
    info!("Connecting...");

    let mut stream = TcpStream::connect("hedgewars.org:46631").await?;

    let mut buf = Buf::new();

    let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(30));
    interval.set_missed_tick_behavior(MissedTickBehavior::Delay);

    loop {
        let r = tokio::select! {
            _ = interval.tick() => {
                // Send Ping
                stream.write_all(ClientMessage::Ping.to_raw_protocol().as_bytes()).await?;
                None
            },
            _ = stream.readable() => None,
            r = results_receiver.recv() => r
        };

        //println!("Loop: {:?}", &r);

        if let Some(execution_result) = r {
            match execution_result {
                Ok(result) => {
                    info!("Checked");
                    debug!("Check result: [{:?}]", result);

                    stream
                        .write_all(
                            ClientMessage::CheckedOk(result)
                                .to_raw_protocol()
                                .as_bytes(),
                        )
                        .await?;
                    stream
                        .write_all(ClientMessage::CheckerReady.to_raw_protocol().as_bytes())
                        .await?;
                }
                Err(e) => {
                    info!("Check failed: {:?}", e);
                    stream
                        .write_all(
                            ClientMessage::CheckedFail("error".to_owned())
                                .to_raw_protocol()
                                .as_bytes(),
                        )
                        .await?;
                    stream
                        .write_all(ClientMessage::CheckerReady.to_raw_protocol().as_bytes())
                        .await?;
                }
            }
        } else {
            let mut msg = [0; 4096];
            // Try to read data, this may still fail with `WouldBlock`
            // if the readiness event is a false positive.
            match stream.try_read(&mut msg) {
                Ok(n) => {
                    //println!("{:?}", &msg);
                    buf.write_all(&msg[0..n])?;
                }
                Err(ref e) if e.kind() == io::ErrorKind::WouldBlock => {}
                Err(e) => {
                    return Err(e.into());
                }
            }
        }

        while let Ok((tail, msg)) = parser::server_message(buf.as_ref()) {
            let tail_len = tail.len();
            buf.consume(buf.len() - tail_len);

            // println!("Message from server: {:?}", &msg);

            match msg {
                Connected(_, _) => {
                    info!("Connected");
                    stream
                        .write_all(
                            ClientMessage::Checker(
                                protocol_number,
                                username.to_owned(),
                                password.to_owned(),
                            )
                            .to_raw_protocol()
                            .as_bytes(),
                        )
                        .await?;
                }
                Ping => {
                    stream
                        .write_all(ClientMessage::Pong.to_raw_protocol().as_bytes())
                        .await?;
                }
                Pong => {
                    // do nothing
                }
                LogonPassed => {
                    stream
                        .write_all(ClientMessage::CheckerReady.to_raw_protocol().as_bytes())
                        .await?;
                }
                Replay(lines) => {
                    info!("Got a replay");
                    replay_sender.send(lines).await?;
                }
                Bye(message) => {
                    warn!("Received BYE: {}", message);
                    return Ok(());
                }
                ChatMsg { nick, msg } => {
                    info!("Chat [{}]: {}", nick, msg);
                }
                RoomAdd(fields) => {
                    let mut l = fields.into_iter();
                    info!("Room added: {}", l.nth(1).unwrap());
                }
                RoomUpdated(name, fields) => {
                    let mut l = fields.into_iter();
                    let new_name = l.nth(1).unwrap();

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

async fn get_protocol_number(executable: &str) -> Result<u16> {
    let output = Command::new(executable).arg("--protocol").output().await?;

    Ok(u16::from_str(String::from_utf8(output.stdout)?.trim()).unwrap_or(55))
}

#[tokio::main]
async fn main() -> Result<()> {
    stderrlog::new()
        .verbosity(3)
        .timestamp(stderrlog::Timestamp::Second)
        .module(module_path!())
        .init()?;

    let mut frontend_settings = dirs::home_dir().ok_or(anyhow!("Home path not detected"))?;
    frontend_settings.push(".hedgewars/settings.ini");

    let i = Ini::load_from_file(frontend_settings.to_str().unwrap()).unwrap();
    let username = i
        .get_from(Some("net"), "nick")
        .ok_or(anyhow!("Nickname not found in frontend config"))?;
    let password = i
        .get_from(Some("net"), "passwordhash")
        .ok_or(anyhow!("Password not found in frontend config"))?;

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

    let protocol_number = get_protocol_number(exe.as_str()).await?;

    info!("Using protocol number {}", protocol_number);

    let (replay_sender, replay_receiver) = mpsc::channel(1);
    let (results_sender, results_receiver) = mpsc::channel(1);

    let (network_result, checker_result) = tokio::join!(
        connect_and_run(
            username,
            password,
            protocol_number,
            replay_sender,
            results_receiver
        ),
        check_loop(&exe, &prefix, results_sender, replay_receiver)
    );

    network_result?;
    checker_result
}
