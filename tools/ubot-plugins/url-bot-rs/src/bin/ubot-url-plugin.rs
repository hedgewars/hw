use url_bot_rs::config::Rtd;
use url_bot_rs::VERSION;
use url_bot_rs::{feat, http::resolve_url, param, plugins::TITLE_PLUGINS, tld::TLD};

use anyhow::Result as AHResult;
use atty::{is, Stream};
use directories::ProjectDirs;
use docopt::Docopt;
use failure::Error;
use lazy_static::lazy_static;
use log::{error, info};
use regex::Regex;
use reqwest::Url;
use serde_derive::Deserialize;
use std::collections::HashSet;
use std::path::PathBuf;
use stderrlog::{ColorChoice, Timestamp};

use lapin::{options::*, types::FieldTable, BasicProperties, Connection, ConnectionProperties};
use tokio_amqp::*;

use futures::prelude::*;

use rand::distributions::Alphanumeric;
use rand::{thread_rng, Rng};

use std::sync::mpsc;
use std::thread;

// docopt usage string
const USAGE: &str = "
URL munching IRC bot.

Usage:
    ubot-url-plugin [options] [-v...] [--conf=PATH...] [--conf-dir=DIR...]

Options:
    -h --help           Show this help message.
    --version           Print version.
    -v --verbose        Show extra information.
    -t --timestamp      Force timestamps.
";

#[derive(Debug, Deserialize, Default)]
pub struct Args {
    flag_verbose: usize,
    flag_conf: Vec<PathBuf>,
    flag_conf_dir: Vec<PathBuf>,
    flag_timestamp: bool,
}

const MIN_VERBOSITY: usize = 2;

#[derive(Debug, PartialEq)]
enum TitleResp {
    Title(String),
    Error(String),
}

/// Run available plugins on a single URL, return the first successful title.
fn process_plugins(rtd: &Rtd, url: &Url) -> Option<String> {
    let result: String = TITLE_PLUGINS
        .iter()
        .filter(|p| p.check(&rtd.conf.plugins, url))
        .filter_map(|p| p.evaluate(&rtd, url).ok())
        .take(1)
        .collect();

    if result.is_empty() {
        None
    } else {
        Some(result)
    }
}

/// find titles in a message and generate responses
fn process_titles(rtd: &Rtd, msg: &str) -> impl Iterator<Item = TitleResp> {
    let mut responses: Vec<TitleResp> = vec![];

    let mut num_processed = 0;
    let mut dedup_urls = HashSet::new();

    // look at each space-separated message token
    for token in msg.split_whitespace() {
        // the token must not contain unsafe characters
        if contains_unsafe_chars(token) {
            continue;
        }

        // get a full URL for tokens without a scheme
        let maybe_token = if feat!(rtd, partial_urls) {
            add_scheme_for_tld(token)
        } else {
            None
        };

        let token = maybe_token.as_ref().map_or(token, String::as_str);

        // the token must be a valid url
        let url = match token.parse::<Url>() {
            Ok(url) => url,
            _ => continue,
        };

        // the scheme must be http or https
        if !["http", "https"].contains(&url.scheme()) {
            continue;
        }

        // skip duplicate urls within the message
        if dedup_urls.contains(&url) {
            continue;
        }

        info!("[{}] RESOLVE <{}>", rtd.conf.network.name, token);

        // try to get the title from the url
        let title = if let Some(title) = process_plugins(rtd, &url) {
            title
        } else {
            match resolve_url(token, rtd) {
                Ok(title) => title,
                Err(err) => {
                    error!("{:?}", err);
                    responses.push(TitleResp::Error(err.to_string()));
                    continue;
                }
            }
        };

        // limit response length, see RFC1459

        let msg = utf8_truncate(&format!("⤷ {}", title), 510);

        info!("[{}] {}", rtd.conf.network.name, msg);

        responses.push(TitleResp::Title(msg.to_string()));

        dedup_urls.insert(url);

        // limit the number of processed URLs
        num_processed += 1;
        if num_processed == param!(rtd, url_limit) {
            break;
        }
    }

    responses.into_iter()
}

// regex for unsafe characters, as defined in RFC 1738
const RE_UNSAFE_CHARS: &str = r#"[{}|\\^~\[\]`<>"]"#;

/// does the token contain characters not permitted by RFC 1738
fn contains_unsafe_chars(token: &str) -> bool {
    lazy_static! {
        static ref UNSAFE: Regex = Regex::new(RE_UNSAFE_CHARS).unwrap();
    }
    UNSAFE.is_match(token)
}

/// truncate to a maximum number of bytes, taking UTF-8 into account
fn utf8_truncate(s: &str, n: usize) -> String {
    s.char_indices()
        .take_while(|(len, c)| len + c.len_utf8() <= n)
        .map(|(_, c)| c)
        .collect()
}

lazy_static! {
    static ref REPEATED_DOTS: Regex = Regex::new(r"\.\.+").unwrap();
}

/// if a token has a recognised TLD, but no scheme, add one
pub fn add_scheme_for_tld(token: &str) -> Option<String> {
    if token.parse::<Url>().is_err() {
        if token.starts_with(|s: char| !s.is_alphabetic()) {
            return None;
        }

        if REPEATED_DOTS.is_match(&token) {
            return None;
        }

        let new_token = format!("http://{}", token);

        if let Ok(url) = new_token.parse::<Url>() {
            if !url.domain()?.contains('.') {
                return None;
            }

            // reject email addresses
            if url.username() != "" {
                return None;
            }

            let tld = url.domain()?.split('.').last()?;

            if TLD.contains(tld) {
                return Some(new_token);
            }
        }
    }

    None
}

fn init_rtd() -> AHResult<Rtd, Error> {
    // parse command line arguments with docopt
    let args: Args = Docopt::new(USAGE)
        .and_then(|d| d.version(Some(VERSION.to_string())).deserialize())
        .unwrap_or_else(|e| e.exit());

    // avoid timestamping when piped, e.g. systemd
    let timestamp = if is(Stream::Stderr) || args.flag_timestamp {
        Timestamp::Second
    } else {
        Timestamp::Off
    };

    stderrlog::new()
        .module(module_path!())
        .modules(vec![
            "url_bot_rs::message",
            "url_bot_rs::config",
            "url_bot_rs::http",
        ])
        .verbosity(args.flag_verbose + MIN_VERBOSITY)
        .timestamp(timestamp)
        .color(ColorChoice::Never)
        .init()
        .unwrap();

    let dirs = ProjectDirs::from("org", "", "url-bot-rs").unwrap();
    let default_conf_dir = dirs.config_dir();

    let default_conf = default_conf_dir.join("config.toml");

    let rtd: Rtd = Rtd::new().conf(&default_conf).load()?.init_http_client()?;

    Ok(rtd)
}

fn random_string(size: usize) -> String {
    thread_rng()
        .sample_iter(&Alphanumeric)
        .take(size)
        .map(char::from)
        .collect()
}

#[tokio::main]
async fn main() -> AHResult<()> {
    let (tx1, rx1) = mpsc::channel::<String>();
    let (tx2, rx2) = mpsc::channel();

    thread::spawn(move || {
        let rtd = init_rtd().expect("RTD not initialized");

        loop {
            let message = &rx1.recv().expect("rx1 recv error");
            let titles: Vec<_> = process_titles(&rtd, message).collect();
            tx2.send(titles).expect("tx2 send error");
        }
    });
    let amqp_url = std::env::var("AMQP_URL").expect("expected AMQP_URL env variabe");
    let conn = Connection::connect(&amqp_url, ConnectionProperties::default().with_tokio()).await?;

    let pub_channel = conn.create_channel().await?;
    let sub_channel = conn.create_channel().await?;

    let queue = sub_channel
        .queue_declare(
            &random_string(32),
            QueueDeclareOptions {
                exclusive: true,
                auto_delete: true,
                ..QueueDeclareOptions::default()
            },
            FieldTable::default(),
        )
        .await?;

    sub_channel
        .queue_bind(
            queue.name().as_str(),
            "irc",
            "msg.hedgewars",
            QueueBindOptions::default(),
            FieldTable::default(),
        )
        .await?;

    let mut subscriber = sub_channel
        .basic_consume(
            queue.name().as_str(),
            &random_string(32),
            BasicConsumeOptions::default(),
            FieldTable::default(),
        )
        .await?;

    while let Some(amqp_message) = subscriber.next().await {
        let (_, delivery) = amqp_message.expect("error in consumer");
        delivery.ack(BasicAckOptions::default()).await?;

        let chat_message = String::from_utf8(delivery.data)?;
        if let Some((_who, message)) = chat_message.split_once('\n') {
            tx1.send(message.to_owned())?;
            let titles = rx2.recv()?;

            for title in titles {
                let title_message = match title {
                    TitleResp::Title(t) => t,
                    TitleResp::Error(e) => e,
                };
                pub_channel
                    .basic_publish(
                        "irc",
                        "say.hedgewars",
                        BasicPublishOptions::default(),
                        title_message.as_bytes().to_vec(),
                        BasicProperties::default(),
                    )
                    .await?;
            }
        }
    }

    Ok(())
}
