use hedgewars_network_protocol::{
    parser::message,
    types::GameCfg,
    {messages::HwProtocolMessage::*, parser::HwProtocolError},
};

#[test]
fn parse_test() {
    assert_eq!(message(b"PING\n\n"), Ok((&b""[..], Ping)));
    assert_eq!(message(b"START_GAME\n\n"), Ok((&b""[..], StartGame)));
    assert_eq!(
        message(b"NICK\nit's me\n\n"),
        Ok((&b""[..], Nick("it's me".to_string())))
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
