#include "netconn_internal.h"

#include "../util/logging.h"
#include "../util/util.h"

#include <string.h>
#include <stdlib.h>
#include <ctype.h>

static void defaultCallback_onMessage(void *context, int msgtype, const char *msg) {
	flib_log_i("Net: [%i] %s", msgtype, msg);
}

static void defaultCallback_onChat(void *context, const char *nick, const char *msg) {
	flib_log_i("%s: %s", nick, msg);
}

// Change the name by suffixing it with a number. If it already ends in a number, increase that number by 1.
static void defaultCallback_onNickTaken(void *context, const char *requestedNick) {
	flib_netconn *conn = context;
	size_t namelen = strlen(requestedNick);
	int digits = 0;
	while(digits<namelen && isdigit(requestedNick[namelen-1-digits])) {
		digits++;
	}
	long suffix = 0;
	if(digits>0) {
		suffix = atol(requestedNick+namelen-digits)+1;
	}
	char *newPlayerName = flib_asprintf("%.*s%li", namelen-digits, requestedNick, suffix);
	if(newPlayerName) {
		flib_netconn_send_nick(conn, newPlayerName);
	} else {
		flib_netconn_send_quit(conn, "Nick already taken.");
	}
	free(newPlayerName);
}

// Default behavior: Quit
static void defaultCallback_onPasswordRequest(void *context, const char *requestedNick) {
	flib_netconn_send_quit((flib_netconn*)context, "Authentication failed");
}

void clearCallbacks(flib_netconn *conn) {
	flib_netconn_onMessage(conn, NULL, NULL);
	flib_netconn_onConnected(conn, NULL, NULL);
	flib_netconn_onDisconnected(conn, NULL, NULL);
	flib_netconn_onRoomAdd(conn, NULL, NULL);
	flib_netconn_onRoomDelete(conn, NULL, NULL);
	flib_netconn_onRoomUpdate(conn, NULL, NULL);
	flib_netconn_onChat(conn, NULL, NULL);
	flib_netconn_onLobbyJoin(conn, NULL, NULL);
	flib_netconn_onLobbyLeave(conn, NULL, NULL);
	flib_netconn_onRoomJoin(conn, NULL, NULL);
	flib_netconn_onRoomLeave(conn, NULL, NULL);
	flib_netconn_onNickTaken(conn, NULL, NULL);
	flib_netconn_onPasswordRequest(conn, NULL, NULL);
	flib_netconn_onRoomChiefStatus(conn, NULL, NULL);
	flib_netconn_onReadyState(conn, NULL, NULL);
	flib_netconn_onEnterRoom(conn, NULL, NULL);
	flib_netconn_onLeaveRoom(conn, NULL, NULL);
	flib_netconn_onTeamAdd(conn, NULL, NULL);
	flib_netconn_onTeamDelete(conn, NULL, NULL);
	flib_netconn_onRunGame(conn, NULL, NULL);
	flib_netconn_onTeamAccepted(conn, NULL, NULL);
	flib_netconn_onHogCountChanged(conn, NULL, NULL);
	flib_netconn_onTeamColorChanged(conn, NULL, NULL);
	flib_netconn_onEngineMessage(conn, NULL, NULL);
	flib_netconn_onCfgScheme(conn, NULL, NULL);
	flib_netconn_onMapChanged(conn, NULL, NULL);
	flib_netconn_onScriptChanged(conn, NULL, NULL);
	flib_netconn_onWeaponsetChanged(conn, NULL, NULL);
	flib_netconn_onAdminAccess(conn, NULL, NULL);
	flib_netconn_onServerVar(conn, NULL, NULL);
}

/**
 * This macro generates a callback setter function. It uses the name of the callback to
 * automatically generate the function name and the fields to set, so a consistent naming
 * convention needs to be enforced (not that that is a bad thing). If null is passed as
 * callback to the generated function, the defaultCb will be set instead (with conn
 * as the context).
 */
#define GENERATE_CB_SETTER(cbName, cbParameterTypes, defaultCb) \
	void flib_netconn_##cbName(flib_netconn *conn, void (*callback)cbParameterTypes, void *context) { \
		if(!conn) { \
			flib_log_e("null parameter in flib_netconn_%s", #cbName); \
		} else { \
			conn->cbName##Cb = callback ? callback : &defaultCb; \
			conn->cbName##Ctx = callback ? context : conn; \
		} \
	}

/**
 * Generate a callback setter function like GENERATE_CB_SETTER, and automatically generate a
 * no-op callback function as well that is used as default.
 */
#define GENERATE_CB_SETTER_AND_DEFAULT(cbName, cbParameterTypes) \
	static void _noop_callback_##cbName cbParameterTypes {} \
	GENERATE_CB_SETTER(cbName, cbParameterTypes, _noop_callback_##cbName)

GENERATE_CB_SETTER(onMessage, (void *context, int msgtype, const char *msg), defaultCallback_onMessage);
GENERATE_CB_SETTER_AND_DEFAULT(onConnected, (void *context));
GENERATE_CB_SETTER_AND_DEFAULT(onDisconnected, (void *context, int reason, const char *message));
GENERATE_CB_SETTER_AND_DEFAULT(onRoomAdd, (void *context, const flib_roomlist_room *room));
GENERATE_CB_SETTER_AND_DEFAULT(onRoomDelete, (void *context, const char *name));
GENERATE_CB_SETTER_AND_DEFAULT(onRoomUpdate, (void *context, const char *oldName, const flib_roomlist_room *room));
GENERATE_CB_SETTER(onChat, (void *context, const char *nick, const char *msg), defaultCallback_onChat);
GENERATE_CB_SETTER_AND_DEFAULT(onLobbyJoin, (void *context, const char *nick));
GENERATE_CB_SETTER_AND_DEFAULT(onLobbyLeave, (void *context, const char *nick, const char *partMsg));
GENERATE_CB_SETTER_AND_DEFAULT(onRoomJoin, (void *context, const char *nick));
GENERATE_CB_SETTER_AND_DEFAULT(onRoomLeave, (void *context, const char *nick, const char *partMessage));
GENERATE_CB_SETTER(onNickTaken, (void *context, const char *nick), defaultCallback_onNickTaken);
GENERATE_CB_SETTER(onPasswordRequest, (void *context, const char *nick), defaultCallback_onPasswordRequest);
GENERATE_CB_SETTER_AND_DEFAULT(onRoomChiefStatus, (void *context, bool chief));
GENERATE_CB_SETTER_AND_DEFAULT(onReadyState, (void *context, const char *nick, bool ready));
GENERATE_CB_SETTER_AND_DEFAULT(onEnterRoom, (void *context, bool chief));
GENERATE_CB_SETTER_AND_DEFAULT(onLeaveRoom, (void *context, int reason, const char *message));
GENERATE_CB_SETTER_AND_DEFAULT(onTeamAdd, (void *context, flib_team *team));
GENERATE_CB_SETTER_AND_DEFAULT(onTeamDelete, (void *context, const char *teamname));
GENERATE_CB_SETTER_AND_DEFAULT(onRunGame, (void *context));
GENERATE_CB_SETTER_AND_DEFAULT(onTeamAccepted, (void *context, const char *teamName));
GENERATE_CB_SETTER_AND_DEFAULT(onHogCountChanged, (void *context, const char *teamName, int hogs));
GENERATE_CB_SETTER_AND_DEFAULT(onTeamColorChanged, (void *context, const char *teamName, uint32_t colorRGB));
GENERATE_CB_SETTER_AND_DEFAULT(onEngineMessage, (void *context, const char *message, int size));
GENERATE_CB_SETTER_AND_DEFAULT(onCfgScheme, (void *context, flib_cfg *scheme));
GENERATE_CB_SETTER_AND_DEFAULT(onMapChanged, (void *context, const flib_map *map, int changetype));
GENERATE_CB_SETTER_AND_DEFAULT(onScriptChanged, (void *context, const char *script));
GENERATE_CB_SETTER_AND_DEFAULT(onWeaponsetChanged, (void *context, flib_weaponset *weaponset));
GENERATE_CB_SETTER_AND_DEFAULT(onAdminAccess, (void *context));
GENERATE_CB_SETTER_AND_DEFAULT(onServerVar, (void *context, const char *name, const char *value));

#undef GENERATE_CB_SETTER_AND_DEFAULT
#undef GENERATE_CB_SETTER
