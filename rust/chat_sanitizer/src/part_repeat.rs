use crate::{MessageChecker, Severity};

struct PartRepeatChecker {}

impl<T> MessageChecker<T> for PartRepeatChecker {
    fn check(&self, player_id: T, message: &str) -> Severity {
        Severity::Pass
    }
}
