pub mod bad_words;
pub mod letter_repeat;

use unicode_skeleton::UnicodeSkeleton;

#[derive(PartialEq, Debug)]
enum Severity {
    Pass,
    Warn,
    Silence,
    Ban,
}

trait MessageChecker<T> {
    fn check(&self, player_id: T, message: &str) -> Severity;
    fn fix(&self, player_id: T, message: &str) -> Option<String> {
        None
    }
}

fn normalized_message(s: &str) -> String {
    s.chars()
        .flat_map(|c| c.to_lowercase())
        .skeleton_chars()
        .collect::<String>()
}
