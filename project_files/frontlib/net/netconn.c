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

#include "netconn.h"
#include "netbase.h"
#include "netprotocol.h"
#include "../util/logging.h"
#include "../util/util.h"
#include "../model/roomlist.h"
#include "../md5/md5.h"

#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>

struct _flib_netconn {
	flib_netbase *netBase;
	char *playerName;
	flib_cfg_meta *metaCfg;
	flib_roomlist *roomList;

	int netconnState;	// One of the NETCONN_STATE constants

	bool isAdmin;			// Player is server administrator
	bool isChief;			// Player can modify the current room


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

	void (*onNickAcceptCb)(void *context, const char *nick);
	void *onNickAcceptCtx;

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

	bool running;
	bool destroyRequested;
};

static void defaultCallback_onMessage(void *context, int msgtype, const char *msg) {
	flib_log_i("Net: [%i] %s", msgtype, msg);
}

static void defaultCallback_void(void *context) {}
static void defaultCallback_bool(void *context, bool isChief) {}
static void defaultCallback_str(void *context, const char *str) {}
static void defaultCallback_int_str(void *context, int i, const char *str) {}
static void defaultCallback_str_str(void *context, const char *str1, const char *str2) {}
static void defaultCallback_str_bool(void *context, const char *str, bool b) {}

static void defaultCallback_onRoomAdd(void *context, const flib_roomlist_room *room) {}
static void defaultCallback_onRoomUpdate(void *context, const char *oldName, const flib_roomlist_room *room) {}
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

static void defaultCallback_onTeamAdd(void *context, flib_team *team) {}

static void clearCallbacks(flib_netconn *conn) {
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
	flib_netconn_onNickAccept(conn, NULL, NULL);
	flib_netconn_onPasswordRequest(conn, NULL, NULL);
	flib_netconn_onRoomChiefStatus(conn, NULL, NULL);
	flib_netconn_onReadyStateCb(conn, NULL, NULL);
	flib_netconn_onEnterRoomCb(conn, NULL, NULL);
	flib_netconn_onTeamAddCb(conn, NULL, NULL);
}

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

int flib_netconn_send_quit(flib_netconn *conn, const char *quitmsg) {
	int result = -1;
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_send_quit");
	} else {
		result = flib_netbase_sendf(conn->netBase, "%s\n%s\n\n", "QUIT", quitmsg ? quitmsg : "User quit");
	}
	return result;
}

int flib_netconn_send_chat(flib_netconn *conn, const char *chat) {
	int result = -1;
	if(!conn || !chat) {
		flib_log_e("null parameter in flib_netconn_send_chat");
	} else {
		result = flib_netbase_sendf(conn->netBase, "%s\n%s\n\n", "CHAT", chat);
	}
	return result;
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

/*
 * Callback registration functions
 */

void flib_netconn_onMessage(flib_netconn *conn, void (*callback)(void *context, int msgtype, const char *msg), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onMessage");
	} else {
		conn->onMessageCb = callback ? callback : &defaultCallback_onMessage;
		conn->onMessageCtx = context;
	}
}

void flib_netconn_onConnected(flib_netconn *conn, void (*callback)(void *context), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onConnected");
	} else {
		conn->onConnectedCb = callback ? callback : &defaultCallback_void;
		conn->onConnectedCtx = context;
	}
}

void flib_netconn_onDisconnected(flib_netconn *conn, void (*callback)(void *context, int reason, const char *message), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onDisconnected");
	} else {
		conn->onDisconnectedCb = callback ? callback : &defaultCallback_int_str;
		conn->onDisconnectedCtx = context;
	}
}

void flib_netconn_onRoomAdd(flib_netconn *conn, void (*callback)(void *context, const flib_roomlist_room *room), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onRoomAdd");
	} else {
		conn->onRoomAddCb = callback ? callback : &defaultCallback_onRoomAdd;
		conn->onRoomAddCtx = context;
	}
}

void flib_netconn_onRoomDelete(flib_netconn *conn, void (*callback)(void *context, const char *name), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onRoomDelete");
	} else {
		conn->onRoomDeleteCb = callback ? callback : &defaultCallback_str;
		conn->onRoomDeleteCtx = context;
	}
}

void flib_netconn_onRoomUpdate(flib_netconn *conn, void (*callback)(void *context, const char *oldName, const flib_roomlist_room *room), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onRoomUpdate");
	} else {
		conn->onRoomUpdateCb = callback ? callback : &defaultCallback_onRoomUpdate;
		conn->onRoomUpdateCtx = context;
	}
}

void flib_netconn_onChat(flib_netconn *conn, void (*callback)(void *context, const char *nick, const char *msg), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onChat");
	} else {
		conn->onChatCb = callback ? callback : &defaultCallback_onChat;
		conn->onChatCtx = context;
	}
}

void flib_netconn_onLobbyJoin(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onLobbyJoin");
	} else {
		conn->onLobbyJoinCb = callback ? callback : &defaultCallback_str;
		conn->onLobbyJoinCtx = context;
	}
}

void flib_netconn_onLobbyLeave(flib_netconn *conn, void (*callback)(void *context, const char *nick, const char *partMsg), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onLobbyLeave");
	} else {
		conn->onLobbyLeaveCb = callback ? callback : &defaultCallback_str_str;
		conn->onLobbyLeaveCtx = context;
	}
}

void flib_netconn_onRoomJoin(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onRoomJoin");
	} else {
		conn->onRoomJoinCb = callback ? callback : &defaultCallback_str;
		conn->onRoomJoinCtx = context;
	}
}

void flib_netconn_onRoomLeave(flib_netconn *conn, void (*callback)(void *context, const char *nick, const char *partMessage), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onRoomLeave");
	} else {
		conn->onRoomLeaveCb = callback ? callback : &defaultCallback_str_str;
		conn->onRoomLeaveCtx = context;
	}
}

void flib_netconn_onNickTaken(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onNickTaken");
	} else if(!callback) {
		conn->onNickTakenCb = &defaultCallback_onNickTaken;
		conn->onNickTakenCtx = conn;
	} else {
		conn->onNickTakenCb = callback;
		conn->onNickTakenCtx = context;
	}
}

void flib_netconn_onNickAccept(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onNickAccept");
	} else {
		conn->onNickAcceptCb = callback ? callback : &defaultCallback_str;
		conn->onNickAcceptCtx = context;
	}
}

void flib_netconn_onPasswordRequest(flib_netconn *conn, void (*callback)(void *context, const char *nick), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onPasswordRequest");
	} else if(!callback) {
		conn->onPasswordRequestCb = &defaultCallback_onPasswordRequest;
		conn->onPasswordRequestCtx = conn;
	} else {
		conn->onPasswordRequestCb = callback;
		conn->onPasswordRequestCtx = context;
	}
}

void flib_netconn_onRoomChiefStatus(flib_netconn *conn, void (*callback)(void *context, bool chief), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onRoomChiefStatus");
	} else {
		conn->onRoomChiefStatusCb = callback ? callback : &defaultCallback_bool;
		conn->onRoomChiefStatusCtx = context;
	}
}

void flib_netconn_onReadyStateCb(flib_netconn *conn, void (*callback)(void *context, const char *nick, bool ready), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onReadyStateCb");
	} else {
		conn->onReadyStateCb = callback ? callback : &defaultCallback_str_bool;
		conn->onReadyStateCtx = context;
	}
}

void flib_netconn_onEnterRoomCb(flib_netconn *conn, void (*callback)(void *context, bool chief), void *context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onEnterRoomCb");
	} else {
		conn->onEnterRoomCb = callback ? callback : &defaultCallback_bool;
		conn->onEnterRoomCtx = context;
	}
}

void flib_netconn_onLeaveRoomCb(flib_netconn *conn, void (*callback)(void *context, int reason, const char *message), void *context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onLeaveRoomCb");
	} else {
		conn->onLeaveRoomCb = callback ? callback : &defaultCallback_int_str;
		conn->onLeaveRoomCtx = context;
	}
}

void flib_netconn_onTeamAddCb(flib_netconn *conn, void (*callback)(void *context, flib_team *team), void *context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onTeamAddCb");
	} else {
		conn->onTeamAddCb = callback ? callback : &defaultCallback_onTeamAdd;
		conn->onTeamAddCtx = context;
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
				free(conn->playerName);
				conn->playerName = flib_strdupnull(netmsg->parts[1]);
				if(!conn->playerName) {
					conn->netconnState = NETCONN_STATE_DISCONNECTED;
					conn->onDisconnectedCb(conn->onDisconnectedCtx, NETCONN_DISCONNECT_INTERNAL_ERROR, "Out of memory");
					exit = true;
				} else {
					conn->onNickAcceptCb(conn->onNickAcceptCtx, conn->playerName);
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
	    	// TODO
//	        QStringList tmp = lst;
//	        tmp.removeFirst();
//	        while (tmp.size() >= 2)
//	        {
//	            if(tmp[0] == "MOTD_NEW") emit serverMessageNew(tmp[1]);
//	            else if(tmp[0] == "MOTD_OLD") emit serverMessageOld(tmp[1]);
//	            else if(tmp[0] == "LATEST_PROTO") emit latestProtocolVar(tmp[1].toInt());
//
//	            tmp.removeFirst();
//	            tmp.removeFirst();
//	        }
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
							if (!strcmp(conn->playerName, netmsg->parts[i])) {
								// TODO what is the reason behind this (copied from QtFrontend)?
								if (conn->isChief && !setFlag) {
									flib_netbase_sendf(conn->netBase, "%s\n\n", "TOGGLE_READY");
								}
							}
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
	        		conn->onTeamAddCb(conn->onTeamAddCtx, team);
	        	}
	        }
	    } else if (!strcmp(cmd, "REMOVE_TEAM")) {
	        if(netmsg->partCount != 2) {
	            flib_log_w("Net: Bad REMOVETEAM message");
	        } else {
	        	// TODO
	        	// emit RemoveNetTeam(HWTeam(lst[1]));
	        }
	    } else if(!strcmp(cmd, "ROOMABANDONED")) {
	        conn->netconnState = NETCONN_STATE_LOBBY;
	        conn->onLeaveRoomCb(conn->onLeaveRoomCtx, NETCONN_ROOMLEAVE_ABANDONED, "Room destroyed");
	    } else if(!strcmp(cmd, "KICKED")) {
	    	conn->netconnState = NETCONN_STATE_LOBBY;
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
	        // TODO
	        // emit AskForRunGame();
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
	        	// TODO
	        	// emit TeamAccepted(lst[1]);
	        }
	    } else if (!strcmp(cmd, "CFG")) {
	        if(netmsg->partCount < 3) {
	            flib_log_w("Net: Bad CFG message");
	        } else {
	        	// TODO
//				QStringList tmp = lst;
//				tmp.removeFirst();
//				tmp.removeFirst();
//				if (lst[1] == "SCHEME")
//					emit netSchemeConfig(tmp);
//				else
//					emit paramChanged(lst[1], tmp);
	        }
	    } else if (!strcmp(cmd, "HH_NUM")) {
	        if (netmsg->partCount != 3) {
	            flib_log_w("Net: Bad TEAM_ACCEPTED message");
	        } else {
	        	// TODO
//				HWTeam tmptm(lst[1]);
//				tmptm.setNumHedgehogs(lst[2].toUInt());
//				emit hhnumChanged(tmptm);
	        }
	    } else if (!strcmp(cmd, "TEAM_COLOR")) {
	        if (netmsg->partCount != 3) {
	            flib_log_w("Net: Bad TEAM_COLOR message");
	        } else {
	        	// TODO
//				HWTeam tmptm(lst[1]);
//				tmptm.setColor(lst[2].toInt());
//				emit teamColorChanged(tmptm);
	        }
	    } else if (!strcmp(cmd, "EM")) {
	        if(netmsg->partCount < 2) {
	            flib_log_w("Net: Bad EM message");
	        } else {
	        	// TODO
//				for(int i = 1; i < netmsg->partCount; ++i) {
//					QByteArray em = QByteArray::fromBase64(lst[i].toAscii());
//					emit FromNet(em);
//				}
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
	    	// TODO callback?
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
