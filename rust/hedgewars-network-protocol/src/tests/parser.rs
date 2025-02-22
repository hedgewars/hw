use crate::{
    parser::HwProtocolError,
    parser::{malformed_message, message, server_message},
    types::GameCfg,
};

#[test]
fn parse_test() {
    use crate::messages::HwProtocolMessage::*;
    use nom::Err::Incomplete;

    assert!(matches!(
        dbg!(message(b"CHAT\nWhat the")),
        Err(Incomplete(_))
    ));
    assert!(matches!(
        dbg!(malformed_message(b"CHAT\nWhat the \xF0\x9F\xA6\x94\n\nBYE")),
        Ok((b"BYE", _))
    ));

    assert_eq!(message(b"PING\n\n"), Ok((&b""[..], Ping)));
    assert_eq!(message(b"START_GAME\n\n"), Ok((&b""[..], StartGame)));
    assert_eq!(
        message(b"NICK\nit's me\n\n"),
        Ok((&b""[..], Nick("it's me".to_string(), None)))
    );
    assert_eq!(message(b"PROTO\n51\n\n"), Ok((&b""[..], Proto(51))));
    assert_eq!(
        message(b"QUIT\nbye-bye\n\n"),
        Ok((&b""[..], Quit(Some("bye-bye".to_string()))))
    );
    assert_eq!(message(b"QUIT\n\n"), Ok((&b""[..], Quit(None))));
    assert_eq!(
        message(b"CMD\nwatch 49471\n\n"),
        Ok((&b""[..], Watch(49471)))
    );
    assert_eq!(
        message(b"BAN\nme\nbad\n77\n\n"),
        Ok((&b""[..], Ban("me".to_string(), "bad".to_string(), 77)))
    );

    assert_eq!(message(b"CMD\nPART\n\n"), Ok((&b""[..], Part(None))));
    assert_eq!(
        message(b"CMD\nPART _msg_\n\n"),
        Ok((&b""[..], Part(Some("_msg_".to_string()))))
    );

    assert_eq!(message(b"CMD\nRND\n\n"), Ok((&b""[..], Rnd(vec![]))));
    assert_eq!(
        message(b"CMD\nRND A B\n\n"),
        Ok((&b""[..], Rnd(vec![String::from("A"), String::from("B")])))
    );

    assert_eq!(
        message(b"CFG\nSCHEME\na\nA\n\n"),
        Ok((
            &b""[..],
            Cfg(GameCfg::Scheme("a".to_string(), vec!["A".to_string()]))
        ))
    );

    assert_eq!(
        message(b"QUIT\n1\n2\n\n"),
        Err(nom::Err::Error(HwProtocolError::new()))
    );
}

#[test]
fn parse_server_messages_test() {
    use crate::messages::HwServerMessage::*;

    assert_eq!(server_message(b"PING\n\n"), Ok((&b""[..], Ping)));

    assert_eq!(
        server_message(b"JOINING\nnoone\n\n"),
        Ok((&b""[..], Joining("noone".to_string())))
    );

    assert_eq!(
        server_message(b"CLIENT_FLAGS\naaa\nA\nB\n\n"),
        Ok((
            &b""[..],
            ClientFlags("aaa".to_string(), vec!["A".to_string(), "B".to_string()])
        ))
    )
}
