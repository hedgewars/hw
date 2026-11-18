use crate::utils::loc;

pub const ACCESS_DENIED: &str = loc("Access denied.");
pub const AUTHENTICATION_FAILED: &str = loc("Authentication failed");
pub const BAD_NUMBER: &str = loc("Bad number.");
pub const ILLEGAL_CLIENT_NAME: &str = loc("Illegal nickname! Nicknames must be between 1-40 characters long, must not have a trailing or leading space and must not have any of these characters: $()*+?[]^{|}");
pub const ILLEGAL_ROOM_NAME: &str = loc("Illegal room name! A room name must be between 1-40 characters long, must not have a trailing or leading space and must not have any of these characters: $()*+?[]^{|}");
pub const ILLEGAL_ROOM_RENAME: &str = loc("Illegal room name! The room name must be between 1-40 characters long, must not have a trailing or leading space and must not have any of these characters: $()*+?[]^{|}");
pub const NICKNAME_PROVIDED: &str = loc("Nickname already provided.");
pub const NO_CHECKER_RIGHTS: &str = loc("No checker rights");
pub const NO_ROOM: &str = loc("No such room.");
pub const NO_TEAM: &str = loc("No such team.");
pub const NO_TEAM_TO_REMOVE: &str = loc("Error: The team you tried to remove does not exist.");
pub const NO_USER: &str = loc("No such user.");
pub const NOT_MASTER: &str = loc("You're not the room master!");
pub const PROTOCOL_PROVIDED: &str = loc("Protocol already known.");
pub const PROTOCOL_TOO_OLD: &str = loc("Protocol version is too old");
pub const REPLAY_LOAD_FAILED: &str = loc("Could't load the replay");
pub const REPLAY_NOT_SUPPORTED: &str = loc("This server does not support replays!");
pub const REGISTRATION_REQUIRED: &str = loc("This server only allows registered users to join.");
pub const REGISTERED_ONLY_ENABLED: &str =
    loc("This server no longer allows unregistered players to join.");
pub const REGISTERED_ONLY_DISABLED: &str =
    loc("This server now allows unregistered players to join.");
pub const ROOM_CONFIG_SAVE_FAILED: &str = loc("Unable to save the room configs.");
pub const ROOM_CONFIG_LOAD_FAILED: &str = loc("Unable to load the room configs.");
pub const ROOM_CONFIG_DESERIALIZE_FAILED: &str = loc("Unable to deserialize the room configs.");
pub const ROOM_CONFIG_LOADED: &str = loc("Room configs loaded successfully.");
pub const ROOM_CONFIG_SAVED: &str = loc("Room configs saved successfully.");
pub const ROOM_EXISTS: &str = loc("A room with the same name already exists.");
pub const ROOM_FULL: &str = loc("This room is already full.");
pub const ROOM_JOIN_RESTRICTED: &str =
    loc("Access denied. This room currently doesn't allow joining.");
pub const ROOM_REGISTRATION_REQUIRED: &str =
    loc("Access denied. This room is for registered users only.");
pub const SUPER_POWER: &str = loc("Super power activated.");
pub const TEAM_EXISTS: &str = loc("There's already a team with same name in the list.");
pub const TEAM_NOT_OWNED: &str = loc("You can't remove a team you don't own.");
pub const TEAM_ADD_RESTRICTED: &str = loc("This room currently does not allow adding new teams.");
pub const TOO_MANY_HEDGEHOGS: &str = loc("Too many hedgehogs!");
pub const TOO_MANY_TEAMS: &str = loc("Too many teams!");
pub const USER_OFFLINE: &str = loc("Player is not online.");
pub const VARIABLE_UPDATED: &str = loc("Server variable has been updated.");
pub const INCOMPATIBLE_ROOM_PROTOCOL: &str =
    loc("Room version incompatible to your Hedgewars version!");
