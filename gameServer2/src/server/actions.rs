use protocol::messages::HWProtocolMessage;

pub enum Action {
    SendMe(String),
    RemoveClient,
    ByeClient(String),
    ReactProtocolMessage(HWProtocolMessage),
}
