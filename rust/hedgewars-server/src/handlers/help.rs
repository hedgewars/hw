use super::{actions::ToPendingMessage, Response};
use hedgewars_network_protocol::messages::server_chat;

const CMD_HELP_SHARED_PLAYER: &[&str] = &[
    "/info <player>: Show info about player",
    "/me <message>: Chat action, e.g. '/me eats pizza' becomes '* Player eats pizza'",
    "/rnd: Flip a virtual coin and reply with 'heads' or 'tails'",
    "/rnd [A] [B] [C] [...]: Reply with a random word from the given list",
    #[cfg(feature = "official-server")]
    "/watch <id>: Watch a demo stored on the server with the given ID",
    "/quit: Quit the server",
    "/help: Show chat command help",
];

const CMD_HELP_ROOM_ONLY_PLAYER: &[&str] = &[
    "/callvote [arguments]: Start a vote",
    "/vote <yes/no>: Vote 'yes' or 'no' for active vote",
    "/greeting [message]: Set or clear greeting message to be shown to players who join the room",
    "/delegate <player>: Surrender room control to player",
    "/maxteams <N>: Limit maximum number of teams to N",
];

const CMD_HELP_SHARED_ADMIN: &[&str] = &[
    "/global <message>: Send global chat message which can be seen by everyone on the server",
    "/registered_only: Toggle 'registered only' state. If enabled, only registered players can join server",
    "/super_power: Activate your super power. With it you can enter any room and are protected from kicking. Expires when you leave server",
];

const CMD_HELP_LOBBY_ONLY_ADMIN: &[&str] = &["/stats: Query server stats"];

const CMD_HELP_ROOM_ONLY_ADMIN: &[&str] = &[
    "/force <yes/no>: Force vote result for active vote",
    "/fix: Force this room to stay open when it is empty",
    "/unfix: Undo the /fix command",
    "/save <config ID> <config name>: Add current room configuration as votable choice for /callvote map",
    "/delete <config ID>: Delete a votable room configuration",
    #[cfg(feature = "official-server")]
    "/saveroom <file name>: Save all votable room configurations (and the greeting) of this room into a file",
    #[cfg(feature = "official-server")]
    "/loadroom <file name>: Load votable room configurations (and greeting) from a file",
];

pub fn send_help(is_in_room: bool, is_admin: bool, response: &mut Response) {
    let mut lines: Vec<&str> = Vec::new();
    if is_in_room {
        lines.push("List of room chat commands:");
        lines.extend_from_slice(CMD_HELP_ROOM_ONLY_PLAYER);
        lines.extend_from_slice(CMD_HELP_SHARED_PLAYER);
        if is_admin {
            lines.push("Commands for server admins only:");
            lines.extend_from_slice(CMD_HELP_ROOM_ONLY_ADMIN);
            lines.extend_from_slice(CMD_HELP_SHARED_ADMIN);
        }
    } else {
        lines.push("List of lobby chat commands:");
        lines.extend_from_slice(CMD_HELP_SHARED_PLAYER);
        if is_admin {
            lines.push("Commands for server admins only:");
            lines.extend_from_slice(CMD_HELP_LOBBY_ONLY_ADMIN);
            lines.extend_from_slice(CMD_HELP_SHARED_ADMIN);
        }
    }

    for line in lines {
        response.add(server_chat(line.to_string()).send_self());
    }
}
