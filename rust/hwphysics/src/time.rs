use crate::common::{GearDataProcessor, GearId};
use fpnum::{fp, FPNum};
use std::{
    cmp::{Eq, Ord, Ordering, PartialEq, PartialOrd},
    collections::BinaryHeap,
};

pub type EventId = u16;

struct TimeEvent {
    time: FPNum,
    gear_id: GearId,
    event_id: EventId,
}

impl PartialOrd for TimeEvent {
    #[inline]
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        self.time.partial_cmp(&other.time)
    }
}

impl PartialEq for TimeEvent {
    #[inline]
    fn eq(&self, other: &Self) -> bool {
        self.time.eq(&other.time)
    }
}

impl Ord for TimeEvent {
    #[inline]
    fn cmp(&self, other: &Self) -> Ordering {
        self.time.cmp(&other.time)
    }
}

impl Eq for TimeEvent {}

pub struct OccurredEvents {
    events: Vec<(GearId, EventId)>,
}

impl OccurredEvents {
    fn new() -> Self {
        Self { events: vec![] }
    }

    fn clear(&mut self) {
        self.events.clear()
    }
}

pub struct TimeProcessor {
    current_event_id: EventId,
    current_time: FPNum,
    events: BinaryHeap<TimeEvent>,
    timeouts: OccurredEvents,
}

impl TimeProcessor {
    pub fn new() -> Self {
        Self {
            current_event_id: 0,
            current_time: fp!(0),
            events: BinaryHeap::with_capacity(1024),
            timeouts: OccurredEvents::new(),
        }
    }

    pub fn register(&mut self, gear_id: GearId, timeout: FPNum) -> EventId {
        let event_id = self.current_event_id;
        self.current_event_id.wrapping_add(1);
        let event = TimeEvent {
            time: self.current_time + timeout,
            gear_id,
            event_id,
        };
        self.events.push(event);
        event_id
    }

    pub fn cancel(&mut self, gear_id: GearId) {}

    pub fn process(&mut self, time_step: FPNum) -> &OccurredEvents {
        self.timeouts.clear();
        self.current_time += time_step;
        while self
            .events
            .peek()
            .filter(|e| e.time <= self.current_time)
            .is_some()
        {
            let event = self.events.pop().unwrap();
            self.timeouts.events.push((event.gear_id, event.event_id))
        }
        &self.timeouts
    }
}
