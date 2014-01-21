/*
 * Hedgewars, a free turn based strategy game
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

/**
 * This file contains functions for communicating with a Hedgewars server to chat, prepare and play
 * rounds of Hedgewars.
 *
 * To use this, first create a netconn object by calling flib_netconn_create. This will start the
 * connection to the game server (which might fail right away, the function returns null then). You
 * should also register your callback functions right at the start to ensure you don't miss any
 * callbacks.
 *
 * In order to allow the netconn to run, you should regularly call flib_netconn_tick(), which
 * performs network I/O and calls your callbacks on interesting events.
 *
 * When the connection is closed, you will receive the onDisconnect callback. This is the signal to
 * destroy the netconn and stop calling tick().
 *
 * The connection process lasts from the time you create the netconn until you receive the
 * onConnected callback (or onDisconnected in case something goes wrong). During that time, you
 * might receive the onNickTaken and onPasswordRequest callbacks; see their description for more
 * information on how to handle them. You could also receive other callbacks during connecting (e.g.
 * about the room list), but it should be safe to ignore them.
 *
 * Once you are connected, you are in the lobby, and you can enter rooms and leave them again. The
 * room and lobby states have different protocols, so many commands only work in either one or the
 * other. If you are in a room you might also be in a game, but most of the functions behave the
 * same ingame as in a room.
 *
 * The state changes from lobby to room when the server tells you that you just entered one, which
 * will also trigger the onEnterRoom callback. This usually happens in reply to either a joinRoom,
 * createRoom or playerFollow command.
 *
 * The state changes back to lobby when the room is dissolved, when you are kicked from the room, or
 * when you actively leave the room using flib_netconn_send_leaveRoom. The first two events will
 * trigger the onLeaveRoom callback.
 */

#ifndef NETCONN_H_
#define NETCONN_H_

#include "../model/gamesetup.h"
#include "../model/scheme.h"
#include "../model/room.h"

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define NETCONN_STATE_CONNECTING 0
#define NETCONN_STATE_LOBBY 1
#define NETCONN_STATE_ROOM 2
#define NETCONN_STATE_DISCONNECTED 10

#define NETCONN_DISCONNECT_NORMAL 0             //!< The connection was closed normally
#define NETCONN_DISCONNECT_SERVER_TOO_OLD 1     //!< The server has a lower protocol version than we do
#define NETCONN_DISCONNECT_AUTH_FAILED 2        //!< You sent a password with flib_netconn_send_password that was not accepted
#define NETCONN_DISCONNECT_CONNLOST 3           //!< The network connection was lost
#define NETCONN_DISCONNECT_INTERNAL_ERROR 100   //!< Something went wrong in frontlib itself

#define NETCONN_ROOMLEAVE_ABANDONED 0           //!< The room was closed because the chief left
#define NETCONN_ROOMLEAVE_KICKED 1              //!< You have been kicked from the room

#define NETCONN_MSG_TYPE_PLAYERINFO 0           //!< A response to flib_netconn_send_playerInfo
#define NETCONN_MSG_TYPE_SERVERMESSAGE 1        //!< The welcome message when connecting to the lobby
#define NETCONN_MSG_TYPE_WARNING 2              //!< A general warning message
#define NETCONN_MSG_TYPE_ERROR 3                //!< A general error message

#define NETCONN_MAPCHANGE_FULL 0
#define NETCONN_MAPCHANGE_MAP 1
#define NETCONN_MAPCHANGE_MAPGEN 2
#define NETCONN_MAPCHANGE_DRAWNMAP 3
#define NETCONN_MAPCHANGE_MAZE_SIZE 4
#define NETCONN_MAPCHANGE_TEMPLATE 5
#define NETCONN_MAPCHANGE_THEME 6
#define NETCONN_MAPCHANGE_SEED 7

typedef struct _flib_netconn flib_netconn;

/**
 * Create a new netplay connection with these parameters.
 * The path to the data directory must end with a path delimiter (e.g. C:\Games\Hedgewars\Data\)
 */
flib_netconn *flib_netconn_create(const char *playerName, const char *dataDirPath, const char *host, int port);
void flib_netconn_destroy(flib_netconn *conn);

/**
 * Perform I/O operations and call callbacks if something interesting happens.
 * Should be called regularly.
 */
void flib_netconn_tick(flib_netconn *conn);

/**
 * Are you currently the owner of this room? The return value only makes sense in
 * NETCONN_STATE_ROOM and NETCONN_STATE_INGAME states.
 */
bool flib_netconn_is_chief(flib_netconn *conn);

/**
 * Returns the playername. This is *probably* the one provided on creation, but if that name was
 * already taken, a different one could have been set by the onNickTaken callback or its default
 * implementation.
 */
const char *flib_netconn_get_playername(flib_netconn *conn);

/**
 * Generate a game setup from the current room state.
 * Returns NULL if the room state does not contain enough information for a complete game setup,
 * or if an error occurs.
 *
 * The new gamesetup must be destroyed with flib_gamesetup_destroy().
 */
flib_gamesetup *flib_netconn_create_gamesetup(flib_netconn *conn);




// Send functions needed when connecting and disconnecting

    /**
     * Request a different nickname.
     * This function only makes sense in reaction to an onNickTaken callback, because the netconn
     * automatically requests the nickname you provide on creation, and once the server accepts the
     * nickname it can no longer be changed.
     */
    int flib_netconn_send_nick(flib_netconn *conn, const char *nick);

    /**
     * Send the password in reply to a password request.
     * If the server does not accept the password, you will be disconnected
     * (NETCONN_DISCONNECT_AUTH_FAILED)
     */
    int flib_netconn_send_password(flib_netconn *conn, const char *passwd);

    /**
     * Tell the server that you want to leave. If successful, the server will disconnect you.
     */
    int flib_netconn_send_quit(flib_netconn *conn, const char *quitmsg);


// Send functions that make sense both in the lobby and in rooms

    /**
     * Send a chat message. This message is either sent to the lobby or the room, depending on
     * whether you are in a room at the moment. The message is not echoed back to you.
     */
    int flib_netconn_send_chat(flib_netconn *conn, const char *chat);

    /**
     * Kick a player. This has different meanings in the lobby and in a room;
     * In the lobby, it will kick the player from the server, and you need to be a server admin to
     * do it. In a room, it will kick the player from the room, and you need to be room chief.
     */
    int flib_netconn_send_kick(flib_netconn *conn, const char *playerName);

    /**
     * Request information about a player (e.g. current room, version, partial IP). If the action
     * succeeds, you will receive an onMessage callback with NETCONN_MSG_TYPE_PLAYERINFO containing
     * the requested information.
     */
    int flib_netconn_send_playerInfo(flib_netconn *conn, const char *playerName);


// Send functions that only make sense in the lobby

    /**
     * Request an update of the room list. Only makes sense when in lobby state.
     * If the action succeeds, you will receive an onRoomlist callback containing the current room
     * data.
     */
    int flib_netconn_send_request_roomlist(flib_netconn *conn);

    /**
     * Join a room as guest (not chief). Only makes sense when in lobby state. If the action
     * succeeds, you will receive an onEnterRoom callback with chief=false followed by other
     * callbacks with current room information.
     */
    int flib_netconn_send_joinRoom(flib_netconn *conn, const char *room);

    /**
     * Follow a player. Only valid in the lobby. If the player is in a room (or in a game), this
     * command is analogous to calling flib_netconn_send_joinRoom with that room.
     */
    int flib_netconn_send_playerFollow(flib_netconn *conn, const char *playerName);

    /**
     * Create and join a new room. Only makes sense when in lobby state. If the action succeeds,
     * you will receive an onEnterRoom callback with chief=true.
     */
    int flib_netconn_send_createRoom(flib_netconn *conn, const char *room);

    /**
     * Ban a player. The scope of this ban depends on whether you are in a room or in the lobby.
     * In a room, you need to be the room chief, and the ban will apply to the room only. In the
     * lobby, you need to be server admin to ban someone, and the ban applies to the entire server.
     */
    int flib_netconn_send_ban(flib_netconn *conn, const char *playerName);

    /**
     * Does something administrator-y. At any rate you need to be an administrator and in the lobby
     * to use this command.
     */
    int flib_netconn_send_clearAccountsCache(flib_netconn *conn);

    /**
     * Sets a server variable to the indicated value. Only makes sense if you are server admin and
     * in the lobby. Known variables are MOTD_NEW, MOTD_OLD and LATEST_PROTO. MOTD_OLD is shown to
     * players with older protocol versions, to inform them that they might want to update.
     */
    int flib_netconn_send_setServerVar(flib_netconn *conn, const char *name, const char *value);

    /**
     * Queries all server variables. Only makes sense if you are server admin and in the lobby.
     * If the action succeeds, you will receive several onServerVar callbacks with the
     * current values of all server variables.
     */
    int flib_netconn_send_getServerVars(flib_netconn *conn);


// Send functions that only make sense in a room

    /**
     * Leave the room for the lobby. Only makes sense in room state. msg can be NULL if you don't
     * want to send a message. The server always accepts a part command, so once you send it off,
     * you can just assume that you are back in the lobby.
     */
    int flib_netconn_send_leaveRoom(flib_netconn *conn, const char *msg);

    /**
     * Change your "ready" status in the room. Only makes sense when in room state. If the action
     * succeeds, you will receive an onClientFlags callback containing the change.
     */
    int flib_netconn_send_toggleReady(flib_netconn *conn);

    /**
     * Add a team to the current room. Apart from the "fixed" team information, this also includes
     * the color, but not the number of hogs. Only makes sense when in room state. If the action
     * succeeds, you will receive an onTeamAccepted callback with the name of the team.
     *
     * Notes: Technically, sending a color here is the only way for a non-chief to set the color of
     * her own team. The server remembers this color and even generates a separate teamColor message
     * to inform everyone of it. However, at the moment the frontends generally override this color
     * with one they choose themselves in order to deal with unfortunate behavior of the QtFrontend,
     * which always sends color index 0 when adding a team but thinks that the team has a random
     * color. The chief always sends a new color in order to bring the QtFrontend back into sync.
     */
    int flib_netconn_send_addTeam(flib_netconn *conn, const flib_team *team);

    /**
     * Remove the team with the name teamname. Only makes sense when in room state.
     * The server does not send a reply on success.
     */
    int flib_netconn_send_removeTeam(flib_netconn *conn, const char *teamname);


// Send functions that only make sense in a room and if you are room chief

    /**
     * Rename the current room. Only makes sense in room state and if you are chief. If the action
     * succeeds, you (and everyone else on the server) will receive an onRoomUpdate message
     * containing the change.
     */
    int flib_netconn_send_renameRoom(flib_netconn *conn, const char *roomName);

    /**
     * Set the number of hogs for a team. Only makes sense in room state and if you are chief.
     * The server does not send a reply.
     */
    int flib_netconn_send_teamHogCount(flib_netconn *conn, const char *teamname, int hogcount);

    /**
     * Set the teamcolor of a team. Only makes sense in room state and if you are chief.
     * The server does not send a reply.
     */
    int flib_netconn_send_teamColor(flib_netconn *conn, const char *teamname, int colorIndex);

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
     * Set the map generator (regular, maze, drawn, named). Only makes sense in room state and if
     * you are chief.
     * The server does not send a reply.
     */
    int flib_netconn_send_mapGen(flib_netconn *conn, int mapGen);

    /**
     * Set the map template for regular maps. Only makes sense in room state and if you are chief.
     * The server does not send a reply.
     */
    int flib_netconn_send_mapTemplate(flib_netconn *conn, int templateFilter);

    /**
     * Set the maze template (maze size) for mazes. Only makes sense in room state and if you are
     * chief. The server does not send a reply.
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
    int flib_netconn_send_scheme(flib_netconn *conn, const flib_scheme *scheme);

    /**
     * Signal that you want to start the game. Only makes sense in room state and if you are chief.
     * The server will check whether all players are ready and whether it believes the setup makes
     * sense (e.g. more than one clan). If the server is satisfied, you will receive an onRunGame
     * callback (all other clients in the room are notified the same way). Otherwise the server
     * might answer with a warning, or might not answer at all.
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


// Send functions that are only needed for running a game

    /**
     * Send a teamchat message, forwarded from the engine. Only makes sense ingame.
     * The server does not send a reply. In contrast to a Chat message, the server
     * automatically converts this into an engine message and passes it on to the other
     * clients.
     */
    int flib_netconn_send_teamchat(flib_netconn *conn, const char *msg);

    /**
     * Send an engine message. Only makes sense when ingame. In a networked game, you have to pass
     * all the engine messages from the engine here, and they will be spread to all other clients
     * in the game to keep the game in sync.
     */
    int flib_netconn_send_engineMessage(flib_netconn *conn, const uint8_t *message, size_t size);

    /**
     * Inform the server that the round has ended. Call this when the engine has disconnected,
     * passing 1 if the round ended normally, 0 otherwise.
     */
    int flib_netconn_send_roundfinished(flib_netconn *conn, bool withoutError);





// Callbacks that are important for connecting/disconnecting

    /**
     * onNickTaken is called when connecting to the server, if it turns out that there is already a
     * player with the same nick.
     * In order to proceed, a new nickname needs to be sent to the server using
     * flib_netconn_send_nick() (or of course you can bail out and send a QUIT).
     * If you don't set a callback, the netconn will automatically react by generating a new name.
     */
    void flib_netconn_onNickTaken(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context);

    /**
     * When connecting with a registered nickname, the server will ask for a password before
     * admitting you in. This callback is called when that happens. As a reaction, you can send the
     * password using flib_netconn_send_password. If you don't register a callback, the default
     * behavior is to just quit in a way that will cause a disconnect with
     * NETCONN_DISCONNECT_AUTH_FAILED.
     *
     * You can't just choose a new nickname when you receive this callback, because at that point
     * the server has already accepted your nick.
     */
    void flib_netconn_onPasswordRequest(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context);

    /**
     * This is called when the server has accepted our nickname (and possibly password) and we have
     * entered the lobby.
     */
    void flib_netconn_onConnected(flib_netconn *conn, void (*callback)(void *context), void* context);

    /**
     * This is always the last callback (unless the netconn is destroyed early), and the netconn
     * should be destroyed when it is received. The reason for the disconnect is passed as one of
     * the NETCONN_DISCONNECT_ constants. Sometimes a message is included as well, but that
     * parameter might also be NULL.
     */
    void flib_netconn_onDisconnected(flib_netconn *conn, void (*callback)(void *context, int reason, const char *message), void* context);


// Callbacks that make sense in most situations

    /**
     * Callback for several informational messages that should be displayed to the user
     * (e.g. in the chat window), but do not require a reaction. If a game is running, you might
     * want to redirect some of these messages to the engine as well so the user will see them.
     */
    void flib_netconn_onMessage(flib_netconn *conn, void (*callback)(void *context, int msgtype, const char *msg), void* context);

    /**
     * We received a chat message. Where this message belongs depends on the current state
     * (lobby/room). If a game is running the message should be passed to the engine.
     */
    void flib_netconn_onChat(flib_netconn *conn, void (*callback)(void *context, const char *nick, const char *msg), void* context);

    /**
     * Callbacks for incremental room list updates. They will fire whenever these events occur,
     * even before you first query the actual roomlist - so be sure not to blindly reference your
     * room list in these callbacks. The server currently only sends updates when a room changes
     * its name, so in order to update other room information you need to query the roomlist again
     * (see send_request_roomlist / onRoomlist).
     */
    void flib_netconn_onRoomAdd(flib_netconn *conn, void (*callback)(void *context, const flib_room *room), void* context);
    void flib_netconn_onRoomDelete(flib_netconn *conn, void (*callback)(void *context, const char *name), void* context);
    void flib_netconn_onRoomUpdate(flib_netconn *conn, void (*callback)(void *context, const char *oldName, const flib_room *room), void* context);

    /**
     * Callbacks for players joining or leaving the lobby. In contrast to the roomlist updates, you
     * will get a JOIN callback for every player already on the server when you join (and there is
     * no direct way to query the current playerlist)
     *
     * NOTE: partMessage may be NULL.
     */
    void flib_netconn_onLobbyJoin(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context);
    void flib_netconn_onLobbyLeave(flib_netconn *conn, void (*callback)(void *context, const char *nick, const char *partMessage), void* context);

    /**
     * This is called when the server informs us that one or more flags associated with a
     * player/client have changed.
     *
     * nick is the name of the player, flags is a string containing one character for each modified
     * flag (see below), and newFlagState signals whether the flags should be set to true or false.
     *
     * Some of these flags are important for protocol purposes (especially if they are set for you)
     * while others are just informational. Also, some flags are only relevant for players who are
     * in the same room as you, and the server will not inform you if they change for others.
     *
     * These are the currently known/used flags:
     * a: Server admin. Always updated.
     * h: Room chief. Updated when in the same room.
     * r: Ready to play. Updated when in the same room.
     * u: Registered user. Always updated.
     *
     * The server tells us the 'a' and 'u' flags for all players when we first join the lobby, and
     * also tells us the 'r' and 'h' flags when we join or create a room. It assumes that all flags
     * are initially false, so it will typically only tell you to set certain flags to true when
     * transmitting the initial states. Reset the 'h' and 'r' flags to false when leaving a room,
     * or when entering room state, to arrive at the right state for each player.
     *
     * The room chief state of yourself is particularly important because it determines whether you
     * can modify settings of the current room. Generally, when you create a room you start out
     * being room chief, and when you join an existing room you are not. However, if the original
     * chief leaves a room, the server can choose a new chief, and if that happens the chief flag
     * will be transferred to someone else.
     */
    void flib_netconn_onClientFlags(flib_netconn *conn, void (*callback)(void *context, const char *nick, const char *flags, bool newFlagState), void *context);

// Callbacks that happen only in response to specific requests

    /**
     * Response to flib_netconn_send_request_roomlist().
     * The rooms array contains the current state of all rooms on the server.
     */
    void flib_netconn_onRoomlist(flib_netconn *conn, void (*callback)(void *context, const flib_room **rooms, int roomCount), void* context);

    /**
     * Response to flib_netconn_send_joinRoom, flib_netconn_send_playerFollow or
     * flib_netconn_send_createRoom.
     *
     * You just left the lobby and entered a room.
     * If chief is true, you can and should send a full configuration for the room now. This
     * consists of ammo, scheme, script and map, where map apparently has to come last.
     */
    void flib_netconn_onEnterRoom(flib_netconn *conn, void (*callback)(void *context, bool chief), void *context);

    /**
     * Response to flib_netconn_send_addTeam.
     * The server might reject your team for several reasons, e.g. because it has the same name as
     * an existing team, or because the room chief restricted adding new teams. If the team is
     * accepted by the server, this callback is fired.
     *
     * If you are the room chief, you are expected to provide the hog count for your own team now
     * using flib_netconn_send_teamHogCount. The color of the team is already set to the one you
     * provided in addTeam.
     */
    void flib_netconn_onTeamAccepted(flib_netconn *conn, void (*callback)(void *context, const char *team), void *context);

    /**
     * When you query the server vars with flib_netconn_send_getServerVars (only works as admin),
     * the server replies with a list of them. This callback is called for each entry in that list.
     */
    void flib_netconn_onServerVar(flib_netconn *conn, void (*callback)(void *context, const char *name, const char *value), void *context);


// Callbacks that are only relevant in a room

    /**
     * You just left a room and entered the lobby again.
     * reason is one of the NETCONN_ROOMLEAVE_ constants (usually a kick).
     * This will not be called when you actively leave a room using PART.
     * Don't confuse with onRoomLeave, which indicates that *someone else* left the room.
     */
    void flib_netconn_onLeaveRoom(flib_netconn *conn, void (*callback)(void *context, int reason, const char *message), void *context);

    /**
     * Someone joined or left the room you are currently in.
     * Analogous to onLobbyJoin/leave, you will receive the join callback for all players that are
     * already in the room when you join, including for yourself (this is actually how it is
     * determined that you joined a room).
     *
     * However, you will *not* receive onRoomLeave messages for everyone when you leave the room.
     */
    void flib_netconn_onRoomJoin(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context);
    void flib_netconn_onRoomLeave(flib_netconn *conn, void (*callback)(void *context, const char *nick, const char *partMessage), void* context);

    /**
     * A new team was added to the room. The person who adds a team does NOT receive this callback
     * (he gets onTeamAccepted instead).
     *
     * The team does not contain bindings, stats, weaponset, color or the number of hogs (but it is
     * assumed to be the default of 4).
     *
     * If you receive this message and you are the room chief, you may want to send a color and hog
     * count for this team using flib_netconn_send_teamHogCount / teamColor for QtFrontend
     * compatibility.
     *
     * The server currently sends another message with the color of the team to the same recipients
     * as this teamAdd message, which will trigger an onTeamColorChanged callback. See the
     * description of flib_netconn_send_addTeam for more information.
     */
    void flib_netconn_onTeamAdd(flib_netconn *conn, void (*callback)(void *context, const flib_team *team), void *context);

    /**
     * A team was removed from the room. The person who removed the team will not receive this
     * callback.
     */
    void flib_netconn_onTeamDelete(flib_netconn *conn, void (*callback)(void *context, const char *teamname), void *context);

    /**
     * The number of hogs in a team has been changed by the room chief. If you are the chief and
     * change the number of hogs yourself, you will not receive this callback.
     */
    void flib_netconn_onHogCountChanged(flib_netconn *conn, void (*callback)(void *context, const char *teamName, int hogs), void *context);

    /**
     * The color of a team has been set or changed. The client who set or changed the color will
     * not receive this callback.
     *
     * Normally, only the chief can change the color of a team. However, this message is also
     * generated when a team is added, so you can receive it even as chief.
     */
    void flib_netconn_onTeamColorChanged(flib_netconn *conn, void (*callback)(void *context, const char *teamName, int colorIndex), void *context);

    /**
     * The room chief has changed the game scheme (or you just joined a room).
     * You will not receive this callback if you changed the scheme yourself.
     */
    void flib_netconn_onSchemeChanged(flib_netconn *conn, void (*callback)(void *context, const flib_scheme *scheme), void *context);

    /**
     * The room chief has changed the map (or you just joined a room). Only non-chiefs receive these
     * messages.
     *
     * To reduce the number of callback functions, the netconn keeps track of the current map
     * settings and always passes the entire current map config, but informs the callee about what
     * has changed (see the NETCONN_MAPCHANGE_ constants).
     *
     * Caution: Due to the way the protocol works, the map might not be complete at this point if it
     * is a hand-drawn map, because the "full" map config does not include the drawn map data.
     */
    void flib_netconn_onMapChanged(flib_netconn *conn, void (*callback)(void *context, const flib_map *map, int changetype), void *context);

    /**
     * The room chief has changed the game style (or you just joined a room). If you are the chief
     * and change the style yourself, you will not receive this callback.
     */
    void flib_netconn_onScriptChanged(flib_netconn *conn, void (*callback)(void *context, const char *script), void *context);

    /**
     * The room chief has changed the weaponset (or you just joined a room). If you are the chief
     * and change the weaponset yourself, you will not receive this callback.
     */
    void flib_netconn_onWeaponsetChanged(flib_netconn *conn, void (*callback)(void *context, const flib_weaponset *weaponset), void *context);

    /**
     * The game is starting. Fire up the engine and join in!
     * You can let the netconn generate the right game setup using flib_netconn_create_gamesetup
     */
    void flib_netconn_onRunGame(flib_netconn *conn, void (*callback)(void *context), void *context);

    /**
     * You are in a room, a game is in progress, and the server is sending you the new input for the
     * engine to keep up to date with the current happenings. Pass it on to the engine using
     * flib_gameconn_send_enginemsg.
     */
    void flib_netconn_onEngineMessage(flib_netconn *conn, void (*callback)(void *context, const uint8_t *message, size_t size), void *context);

#endif
