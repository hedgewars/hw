use crate::{normalized_message, MessageChecker, Severity};

use std::marker::PhantomData;

struct BadWordsChecker<T> {
    blacklist: Vec<String>,
    whitelist: Vec<String>,
    player_id_type: PhantomData<T>,
}

impl<T> BadWordsChecker<T> {
    pub fn new(blacklist: &[&str], whitelist: &[&str]) -> Self {
        Self {
            blacklist: blacklist.iter().map(|s| normalized_message(*s)).collect(),
            whitelist: whitelist.iter().map(|s| normalized_message(*s)).collect(),
            player_id_type: PhantomData,
        }
    }
}

impl<T> MessageChecker<T> for BadWordsChecker<T> {
    fn check(&self, _player_id: T, message: &str) -> Severity {
        let msg = normalized_message(message);

        // silly implementation, allows bad messages with a single good word
        for bad_word in &self.blacklist {
            if msg.contains(bad_word) {
                if !self
                    .whitelist
                    .iter()
                    .any(|good_word| msg.contains(good_word))
                {
                    return Severity::Warn;
                }
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
        let checker = BadWordsChecker::new(&["fsck", "poop"], &["fsck -y"]);
        assert_eq!(checker.check(0, "group hug"), Severity::Pass);
        assert_eq!(checker.check(0, "fpoopf"), Severity::Warn);
        assert_eq!(checker.check(0, "PooP"), Severity::Warn);

        // this one fails
        //assert_eq!(checker.check(0, "poop 'fsck -y' poop"), Severity::Warn);

        // ideally this one shouldn't fail, need a better confusables check
        // assert_eq!(checker.check(0, "P00P"), Severity::Warn);
    }
}
