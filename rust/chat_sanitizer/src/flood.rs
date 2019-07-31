use crate::{MessageChecker, Severity};

struct FloodChecker {}

impl<T> MessageChecker<T> for FloodChecker {
    fn check(&self, player_id: T, message: &str) -> Severity {
        Severity::Pass
    }
}
