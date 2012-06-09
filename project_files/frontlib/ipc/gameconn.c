#include "gameconn.h"
#include "ipcconn.h"
#include "ipcprotocol.h"
#include "../util/logging.h"
#include "../hwconsts.h"
#include <stdbool.h>
#include <stdlib.h>

typedef enum {
	AWAIT_CONNECTION,
	CONNECTED,
	FINISHED
} gameconn_state;

struct _flib_gameconn {
	flib_ipcconn connection;
	flib_vector configBuffer;

	gameconn_state state;
	bool netgame;

	void (*onConnectCb)(void* context);
	void *onConnectCtx;

	void (*onDisconnectCb)(void* context, int reason);
	void *onDisconnectCtx;

	void (*onErrorMessageCb)(void* context, const char *msg);
	void *onErrorMessageCtx;

	void (*onChatCb)(void* context, const char *msg, bool teamchat);
	void *onChatCtx;

	void (*onGameRecordedCb)(void *context, const uint8_t *record, int size, bool isSavegame);
	void *onGameRecordedCtx;

	void (*onNetMessageCb)(void *context, const uint8_t *em, int size);
	void *onNetMessageCtx;

	bool running;
	bool destroyRequested;
};

static void defaultCallback_onConnect(void* context) {}
static void defaultCallback_onDisconnect(void* context, int reason) {}
static void defaultCallback_onErrorMessage(void* context, const char *msg) {
	flib_log_w("Error from engine (no callback set): %s", msg);
}
static void defaultCallback_onChat(void* context, const char *msg, bool teamchat) {}
static void defaultCallback_onGameRecorded(void *context, const uint8_t *record, int size, bool isSavegame) {}
static void defaultCallback_onNetMessage(void *context, const uint8_t *em, int size) {}

static void clearCallbacks(flib_gameconn *conn) {
	conn->onConnectCb = &defaultCallback_onConnect;
	conn->onDisconnectCb = &defaultCallback_onDisconnect;
	conn->onErrorMessageCb = &defaultCallback_onErrorMessage;
	conn->onChatCb = &defaultCallback_onChat;
	conn->onGameRecordedCb = &defaultCallback_onGameRecorded;
	conn->onNetMessageCb = &defaultCallback_onNetMessage;
}

static bool getGameMod(flib_cfg_meta *meta, flib_cfg *conf, int maskbit) {
	for(int i=0; i<meta->modCount; i++) {
		if(meta->mods[i].bitmaskIndex == maskbit) {
			return conf->mods[i];
		}
	}
	flib_log_e("Unable to find game mod with mask bit %i", maskbit);
	return false;
}

static int fillConfigBuffer(flib_vector configBuffer, const char *playerName, flib_cfg_meta *metaconf, flib_gamesetup *setup, bool netgame) {
	bool error = false;
	bool perHogAmmo = false;
	bool sharedAmmo = false;

	error |= flib_ipc_append_message(configBuffer, netgame ? "TN" : "TL");
	error |= flib_ipc_append_seed(configBuffer, setup->seed);
	if(setup->map) {
		error |= flib_ipc_append_mapconf(configBuffer, setup->map, false);
	}
	if(setup->script) {
		error |= flib_ipc_append_message(configBuffer, "escript %s", setup->script);
	}
	if(setup->gamescheme) {
		error |= flib_ipc_append_gamescheme(configBuffer, setup->gamescheme, metaconf);
		perHogAmmo = getGameMod(metaconf, setup->gamescheme, GAMEMOD_PERHOGAMMO_MASKBIT);
		sharedAmmo = getGameMod(metaconf, setup->gamescheme, GAMEMOD_SHAREDAMMO_MASKBIT);
	}
	if(setup->teams) {
		for(int i=0; i<setup->teamcount; i++) {
			error |= flib_ipc_append_addteam(configBuffer, &setup->teams[i], perHogAmmo, sharedAmmo);
		}
	}
	error |= flib_ipc_append_message(configBuffer, "!");
	return error ? -1 : 0;
}

static flib_gameconn *flib_gameconn_create_partial(bool record, const char *playerName, bool netGame) {
	flib_gameconn *result = NULL;
	flib_gameconn *tempConn = calloc(1, sizeof(flib_gameconn));
	if(tempConn) {
		tempConn->connection = flib_ipcconn_create(record, playerName);
		tempConn->configBuffer = flib_vector_create();
		if(tempConn->connection && tempConn->configBuffer) {
			tempConn->state = AWAIT_CONNECTION;
			tempConn->netgame = netGame;
			clearCallbacks(tempConn);
			result = tempConn;
			tempConn = NULL;
		}
	}
	flib_gameconn_destroy(tempConn);
	return result;
}

flib_gameconn *flib_gameconn_create(const char *playerName, flib_cfg_meta *metaconf, flib_gamesetup *setup, bool netgame) {
	flib_gameconn *result = NULL;
	flib_gameconn *tempConn = flib_gameconn_create_partial(true, playerName, netgame);
	if(tempConn) {
		if(fillConfigBuffer(tempConn->configBuffer, playerName, metaconf, setup, netgame) == 0) {
			result = tempConn;
			tempConn = NULL;
		}
	}
	flib_gameconn_destroy(tempConn);
	return result;
}

flib_gameconn *flib_gameconn_create_playdemo(const uint8_t *demo, int size) {
	flib_gameconn *result = NULL;
	flib_gameconn *tempConn = flib_gameconn_create_partial(false, "Player", false);
	if(tempConn) {
		if(flib_vector_append(tempConn->configBuffer, demo, size) == size) {
			result = tempConn;
			tempConn = NULL;
		}
	}
	flib_gameconn_destroy(tempConn);
	return result;
}

flib_gameconn *flib_gameconn_create_loadgame(const char *playerName, const uint8_t *save, int size) {
	flib_gameconn *result = NULL;
	flib_gameconn *tempConn = flib_gameconn_create_partial(true, playerName, false);
	if(tempConn) {
		if(flib_vector_append(tempConn->configBuffer, save, size) == size) {
			result = tempConn;
			tempConn = NULL;
		}
	}
	flib_gameconn_destroy(tempConn);
	return result;
}

void flib_gameconn_destroy(flib_gameconn *conn) {
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
			flib_ipcconn_destroy(&conn->connection);
			flib_vector_destroy(&conn->configBuffer);
			free(conn);
		}
	}
}

int flib_gameconn_getport(flib_gameconn *conn) {
	if(!conn) {
		flib_log_e("null parameter in flib_gameconn_getport");
		return 0;
	} else {
		return flib_ipcconn_port(conn->connection);
	}
}

void flib_gameconn_onConnect(flib_gameconn *conn, void (*callback)(void* context), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_gameconn_onConnect");
	} else {
		conn->onConnectCb = callback ? callback : &defaultCallback_onConnect;
		conn->onConnectCtx = context;
	}
}

void flib_gameconn_onDisconnect(flib_gameconn *conn, void (*callback)(void* context, int reason), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_gameconn_onDisconnect");
	} else {
		conn->onDisconnectCb = callback ? callback : &defaultCallback_onDisconnect;
		conn->onDisconnectCtx = context;
	}
}

void flib_gameconn_onErrorMessage(flib_gameconn *conn, void (*callback)(void* context, const char *msg), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_gameconn_onErrorMessage");
	} else {
		conn->onErrorMessageCb = callback ? callback : &defaultCallback_onErrorMessage;
		conn->onErrorMessageCtx = context;
	}
}

void flib_gameconn_onChat(flib_gameconn *conn, void (*callback)(void* context, const char *msg, bool teamchat), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_gameconn_onChat");
	} else {
		conn->onChatCb = callback ? callback : &defaultCallback_onChat;
		conn->onChatCtx = context;
	}
}

void flib_gameconn_onGameRecorded(flib_gameconn *conn, void (*callback)(void *context, const uint8_t *record, int size, bool isSavegame), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_gameconn_onGameRecorded");
	} else {
		conn->onGameRecordedCb = callback ? callback : &defaultCallback_onGameRecorded;
		conn->onGameRecordedCtx = context;
	}
}

void flib_gameconn_onNetMessage(flib_gameconn *conn, void (*callback)(void *context, const uint8_t *em, int size), void* context) {
	if(!conn) {
		flib_log_e("null parameter in flib_gameconn_onNetMessage");
	} else {
		conn->onNetMessageCb = callback ? callback : &defaultCallback_onNetMessage;
		conn->onNetMessageCtx = context;
	}
}

static void flib_gameconn_wrappedtick(flib_gameconn *conn) {
	if(conn->state == AWAIT_CONNECTION) {
		flib_ipcconn_accept(conn->connection);
		switch(flib_ipcconn_state(conn->connection)) {
		case IPC_CONNECTED:
			{
				flib_constbuffer configBuffer = flib_vector_as_constbuffer(conn->configBuffer);
				if(flib_ipcconn_send_raw(conn->connection, configBuffer.data, configBuffer.size)) {
					conn->state = FINISHED;
					conn->onDisconnectCb(conn->onDisconnectCtx, GAME_END_ERROR);
					return;
				} else {
					conn->state = CONNECTED;
					conn->onConnectCb(conn->onConnectCtx);
					if(conn->destroyRequested) {
						return;
					}
				}
			}
			break;
		case IPC_NOT_CONNECTED:
			conn->state = FINISHED;
			conn->onDisconnectCb(conn->onDisconnectCtx, GAME_END_ERROR);
			return;
		default:
			break;
		}
	}

	if(conn->state == CONNECTED) {
		uint8_t msgbuffer[257];
		int len;
		while(!conn->destroyRequested && (len = flib_ipcconn_recv_message(conn->connection, msgbuffer))>=0) {
			if(len<2) {
				flib_log_w("Received short message from IPC (<2 bytes)");
				continue;
			}
			switch(msgbuffer[1]) {
			case '?':
				// The pong is already part of the config message
				break;
			case 'C':
				// And we already send the config message on connecting.
				break;
			case 'E':
				if(len>=3) {
					msgbuffer[len-2] = 0;
					conn->onErrorMessageCb(conn->onErrorMessageCtx, (char*)msgbuffer+2);
				}
				break;
			case 'i':
				// TODO stats
				break;
			case 'Q':
			case 'H':
			case 'q':
				{
					int reason = msgbuffer[1]=='Q' ? GAME_END_INTERRUPTED : msgbuffer[1]=='H' ? GAME_END_HALTED : GAME_END_FINISHED;
					bool savegame = (reason != GAME_END_FINISHED) && !conn->netgame;
					flib_constbuffer record = flib_ipcconn_getrecord(conn->connection, savegame);
					if(record.size) {
						conn->onGameRecordedCb(conn->onGameRecordedCtx, record.data, record.size, savegame);
						if(conn->destroyRequested) {
							return;
						}
					}
					conn->state = FINISHED;
					conn->onDisconnectCb(conn->onDisconnectCtx, reason);
					return;
				}
			case 's':
				if(len>=3) {
					msgbuffer[len-2] = 0;
					conn->onChatCb(conn->onChatCtx, (char*)msgbuffer+2, false);
				}
				break;
			case 'b':
				if(len>=3) {
					msgbuffer[len-2] = 0;
					conn->onChatCb(conn->onChatCtx, (char*)msgbuffer+2, true);
				}
				break;
			default:
				conn->onNetMessageCb(conn->onNetMessageCtx, msgbuffer, len);
				break;
			}
		}
	}

	if(flib_ipcconn_state(conn->connection) == IPC_NOT_CONNECTED) {
		conn->state = FINISHED;
		conn->onDisconnectCb(conn->onDisconnectCtx, GAME_END_ERROR);
	}
}

void flib_gameconn_tick(flib_gameconn *conn) {
	if(!conn) {
		flib_log_e("null parameter in flib_gameconn_tick");
	} else if(conn->running) {
		flib_log_w("Call to flib_gameconn_tick from a callback");
	} else if(conn->state == FINISHED) {
		flib_log_w("Call to flib_gameconn_tick, but we are already done.");
	} else {
		conn->running = true;
		flib_gameconn_wrappedtick(conn);
		conn->running = false;

		if(conn->destroyRequested) {
			flib_gameconn_destroy(conn);
		}
	}
}
