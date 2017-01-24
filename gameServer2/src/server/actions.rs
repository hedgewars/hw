use protocol::messages::{HWProtocolMessage, HWServerMessage};

pub enum Action {
    SendMe(String),
    RemoveClient,
    ByeClient(String),
    ReactProtocolMessage(HWProtocolMessage),
}
