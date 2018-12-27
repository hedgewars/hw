use crate::{MessageChecker, Severity};

struct CapsAbuseChecker {}

impl<T> MessageChecker<T> for CapsAbuseChecker {
    fn check(&self, player_id: T, message: &str) -> Severity {
        Severity::Pass
    }
}
