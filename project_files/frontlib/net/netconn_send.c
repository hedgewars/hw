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

#include "netconn_internal.h"

#include "../util/logging.h"
#include "../util/util.h"
#include "../util/buffer.h"
#include "../md5/md5.h"
#include "../base64/base64.h"

#include <zlib.h>

#include <stdlib.h>
#include <string.h>
#include <limits.h>

// cmdname is always given as literal from functions in this file, so it is never null.
static int sendVoid(flib_netconn *conn, const char *cmdname) {
    if(log_e_if(!conn, "Invalid parameter sending %s command", cmdname)) {
        return -1;
    }
    return flib_netbase_sendf(conn->netBase, "%s\n\n", cmdname);
}

// Testing for !*str prevents sending 0-length parameters (they trip up the protocol)
static int sendStr(flib_netconn *conn, const char *cmdname, const char *str) {
    if(log_e_if(!conn || flib_strempty(str), "Invalid parameter sending %s command", cmdname)) {
        return -1;
    }
    return flib_netbase_sendf(conn->netBase, "%s\n%s\n\n", cmdname, str);
}

static int sendInt(flib_netconn *conn, const char *cmdname, int param) {
    if(log_e_if(!conn, "Invalid parameter sending %s command", cmdname)) {
        return -1;
    }
    return flib_netbase_sendf(conn->netBase, "%s\n%i\n\n", cmdname, param);
}

int flib_netconn_send_nick(flib_netconn *conn, const char *nick) {
    int result = -1;
    if(!log_badargs_if2(conn==NULL, flib_strempty(nick))) {
        char *tmpName = flib_strdupnull(nick);
        if(tmpName) {
            if(!flib_netbase_sendf(conn->netBase, "%s\n%s\n\n", "NICK", nick)) {
                free(conn->playerName);
                conn->playerName = tmpName;
                tmpName = NULL;
                result = 0;
            }
        }
        free(tmpName);
    }
    return result;
}

int flib_netconn_send_password(flib_netconn *conn, const char *passwd) {
    int result = -1;
    if(!log_badargs_if2(conn==NULL, passwd==NULL)) {
        md5_state_t md5state;
        uint8_t md5bytes[16];
        char md5hex[33];
        md5_init(&md5state);
        md5_append(&md5state, (unsigned char*)passwd, strlen(passwd));
        md5_finish(&md5state, md5bytes);
        for(int i=0;i<sizeof(md5bytes); i++) {
            // Needs to be lowercase - server checks case sensitive
            snprintf(md5hex+i*2, 3, "%02x", (unsigned)md5bytes[i]);
        }
        result = flib_netbase_sendf(conn->netBase, "%s\n%s\n\n", "PASSWORD", md5hex);
    }
    return result;
}

int flib_netconn_send_quit(flib_netconn *conn, const char *quitmsg) {
    return sendStr(conn, "QUIT", (quitmsg && *quitmsg) ? quitmsg : "User quit");
}

int flib_netconn_send_chat(flib_netconn *conn, const char *chat) {
    if(!flib_strempty(chat)) {
        return sendStr(conn, "CHAT", chat);
    }
    return 0;
}

int flib_netconn_send_kick(flib_netconn *conn, const char *playerName) {
    return sendStr(conn, "KICK", playerName);
}

int flib_netconn_send_playerInfo(flib_netconn *conn, const char *playerName) {
    return sendStr(conn, "INFO", playerName);
}

int flib_netconn_send_request_roomlist(flib_netconn *conn) {
    return sendVoid(conn, "LIST");
}

int flib_netconn_send_joinRoom(flib_netconn *conn, const char *room) {
    if(!sendStr(conn, "JOIN_ROOM", room)) {
        conn->isChief = false;
        return 0;
    }
    return -1;
}

int flib_netconn_send_playerFollow(flib_netconn *conn, const char *playerName) {
    return sendStr(conn, "FOLLOW", playerName);
}

int flib_netconn_send_createRoom(flib_netconn *conn, const char *room) {
    if(!sendStr(conn, "CREATE_ROOM", room)) {
        conn->isChief = true;
        return 0;
    }
    return -1;
}

int flib_netconn_send_ban(flib_netconn *conn, const char *playerName) {
    return sendStr(conn, "BAN", playerName);
}

int flib_netconn_send_clearAccountsCache(flib_netconn *conn) {
    return sendVoid(conn, "CLEAR_ACCOUNTS_CACHE");
}

int flib_netconn_send_setServerVar(flib_netconn *conn, const char *name, const char *value) {
    if(log_badargs_if3(conn==NULL, flib_strempty(name), flib_strempty(value))) {
        return -1;
    }
    return flib_netbase_sendf(conn->netBase, "%s\n%s\n%s\n\n", "SET_SERVER_VAR", name, value);
}

int flib_netconn_send_getServerVars(flib_netconn *conn) {
    return sendVoid(conn, "GET_SERVER_VAR");
}
int flib_netconn_send_leaveRoom(flib_netconn *conn, const char *str) {
    int result = -1;
    if(conn->netconnState==NETCONN_STATE_ROOM) {
        result = (str && *str) ? sendStr(conn, "PART", str) : sendVoid(conn, "PART");
        if(!result) {
            netconn_leaveRoom(conn);
        }
    }
    return result;
}

int flib_netconn_send_toggleReady(flib_netconn *conn) {
    return sendVoid(conn, "TOGGLE_READY");
}

static void addTeamToPendingList(flib_netconn *conn, const flib_team *team) {
    flib_team *teamcopy = flib_team_copy(team);
    if(teamcopy) {
        teamcopy->remoteDriven = false;
        free(teamcopy->ownerName);
        teamcopy->ownerName = flib_strdupnull(conn->playerName);
        if(teamcopy->ownerName) {
            flib_teamlist_delete(&conn->pendingTeamlist, team->name);
            if(!flib_teamlist_insert(&conn->pendingTeamlist, teamcopy, 0)) {
                teamcopy = NULL;
            }
        }
    }
    flib_team_destroy(teamcopy);
}

int flib_netconn_send_addTeam(flib_netconn *conn, const flib_team *team) {
    int result = -1;
    if(!log_badargs_if2(conn==NULL, team==NULL)) {
        bool missingInfo = flib_strempty(team->name) || flib_strempty(team->grave) || flib_strempty(team->fort) || flib_strempty(team->voicepack) || flib_strempty(team->flag);
        for(int i=0; i<HEDGEHOGS_PER_TEAM; i++) {
            missingInfo |= flib_strempty(team->hogs[i].name) || flib_strempty(team->hogs[i].hat);
        }
        if(!log_e_if(missingInfo, "Incomplete team definition")) {
            flib_vector *vec = flib_vector_create();
            if(vec) {
                bool error = false;
                error |= flib_vector_appendf(vec, "ADD_TEAM\n%s\n%i\n%s\n%s\n%s\n%s\n%i\n", team->name, team->colorIndex, team->grave, team->fort, team->voicepack, team->flag, team->hogs[0].difficulty);
                for(int i=0; i<HEDGEHOGS_PER_TEAM; i++) {
                    error |= flib_vector_appendf(vec, "%s\n%s\n", team->hogs[i].name, team->hogs[i].hat);
                }
                error |= flib_vector_appendf(vec, "\n");
                if(!error && !flib_netbase_send_raw(conn->netBase, flib_vector_data(vec), flib_vector_size(vec))) {
                    addTeamToPendingList(conn, team);
                    result = 0;
                }
            }
            flib_vector_destroy(vec);
        }
    }
    return result;
}

int flib_netconn_send_removeTeam(flib_netconn *conn, const char *teamname) {
    flib_team *team = flib_teamlist_find(&conn->teamlist, teamname);
    if(team && !team->remoteDriven && !sendStr(conn, "REMOVE_TEAM", teamname)) {
        flib_teamlist_delete(&conn->teamlist, teamname);
        return 0;
    }
    return -1;
}

int flib_netconn_send_renameRoom(flib_netconn *conn, const char *roomName) {
    return sendStr(conn, "ROOM_NAME", roomName);
}

int flib_netconn_send_teamHogCount(flib_netconn *conn, const char *teamname, int hogcount) {
    if(!log_badargs_if5(conn==NULL, flib_strempty(teamname), hogcount<1, hogcount>HEDGEHOGS_PER_TEAM, !conn->isChief)
            && !flib_netbase_sendf(conn->netBase, "HH_NUM\n%s\n%i\n\n", teamname, hogcount)) {
        flib_team *team = flib_teamlist_find(&conn->teamlist, teamname);
        if(team) {
            team->hogsInGame = hogcount;
        }
        return 0;
    }
    return -1;
}

int flib_netconn_send_teamColor(flib_netconn *conn, const char *teamname, int colorIndex) {
    if(!log_badargs_if3(conn==NULL, flib_strempty(teamname), !conn->isChief)
            && !flib_netbase_sendf(conn->netBase, "TEAM_COLOR\n%s\n%i\n\n", teamname, colorIndex)) {
        flib_team *team = flib_teamlist_find(&conn->teamlist, teamname);
        if(team) {
            team->colorIndex = colorIndex;
        }
        return 0;
    }
    return -1;
}

int flib_netconn_send_weaponset(flib_netconn *conn, const flib_weaponset *weaponset) {
    if(!log_badargs_if3(conn==NULL, weaponset==NULL, flib_strempty(weaponset->name))) {
        char ammostring[WEAPONS_COUNT*4+1];
        strcpy(ammostring, weaponset->loadout);
        strcat(ammostring, weaponset->crateprob);
        strcat(ammostring, weaponset->delay);
        strcat(ammostring, weaponset->crateammo);
        if(conn->isChief) {
            if(!flib_netbase_sendf(conn->netBase, "CFG\nAMMO\n%s\n%s\n\n", weaponset->name, ammostring)) {
                netconn_setWeaponset(conn, weaponset);
                return 0;
            }
        }
    }
    return -1;
}

int flib_netconn_send_map(flib_netconn *conn, const flib_map *map) {
    if(log_badargs_if2(conn==NULL, map==NULL)) {
        return -1;
    }
    bool error = false;

    if(map->seed) {
        error |= flib_netconn_send_mapSeed(conn, map->seed);
    }
    error |= flib_netconn_send_mapTemplate(conn, map->templateFilter);
    if(map->theme) {
        error |= flib_netconn_send_mapTheme(conn, map->theme);
    }
    error |= flib_netconn_send_mapGen(conn, map->mapgen);
    error |= flib_netconn_send_mapMazeSize(conn, map->mazeSize);
    if(map->drawData && map->drawDataSize>0) {
        error |= flib_netconn_send_mapDrawdata(conn, map->drawData, map->drawDataSize);
    }
    // Name is sent last, because the QtFrontend uses this to update its preview, and to show/hide
    // certain fields
    if(map->name) {
        error |= flib_netconn_send_mapName(conn, map->name);
    }
    return error;
}

int flib_netconn_send_mapName(flib_netconn *conn, const char *mapName) {
    if(log_badargs_if2(conn==NULL, mapName==NULL)) {
        return -1;
    }
    if(conn->isChief) {
        if(!sendStr(conn, "CFG\nMAP", mapName)) {
            char *copy = flib_strdupnull(mapName);
            if(copy) {
                free(conn->map->name);
                conn->map->name = copy;
                return 0;
            }
        }
    }
    return -1;
}

int flib_netconn_send_mapGen(flib_netconn *conn, int mapGen) {
    if(log_badargs_if(conn==NULL)) {
        return -1;
    }
    if(conn->isChief) {
        if(!sendInt(conn, "CFG\nMAPGEN", mapGen)) {
            conn->map->mapgen = mapGen;
            return 0;
        }
    }
    return -1;
}

int flib_netconn_send_mapTemplate(flib_netconn *conn, int templateFilter) {
    if(log_badargs_if(conn==NULL)) {
        return -1;
    }
    if(conn->isChief) {
        if(!sendInt(conn, "CFG\nTEMPLATE", templateFilter)) {
            conn->map->templateFilter = templateFilter;
            return 0;
        }
    }
    return -1;
}

int flib_netconn_send_mapMazeSize(flib_netconn *conn, int mazeSize) {
    if(log_badargs_if(conn==NULL)) {
        return -1;
    }
    if(conn->isChief) {
        if(!sendInt(conn, "CFG\nMAZE_SIZE", mazeSize)) {
            conn->map->mazeSize = mazeSize;
            return 0;
        }
    }
    return -1;
}

int flib_netconn_send_mapSeed(flib_netconn *conn, const char *seed) {
    if(log_badargs_if2(conn==NULL, seed==NULL)) {
        return -1;
    }
    if(conn->isChief) {
        if(!sendStr(conn, "CFG\nSEED", seed)) {
            char *copy = flib_strdupnull(seed);
            if(copy) {
                free(conn->map->seed);
                conn->map->seed = copy;
                return 0;
            }
        }
    }
    return -1;
}

int flib_netconn_send_mapTheme(flib_netconn *conn, const char *theme) {
    if(log_badargs_if2(conn==NULL, theme==NULL)) {
        return -1;
    }
    if(conn->isChief) {
        if(!sendStr(conn, "CFG\nTHEME", theme)) {
            char *copy = flib_strdupnull(theme);
            if(copy) {
                free(conn->map->theme);
                conn->map->theme = copy;
                return 0;
            }
        }
    }
    return -1;
}

int flib_netconn_send_mapDrawdata(flib_netconn *conn, const uint8_t *drawData, size_t size) {
    int result = -1;
    if(!log_badargs_if3(conn==NULL, drawData==NULL && size>0, size>SIZE_MAX/2) && conn->isChief) {
        uLongf zippedSize = compressBound(size);
        uint8_t *zipped = flib_malloc(zippedSize+4); // 4 extra bytes for header
        if(zipped) {
            // Create the QCompress size header (uint32 big endian)
            zipped[0] = (size>>24) & 0xff;
            zipped[1] = (size>>16) & 0xff;
            zipped[2] = (size>>8) & 0xff;
            zipped[3] = (size) & 0xff;

            if(compress(zipped+4, &zippedSize, drawData, size) != Z_OK) {
                flib_log_e("Error compressing drawn map data.");
            } else {
                char *base64encout = NULL;
                base64_encode_alloc((const char*)zipped, zippedSize+4, &base64encout);
                if(!base64encout) {
                    flib_log_e("Error base64-encoding drawn map data.");
                } else {
                    result = flib_netbase_sendf(conn->netBase, "CFG\nDRAWNMAP\n%s\n\n", base64encout);
                }
                free(base64encout);
            }
        }
        free(zipped);
    }

    if(!result) {
        uint8_t *copy = flib_bufdupnull(drawData, size);
        if(copy) {
            free(conn->map->drawData);
            conn->map->drawData = copy;
            conn->map->drawDataSize = size;
        }
    }
    return result;
}

int flib_netconn_send_script(flib_netconn *conn, const char *scriptName) {
    if(log_badargs_if2(conn==NULL, scriptName==NULL)) {
        return -1;
    }
    if(conn->isChief) {
        if(!sendStr(conn, "CFG\nSCRIPT", scriptName)) {
            netconn_setScript(conn, scriptName);
            return 0;
        }
    }
    return -1;
}

int flib_netconn_send_scheme(flib_netconn *conn, const flib_scheme *scheme) {
    int result = -1;
    if(!log_badargs_if3(conn==NULL, scheme==NULL, flib_strempty(scheme->name)) && conn->isChief) {
        flib_vector *vec = flib_vector_create();
        if(vec) {
            bool error = false;
            error |= flib_vector_appendf(vec, "CFG\nSCHEME\n%s\n", scheme->name);
            for(int i=0; i<flib_meta.modCount; i++) {
                error |= flib_vector_appendf(vec, "%s\n", scheme->mods[i] ? "true" : "false");
            }
            for(int i=0; i<flib_meta.settingCount; i++) {
                error |= flib_vector_appendf(vec, "%i\n", scheme->settings[i]);
            }
            error |= flib_vector_appendf(vec, "\n");
            if(!error) {
                result = flib_netbase_send_raw(conn->netBase, flib_vector_data(vec), flib_vector_size(vec));
            }
        }
        flib_vector_destroy(vec);
    }

    if(!result) {
        netconn_setScheme(conn, scheme);
    }
    return result;
}

int flib_netconn_send_startGame(flib_netconn *conn) {
    return sendVoid(conn, "START_GAME");
}

int flib_netconn_send_toggleRestrictJoins(flib_netconn *conn) {
    return sendVoid(conn, "TOGGLE_RESTRICT_JOINS");
}

int flib_netconn_send_toggleRestrictTeams(flib_netconn *conn) {
    return sendVoid(conn, "TOGGLE_RESTRICT_TEAMS");
}

int flib_netconn_send_teamchat(flib_netconn *conn, const char *chat) {
    if(!flib_strempty(chat)) {
        return sendStr(conn, "TEAMCHAT", chat);
    }
    return 0;
}

int flib_netconn_send_engineMessage(flib_netconn *conn, const uint8_t *message, size_t size) {
    int result = -1;
    if(!log_badargs_if2(conn==NULL, message==NULL && size>0)) {
        char *base64encout = NULL;
        base64_encode_alloc((const char*)message, size, &base64encout);
        if(base64encout) {
            result = flib_netbase_sendf(conn->netBase, "EM\n%s\n\n", base64encout);
        }
        free(base64encout);
    }
    return result;
}

int flib_netconn_send_roundfinished(flib_netconn *conn, bool withoutError) {
    return sendInt(conn, "ROUNDFINISHED", withoutError ? 1 : 0);
}

