use crate::{
    server::{actions::Action, server::HWServer},
    protocol::messages::{
        HWProtocolMessage::{self, Rnd}, HWServerMessage::{self, ChatMsg},
    }
};
use rand::{self, Rng, thread_rng};

pub fn rnd_reply(options: &[String]) -> HWServerMessage {
    let mut rng = thread_rng();
    let reply = if options.is_empty() {
        (*rng.choose(&["heads", "tails"]).unwrap()).to_owned()
    } else {
        rng.choose(&options).unwrap().clone()
    };

    ChatMsg {
        nick: "[random]".to_owned(),
        msg: reply.clone(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use protocol::messages::HWServerMessage::ChatMsg;
    use server::actions::{
        Action::{self, Send}, PendingMessage,
    };

    fn reply2string(r: HWServerMessage) -> String {
        match r {
            ChatMsg { msg: p, .. } => String::from(p),
            _ => panic!("expected a ChatMsg"),
        }
    }

    fn run_handle_test(opts: Vec<String>) {
        let opts2 = opts.clone();
        for opt in opts {
            while reply2string(rnd_reply(&opts2)) != opt {}
        }
    }

    /// This test terminates almost surely.
    #[test]
    fn test_handle_rnd_empty() {
        run_handle_test(vec![])
    }

    /// This test terminates almost surely.
    #[test]
    fn test_handle_rnd_nonempty() {
        run_handle_test(vec!["A".to_owned(), "B".to_owned(), "C".to_owned()])
    }

    /// This test terminates almost surely (strong law of large numbers)
    #[test]
    fn test_distribution() {
        let eps = 0.000001;
        let lim = 0.5;
        let opts = vec![0.to_string(), 1.to_string()];
        let mut ones = 0;
        let mut tries = 0;

        while tries < 1000 || ((ones as f64 / tries as f64) - lim).abs() >= eps {
            tries += 1;
            if reply2string(rnd_reply(&opts)) == 1.to_string() {
                ones += 1;
            }
        }
    }
}
