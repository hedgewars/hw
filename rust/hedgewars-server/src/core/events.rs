use slab::Slab;
use std::{
    convert::TryInto,
    iter,
    num::NonZeroU32,
    time::{Duration, Instant},
};

struct Event<Data> {
    event_id: u32,
    data: Data,
}

#[derive(Clone)]
pub struct Timeout {
    tick_index: u32,
    event_index: u32,
    event_id: u32,
}

pub struct TimedEvents<Data, const MAX_TIMEOUT: usize> {
    events: [Slab<Event<Data>>; MAX_TIMEOUT],
    current_time: Instant,
    current_tick_index: u32,
    next_event_id: u32,
}

impl<Data, const MAX_TIMEOUT: usize> TimedEvents<Data, MAX_TIMEOUT> {
    pub fn new() -> Self {
        Self {
            events: iter::repeat_with(|| Slab::new())
                .take(MAX_TIMEOUT)
                .collect::<Vec<_>>()
                .try_into()
                .ok()
                .unwrap(),
            current_time: Instant::now(),
            current_tick_index: 0,
            next_event_id: 0,
        }
    }

    pub fn set_timeout(&mut self, seconds_delay: NonZeroU32, data: Data) -> Timeout {
        let tick_index = (self.current_tick_index
            + std::cmp::min(seconds_delay.get(), MAX_TIMEOUT as u32))
            % MAX_TIMEOUT as u32;
        let event_id = self.next_event_id;
        self.next_event_id += 1;
        let event = Event { event_id, data };

        let entry = self.events[tick_index as usize].vacant_entry();
        let event_index = entry.key() as u32;
        entry.insert(event);
        Timeout {
            tick_index,
            event_index,
            event_id,
        }
    }

    pub fn cancel_timeout(&mut self, timeout: Timeout) -> Option<Data> {
        let events = &mut self.events[timeout.tick_index as usize];
        if matches!(events.get(timeout.event_index as usize), Some(Event { event_id: id, ..}) if *id == timeout.event_id)
        {
            Some(events.remove(timeout.event_index as usize).data)
        } else {
            None
        }
    }

    pub fn poll(&mut self, time: Instant) -> Vec<Data> {
        let mut result = vec![];
        let second = Duration::from_secs(1);
        while time - self.current_time > second {
            self.current_time += second;
            self.current_tick_index = (self.current_tick_index + 1) % MAX_TIMEOUT as u32;
            result.extend(
                self.events[self.current_tick_index as usize]
                    .drain()
                    .map(|e| e.data),
            );
        }
        result
    }
}

mod test {
    use super::TimedEvents;
    use std::{
        num::NonZeroU32,
        time::{Duration, Instant},
    };

    #[test]
    fn events_test() {
        let mut events = TimedEvents::<u32, 30>::new();
        let now = Instant::now();

        let timeouts = (1..=3)
            .map(|n| events.set_timeout(NonZeroU32::new(n).unwrap(), n))
            .collect::<Vec<_>>();

        let second = Duration::from_secs(1);
        assert_eq!(events.cancel_timeout(timeouts[1].clone()), Some(2));
        assert_eq!(events.poll(now + second), vec![1]);
        assert!(events.poll(now + second).is_empty());
        assert!(events.poll(now + 2 * second).is_empty());
        assert_eq!(events.poll(now + 3 * second), vec![3]);
    }
}
