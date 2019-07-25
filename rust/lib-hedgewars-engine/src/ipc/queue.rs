use hedgewars_engine_messages::{
    messages::EngineMessage::*, messages::SyncedEngineMessage::*,
    messages::UnsyncedEngineMessage::*, messages::*,
};
use queues::*;

#[derive(PartialEq)]
pub enum QueueChatStrategy {
    NetworkGame,
    LocalGame,
}

pub struct MessagesQueue {
    strategy: QueueChatStrategy,
    hi_ticks: u32,
    unordered: Queue<EngineMessage>,
    ordered: Queue<EngineMessage>,
}

impl MessagesQueue {
    pub fn new(strategy: QueueChatStrategy) -> Self {
        MessagesQueue {
            strategy,
            hi_ticks: 0,
            unordered: queue![],
            ordered: queue![],
        }
    }

    fn is_unordered(&self, message: &EngineMessage) -> bool {
        match message {
            Unordered(_) => true,
            Unsynced(HogSay(_)) | Unsynced(ChatMessage(_)) | Unsynced(TeamMessage(_)) => {
                self.strategy == QueueChatStrategy::NetworkGame
            }
            _ => false,
        }
    }

    pub fn push(&mut self, engine_message: EngineMessage) {
        if self.is_unordered(&engine_message) {
            self.unordered.add(engine_message).unwrap();
        } else if let Synced(TimeWrap, timestamp) = engine_message {
            self.ordered
                .add(Synced(TimeWrap, timestamp + self.hi_ticks))
                .unwrap();
            self.hi_ticks += 65536;
        } else if let Synced(message, timestamp) = engine_message {
            self.ordered
                .add(Synced(message, timestamp + self.hi_ticks))
                .unwrap();
        } else {
            self.ordered.add(engine_message).unwrap();
        }
    }

    pub fn pop(&mut self, timestamp: u32) -> Option<EngineMessage> {
        if let Ok(message) = self.unordered.remove() {
            Some(message)
        } else if let Ok(Synced(_, message_timestamp)) = self.ordered.peek() {
            if message_timestamp == timestamp {
                self.ordered.remove().ok()
            } else {
                None
            }
        } else {
            self.ordered.remove().ok()
        }
    }

    pub fn iter(&mut self, timestamp: u32) -> MessagesQueueIterator {
        MessagesQueueIterator {
            timestamp,
            queue: self,
        }
    }
}

pub struct MessagesQueueIterator<'a> {
    timestamp: u32,
    queue: &'a mut MessagesQueue,
}

impl<'a> Iterator for MessagesQueueIterator<'a> {
    type Item = EngineMessage;

    fn next(&mut self) -> Option<EngineMessage> {
        self.queue.pop(self.timestamp)
    }
}

#[test]
fn queue_order() {
    use hedgewars_engine_messages::messages::UnorderedEngineMessage::*;

    let mut queue = MessagesQueue::new(QueueChatStrategy::LocalGame);

    queue.push(Synced(Skip, 1));
    queue.push(Unsynced(ChatMessage("hi".to_string())));
    queue.push(Synced(TimeWrap, 65535));
    queue.push(Unordered(Ping));
    queue.push(Synced(Skip, 2));

    let zero_tick: Vec<EngineMessage> = queue.iter(0).collect();
    assert_eq!(zero_tick, vec![Unordered(Ping)]);
    assert_eq!(queue.pop(1), Some(Synced(Skip, 1)));
    assert_eq!(queue.pop(1), Some(Unsynced(ChatMessage("hi".to_string()))));
    assert_eq!(queue.pop(1), None);
    assert_eq!(queue.pop(2), None);
    assert_eq!(queue.pop(65535), Some(Synced(TimeWrap, 65535)));
    assert_eq!(queue.pop(65535), None);
    assert_eq!(queue.pop(65538), Some(Synced(Skip, 65538)));
    assert_eq!(queue.pop(65538), None);
    assert_eq!(queue.pop(65539), None);
}
