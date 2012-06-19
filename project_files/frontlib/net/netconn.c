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

#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

struct _flib_netconn {
	flib_netbase *netBase;
	char *playerName;

	int netconnState;	// One of the NETCONN_STATE constants

	void (*onErrorCb)(void* context, int errorCode, const char *errorMsg);
	void *onErrorCtx;

	void (*onConnectedCb)(void *context, const char *serverMessage);
	void *onConnectedCtx;

	bool running;
	bool destroyRequested;
};

static void defaultCallback_onError(void* context, int errorCode, const char *errormsg) {}
static void defaultCallback_onConnected(void *context, const char *serverMessage) {}

static void clearCallbacks(flib_netconn *conn) {
	conn->onErrorCb = &defaultCallback_onError;
	conn->onConnectedCb = &defaultCallback_onConnected;
}


flib_netconn *flib_netconn_create(const char *playerName, const char *host, uint16_t port) {
	flib_netconn *result = NULL;
	flib_netconn *newConn = flib_calloc(1, sizeof(flib_netconn));
	if(newConn) {
		newConn->netconnState = NETCONN_STATE_AWAIT_CONNECTED;
		newConn->running = false;
		newConn->destroyRequested = false;
		clearCallbacks(newConn);
		newConn->netBase = flib_netbase_create(host, port);
		newConn->playerName = flib_strdupnull(playerName);
		if(newConn->netBase && newConn->playerName) {
			result = newConn;
			newConn = NULL;
		}
	}
	flib_netconn_destroy(newConn);
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
			free(conn->playerName);
			free(conn);
		}
	}
}

void flib_netconn_onError(flib_netconn *conn, void (*callback)(void *context, int errorCode, const char *errorMsg), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onError");
	} else {
		conn->onErrorCb = callback ? callback : &defaultCallback_onError;
		conn->onErrorCtx = context;
	}
}

void flib_netconn_onConnected(flib_netconn *conn, void (*callback)(void *context, const char *serverMessage), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_netconn_onConnected");
	} else {
		conn->onConnectedCb = callback ? callback : &defaultCallback_onConnected;
		conn->onConnectedCtx = context;
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

		const char *cmd = netmsg->parts[0];

	    if (!strcmp(cmd, "NICK") && netmsg->partCount>=2) {
	    	free(conn->playerName);
	    	conn->playerName = flib_strdupnull(netmsg->parts[1]);
	    	if(!conn->playerName) {
	    		// TODO handle error
	    	}
	    	// TODO callback?
	    } else if (!strcmp(cmd, "PROTO")) {
	        // The server just echoes this back apparently
		} else if (!strcmp(cmd, "ERROR")) {
			// TODO: onErrorMessage?
			if (netmsg->partCount == 2) {
				conn->onErrorCb(conn->onErrorCtx, NETCONN_ERROR_FROM_SERVER, netmsg->parts[1]);
			} else {
				conn->onErrorCb(conn->onErrorCtx, NETCONN_ERROR_FROM_SERVER, "Unknown Error");
			}
		} else if(!strcmp(cmd, "WARNING")) {
			// TODO: onWarnMessage?
			if (netmsg->partCount == 2) {
				conn->onErrorCb(conn->onErrorCtx, NETCONN_ERROR_FROM_SERVER, netmsg->parts[1]);
			} else {
				conn->onErrorCb(conn->onErrorCtx, NETCONN_ERROR_FROM_SERVER, "Unknown Warning");
			}
	    } else if(!strcmp(cmd, "CONNECTED")) {
			if(netmsg->partCount<3 || atol(netmsg->parts[2])<MIN_SERVER_VERSION) {
				flib_log_w("Server too old");
				flib_netbase_sendf(net, "%s\n%s\n\n", "QUIT", "Server too old");
				// TODO actually disconnect?
				conn->netconnState = NETCONN_STATE_DISCONNECTED;
				conn->onErrorCb(conn->onErrorCtx, NETCONN_ERROR_SERVER_TOO_OLD, "Server too old");
				exit = true;
			} else {
				flib_netbase_sendf(net, "%s\n%s\n\n", "NICK", conn->playerName);
				flib_netbase_sendf(net, "%s\n%i\n\n", "PROTO", (int)PROTOCOL_VERSION);
				conn->netconnState = NETCONN_STATE_LOBBY;
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
	        	// TODO
				//QStringList tmp = lst;
				//tmp.removeFirst();
				//m_roomsListModel->setRoomsList(tmp);
	        }
	    } else if (!strcmp(cmd, "SERVER_MESSAGE")) {
	        if(netmsg->partCount < 2) {
	        	flib_log_w("Net: Empty SERVERMESSAGE message");
	        } else {
	        	// TODO
	        	// emit serverMessage(lst[1]);
	        }
	    } else if (!strcmp(cmd, "CHAT")) {
	        if(netmsg->partCount < 3) {
	        	flib_log_w("Net: Empty CHAT message");
	        } else {
	        	// TODO
				// if (netClientState == InLobby)
				// 	emit chatStringLobby(lst[1], HWProto::formatChatMsgForFrontend(lst[2]));
				// else
				//	emit chatStringFromNet(HWProto::formatChatMsg(lst[1], lst[2]));
	        }
	    } else if (!strcmp(cmd, "INFO")) {
	        if(netmsg->partCount < 5) {
	        	flib_log_w("Net: Malformed INFO message");
	        } else {
	        	// TODO
//				QStringList tmp = lst;
//				tmp.removeFirst();
//				if (netClientState == InLobby)
//					emit chatStringLobby(tmp.join("\n").prepend('\x01'));
//				else
//					emit chatStringFromNet(tmp.join("\n").prepend('\x01'));
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
								// TODO
								// if (isChief && !setFlag) ToggleReady();
								// else emit setMyReadyStatus(setFlag);
							}
							// TODO
							// emit setReadyStatus(lst[i], setFlag);
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
	        	// TODO
//				QStringList tmp = lst;
//				tmp.removeFirst();
//				emit AddNetTeam(tmp);
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
//	        TODO
//	        askRoomsList();
//	        emit LeftRoom(tr("Room destroyed"));
	    } else if(!strcmp(cmd, "KICKED")) {
	    	conn->netconnState = NETCONN_STATE_LOBBY;
//	    	TODO
//	        askRoomsList();
//	        emit LeftRoom(tr("You got kicked"));
	    } else if(!strcmp(cmd, "JOINED")) {
	        if(netmsg->partCount < 2) {
	            flib_log_w("Net: Bad JOINED message");
	        } else {
				for(int i = 1; i < netmsg->partCount; ++i)
				{
					bool isMe = !strcmp(conn->playerName, netmsg->parts[i]);
					if (isMe) {
						conn->netconnState = NETCONN_STATE_ROOM;
//						TODO
//						emit EnteredGame();
//						emit roomMaster(isChief);
//						if (isChief)
//							emit configAsked();
					}

//					TODO
//					emit nickAdded(lst[i], isChief && !isMe));
//					emit chatStringFromNet(tr("%1 *** %2 has joined the room").arg('\x03').arg(lst[i]));
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
						conn->netconnState = NETCONN_STATE_LOBBY;
						// TODO
//						RawSendNet(QString("LIST"));
//						emit connected();
					}
					// TODO
//					emit nickAddedLobby(lst[i], false);
//					emit chatStringLobby(lst[i], tr("%1 *** %2 has joined").arg('\x03').arg("|nick|"));
				}
	        }
	    } else if(!strcmp(cmd, "LEFT")) {
	        if(netmsg->partCount < 2) {
	            flib_log_w("Net: Bad LEFT message");
	        } else {
	        	// TODO
//				emit nickRemoved(lst[1]);
//				if (netmsg->partCount < 3)
//					emit chatStringFromNet(tr("%1 *** %2 has left").arg('\x03').arg(lst[1]));
//				else
//					emit chatStringFromNet(tr("%1 *** %2 has left (%3)").arg('\x03').arg(lst[1], lst[2]));
	        }
	    } else if(!strcmp(cmd, "ROOM") && netmsg->partCount >= 2) {
	    	const char *subcmd = netmsg->parts[1];
	    	if(!strcmp(subcmd, "ADD") && netmsg->partCount == 10) {
	    		// TODO
//				QStringList tmp = lst;
//				tmp.removeFirst();
//				tmp.removeFirst();
//
//				m_roomsListModel->addRoom(tmp);
			} else if(!strcmp(subcmd, "UPD") && netmsg->partCount == 11) {
				// TODO
//				QStringList tmp = lst;
//				tmp.removeFirst();
//				tmp.removeFirst();
//
//				QString roomName = tmp.takeFirst();
//				m_roomsListModel->updateRoom(roomName, tmp);
			} else if(!strcmp(subcmd, "DEL") && netmsg->partCount == 3) {
				// TODO
				// m_roomsListModel->removeRoom(lst[2]);
			} else {
				flib_log_w("Net: Unknown or malformed ROOM subcommand: %s", subcmd);
			}
	    } else if(!strcmp(cmd, "LOBBY:LEFT")) {
	        if(netmsg->partCount < 2) {
	            flib_log_w("Net: Bad LOBBY:LEFT message");
	        } else {
	        	// TODO
//				emit nickRemovedLobby(lst[1]);
//				if (netmsg->partCount < 3)
//					emit chatStringLobby(tr("%1 *** %2 has left").arg('\x03').arg(lst[1]));
//				else
//					emit chatStringLobby(lst[1], tr("%1 *** %2 has left (%3)").arg('\x03').arg("|nick|", lst[2]));
	        }
	    } else if (!strcmp(cmd, "RUN_GAME")) {
	        conn->netconnState = NETCONN_STATE_INGAME;
	        // TODO
	        // emit AskForRunGame();
	    } else if (!strcmp(cmd, "ASKPASSWORD")) {
	    	// TODO
	        // emit AskForPassword(mynick);
	    } else if (!strcmp(cmd, "NOTICE")) {
	        if(netmsg->partCount < 2) {
	            flib_log_w("Net: Bad NOTICE message");
	        } else {
				errno = 0;
				long n = strtol(netmsg->parts[1], NULL, 10);
				if(errno) {
					flib_log_w("Net: Bad NOTICE message");
				} else {
					// TODO
					// handleNotice(n);
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
				if (!strcmp(netmsg->parts[1], "Authentication failed")) {
					// TODO
					//emit AuthFailed();
				}
				// TODO
//				m_game_connected = false;
//				Disconnect();
//				emit disconnected(lst[1]);
	        }
	    } else if (!strcmp(cmd, "ADMIN_ACCESS")) {
	    	// TODO
	        // emit adminAccess(true);
	    } else if (!strcmp(cmd, "ROOM_CONTROL_ACCESS")) {
	        if (netmsg->partCount < 2) {
	            flib_log_w("Net: Bad ROOM_CONTROL_ACCESS message");
	        } else {
	        	// TODO
//				isChief = (lst[1] != "0");
//				emit roomMaster(isChief);
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
