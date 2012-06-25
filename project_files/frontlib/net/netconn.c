/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

// TODO: Check the state transitions. Document with a diagram or something

#include "netconn_internal.h"
#include "netprotocol.h"
#include "../util/logging.h"
#include "../util/util.h"
#include "../model/roomlist.h"
#include "../md5/md5.h"
#include "../base64/base64.h"

#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>

flib_netconn *flib_netconn_create(const char *playerName, flib_cfg_meta *metacfg, const char *host, uint16_t port) {
	flib_netconn *result = NULL;
	if(!playerName || !metacfg || !host) {
		flib_log_e("null parameter in flib_netconn_create");
	} else {
		flib_netconn *newConn = flib_calloc(1, sizeof(flib_netconn));
		if(newConn) {
			newConn->netconnState = NETCONN_STATE_CONNECTING;
			newConn->isAdmin = false;
			newConn->isChief = false;
			newConn->metaCfg = flib_cfg_meta_retain(metacfg);
			newConn->roomList = flib_roomlist_create();
			newConn->map = flib_map_create_named("", "NoSuchMap");
			newConn->running = false;
			newConn->destroyRequested = false;
			clearCallbacks(newConn);
			newConn->netBase = flib_netbase_create(host, port);
			newConn->playerName = flib_strdupnull(playerName);
			if(newConn->netBase && newConn->playerName && newConn->roomList) {
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
			clearCallbacks(conn);
			conn->destroyRequested = true;
		} else {
			flib_netbase_destroy(conn->netBase);
			flib_cfg_meta_release(conn->metaCfg);
			flib_roomlist_destroy(conn->roomList);
			flib_map_release(conn->map);
			free(conn->playerName);
			free(conn);
		}
	}
}

const flib_roomlist *flib_netconn_get_roomlist(flib_netconn *conn) {
	const flib_roomlist *result = NULL;
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_get_roomlist");
	} else {
		result = conn->roomList;
	}
	return result;
}

bool flib_netconn_is_chief(flib_netconn *conn) {
	bool result = false;
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_is_chief");
	} else if(conn->netconnState == NETCONN_STATE_ROOM || conn->netconnState == NETCONN_STATE_INGAME) {
		result = conn->isChief;
	}
	return result;
}

void leaveRoom(flib_netconn *conn) {
	conn->netconnState = NETCONN_STATE_LOBBY;
	conn->isChief = false;
	flib_map *map = flib_map_create_named("", "NoSuchMap");
	if(map) {
		flib_map_release(conn->map);
		conn->map = map;
	} else {
		flib_log_e("Error resetting netconn.map");
	}
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
	        	flib_roomlist_clear(conn->roomList);
	        	for(int i=1; i<netmsg->partCount; i+=8) {
	        		if(flib_roomlist_add(conn->roomList, netmsg->parts+i)) {
	        			flib_log_e("Error adding room to list in ROOMS message");
	        		}
	        	}
	        	if(conn->netconnState == NETCONN_STATE_CONNECTING) {
	        		// We delay the "connected" callback until now to ensure the room list is avaliable.
	        		conn->onConnectedCb(conn->onConnectedCtx);
					conn->netconnState = NETCONN_STATE_LOBBY;
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

				for(int i=1; flags[i]; i++) {
					switch(flags[i]) {
					case 'r':
						for(int j = 2; j < netmsg->partCount; ++j) {
							conn->onReadyStateCb(conn->onReadyStateCtx, netmsg->parts[i], setFlag);
						}
						break;
					default:
						flib_log_w("Net: Unknown flag %c in CLIENT_FLAGS message", flags[i]);
						break;
					}
				}
	        }
	    } else if (!strcmp(cmd, "ADD_TEAM")) {
	        if(netmsg->partCount != 24) {
	            flib_log_w("Net: Bad ADD_TEAM message");
	        } else {
	        	flib_team *team = flib_team_from_netmsg(netmsg->parts+1);
	        	if(!team) {
					conn->netconnState = NETCONN_STATE_DISCONNECTED;
					conn->onDisconnectedCb(conn->onDisconnectedCtx, NETCONN_DISCONNECT_INTERNAL_ERROR, "Internal error");
					exit = true;
	        	} else {
	        		team->remoteDriven = true;
	        		conn->onTeamAddCb(conn->onTeamAddCtx, team);
	        	}
	        	flib_team_release(team);
	        }
	    } else if (!strcmp(cmd, "REMOVE_TEAM")) {
	        if(netmsg->partCount != 2) {
	            flib_log_w("Net: Bad REMOVETEAM message");
	        } else {
	        	conn->onTeamDeleteCb(conn->onTeamDeleteCtx, netmsg->parts[1]);
	        }
	    } else if(!strcmp(cmd, "ROOMABANDONED")) {
	    	leaveRoom(conn);
	        conn->onLeaveRoomCb(conn->onLeaveRoomCtx, NETCONN_ROOMLEAVE_ABANDONED, "Room destroyed");
	    } else if(!strcmp(cmd, "KICKED")) {
	    	leaveRoom(conn);
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
					if (isMe) {
						if(flib_netbase_sendf(conn->netBase, "%s\n\n", "LIST")) {
							// If sending this fails, the protocol breaks (we'd be waiting infinitely for the room list)
							flib_netbase_sendf(net, "%s\n%s\n\n", "QUIT", "Client error");
							conn->netconnState = NETCONN_STATE_DISCONNECTED;
							conn->onDisconnectedCb(conn->onDisconnectedCtx, NETCONN_DISCONNECT_INTERNAL_ERROR, "Failed to send a critical message.");
							exit = true;
						}
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
	    		if(flib_roomlist_add(conn->roomList, netmsg->parts+2)) {
	    			flib_log_e("Error adding new room to list");
	    		} else {
	    			conn->onRoomAddCb(conn->onRoomAddCtx, conn->roomList->rooms[0]);
	    		}
			} else if(!strcmp(subcmd, "UPD") && netmsg->partCount == 11) {
	    		if(flib_roomlist_update(conn->roomList, netmsg->parts[2], netmsg->parts+3)) {
	    			flib_log_e("Error updating room in list");
	    		} else {
	    			conn->onRoomUpdateCb(conn->onRoomUpdateCtx, netmsg->parts[2], flib_roomlist_find(conn->roomList, netmsg->parts[2]));
	    		}
			} else if(!strcmp(subcmd, "DEL") && netmsg->partCount == 3) {
	    		if(flib_roomlist_delete(conn->roomList, netmsg->parts[2])) {
	    			flib_log_e("Error deleting room from list");
	    		} else {
	    			conn->onRoomDeleteCb(conn->onRoomDeleteCtx, netmsg->parts[2]);
	    		}
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
	        conn->netconnState = NETCONN_STATE_INGAME;
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
	        if (netmsg->partCount != 2) {
	            flib_log_w("Net: Bad TEAM_ACCEPTED message");
	        } else {
	        	conn->onTeamAcceptedCb(conn->onTeamAcceptedCtx, netmsg->parts[1]);
	        }
	    } else if (!strcmp(cmd, "CFG")) {
	        if(netmsg->partCount < 3) {
	            flib_log_w("Net: Bad CFG message");
	        } else {
	        	const char *subcmd = netmsg->parts[1];
				if(!strcmp(subcmd, "SCHEME") && netmsg->partCount == conn->metaCfg->modCount + conn->metaCfg->settingCount + 3) {
					flib_cfg *cfg = flib_netmsg_to_cfg(conn->metaCfg, netmsg->parts+2);
					if(cfg) {
						conn->onCfgSchemeCb(conn->onCfgSchemeCtx, cfg);
					} else {
						flib_log_e("Error processing CFG SCHEME message");
					}
					flib_cfg_release(cfg);
				} else if(!strcmp(subcmd, "FULLMAPCONFIG") && netmsg->partCount == 7) {
					flib_map *map = flib_netmsg_to_map(netmsg->parts+2);
					if(map) {
						flib_map_release(conn->map);
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
					uint8_t *drawnMapData = flib_netmsg_to_drawnmapdata(&drawnMapSize, netmsg->parts[2]);
					if(drawnMapData) {
						free(conn->map->drawData);
						conn->map->drawData = drawnMapData;
						conn->map->drawDataSize = drawnMapSize;
						conn->onMapChangedCb(conn->onMapChangedCtx, conn->map, NETCONN_MAPCHANGE_DRAWNMAP);
					} else {
						flib_log_e("Error processing CFG DRAWNMAP message");
					}
				} else if(!strcmp(subcmd, "SCRIPT") && netmsg->partCount == 3) {
					conn->onScriptChangedCb(conn->onScriptChangedCtx, netmsg->parts[2]);
				} else if(!strcmp(subcmd, "AMMO") && netmsg->partCount == 4) {
					flib_weaponset *weapons = flib_weaponset_from_ammostring(netmsg->parts[2], netmsg->parts[3]);
					if(weapons) {
						conn->onWeaponsetChangedCb(conn->onWeaponsetChangedCtx, weapons);
					} else {
						flib_log_e("Error processing CFG AMMO message");
					}
					flib_weaponset_release(weapons);
				} else {
					flib_log_w("Net: Unknown or malformed CFG subcommand: %s", subcmd);
				}
	        }
	    } else if (!strcmp(cmd, "HH_NUM")) {
	        if (netmsg->partCount != 3) {
	            flib_log_w("Net: Bad HH_NUM message");
	        } else {
	        	int hogs = atoi(netmsg->parts[2]);
	        	if(hogs<=0 || hogs>HEDGEHOGS_PER_TEAM) {
	        		flib_log_w("Net: Bad HH_NUM message: %s hogs", netmsg->parts[2]);
	        	} else {
	        		conn->onHogCountChangedCb(conn->onHogCountChangedCtx, netmsg->parts[1], hogs);
	        	}
	        }
	    } else if (!strcmp(cmd, "TEAM_COLOR")) {
	        if (netmsg->partCount != 3) {
	            flib_log_w("Net: Bad TEAM_COLOR message");
	        } else {
	        	long color;
	        	if(sscanf(netmsg->parts[2], "#%lx", &color)) {
	        		conn->onTeamColorChangedCb(conn->onTeamColorChangedCtx, netmsg->parts[1], (uint32_t)color);
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
						conn->onEngineMessageCb(conn->onEngineMessageCtx, out, outlen);
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
	    	conn->onAdminAccessCb(conn->onAdminAccessCtx);
	    	conn->isAdmin = true;
	    } else if (!strcmp(cmd, "ROOM_CONTROL_ACCESS")) {
	        if (netmsg->partCount < 2) {
	            flib_log_w("Net: Bad ROOM_CONTROL_ACCESS message");
	        } else {
	        	conn->isChief = strcmp("0", netmsg->parts[1]);
	        	conn->onRoomChiefStatusCb(conn->onRoomChiefStatusCtx, conn->isChief);
	        }
	    } else {
	    	flib_log_w("Unknown server command: %s", cmd);
	    }
		flib_netmsg_destroy(netmsg);
	}
}

void flib_netconn_tick(flib_netconn *conn) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_tick");
	} else if(conn->running) {
		flib_log_w("Call to flib_netconn_tick from a callback");
	} else if(conn->netconnState == NETCONN_STATE_DISCONNECTED) {
		flib_log_w("Call to flib_netconn_tick, but we are already done.");
	} else {
		conn->running = true;
		flib_netconn_wrappedtick(conn);
		conn->running = false;

		if(conn->destroyRequested) {
			flib_netconn_destroy(conn);
		}
	}
}
