#include "netconn_internal.h"

#include "../util/logging.h"
#include "../util/util.h"
#include "../util/buffer.h"
#include "../md5/md5.h"
#include "../base64/base64.h"

#include <stdlib.h>
#include <string.h>
#include <zlib.h>

// TODO state changes

// cmdname is always given as literal from functions in this file, so it is never null.
static int sendVoid(flib_netconn *conn, const char *cmdname) {
	if(!conn) {
		flib_log_e("null parameter trying to send %s command.", cmdname);
		return -1;
	}
	return flib_netbase_sendf(conn->netBase, "%s\n\n", cmdname);
}

static int sendStr(flib_netconn *conn, const char *cmdname, const char *str) {
	if(!conn || !str) {
		flib_log_e("null parameter trying to send %s command.", cmdname);
		return -1;
	}
	return flib_netbase_sendf(conn->netBase, "%s\n%s\n\n", cmdname, str);
}

static int sendInt(flib_netconn *conn, const char *cmdname, int param) {
	if(!conn) {
		flib_log_e("null parameter trying to send %s command.", cmdname);
		return -1;
	}
	return flib_netbase_sendf(conn->netBase, "%s\n%i\n\n", cmdname, param);
}

int flib_netconn_send_quit(flib_netconn *conn, const char *quitmsg) {
	return sendStr(conn, "QUIT", quitmsg ? quitmsg : "User quit");
}

int flib_netconn_send_chat(flib_netconn *conn, const char *chat) {
	return sendStr(conn, "CHAT", chat);
}

int flib_netconn_send_teamchat(flib_netconn *conn, const char *chat) {
	return sendStr(conn, "TEAMCHAT", chat);
}

int flib_netconn_send_nick(flib_netconn *conn, const char *nick) {
	int result = -1;
	if(!conn || !nick) {
		flib_log_e("null parameter in flib_netconn_send_nick");
	} else {
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

int flib_netconn_send_password(flib_netconn *conn, const char *latin1Passwd) {
	int result = -1;
	if(!conn || !latin1Passwd) {
		flib_log_e("null parameter in flib_netconn_send_password");
	} else {
		md5_state_t md5state;
		uint8_t md5bytes[16];
		char md5hex[33];
		md5_init(&md5state);
		md5_append(&md5state, (unsigned char*)latin1Passwd, strlen(latin1Passwd));
		md5_finish(&md5state, md5bytes);
		for(int i=0;i<sizeof(md5bytes); i++) {
			// Needs to be lowercase - server checks case sensitive
			snprintf(md5hex+i*2, 3, "%02x", (unsigned)md5bytes[i]);
		}
		result = flib_netbase_sendf(conn->netBase, "%s\n%s\n\n", "PASSWORD", md5hex);
	}
	return result;
}

int flib_netconn_send_joinRoom(flib_netconn *conn, const char *room) {
	return sendStr(conn, "JOIN_ROOM", room);
}

int flib_netconn_send_createRoom(flib_netconn *conn, const char *room) {
	return sendStr(conn, "CREATE_ROOM", room);
}

int flib_netconn_send_renameRoom(flib_netconn *conn, const char *roomName) {
	return sendStr(conn, "ROOM_NAME", roomName);
}

int flib_netconn_send_leaveRoom(flib_netconn *conn) {
	return sendVoid(conn, "PART");
}

int flib_netconn_send_toggleReady(flib_netconn *conn) {
	return sendVoid(conn, "TOGGLE_READY");
}

int flib_netconn_send_addTeam(flib_netconn *conn, const flib_team *team) {
	int result = -1;
	if(!conn || !team) {
		flib_log_e("null parameter in flib_netconn_send_addTeam");
	} else {
		bool missingInfo = !team->name || !team->color || !team->grave || !team->fort || !team->voicepack || !team->flag;
		for(int i=0; i<HEDGEHOGS_PER_TEAM; i++) {
			missingInfo |= !team->hogs[i].name || !team->hogs[i].hat;
		}
		if(missingInfo) {
			flib_log_e("Incomplete team definition for flib_netconn_send_addTeam");
		} else {
			flib_vector *vec = flib_vector_create();
			if(vec) {
				bool error = false;
				error |= flib_vector_appendf(vec, "ADD_TEAM\n%s\n%lu\n%s\n%s\n%s\n%s\n%i\n", team->name, (unsigned long)team->color, team->grave, team->fort, team->voicepack, team->flag, team->hogs[0].difficulty);
				for(int i=0; i<HEDGEHOGS_PER_TEAM; i++) {
					error |= flib_vector_appendf(vec, "%s\n%s\n", team->hogs[i].name, team->hogs[i].hat);
				}
				error |= flib_vector_appendf(vec, "\n");
				if(!error) {
					result = flib_netbase_send_raw(conn->netBase, flib_vector_data(vec), flib_vector_size(vec));
				}
			}
			flib_vector_destroy(vec);
		}
	}
	return result;
}

int flib_netconn_send_removeTeam(flib_netconn *conn, const char *teamname) {
	return sendStr(conn, "REMOVE_TEAM", teamname);
}

int flib_netconn_send_engineMessage(flib_netconn *conn, const uint8_t *message, size_t size) {
	int result = -1;
	if(!conn || (!message && size>0)) {
		flib_log_e("null parameter in flib_netconn_send_engineMessage");
	} else {
		char *base64encout = NULL;
		base64_encode_alloc((const char*)message, size, &base64encout);
		if(base64encout) {
			result = flib_netbase_sendf(conn->netBase, "EM\n%s\n\n", base64encout);
		}
		free(base64encout);
	}
	return result;
}

int flib_netconn_send_teamHogCount(flib_netconn *conn, const char *teamname, int hogcount) {
	if(!conn || !teamname || hogcount<1 || hogcount>HEDGEHOGS_PER_TEAM) {
		flib_log_e("invalid parameter in flib_netconn_send_teamHogCount");
		return -1;
	}
	return flib_netbase_sendf(conn->netBase, "HH_NUM\n%s\n%i\n\n", teamname, hogcount);
}

int flib_netconn_send_teamColor(flib_netconn *conn, const char *teamname, uint32_t colorRGB) {
	if(!conn || !teamname) {
		flib_log_e("null parameter in flib_netconn_send_teamColor");
		return -1;
	}
	return flib_netbase_sendf(conn->netBase, "TEAM_COLOR\n%s\n%lu\n\n", teamname, (unsigned long)colorRGB);
}

int flib_netconn_send_weaponset(flib_netconn *conn, const flib_weaponset *weaponset) {
	if(!conn || !weaponset) {
		flib_log_e("null parameter in flib_netconn_send_weaponset");
		return -1;
	}

	char ammostring[WEAPONS_COUNT*4+1];
	strcpy(ammostring, weaponset->loadout);
	strcat(ammostring, weaponset->crateprob);
	strcat(ammostring, weaponset->delay);
	strcat(ammostring, weaponset->crateammo);
	return flib_netbase_sendf(conn->netBase, "CFG\nAMMO\n%s\n%s\n\n", weaponset->name, ammostring);
}

int flib_netconn_send_map(flib_netconn *conn, const flib_map *map) {
	if(!conn || !map) {
		flib_log_e("null parameter in flib_netconn_send_map");
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
	if(map->name) {
		error |= flib_netconn_send_mapName(conn, map->name);
	}
	if(map->drawData && map->drawDataSize>0) {
		error |= flib_netconn_send_mapDrawdata(conn, map->drawData, map->drawDataSize);
	}
	return error;
}

int flib_netconn_send_mapName(flib_netconn *conn, const char *mapName) {
	return sendStr(conn, "CFG\nMAP", mapName);
}

int flib_netconn_send_mapGen(flib_netconn *conn, int mapGen) {
	return sendInt(conn, "CFG\nMAPGEN", mapGen);
}

int flib_netconn_send_mapTemplate(flib_netconn *conn, int templateFilter) {
	return sendInt(conn, "CFG\nTEMPLATE", templateFilter);
}

int flib_netconn_send_mapMazeSize(flib_netconn *conn, int mazeSize) {
	return sendInt(conn, "CFG\nMAZE_SIZE", mazeSize);
}

int flib_netconn_send_mapSeed(flib_netconn *conn, const char *seed) {
	return sendStr(conn, "CFG\nSEED", seed);
}

int flib_netconn_send_mapTheme(flib_netconn *conn, const char *theme) {
	return sendStr(conn, "CFG\nTHEME", theme);
}

int flib_netconn_send_mapDrawdata(flib_netconn *conn, const uint8_t *drawData, size_t size) {
	int result = -1;
	if(!conn || (!drawData && size>0) || size>SIZE_MAX/2) {
		flib_log_e("invalid parameter in flib_netconn_send_map");
	} else {
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
	return result;
}

int flib_netconn_send_script(flib_netconn *conn, const char *scriptName) {
	return sendStr(conn, "CFG\nSCRIPT", scriptName);
}

int flib_netconn_send_scheme(flib_netconn *conn, const flib_cfg *scheme) {
	int result = -1;
	if(!conn || !scheme) {
		flib_log_e("null parameter in flib_netconn_send_scheme");
	} else {
		flib_vector *vec = flib_vector_create();
		if(vec) {
			bool error = false;
			error |= flib_vector_appendf(vec, "CFG\nSCHEME\n%s\n", scheme->name);
			for(int i=0; i<scheme->meta->modCount; i++) {
				error |= flib_vector_appendf(vec, "%s\n", scheme->mods[i] ? "true" : "false");
			}
			for(int i=0; i<scheme->meta->settingCount; i++) {
				error |= flib_vector_appendf(vec, "%i\n", scheme->settings[i]);
			}
			error |= flib_vector_appendf(vec, "\n");
			if(!error) {
				result = flib_netbase_send_raw(conn->netBase, flib_vector_data(vec), flib_vector_size(vec));
			}
		}
		flib_vector_destroy(vec);
	}
	return result;
}

int flib_netconn_send_roundfinished(flib_netconn *conn, bool withoutError) {
	return sendInt(conn, "ROUNDFINISHED", withoutError ? 1 : 0);
}

int flib_netconn_send_ban(flib_netconn *conn, const char *playerName) {
	return sendStr(conn, "BAN", playerName);
}

int flib_netconn_send_kick(flib_netconn *conn, const char *playerName) {
	return sendStr(conn, "KICK", playerName);
}

int flib_netconn_send_playerInfo(flib_netconn *conn, const char *playerName) {
	return sendStr(conn, "INFO", playerName);
}

int flib_netconn_send_playerFollow(flib_netconn *conn, const char *playerName) {
	return sendStr(conn, "FOLLOW", playerName);
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

int flib_netconn_send_clearAccountsCache(flib_netconn *conn) {
	return sendVoid(conn, "CLEAR_ACCOUNTS_CACHE");
}

int flib_netconn_send_setServerVar(flib_netconn *conn, const char *name, const char *value) {
	if(!conn || !name || !value) {
		flib_log_e("null parameter trying to send SET_SERVER_VAR command.");
		return -1;
	}
	return flib_netbase_sendf(conn->netBase, "%s\n%s\n%s\n\n", "SET_SERVER_VAR", name, value);
}

int flib_netconn_send_getServerVars(flib_netconn *conn) {
	return sendVoid(conn, "GET_SERVER_VAR");
}
