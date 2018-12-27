use crate::{MessageChecker, Severity};

struct LetterRepeatChecker {}

impl<T> MessageChecker<T> for LetterRepeatChecker {
    fn check(&self, player_id: T, message: &str) -> Severity {
        Severity::Pass
    }
}
