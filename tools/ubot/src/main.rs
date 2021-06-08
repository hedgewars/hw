use lapin::{
    message::Delivery, options::*, types::FieldTable, BasicProperties, Connection,
    ConnectionProperties,
};
use tokio_amqp::*;

use futures::prelude::*;
use irc::client::prelude::*;

use anyhow::{bail, Result as AHResult};

use url::Url;

use rand::distributions::Alphanumeric;
use rand::{thread_rng, Rng};

fn url2irc_config(url: &str) -> AHResult<Config> {
    let url = Url::parse(url)?;

    if url.scheme() != "irc" {
        bail!("Expected 'irc' scheme")
    }

    Ok(Config {
        nickname: Some(url.username().to_owned()),
        nick_password: url.password().map(|s| s.to_owned()),
        server: url.host_str().map(|s| s.to_owned()),
        port: url.port(),
        channels: vec![format!("#{}", &url.path()[1..])],
        //use_mock_connection: true,
        ..Config::default()
    })
}

fn random_string(size: usize) -> String {
    thread_rng()
        .sample_iter(&Alphanumeric)
        .take(size)
        .map(char::from)
        .collect()
}

async fn handle_irc(pub_channel: &lapin::Channel, irc_message: &Message) -> AHResult<()> {
    if let Command::PRIVMSG(msgtarget, message) = &irc_message.command {
        let target = irc_message
            .response_target()
            .expect("Really expected PRIVMSG would have a source");
        let target = if target.starts_with('#') {
            &target[1..]
        } else {
            &target
        };

        if message.starts_with("!") {
            if let Some((cmd, param)) = message.split_once(' ') {
                pub_channel
                    .basic_publish(
                        "irc",
                        &format!("cmd.{}.{}", &cmd[1..], target),
                        BasicPublishOptions::default(),
                        format!("{}\n{}", msgtarget, param).as_bytes().to_vec(),
                        BasicProperties::default(),
                    )
                    .await?;
            } else {
                pub_channel
                    .basic_publish(
                        "irc",
                        &format!("cmd.{}.{}", &message[1..], target),
                        BasicPublishOptions::default(),
                        msgtarget.as_bytes().to_vec(),
                        BasicProperties::default(),
                    )
                    .await?;
            }
        } else {
            pub_channel
                .basic_publish(
                    "irc",
                    &format!("msg.{}", target),
                    BasicPublishOptions::default(),
                    format!("{}\n{}", msgtarget, message).as_bytes().to_vec(),
                    BasicProperties::default(),
                )
                .await?;
        }
    }

    Ok(())
}

async fn handle_amqp(
    irc_client: &mut Client,
    irc_channel: &str,
    delivery: Delivery,
) -> AHResult<()> {
    let message = String::from_utf8(delivery.data)?;
    Ok(irc_client.send_privmsg(irc_channel, message)?)
}

#[tokio::main]
async fn main() -> AHResult<()> {
    let amqp_url = std::env::var("AMQP_URL").expect("expected AMQP_URL env variabe");
    let irc_url = std::env::var("IRC_URL").expect("expected IRC_URL env variabe");
    let conn = Connection::connect(&amqp_url, ConnectionProperties::default().with_tokio()).await?;

    let pub_channel = conn.create_channel().await?;
    let sub_channel = conn.create_channel().await?;

    let irc_config = url2irc_config(&irc_url)?;
    let irc_channel = irc_config.channels[0].to_owned();
    let mut irc_client = Client::from_config(irc_config).await?;
    let mut irc_stream = irc_client.stream()?;
    irc_client.identify()?;

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
            &format!("say.{}", &irc_channel[1..]),
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

    loop {
        tokio::select! {
            Some(irc_message) = irc_stream.next() => handle_irc(&pub_channel, &irc_message?).await?,
            Some(amqp_message) = subscriber.next() => {
                let (_, delivery) = amqp_message.expect("error in consumer");
                delivery
                    .ack(BasicAckOptions::default())
                    .await?;

                    handle_amqp(&mut irc_client, &irc_channel, delivery).await?
            }
        }
    }
}
