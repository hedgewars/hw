use std::time::{Duration, Instant};

#[derive(Clone, Copy, Debug)]
pub enum FloodEvent {
    LobbyChatMessage,
    EngineMessage,
    RoomJoin,
    RoomNameUpdate,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum FloodAction {
    None,
    Warn(&'static str),
    Bye(&'static str),
}

#[derive(Clone, Debug, Default)]
pub struct FloodControl {
    ei_lobby_chat: Vec<(u32, Instant)>,
    ei_em: Vec<(u32, Instant)>,
    ei_join: Vec<(u32, Instant)>,
}

impl FloodControl {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn register_event(&mut self, event: FloodEvent) -> FloodAction {
        let (num_per_entry, (sec1, num1), (sec2, num2), warn_msg, bye_msg) = match event {
            FloodEvent::LobbyChatMessage => (
                3,
                (Duration::from_secs(10), 2),
                (Duration::from_secs(30), 3),
                "Warning! Chat flood protection activated",
                "Excess flood",
            ),
            FloodEvent::RoomNameUpdate => (
                3,
                (Duration::from_secs(10), 2),
                (Duration::from_secs(30), 3),
                "Warning! Room name change flood protection activated",
                "Excess flood",
            ),
            FloodEvent::RoomJoin => (
                2,
                (Duration::from_secs(10), 2),
                (Duration::from_secs(35), 3),
                "Warning! Joins flood protection activated",
                "Excess flood",
            ),
            FloodEvent::EngineMessage => (
                8,
                (Duration::from_secs(10), 4),
                (Duration::from_secs(25), 5),
                "Game messages flood detected - 1",
                "Excess flood",
            ),
        };

        let entries = match event {
            FloodEvent::LobbyChatMessage | FloodEvent::RoomNameUpdate => &mut self.ei_lobby_chat,
            FloodEvent::EngineMessage => &mut self.ei_em,
            FloodEvent::RoomJoin => &mut self.ei_join,
        };

        if let Some((count, _)) = entries.first_mut() {
            if *count > 0 {
                *count -= 1;
                return FloodAction::None;
            }
        }

        let now = Instant::now();
        let l2 = entries
            .iter()
            .take_while(|(_, t)| now.duration_since(*t) <= sec2)
            .count();
        entries.truncate(l2);

        let l1 = entries
            .iter()
            .take_while(|(_, t)| now.duration_since(*t) <= sec1)
            .count();

        let action = if l2 > num2 || l1 > num1 {
            FloodAction::Bye(bye_msg)
        } else if l1 >= num1 || l2 >= num2 {
            FloodAction::Warn(warn_msg)
        } else {
            FloodAction::None
        };

        entries.insert(0, (num_per_entry, now));
        action
    }
}
