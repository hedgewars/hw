#ifndef NETCONN_H_
#define NETCONN_H_

#include "../model/gamesetup.h"
#include "../model/cfg.h"
#include "../model/roomlist.h"

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define NETCONN_STATE_CONNECTING 0
#define NETCONN_STATE_LOBBY 1
#define NETCONN_STATE_ROOM 2
#define NETCONN_STATE_INGAME 3
#define NETCONN_STATE_DISCONNECTED 10

#define NETCONN_DISCONNECT_NORMAL 0
#define NETCONN_DISCONNECT_SERVER_TOO_OLD 1
#define NETCONN_DISCONNECT_AUTH_FAILED 2
#define NETCONN_DISCONNECT_INTERNAL_ERROR 100

#define NETCONN_ROOMLEAVE_ABANDONED 0
#define NETCONN_ROOMLEAVE_KICKED 1

#define NETCONN_MSG_TYPE_PLAYERINFO 0
#define NETCONN_MSG_TYPE_SERVERMESSAGE 1
#define NETCONN_MSG_TYPE_WARNING 2
#define NETCONN_MSG_TYPE_ERROR 3

#define NETCONN_MAPCHANGE_FULL 0
#define NETCONN_MAPCHANGE_MAP 1
#define NETCONN_MAPCHANGE_MAPGEN 2
#define NETCONN_MAPCHANGE_DRAWNMAP 3
#define NETCONN_MAPCHANGE_MAZE_SIZE 4
#define NETCONN_MAPCHANGE_TEMPLATE 5
#define NETCONN_MAPCHANGE_THEME 6
#define NETCONN_MAPCHANGE_SEED 7

// TODO: Order of functions, and match the order in netconn.c
typedef struct _flib_netconn flib_netconn;

flib_netconn *flib_netconn_create(const char *playerName, flib_cfg_meta *metacfg, const char *host, uint16_t port);
void flib_netconn_destroy(flib_netconn *conn);

/**
 * Perform I/O operations and call callbacks if something interesting happens.
 * Should be called regularly.
 */
void flib_netconn_tick(flib_netconn *conn);


/**
 * Return the current roomlist. Don't free or modify.
 */
const flib_roomlist *flib_netconn_get_roomlist(flib_netconn *conn);

/**
 * Are you currently the owner of this room? The return value only makes sense in
 * NETCONN_STATE_ROOM and NETCONN_STATE_INGAME states.
 */
bool flib_netconn_is_chief(flib_netconn *conn);

/**
 * quitmsg may be null
 */
int flib_netconn_send_quit(flib_netconn *conn, const char *quitmsg);
int flib_netconn_send_chat(flib_netconn *conn, const char *chat);

/**
 * Send a teamchat message, forwarded from the engine. Only makes sense ingame.
 * The server does not send a reply. TODO figure out details
 */
int flib_netconn_send_teamchat(flib_netconn *conn, const char *msg);

/**
 * Note: Most other functions in this lib accept UTF-8, but the password needs to be
 * sent as latin1
 */
int flib_netconn_send_password(flib_netconn *conn, const char *latin1Passwd);

/**
 * Request a different nickname.
 * This function only makes sense in reaction to an onNickTaken callback, because the netconn automatically
 * requests the nickname you provide on creation, and once the server accepts the nickname it can no longer
 * be changed.
 */
int flib_netconn_send_nick(flib_netconn *conn, const char *nick);

/**
 * Join a room as guest (not chief). Only makes sense when in lobby state. If the action succeeds, you will
 * receive an onEnterRoom callback with chief=false.
 */
int flib_netconn_send_joinRoom(flib_netconn *conn, const char *room);

/**
 * Create and join a new room. Only makes sense when in lobby state. If the action succeeds, you will
 * receive an onEnterRoom callback with chief=true.
 */
int flib_netconn_send_createRoom(flib_netconn *conn, const char *room);

/**
 * Rename the current room. Only makes sense in room state and if you are chief.
 * TODO: reply
 */
int flib_netconn_send_renameRoom(flib_netconn *conn, const char *roomName);

/**
 * Leave the room for the lobby. Only makes sense in room state.
 * TODO: reply, TODO can you send a message?
 */
int flib_netconn_send_leaveRoom(flib_netconn *conn);

/**
 * Change your "ready" status in the room. Only makes sense when in room state.
 * TODO: reply
 */
int flib_netconn_send_toggleReady(flib_netconn *conn);

/**
 * Add a team to the current room. The message includes the team color, but not
 * the number of hogs. Only makes sense when in room state. If the action succeeds, you will
 * receive an onTeamAccepted callback with the name of the team.
 */
int flib_netconn_send_addTeam(flib_netconn *conn, const flib_team *team);

/**
 * Remove the team with the name teamname. Only makes sense when in room state.
 * TODO: reply
 */
int flib_netconn_send_removeTeam(flib_netconn *conn, const char *teamname);

/**
 * Send an engine message. Only makes sense when ingame.
 * TODO: reply
 */
int flib_netconn_send_engineMessage(flib_netconn *conn, const uint8_t *message, size_t size);

/**
 * Set the number of hogs for a team. Only makes sense in room state and if you are chief.
 * The server does not send a reply.
 */
int flib_netconn_send_teamHogCount(flib_netconn *conn, const char *teamname, int hogcount);

/**
 * Set the teamcolor of a team. Only makes sense in room state and if you are chief.
 * The server does not send a reply.
 */
int flib_netconn_send_teamColor(flib_netconn *conn, const char *teamname, uint32_t colorRGB);

/**
 * Set the weaponset for the room. Only makes sense in room state and if you are chief.
 * The server does not send a reply.
 */
int flib_netconn_send_weaponset(flib_netconn *conn, const flib_weaponset *weaponset);

/**
 * Set the map for the room. Only makes sense in room state and if you are chief.
 * The server does not send a reply.
 */
int flib_netconn_send_map(flib_netconn *conn, const flib_map *map);

/**
 * Set the mapname. Only makes sense in room state and if you are chief.
 * The server does not send a reply.
 */
int flib_netconn_send_mapName(flib_netconn *conn, const char *mapName);

/**
 * Set the map generator. Only makes sense in room state and if you are chief.
 * The server does not send a reply.
 */
int flib_netconn_send_mapGen(flib_netconn *conn, int mapGen);

/**
 * Set the map template for regular maps. Only makes sense in room state and if you are chief.
 * The server does not send a reply.
 */
int flib_netconn_send_mapTemplate(flib_netconn *conn, int templateFilter);

/**
 * Set the maze template (maze size) for mazes. Only makes sense in room state and if you are chief.
 * The server does not send a reply.
 */
int flib_netconn_send_mapMazeSize(flib_netconn *conn, int mazeSize);

/**
 * Set the seed for the map. Only makes sense in room state and if you are chief.
 * The server does not send a reply.
 */
int flib_netconn_send_mapSeed(flib_netconn *conn, const char *seed);

/**
 * Set the theme for the map. Only makes sense in room state and if you are chief.
 * The server does not send a reply.
 */
int flib_netconn_send_mapTheme(flib_netconn *conn, const char *theme);

/**
 * Set the draw data for the drawn map. Only makes sense in room state and if you are chief.
 * The server does not send a reply.
 */
int flib_netconn_send_mapDrawdata(flib_netconn *conn, const uint8_t *drawData, size_t size);

/**
 * Set the script (game style). Only makes sense in room state and if you are chief.
 * The server does not send a reply.
 */
int flib_netconn_send_script(flib_netconn *conn, const char *scriptName);

/**
 * Set the scheme. Only makes sense in room state and if you are chief.
 * The server does not send a reply.
 */
int flib_netconn_send_scheme(flib_netconn *conn, const flib_cfg *scheme);

/**
 * Inform the server that the round has ended. TODO: Figure out details
 */
int flib_netconn_send_roundfinished(flib_netconn *conn, bool withoutError);

/**
 * Ban a player. TODO: Figure out details
 */
int flib_netconn_send_ban(flib_netconn *conn, const char *playerName);

/**
 * Kick a player. TODO: Figure out details
 */
int flib_netconn_send_kick(flib_netconn *conn, const char *playerName);

/**
 * Request information about a player. If the action succeeds, you will
 * receive an onMessage callback with NETCONN_MSG_TYPE_PLAYERINFO containing
 * the requested information.
 */
int flib_netconn_send_playerInfo(flib_netconn *conn, const char *playerName);

/**
 * Follow a player. TODO figure out details
 */
int flib_netconn_send_playerFollow(flib_netconn *conn, const char *playerName);

/**
 * Signal that you want to start the game. Only makes sense in room state and if you are chief.
 * TODO figure out details
 */
int flib_netconn_send_startGame(flib_netconn *conn);

/**
 * Allow/forbid players to join the room. Only makes sense in room state and if you are chief.
 * The server does not send a reply.
 */
int flib_netconn_send_toggleRestrictJoins(flib_netconn *conn);

/**
 * Allow/forbid adding teams to the room. Only makes sense in room state and if you are chief.
 * The server does not send a reply.
 */
int flib_netconn_send_toggleRestrictTeams(flib_netconn *conn);

/**
 * Probably does something administrator-y.
 */
int flib_netconn_send_clearAccountsCache(flib_netconn *conn);

/**
 * Sets a server variable to the indicated value. Only makes sense if you are server admin.
 * Known variables are MOTD_NEW, MOTD_OLD and LATEST_PROTO.
 * TODO reply?
 */
int flib_netconn_send_setServerVar(flib_netconn *conn, const char *name, const char *value);

/**
 * Queries all server variables. Only makes sense if you are server admin. (TODO: try)
 * If the action succeeds, you will receive several onServerVar callbacks with the
 * current values of all server variables.
 */
int flib_netconn_send_getServerVars(flib_netconn *conn);










/**
 * Callback for several informational messages that should be displayed to the user
 * (e.g. in the chat window), but do not require a reaction. If a game is running, you might
 * want to redirect some of these messages to the engine as well so the user will see them.
 */
void flib_netconn_onMessage(flib_netconn *conn, void (*callback)(void *context, int msgtype, const char *msg), void* context);

/**
 * We received a chat message. Where this message belongs depends on the current state (lobby/room/game). In particular,
 * if a game is running the message should be passed to the engine.
 */
void flib_netconn_onChat(flib_netconn *conn, void (*callback)(void *context, const char *nick, const char *msg), void* context);

/**
 * This is called when we receive a CONNECTED message from the server, which should be the first
 * message arriving from the server.
 */
void flib_netconn_onConnected(flib_netconn *conn, void (*callback)(void *context), void* context);

/**
 * This is *always* the last callback (unless the netconn is destroyed early), and the netconn should be destroyed when it is received.
 * The reason is one of the NETCONN_DISCONNECT_ constants. Sometime a message is included as well, but that parameter might
 * also be NULL.
 */
void flib_netconn_onDisconnected(flib_netconn *conn, void (*callback)(void *context, int reason, const char *message), void* context);

/**
 * Callbacks for room list updates. The room list is managed automatically and can be queried with
 * flib_netconn_get_roomlist() as soon as the onConnected callback is fired. These callbacks
 * provide notification about changes.
 */
void flib_netconn_onRoomAdd(flib_netconn *conn, void (*callback)(void *context, const flib_roomlist_room *room), void* context);
void flib_netconn_onRoomDelete(flib_netconn *conn, void (*callback)(void *context, const char *name), void* context);
void flib_netconn_onRoomUpdate(flib_netconn *conn, void (*callback)(void *context, const char *oldName, const flib_roomlist_room *room), void* context);

/**
 * Callbacks for players joining or leaving the lobby. If join is true it's a join, otherwise a leave.
 * NOTE: partMessage is null if no parting message was given.
 */
void flib_netconn_onLobbyJoin(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context);
void flib_netconn_onLobbyLeave(flib_netconn *conn, void (*callback)(void *context, const char *nick, const char *partMessage), void* context);

/**
 * onNickTaken is called on connecting to the server, if it turns out that there is already a player with the same nick.
 * In order to proceed, a new nickname needs to be sent to the server using flib_netconn_send_nick() (or of course you can
 * bail out and send a QUIT). If you don't set a callback, the netconn will automatically react by generating a new name.
 * Once the server accepts a name, you will be informed with an onNickAccept callback.
 */
void flib_netconn_onNickTaken(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context);

/**
 * When connecting with a registered nickname, the server will ask for a password before admitting you in.
 * This callback is called when that happens. As a reaction, you can send the password using
 * flib_netconn_send_password or choose a different nick. If you don't register a callback,
 * the default behavior is to just quit in a way that will cause a disconnect with NETCONN_DISCONNECT_AUTH_FAILED.
 */
void flib_netconn_onPasswordRequest(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context);

/**
 * You just left the lobby and entered a room.
 * If chief is true, you can and should send a full configuration for the room now.
 * This consists of TODO
 */
void flib_netconn_onEnterRoom(flib_netconn *conn, void (*callback)(void *context, bool chief), void *context);


/**
 * The following callbacks are only relevant in room state.
 */

/**
 * This callback informs about changes to your room chief status, i.e. whether you are allowed to
 * modify the current room. Generally when you create a room you start out being room chief, and
 * when you join an existing room you are not. However, in some situations room ownership can change,
 * and if that happens this callback is called with the new status.
 *
 * Note: This callback does not automatically fire when joining a room. You can always query the
 * current chief status using flib_netconn_is_chief().
 */
void flib_netconn_onRoomChiefStatus(flib_netconn *conn, void (*callback)(void *context, bool chief), void* context);

/**
 * One of the players in the room (possibly you!) changed their ready state.
 */
void flib_netconn_onReadyState(flib_netconn *conn, void (*callback)(void *context, const char *nick, bool ready), void* context);

/**
 * You just left a room and entered the lobby again.
 * reason is one of the NETCONN_ROOMLEAVE_ constants.
 * This will not be called when you actively leave a room using PART.
 */
void flib_netconn_onLeaveRoom(flib_netconn *conn, void (*callback)(void *context, int reason, const char *message), void *context);

/**
 * A new team was added to the room. The person who adds a team does NOT receive this callback (he gets onTeamAccepted instead).
 * The team does not contain bindings, stats, weaponset, color or the number of hogs.
 */
void flib_netconn_onTeamAdd(flib_netconn *conn, void (*callback)(void *context, flib_team *team), void *context);

/**
 * A team was removed from the room.
 */
void flib_netconn_onTeamDelete(flib_netconn *conn, void (*callback)(void *context, const char *teamname), void *context);

void flib_netconn_onRoomJoin(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context);
void flib_netconn_onRoomLeave(flib_netconn *conn, void (*callback)(void *context, const char *nick, const char *partMessage), void* context);

/**
 * The game is starting. Fire up the engine and join in!
 * TODO: How?
 */
void flib_netconn_onRunGame(flib_netconn *conn, void (*callback)(void *context), void *context);

/**
 * When you ask for a team to be added, the server might reject it for several reasons, e.g. because it has the same name
 * as an existing team, or because the room chief restricted adding new teams. If the team is accepted by the server,
 * this callback is fired.
 */
void flib_netconn_onTeamAccepted(flib_netconn *conn, void (*callback)(void *context, const char *teamName), void *context);

/**
 * The number of hogs in a team has been changed by the room chief. If you are the chief and change the number of hogs yourself,
 * you will not receive this callback!
 */
void flib_netconn_onHogCountChanged(flib_netconn *conn, void (*callback)(void *context, const char *teamName, int hogs), void *context);

/**
 * The color of a team has been changed by the room chief. If you are the chief and change the color yourself,
 * you will not receive this callback!
 */
void flib_netconn_onTeamColorChanged(flib_netconn *conn, void (*callback)(void *context, const char *teamName, uint32_t colorARGB), void *context);

void flib_netconn_onEngineMessage(flib_netconn *conn, void (*callback)(void *context, const char *message, int size), void *context);

void flib_netconn_onCfgScheme(flib_netconn *conn, void (*callback)(void *context, flib_cfg *scheme), void *context);

/**
 * This is called when the map configuration in a room is changed (or first received). Only non-chiefs receive these messages.
 * To reduce the number of callback functions, the netconn keeps track of the current map settings and always passes the entire
 * current map config, but informs the callee about what has changed (see the NETCONN_MAPCHANGE_ constants).
 * The map parameter passed to the callback is an internally held map config. If you want to keep it around, best make a copy
 * or it may or may not change while you are not looking.
 *
 * Caution: Due to the way the protocol works, the map might not be complete at this point if it is a hand-drawn map, because
 * the "full" map config does not include the drawn map data.
 */
void flib_netconn_onMapChanged(flib_netconn *conn, void (*callback)(void *context, const flib_map *map, int changetype), void *context);

/**
 * The "game style" script has been changed by the room chief. If you are the chief and change the script yourself,
 * you will not receive this callback!
 */
void flib_netconn_onScriptChanged(flib_netconn *conn, void (*callback)(void *context, const char *script), void *context);

/**
 * The weaponset has been changed by the room chief. If you are the chief and change the weaponset yourself,
 * you will not receive this callback!
 */
void flib_netconn_onWeaponsetChanged(flib_netconn *conn, void (*callback)(void *context, flib_weaponset *weaponset), void *context);

/**
 * This callback is called if the server informs us that we have admin rights.
 */
void flib_netconn_onAdminAccess(flib_netconn *conn, void (*callback)(void *context), void *context);

/**
 * When you query the server vars with GET_SERVER_VAR (TODO probably only works as admin), the server
 * replies with a list of them. This callback is called for each entry in that list.
 */
void flib_netconn_onServerVar(flib_netconn *conn, void (*callback)(void *context, const char *name, const char *value), void *context);

#endif
