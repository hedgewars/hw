use crate::{MessageChecker, Severity};

use itertools::Itertools;
use std::marker::PhantomData;

struct LetterRepeatChecker<T> {
    threshold: usize,
    player_id_type: PhantomData<T>,
}

impl<T> LetterRepeatChecker<T> {
    pub fn new(threshold: usize) -> Self {
        Self {
            threshold,
            player_id_type: PhantomData,
        }
    }
}

impl<T> MessageChecker<T> for LetterRepeatChecker<T> {
    fn check(&self, _player_id: T, message: &str) -> Severity {
        for (_key, group) in &message.chars().into_iter().group_by(|c| *c) {
            if group.count() >= self.threshold {
                return Severity::Warn;
            }
        }

        Severity::Pass
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn it_works() {
        let checker = LetterRepeatChecker::new(3);
        assert_eq!(checker.check(0, "Hello world!"), Severity::Pass);
        assert_eq!(checker.check(0, "ooops"), Severity::Warn);
        assert_eq!(
            checker.check(0, "жираф - длинношеее животное"),
            Severity::Warn
        );
    }
}
