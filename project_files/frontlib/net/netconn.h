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


struct _flib_netconn;
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
 * Note: Most other functions in this lib accept UTF-8, but the password needs to be
 * sent as latin1
 */
int flib_netconn_send_password(flib_netconn *conn, const char *latin1Passwd);

/**
 * Request a different nickname.
 * This function only makes sense in reaction to an onNickTaken callback, because the netconn automatically
 * requests the nickname you provide on creation, and once the server accepts the nickname (onNickAccept)
 * it can no longer be changed.
 *
 * As a response to the nick change request, the server will either reply with a confirmation (onNickAccept)
 * or a rejection (onNickTaken). Note that the server confirms a nick even if it is password protected, the
 * password request happens afterwards.
 */
int flib_netconn_send_nick(flib_netconn *conn, const char *nick);

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
 * Callbacks for players joining or leaving a room or the lobby. If join is true it's a join, otherwise a leave.
 * NOTE: partMessage is null if no parting message was given.
 */
void flib_netconn_onLobbyJoin(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context);
void flib_netconn_onLobbyLeave(flib_netconn *conn, void (*callback)(void *context, const char *nick, const char *partMessage), void* context);
void flib_netconn_onRoomJoin(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context);
void flib_netconn_onRoomLeave(flib_netconn *conn, void (*callback)(void *context, const char *nick, const char *partMessage), void* context);

/**
 * onNickTaken is called on connecting to the server, if it turns out that there is already a player with the same nick.
 * In order to proceed, a new nickname needs to be sent to the server using flib_netconn_send_nick() (or of course you can
 * bail out and send a QUIT). If you don't set a callback, the netconn will automatically react by generating a new name.
 * Once the server accepts a name, you will be informed with an onNickAccept callback.
 */
void flib_netconn_onNickTaken(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context);

/**
 * onNickAccept informs that your nickname has been accepted by the server, i.e. there was nobody with that nick already
 * on the server.
 * Note that a nick request is sent automatically by the netconn when you join the server, so you should receive this
 * callback shortly after connecting.
 */
void flib_netconn_onNickAccept(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context);

/**
 * When connecting with a registered nickname, the server will ask for a password before admitting you in.
 * This callback is called when that happens. As a reaction, you can send the password using
 * flib_netconn_send_password or choose a different nick. If you don't register a callback,
 * the default behavior is to just quit in a way that will cause a disconnect with NETCONN_DISCONNECT_AUTH_FAILED.
 */
void flib_netconn_onPasswordRequest(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context);

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
void flib_netconn_onReadyStateCb(flib_netconn *conn, void (*callback)(void *context, const char *nick, bool ready), void* context);

/**
 * You just left the lobby and entered a room.
 * If chief is true, you can and should send a full configuration for the room now.
 */
void flib_netconn_onEnterRoomCb(flib_netconn *conn, void (*callback)(void *context, bool chief), void *context);

/**
 * You just left a room and entered the lobby again.
 * reason is one of the NETCONN_ROOMLEAVE_ constants.
 * This will not be called when you actively leave a room using PART.
 */
void flib_netconn_onLeaveRoomCb(flib_netconn *conn, void (*callback)(void *context, int reason, const char *message), void *context);

void flib_netconn_onTeamAddCb(flib_netconn *conn, void (*callback)(void *context, flib_team *team), void *context);

#endif
