use protocol::messages::{
    HWProtocolMessage::{self, Rnd}, HWServerMessage::ChatMsg,
};
use rand::{self, Rng};
use server::{actions::Action, server::HWServer};

pub fn rnd_reply(options: Vec<String>) -> Vec<Action> {
    let options = if options.is_empty() {
        vec!["heads".to_owned(), "tails".to_owned()]
    } else {
        options
    };
    let reply = rand::thread_rng().choose(&options).unwrap();
    let msg = ChatMsg {
        nick: "[random]".to_owned(),
        msg: reply.clone(),
    };
    let msg = msg.send_all().action();
    vec![msg]
}

#[cfg(test)]
mod tests {
    use super::*;
    use protocol::messages::HWServerMessage::ChatMsg;
    use server::actions::{
        Action::{self, Send}, PendingMessage,
    };

    fn reply2string(mut r: Vec<Action>) -> String {
        assert_eq!(r.len(), 1);
        match r.remove(0) {
            Send(PendingMessage {
                message: ChatMsg { msg: p, .. },
                ..
            }) => String::from(p),
            _ => panic!("reply should be a string"),
        }
    }

    fn run_handle_test(opts: Vec<String>) {
        let opts2 = opts.clone();
        for opt in opts {
            while reply2string(rnd_reply(opts2.clone())) != opt {}
        }
    }

    #[test]
    fn test_handle_rnd_empty() {
        run_handle_test(vec![])
    }

    #[test]
    fn test_handle_rnd_nonempty() {
        run_handle_test(vec!["A".to_owned(), "B".to_owned(), "C".to_owned()])
    }
}
