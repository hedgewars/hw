/**
 * Common definitions needed by netconn functions, to allow splitting them into several files.
 */

#ifndef NETCONN_INTERNAL_H_
#define NETCONN_INTERNAL_H_

#include "netconn.h"
#include "netbase.h"
#include "../model/cfg.h"
#include "../model/roomlist.h"
#include "../model/map.h"
#include "../model/team.h"
#include "../model/weapon.h"

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

struct _flib_netconn {
	flib_netbase *netBase;
	char *playerName;
	flib_cfg_meta *metaCfg;
	flib_roomlist *roomList;

	int netconnState;	// One of the NETCONN_STATE constants

	bool isAdmin;			// Player is server administrator
	bool isChief;			// Player can modify the current room
	flib_map *map;			// Map settings in the current room.

	void (*onMessageCb)(void *context, int msgtype, const char *msg);
	void *onMessageCtx;

	void (*onConnectedCb)(void *context);
	void *onConnectedCtx;

	void (*onDisconnectedCb)(void *context, int reason, const char *message);
	void *onDisconnectedCtx;

	void (*onRoomAddCb)(void *context, const flib_roomlist_room *room);
	void *onRoomAddCtx;

	void (*onRoomDeleteCb)(void *context, const char *name);
	void *onRoomDeleteCtx;

	void (*onRoomUpdateCb)(void *context, const char *oldName, const flib_roomlist_room *room);
	void *onRoomUpdateCtx;

	void (*onChatCb)(void *context, const char *nick, const char *msg);
	void *onChatCtx;

	void (*onLobbyJoinCb)(void *context, const char *nick);
	void *onLobbyJoinCtx;

	void (*onLobbyLeaveCb)(void *context, const char *nick, const char *partMessage);
	void *onLobbyLeaveCtx;

	void (*onRoomJoinCb)(void *context, const char *nick);
	void *onRoomJoinCtx;

	void (*onRoomLeaveCb)(void *context, const char *nick, const char *partMessage);
	void *onRoomLeaveCtx;

	void (*onNickTakenCb)(void *context, const char *nick);
	void *onNickTakenCtx;

	void (*onPasswordRequestCb)(void *context, const char *nick);
	void *onPasswordRequestCtx;

	void (*onRoomChiefStatusCb)(void *context, bool isChief);
	void *onRoomChiefStatusCtx;

	void (*onReadyStateCb)(void *context, const char *nick, bool ready);
	void *onReadyStateCtx;

	void (*onEnterRoomCb)(void *context, bool chief);
	void *onEnterRoomCtx;

	void (*onLeaveRoomCb)(void *context, int reason, const char *message);
	void *onLeaveRoomCtx;

	void (*onTeamAddCb)(void *context, flib_team *team);
	void *onTeamAddCtx;

	void (*onTeamDeleteCb)(void *context, const char *teamname);
	void *onTeamDeleteCtx;

	void (*onRunGameCb)(void *context);
	void *onRunGameCtx;

	void (*onTeamAcceptedCb)(void *context, const char *teamName);
	void *onTeamAcceptedCtx;

	void (*onHogCountChangedCb)(void *context, const char *teamName, int hogs);
	void *onHogCountChangedCtx;

	void (*onTeamColorChangedCb)(void *context, const char *teamName, uint32_t colorRGB);
	void *onTeamColorChangedCtx;

	void (*onEngineMessageCb)(void *context, const char *message, int size);
	void *onEngineMessageCtx;

	void (*onCfgSchemeCb)(void *context, flib_cfg *scheme);
	void *onCfgSchemeCtx;

	void (*onMapChangedCb)(void *context, const flib_map *map, int changetype);
	void *onMapChangedCtx;

	void (*onScriptChangedCb)(void *context, const char *script);
	void *onScriptChangedCtx;

	void (*onWeaponsetChangedCb)(void *context, flib_weaponset *weaponset);
	void *onWeaponsetChangedCtx;

	void (*onAdminAccessCb)(void *context);
	void *onAdminAccessCtx;

	void (*onServerVarCb)(void *context, const char *name, const char *value);
	void *onServerVarCtx;

	bool running;
	bool destroyRequested;
};

void clearCallbacks(flib_netconn *conn);

#endif
