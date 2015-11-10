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
 * Common definitions needed by netconn functions, to allow splitting them into several files.
 */

#ifndef NETCONN_INTERNAL_H_
#define NETCONN_INTERNAL_H_

#include "netconn.h"
#include "netbase.h"
#include "../model/map.h"
#include "../model/team.h"
#include "../model/weapon.h"
#include "../model/room.h"

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

struct _flib_netconn {
    flib_netbase *netBase;
    char *playerName;
    char *dataDirPath;

    int netconnState;           //!< One of the NETCONN_STATE constants

    bool isChief;               //!< Player can modify the current room
    flib_map *map;
    flib_teamlist pendingTeamlist;
    flib_teamlist teamlist;
    flib_scheme *scheme;
    char *style;
    flib_weaponset *weaponset;

    void (*onMessageCb)(void *context, int msgtype, const char *msg);
    void *onMessageCtx;

    void (*onConnectedCb)(void *context);
    void *onConnectedCtx;

    void (*onDisconnectedCb)(void *context, int reason, const char *message);
    void *onDisconnectedCtx;

    void (*onRoomlistCb)(void *context, const flib_room **rooms, int roomCount);
    void *onRoomlistCtx;

    void (*onRoomAddCb)(void *context, const flib_room *room);
    void *onRoomAddCtx;

    void (*onRoomDeleteCb)(void *context, const char *name);
    void *onRoomDeleteCtx;

    void (*onRoomUpdateCb)(void *context, const char *oldName, const flib_room *room);
    void *onRoomUpdateCtx;

    void (*onClientFlagsCb)(void *context, const char *nick, const char *flags, bool newFlagState);
    void *onClientFlagsCtx;

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

    void (*onEnterRoomCb)(void *context, bool chief);
    void *onEnterRoomCtx;

    void (*onLeaveRoomCb)(void *context, int reason, const char *message);
    void *onLeaveRoomCtx;

    void (*onTeamAddCb)(void *context, const flib_team *team);
    void *onTeamAddCtx;

    void (*onTeamDeleteCb)(void *context, const char *teamname);
    void *onTeamDeleteCtx;

    void (*onRunGameCb)(void *context);
    void *onRunGameCtx;

    void (*onTeamAcceptedCb)(void *context, const char *teamName);
    void *onTeamAcceptedCtx;

    void (*onHogCountChangedCb)(void *context, const char *teamName, int hogs);
    void *onHogCountChangedCtx;

    void (*onTeamColorChangedCb)(void *context, const char *teamName, int colorIndex);
    void *onTeamColorChangedCtx;

    void (*onEngineMessageCb)(void *context, const uint8_t *message, size_t size);
    void *onEngineMessageCtx;

    void (*onSchemeChangedCb)(void *context, const flib_scheme *scheme);
    void *onSchemeChangedCtx;

    void (*onMapChangedCb)(void *context, const flib_map *map, int changetype);
    void *onMapChangedCtx;

    void (*onScriptChangedCb)(void *context, const char *script);
    void *onScriptChangedCtx;

    void (*onWeaponsetChangedCb)(void *context, const flib_weaponset *weaponset);
    void *onWeaponsetChangedCtx;

    void (*onServerVarCb)(void *context, const char *name, const char *value);
    void *onServerVarCtx;

    bool running;
    bool destroyRequested;
};

void netconn_clearCallbacks(flib_netconn *conn);
void netconn_leaveRoom(flib_netconn *conn);
void netconn_setMap(flib_netconn *conn, const flib_map *map);
void netconn_setWeaponset(flib_netconn *conn, const flib_weaponset *weaponset);
void netconn_setScript(flib_netconn *conn, const char *script);
void netconn_setScheme(flib_netconn *conn, const flib_scheme *scheme);

#endif
