/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
 * Copyright (c) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "netconn_internal.h"
#include "netprotocol.h"
#include "../util/logging.h"
#include "../util/util.h"
#include "../md5/md5.h"
#include "../base64/base64.h"
#include "../model/mapcfg.h"

#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>

flib_netconn *flib_netconn_create(const char *playerName, const char *dataDirPath, const char *host, int port) {
    flib_netconn *result = NULL;
    if(!log_badargs_if4(playerName==NULL, host==NULL, port<1, port>65535)) {
        flib_netconn *newConn = flib_calloc(1, sizeof(flib_netconn));
        if(newConn) {
            newConn->netBase = flib_netbase_create(host, port);
            newConn->playerName = flib_strdupnull(playerName);
            newConn->dataDirPath = flib_strdupnull(dataDirPath);

            newConn->netconnState = NETCONN_STATE_CONNECTING;

            newConn->isChief = false;
            newConn->map = flib_map_create_named("", "NoSuchMap");
            newConn->pendingTeamlist.teamCount = 0;
            newConn->pendingTeamlist.teams = NULL;
            newConn->teamlist.teamCount = 0;
            newConn->teamlist.teams = NULL;
            newConn->scheme = NULL;
            newConn->style = NULL;
            newConn->weaponset = NULL;

            newConn->running = false;
            newConn->destroyRequested = false;
            netconn_clearCallbacks(newConn);
            if(newConn->netBase && newConn->playerName && newConn->dataDirPath && newConn->map) {
                result = newConn;
                newConn = NULL;
            }
        }
        flib_netconn_destroy(newConn);
    }
    return result;
}

void flib_netconn_destroy(flib_netconn *conn) {
    if(conn) {
        if(conn->running) {
            /*
             * The function was called from a callback, so the tick function is still running
             * and we delay the actual destruction. We ensure no further callbacks will be
             * sent to prevent surprises.
             */
            netconn_clearCallbacks(conn);
            conn->destroyRequested = true;
        } else {
            flib_netbase_destroy(conn->netBase);
            free(conn->playerName);
            free(conn->dataDirPath);

            flib_map_destroy(conn->map);
            flib_teamlist_clear(&conn->pendingTeamlist);
            flib_teamlist_clear(&conn->teamlist);
            flib_scheme_destroy(conn->scheme);
            free(conn->style);
            flib_weaponset_destroy(conn->weaponset);

            free(conn);
        }
    }
}

bool flib_netconn_is_chief(flib_netconn *conn) {
    if(!log_badargs_if(conn==NULL) && conn->netconnState==NETCONN_STATE_ROOM) {
        return conn->isChief;
    }
    return false;
}

const char *flib_netconn_get_playername(flib_netconn *conn) {
    if(!log_badargs_if(conn==NULL)) {
        return conn->playerName;
    }
    return NULL;
}

void netconn_leaveRoom(flib_netconn *conn) {
    conn->netconnState = NETCONN_STATE_LOBBY;
    conn->isChief = false;
    flib_map_destroy(conn->map);
    conn->map = flib_map_create_named("", "NoSuchMap");
    flib_teamlist_clear(&conn->pendingTeamlist);
    flib_teamlist_clear(&conn->teamlist);
    flib_scheme_destroy(conn->scheme);
    conn->scheme = NULL;
    free(conn->style);
    conn->style = NULL;
    flib_weaponset_destroy(conn->weaponset);
    conn->weaponset = NULL;
}

void netconn_setMap(flib_netconn *conn, const flib_map *map) {
    flib_map *copy = flib_map_copy(map);
    if(copy) {
        flib_map_destroy(conn->map);
        conn->map = copy;
    }
}

void netconn_setWeaponset(flib_netconn *conn, const flib_weaponset *weaponset) {
    flib_weaponset *copy = flib_weaponset_copy(weaponset);
    if(copy) {
        flib_weaponset_destroy(conn->weaponset);
        conn->weaponset = copy;
    }
}

void netconn_setScript(flib_netconn *conn, const char *script) {
    char *copy = flib_strdupnull(script);
    if(copy) {
        free(conn->style);
        conn->style = copy;
    }
}

void netconn_setScheme(flib_netconn *conn, const flib_scheme *scheme) {
    flib_scheme *copy = flib_scheme_copy(scheme);
    if(copy) {
        flib_scheme_destroy(conn->scheme);
        conn->scheme = copy;
    }
}

flib_gamesetup *flib_netconn_create_gamesetup(flib_netconn *conn) {
    flib_gamesetup *result = NULL;
    if(!log_badargs_if(conn==NULL)) {
        if(conn->teamlist.teamCount==0 || !conn->scheme || !conn->weaponset) {
            flib_log_e("Incomplete room state");
        } else {
            flib_gamesetup stackSetup = {0};
            stackSetup.gamescheme = conn->scheme;
            stackSetup.map = conn->map;
            stackSetup.style = conn->style;
            stackSetup.teamlist = &conn->teamlist;
            result = flib_gamesetup_copy(&stackSetup);
            if(result) {
                bool error = false;
                for(int i=0; i<result->teamlist->teamCount; i++) {
                    if(flib_team_set_weaponset(result->teamlist->teams[i], conn->weaponset)) {
                        error = true;
                    }
                    flib_team_set_health(result->teamlist->teams[i], flib_scheme_get_setting(conn->scheme, "health", 100));
                }
                if(result->map->mapgen == MAPGEN_NAMED && result->map->name) {
                    flib_mapcfg mapcfg;
                    if(!flib_mapcfg_read(conn->dataDirPath, result->map->name, &mapcfg)) {
                        free(result->map->theme);
                        result->map->theme = flib_strdupnull(mapcfg.theme);
                        if(!result->map->theme) {
                            error = true;
                        }
                    } else {
                        flib_log_e("Unable to read map config for map %s", result->map->name);
                    }
                }
                if(error) {
                    flib_gamesetup_destroy(result);
                    result = NULL;
                }
            }
        }
    }
    return result;
}

static void flib_netconn_wrappedtick(flib_netconn *conn) {
    flib_netmsg *netmsg;
    flib_netbase *net = conn->netBase;
    bool exit = false;

    while(!exit && !conn->destroyRequested && (netmsg=flib_netbase_recv_message(conn->netBase))) {
        if(netmsg->partCount==0) {
            flib_log_w("Empty server message");
            continue;
        }

        if(flib_log_isActive(FLIB_LOGLEVEL_DEBUG)) {
            char *buf = flib_join(netmsg->parts, netmsg->partCount, "|");
            if(buf) {
                flib_log_d("[Net In]%s", buf);
            }
            free(buf);
        }

        const char *cmd = netmsg->parts[0];

        if (!strcmp(cmd, "NICK") && netmsg->partCount>=2) {
            if(netmsg->partCount<2) {
                flib_log_w("Net: Malformed NICK message");
            } else {
                char *nick = flib_strdupnull(netmsg->parts[1]);
                if(nick) {
                    free(conn->playerName);
                    conn->playerName = nick;
                } else {
                    conn->netconnState = NETCONN_STATE_DISCONNECTED;
                    conn->onDisconnectedCb(conn->onDisconnectedCtx, NETCONN_DISCONNECT_INTERNAL_ERROR, "Out of memory");
                    exit = true;
                }
            }
        } else if (!strcmp(cmd, "PROTO")) {
            // The server just echoes this back apparently
        } else if (!strcmp(cmd, "ERROR")) {
            if (netmsg->partCount >= 2) {
                conn->onMessageCb(conn->onMessageCtx, NETCONN_MSG_TYPE_ERROR, netmsg->parts[1]);
            } else {
                conn->onMessageCb(conn->onMessageCtx, NETCONN_MSG_TYPE_ERROR, "Unknown Error");
            }
        } else if(!strcmp(cmd, "WARNING")) {
            if (netmsg->partCount >= 2) {
                conn->onMessageCb(conn->onMessageCtx, NETCONN_MSG_TYPE_WARNING, netmsg->parts[1]);
            } else {
                conn->onMessageCb(conn->onMessageCtx, NETCONN_MSG_TYPE_WARNING, "Unknown Warning");
            }
        } else if(!strcmp(cmd, "CONNECTED")) {
            if(netmsg->partCount<3 || atol(netmsg->parts[2])<MIN_SERVER_VERSION) {
                flib_log_w("Net: Server too old");
                flib_netbase_sendf(net, "%s\n%s\n\n", "QUIT", "Server too old");
                conn->netconnState = NETCONN_STATE_DISCONNECTED;
                conn->onDisconnectedCb(conn->onDisconnectedCtx, NETCONN_DISCONNECT_SERVER_TOO_OLD, "Server too old");
                exit = true;
            } else {
                flib_netbase_sendf(net, "%s\n%s\n\n", "NICK", conn->playerName);
                flib_netbase_sendf(net, "%s\n%i\n\n", "PROTO", (int)PROTOCOL_VERSION);
            }
        } else if(!strcmp(cmd, "PING")) {
            if (netmsg->partCount > 1) {
                flib_netbase_sendf(net, "%s\n%s\n\n", "PONG", netmsg->parts[1]);
            } else {
                flib_netbase_sendf(net, "%s\n\n", "PONG");
            }
        } else if(!strcmp(cmd, "ROOMS")) {
            if(netmsg->partCount % 8 != 1) {
                flib_log_w("Net: Malformed ROOMS message");
            } else {
                int roomCount = netmsg->partCount/8;
                flib_room **rooms = flib_room_array_from_netmsg(netmsg->parts+1, roomCount);
                if(rooms) {
                    conn->onRoomlistCb(conn->onRoomlistCtx, (const flib_room**)rooms, roomCount);
                    for(int i=0; i<roomCount; i++) {
                        flib_room_destroy(rooms[i]);
                    }
                    free(rooms);
                }
            }
        } else if (!strcmp(cmd, "SERVER_MESSAGE")) {
            if(netmsg->partCount < 2) {
                flib_log_w("Net: Empty SERVERMESSAGE message");
            } else {
                conn->onMessageCb(conn->onMessageCtx, NETCONN_MSG_TYPE_SERVERMESSAGE, netmsg->parts[1]);
            }
        } else if (!strcmp(cmd, "CHAT")) {
            if(netmsg->partCount < 3) {
                flib_log_w("Net: Empty CHAT message");
            } else {
                conn->onChatCb(conn->onChatCtx, netmsg->parts[1], netmsg->parts[2]);
            }
        } else if (!strcmp(cmd, "INFO")) {
            if(netmsg->partCount < 5) {
                flib_log_w("Net: Malformed INFO message");
            } else {
                char *joined = flib_join(netmsg->parts+1, netmsg->partCount-1, "\n");
                if(joined) {
                    conn->onMessageCb(conn->onMessageCtx, NETCONN_MSG_TYPE_PLAYERINFO, joined);
                }
                free(joined);
            }
        } else if(!strcmp(cmd, "SERVER_VARS")) {
            for(int offset=1; offset+2<netmsg->partCount; offset+=2) {
                conn->onServerVarCb(conn->onServerVarCtx, netmsg->parts[offset], netmsg->parts[offset+1]);
            }
        } else if (!strcmp(cmd, "CLIENT_FLAGS")) {
            if(netmsg->partCount < 3 || strlen(netmsg->parts[1]) < 2) {
                flib_log_w("Net: Malformed CLIENT_FLAGS message");
            } else {
                const char *flags = netmsg->parts[1];
                bool setFlag = flags[0] == '+';

                for(int j = 2; j < netmsg->partCount; ++j) {
                    bool isSelf = !strcmp(conn->playerName, netmsg->parts[j]);
                    if(isSelf && strchr(flags, 'h')) {
                        conn->isChief = setFlag;
                    }
                    conn->onClientFlagsCb(conn->onClientFlagsCtx, netmsg->parts[j], flags+1, setFlag);
                }
            }
        } else if (!strcmp(cmd, "ADD_TEAM")) {
            if(netmsg->partCount != 24 || conn->netconnState!=NETCONN_STATE_ROOM) {
                flib_log_w("Net: Bad ADD_TEAM message");
            } else {
                flib_team *team = flib_team_from_netmsg(netmsg->parts+1);
                if(!team || flib_teamlist_insert(&conn->teamlist, team, conn->teamlist.teamCount)) {
                    flib_team_destroy(team);
                    conn->netconnState = NETCONN_STATE_DISCONNECTED;
                    conn->onDisconnectedCb(conn->onDisconnectedCtx, NETCONN_DISCONNECT_INTERNAL_ERROR, "Internal error");
                    exit = true;
                } else {
                    conn->onTeamAddCb(conn->onTeamAddCtx, team);
                }
            }
        } else if (!strcmp(cmd, "REMOVE_TEAM")) {
            if(netmsg->partCount != 2 || conn->netconnState!=NETCONN_STATE_ROOM) {
                flib_log_w("Net: Bad REMOVETEAM message");
            } else {
                flib_teamlist_delete(&conn->teamlist, netmsg->parts[1]);
                conn->onTeamDeleteCb(conn->onTeamDeleteCtx, netmsg->parts[1]);
            }
        } else if(!strcmp(cmd, "ROOMABANDONED")) {
            netconn_leaveRoom(conn);
            conn->onLeaveRoomCb(conn->onLeaveRoomCtx, NETCONN_ROOMLEAVE_ABANDONED, "Room destroyed");
        } else if(!strcmp(cmd, "KICKED")) {
            netconn_leaveRoom(conn);
            conn->onLeaveRoomCb(conn->onLeaveRoomCtx, NETCONN_ROOMLEAVE_KICKED, "You got kicked");
        } else if(!strcmp(cmd, "JOINED")) {
            if(netmsg->partCount < 2) {
                flib_log_w("Net: Bad JOINED message");
            } else {
                for(int i = 1; i < netmsg->partCount; ++i)
                {
                    bool isMe = !strcmp(conn->playerName, netmsg->parts[i]);
                    if (isMe) {
                        conn->netconnState = NETCONN_STATE_ROOM;
                        conn->onEnterRoomCb(conn->onEnterRoomCtx, conn->isChief);
                    }

                    conn->onRoomJoinCb(conn->onRoomJoinCtx, netmsg->parts[i]);
                }
            }
        } else if(!strcmp(cmd, "LOBBY:JOINED")) {
            if(netmsg->partCount < 2) {
                flib_log_w("Net: Bad JOINED message");
            } else {
                for(int i = 1; i < netmsg->partCount; ++i)
                {
                    bool isMe = !strcmp(conn->playerName, netmsg->parts[i]);
                    if (isMe && conn->netconnState == NETCONN_STATE_CONNECTING) {
                        conn->onConnectedCb(conn->onConnectedCtx);
                        conn->netconnState = NETCONN_STATE_LOBBY;
                    }
                    conn->onLobbyJoinCb(conn->onLobbyJoinCtx, netmsg->parts[i]);
                }
            }
        } else if(!strcmp(cmd, "LEFT")) {
            if(netmsg->partCount < 2) {
                flib_log_w("Net: Bad LEFT message");
            } else {
                conn->onRoomLeaveCb(conn->onRoomLeaveCtx, netmsg->parts[1], netmsg->partCount>2 ? netmsg->parts[2] : NULL);
            }
        } else if(!strcmp(cmd, "ROOM") && netmsg->partCount >= 2) {
            const char *subcmd = netmsg->parts[1];
            if(!strcmp(subcmd, "ADD") && netmsg->partCount == 10) {
                flib_room *room = flib_room_from_netmsg(netmsg->parts+2);
                if(room) {
                    conn->onRoomAddCb(conn->onRoomAddCtx, room);
                }
                flib_room_destroy(room);
            } else if(!strcmp(subcmd, "UPD") && netmsg->partCount == 11) {
                flib_room *room = flib_room_from_netmsg(netmsg->parts+3);
                if(room) {
                    conn->onRoomUpdateCb(conn->onRoomUpdateCtx, netmsg->parts[2], room);
                }
                flib_room_destroy(room);
            } else if(!strcmp(subcmd, "DEL") && netmsg->partCount == 3) {
                conn->onRoomDeleteCb(conn->onRoomDeleteCtx, netmsg->parts[2]);
            } else {
                flib_log_w("Net: Unknown or malformed ROOM subcommand: %s", subcmd);
            }
        } else if(!strcmp(cmd, "LOBBY:LEFT")) {
            if(netmsg->partCount < 2) {
                flib_log_w("Net: Bad LOBBY:LEFT message");
            } else {
                conn->onLobbyLeaveCb(conn->onLobbyLeaveCtx, netmsg->parts[1], netmsg->partCount>2 ? netmsg->parts[2] : NULL);
            }
        } else if (!strcmp(cmd, "RUN_GAME")) {
            conn->onRunGameCb(conn->onRunGameCtx);
        } else if (!strcmp(cmd, "ASKPASSWORD")) {
            conn->onPasswordRequestCb(conn->onPasswordRequestCtx, conn->playerName);
        } else if (!strcmp(cmd, "NOTICE")) {
            if(netmsg->partCount < 2) {
                flib_log_w("Net: Bad NOTICE message");
            } else {
                errno = 0;
                long n = strtol(netmsg->parts[1], NULL, 10);
                if(errno) {
                    flib_log_w("Net: Bad NOTICE message");
                } else if(n==0) {
                    conn->onNickTakenCb(conn->onNickTakenCtx, conn->playerName);
                } else {
                    flib_log_w("Net: Unknown NOTICE message: %l", n);
                }
            }
        } else if (!strcmp(cmd, "TEAM_ACCEPTED")) {
            if (netmsg->partCount != 2 || conn->netconnState!=NETCONN_STATE_ROOM) {
                flib_log_w("Net: Bad TEAM_ACCEPTED message");
            } else {
                flib_team *team = flib_team_copy(flib_teamlist_find(&conn->pendingTeamlist, netmsg->parts[1]));
                if(team) {
                    flib_teamlist_insert(&conn->teamlist, team, conn->teamlist.teamCount);
                    flib_teamlist_delete(&conn->pendingTeamlist, netmsg->parts[1]);
                } else {
                    flib_log_e("Team accepted that was not requested: %s", netmsg->parts[1]);
                }
                conn->onTeamAcceptedCb(conn->onTeamAcceptedCtx, netmsg->parts[1]);
            }
        } else if (!strcmp(cmd, "CFG")) {
            if(netmsg->partCount < 3 || conn->netconnState!=NETCONN_STATE_ROOM) {
                flib_log_w("Net: Bad CFG message");
            } else {
                const char *subcmd = netmsg->parts[1];
                if(!strcmp(subcmd, "SCHEME") && netmsg->partCount == flib_meta.modCount + flib_meta.settingCount + 3) {
                    flib_scheme *cfg = flib_scheme_from_netmsg(netmsg->parts+2);
                    if(cfg) {
                        flib_scheme_destroy(conn->scheme);
                        conn->scheme = cfg;
                        conn->onSchemeChangedCb(conn->onSchemeChangedCtx, cfg);
                    } else {
                        flib_log_e("Error processing CFG SCHEME message");
                    }
                } else if(!strcmp(subcmd, "FULLMAPCONFIG") && netmsg->partCount == 7) {
                    flib_map *map = flib_map_from_netmsg(netmsg->parts+2);
                    if(map) {
                        flib_map_destroy(conn->map);
                        conn->map = map;
                        conn->onMapChangedCb(conn->onMapChangedCtx, conn->map, NETCONN_MAPCHANGE_FULL);
                    } else {
                        flib_log_e("Error processing CFG FULLMAPCONFIG message");
                    }
                } else if(!strcmp(subcmd, "MAP") && netmsg->partCount == 3) {
                    char *mapname = flib_strdupnull(netmsg->parts[2]);
                    if(mapname) {
                        free(conn->map->name);
                        conn->map->name = mapname;
                        conn->onMapChangedCb(conn->onMapChangedCtx, conn->map, NETCONN_MAPCHANGE_MAP);
                    } else {
                        flib_log_e("Error processing CFG MAP message");
                    }
                } else if(!strcmp(subcmd, "THEME") && netmsg->partCount == 3) {
                    char *themename = flib_strdupnull(netmsg->parts[2]);
                    if(themename) {
                        free(conn->map->theme);
                        conn->map->theme = themename;
                        conn->onMapChangedCb(conn->onMapChangedCtx, conn->map, NETCONN_MAPCHANGE_THEME);
                    } else {
                        flib_log_e("Error processing CFG THEME message");
                    }
                } else if(!strcmp(subcmd, "SEED") && netmsg->partCount == 3) {
                    char *seed = flib_strdupnull(netmsg->parts[2]);
                    if(seed) {
                        free(conn->map->seed);
                        conn->map->seed = seed;
                        conn->onMapChangedCb(conn->onMapChangedCtx, conn->map, NETCONN_MAPCHANGE_SEED);
                    } else {
                        flib_log_e("Error processing CFG SEED message");
                    }
                } else if(!strcmp(subcmd, "TEMPLATE") && netmsg->partCount == 3) {
                    conn->map->templateFilter = atoi(netmsg->parts[2]);
                    conn->onMapChangedCb(conn->onMapChangedCtx, conn->map, NETCONN_MAPCHANGE_TEMPLATE);
                } else if(!strcmp(subcmd, "MAPGEN") && netmsg->partCount == 3) {
                    conn->map->mapgen = atoi(netmsg->parts[2]);
                    conn->onMapChangedCb(conn->onMapChangedCtx, conn->map, NETCONN_MAPCHANGE_MAPGEN);
                } else if(!strcmp(subcmd, "MAZE_SIZE") && netmsg->partCount == 3) {
                    conn->map->mazeSize = atoi(netmsg->parts[2]);
                    conn->onMapChangedCb(conn->onMapChangedCtx, conn->map, NETCONN_MAPCHANGE_MAZE_SIZE);
                } else if(!strcmp(subcmd, "DRAWNMAP") && netmsg->partCount == 3) {
                    size_t drawnMapSize = 0;
                    uint8_t *drawnMapData = NULL;
                    if(!flib_drawnmapdata_from_netmsg(netmsg->parts[2], &drawnMapData, &drawnMapSize)) {
                        free(conn->map->drawData);
                        conn->map->drawData = drawnMapData;
                        conn->map->drawDataSize = drawnMapSize;
                        conn->onMapChangedCb(conn->onMapChangedCtx, conn->map, NETCONN_MAPCHANGE_DRAWNMAP);
                    } else {
                        flib_log_e("Error processing CFG DRAWNMAP message");
                    }
                } else if(!strcmp(subcmd, "SCRIPT") && netmsg->partCount == 3) {
                    netconn_setScript(conn, netmsg->parts[2]);
                    conn->onScriptChangedCb(conn->onScriptChangedCtx, netmsg->parts[2]);
                } else if(!strcmp(subcmd, "AMMO") && netmsg->partCount == 4) {
                    flib_weaponset *weapons = flib_weaponset_from_ammostring(netmsg->parts[2], netmsg->parts[3]);
                    if(weapons) {
                        flib_weaponset_destroy(conn->weaponset);
                        conn->weaponset = weapons;
                        conn->onWeaponsetChangedCb(conn->onWeaponsetChangedCtx, weapons);
                    } else {
                        flib_log_e("Error processing CFG AMMO message");
                    }
                } else {
                    flib_log_w("Net: Unknown or malformed CFG subcommand: %s", subcmd);
                }
            }
        } else if (!strcmp(cmd, "HH_NUM")) {
            if (netmsg->partCount != 3 || conn->netconnState!=NETCONN_STATE_ROOM) {
                flib_log_w("Net: Bad HH_NUM message");
            } else {
                int hogs = atoi(netmsg->parts[2]);
                if(hogs<=0 || hogs>HEDGEHOGS_PER_TEAM) {
                    flib_log_w("Net: Bad HH_NUM message: %s hogs", netmsg->parts[2]);
                } else {
                    flib_team *team = flib_teamlist_find(&conn->teamlist, netmsg->parts[1]);
                    if(team) {
                        team->hogsInGame = hogs;
                    } else {
                        flib_log_e("HH_NUM message for unknown team %s", netmsg->parts[1]);
                    }
                    conn->onHogCountChangedCb(conn->onHogCountChangedCtx, netmsg->parts[1], hogs);
                }
            }
        } else if (!strcmp(cmd, "TEAM_COLOR")) {
            if (netmsg->partCount != 3 || conn->netconnState!=NETCONN_STATE_ROOM) {
                flib_log_w("Net: Bad TEAM_COLOR message");
            } else {
                long color;
                if(sscanf(netmsg->parts[2], "%lu", &color) && color>=0 && color<flib_teamcolor_count) {
                    flib_team *team = flib_teamlist_find(&conn->teamlist, netmsg->parts[1]);
                    if(team) {
                        team->colorIndex = color;
                    } else {
                        flib_log_e("TEAM_COLOR message for unknown team %s", netmsg->parts[1]);
                    }
                    conn->onTeamColorChangedCb(conn->onTeamColorChangedCtx, netmsg->parts[1], color);
                } else {
                    flib_log_w("Net: Bad TEAM_COLOR message: Color %s", netmsg->parts[2]);
                }
            }
        } else if (!strcmp(cmd, "EM")) {
            if(netmsg->partCount < 2) {
                flib_log_w("Net: Bad EM message");
            } else {
                for(int i = 1; i < netmsg->partCount; ++i) {
                    char *out = NULL;
                    size_t outlen;
                    bool ok = base64_decode_alloc(netmsg->parts[i], strlen(netmsg->parts[i]), &out, &outlen);
                    if(ok && outlen) {
                        conn->onEngineMessageCb(conn->onEngineMessageCtx, (uint8_t*)out, outlen);
                    } else {
                        flib_log_e("Net: Malformed engine message: %s", netmsg->parts[i]);
                    }
                    free(out);
                }
            }
        } else if (!strcmp(cmd, "BYE")) {
            if (netmsg->partCount < 2) {
                flib_log_w("Net: Bad BYE message");
            } else {
                conn->netconnState = NETCONN_STATE_DISCONNECTED;
                if (!strcmp(netmsg->parts[1], "Authentication failed")) {
                    conn->onDisconnectedCb(conn->onDisconnectedCtx, NETCONN_DISCONNECT_AUTH_FAILED, netmsg->parts[1]);
                } else {
                    conn->onDisconnectedCb(conn->onDisconnectedCtx, NETCONN_DISCONNECT_NORMAL, netmsg->parts[1]);
                }
                exit = true;
            }
        } else if (!strcmp(cmd, "ADMIN_ACCESS")) {
            // deprecated
        } else if (!strcmp(cmd, "ROOM_CONTROL_ACCESS")) {
            // deprecated
        } else {
            flib_log_w("Unknown server command: %s", cmd);
        }
        flib_netmsg_destroy(netmsg);
    }

    if(!exit && !conn->destroyRequested && !flib_netbase_connected(net)) {
        conn->netconnState = NETCONN_STATE_DISCONNECTED;
        conn->onDisconnectedCb(conn->onDisconnectedCtx, NETCONN_DISCONNECT_CONNLOST, "Connection lost");
    }
}

void flib_netconn_tick(flib_netconn *conn) {
    if(!log_badargs_if(conn==NULL)
            && !log_w_if(conn->running, "Call to flib_netconn_tick from a callback")
            && !log_w_if(conn->netconnState == NETCONN_STATE_DISCONNECTED, "We are already done.")) {
        conn->running = true;
        flib_netconn_wrappedtick(conn);
        conn->running = false;

        if(conn->destroyRequested) {
            flib_netconn_destroy(conn);
        }
    }
}
