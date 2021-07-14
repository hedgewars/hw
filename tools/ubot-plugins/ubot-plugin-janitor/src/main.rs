use anyhow::Result as AHResult;

use futures::prelude::*;
use lapin::{options::*, types::FieldTable, BasicProperties, Connection, ConnectionProperties};

use tokio_amqp::*;

#[tokio::main]
async fn main() -> AHResult<()> {
    let amqp_url = std::env::var("AMQP_URL").expect("expected AMQP_URL env variabe");
    let conn = Connection::connect(&amqp_url, ConnectionProperties::default().with_tokio()).await?;

    let pub_channel = conn.create_channel().await?;
    let sub_channel = conn.create_channel().await?;

    let queue = sub_channel
        .queue_declare(
            &"",
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
            "*.hedgewars",
            QueueBindOptions::default(),
            FieldTable::default(),
        )
        .await?;

    let mut subscriber = sub_channel
        .basic_consume(
            queue.name().as_str(),
            &"",
            BasicConsumeOptions::default(),
            FieldTable::default(),
        )
        .await?;

    let mut last_joined = None;
    let mut talking_to = None;

    while let Some(amqp_message) = subscriber.next().await {
        let (_, delivery) = amqp_message.expect("error in consumer");
        delivery.ack(BasicAckOptions::default()).await?;

        match delivery.routing_key.as_str() {
            "msg.hedgewars" => {
                let chat_message = String::from_utf8_lossy(&delivery.data);
                if let Some((who, _)) = chat_message.split_once('\n') {
                    let who = Some(who.to_owned());
                    if talking_to == who || last_joined == who {
                        talking_to = who;
                        pub_channel
                            .basic_publish(
                                "irc",
                                "cmd.say.hedgewars",
                                BasicPublishOptions::default(),
                                vec![],
                                BasicProperties::default(),
                            )
                            .await?;
                    } else {
                        last_joined = None;
                        talking_to = None;
                    }
                }
            }
            "join.hedgewars" => {
                last_joined = Some(String::from_utf8_lossy(&delivery.data).to_string());
            }
            _ => (),
        }
    }

    Ok(())
}
