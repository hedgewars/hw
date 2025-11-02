use crate::{MessageChecker, Severity};

struct URLChecker {}

impl<T> MessageChecker<T> for URLChecker {
    fn check(&self, player_id: T, message: &str) -> Severity {
        Severity::Pass
    }
}
