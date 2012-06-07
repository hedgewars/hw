#include "ipc.h"
#include "ipcconn.h"
#include "logging.h"

#include <stdbool.h>
#include <stdlib.h>

typedef struct _flib_ipc {
	flib_ipcconn connection;
	IpcConnState oldConnState;

	void (*onConnectCb)(void*);
	void *onConnectCtx;

	void (*onDisconnectCb)(void*);
	void *onDisconnectCtx;

	void (*onConfigQueryCb)(void*);
	void *onConfigQueryCtx;

	void (*onEngineErrorCb)(void*, const uint8_t*);
	void *onEngineErrorCtx;

	void (*onGameEndCb)(void*, int);
	void *onGameEndCtx;

	void (*onChatCb)(void*, const uint8_t*, int);
	void *onChatCtx;

	void (*onEngineMessageCb)(void*, const uint8_t*, int);
	void *onEngineMessageCtx;

	bool running;
	bool destroyRequested;
} _flib_ipc;

static void emptyCallback(void* ptr) {}
static void emptyCallback_int(void* ptr, int i) {}
static void emptyCallback_str(void* ptr, const uint8_t* str) {}
static void emptyCallback_str_int(void* ptr, const uint8_t* str, int i) {}

static void clearCallbacks(flib_ipc ipc) {
	ipc->onConnectCb = &emptyCallback;
	ipc->onDisconnectCb = &emptyCallback;
	ipc->onConfigQueryCb = &emptyCallback;
	ipc->onEngineErrorCb = &emptyCallback_str;
	ipc->onGameEndCb = &emptyCallback_int;
	ipc->onChatCb = &emptyCallback_str_int;
	ipc->onEngineMessageCb = &emptyCallback_str_int;
}

flib_ipc flib_ipc_create(bool recordDemo, const char *localPlayerName) {
	flib_ipc result = malloc(sizeof(_flib_ipc));
	flib_ipcconn connection = flib_ipcconn_create(recordDemo, localPlayerName);

	if(!result || !connection) {
		free(result);
		flib_ipcconn_destroy(&connection);
		return NULL;
	}

	result->connection = connection;
	result->oldConnState = IPC_LISTENING;
	result->running = false;
	result->destroyRequested = false;

	clearCallbacks(result);
	return result;
}

void flib_ipc_destroy(flib_ipc *ipcptr) {
	if(!ipcptr || !*ipcptr) {
		return;
	}
	flib_ipc ipc = *ipcptr;
	if(ipc->running) {
		// The function was called from a callback of this ipc connection,
		// so the tick function is still running and we delay the actual
		// destruction. We ensure no further callbacks will be sent to prevent
		// surprises.
		clearCallbacks(ipc);
		ipc->destroyRequested = true;
	} else {
		flib_ipcconn_destroy(&ipc->connection);
		free(ipc);
	}
	*ipcptr = NULL;
}

void flib_ipc_onConnect(flib_ipc ipc, void (*callback)(void* context), void* context) {
	if(!ipc) {
		flib_log_w("Call to flib_ipc_onConnect with ipc==null");
		return;
	}
	ipc->onConnectCb = callback ? callback : &emptyCallback;
	ipc->onConnectCtx = context;
}

void flib_ipc_onDisconnect(flib_ipc ipc, void (*callback)(void* context), void* context) {
	if(!ipc) {
		flib_log_w("Call to flib_ipc_onDisconnect with ipc==null");
		return;
	}
	ipc->onDisconnectCb = callback ? callback : &emptyCallback;
	ipc->onDisconnectCtx = context;
}

void flib_ipc_onConfigQuery(flib_ipc ipc, void (*callback)(void* context), void* context) {
	if(!ipc) {
		flib_log_w("Call to flib_ipc_onConfigQuery with ipc==null");
		return;
	}
	ipc->onConfigQueryCb = callback ? callback : &emptyCallback;
	ipc->onConfigQueryCtx = context;
}

void flib_ipc_onEngineError(flib_ipc ipc, void (*callback)(void* context, const uint8_t *error), void* context) {
	if(!ipc) {
		flib_log_w("Call to flib_ipc_onEngineError with ipc==null");
		return;
	}
	ipc->onEngineErrorCb = callback ? callback : &emptyCallback_str;
	ipc->onEngineErrorCtx = context;
}

void flib_ipc_onGameEnd(flib_ipc ipc, void (*callback)(void* context, int gameEndType), void* context) {
	if(!ipc) {
		flib_log_w("Call to flib_ipc_onGameEnd with ipc==null");
		return;
	}
	ipc->onGameEndCb = callback ? callback : &emptyCallback_int;
	ipc->onGameEndCtx = context;
}

void flib_ipc_onChat(flib_ipc ipc, void (*callback)(void* context, const uint8_t *messagestr, int teamchat), void* context) {
	if(!ipc) {
		flib_log_w("Call to flib_ipc_onChat with ipc==null");
		return;
	}
	ipc->onChatCb = callback ? callback : &emptyCallback_str_int;
	ipc->onChatCtx = context;
}

void flib_ipc_onEngineMessage(flib_ipc ipc, void (*callback)(void* context, const uint8_t *message, int len), void* context) {
	if(!ipc) {
		flib_log_w("Call to flib_ipc_onEngineMessage with ipc==null");
		return;
	}
	ipc->onEngineMessageCb = callback ? callback : &emptyCallback_str_int;
	ipc->onEngineMessageCtx = context;
}

static void flib_ipc_wrappedtick(flib_ipc ipc) {
	if(ipc->oldConnState == IPC_NOT_CONNECTED) {
		return;
	}

	if(ipc->oldConnState == IPC_LISTENING) {
		flib_ipcconn_accept(ipc->connection);
		if(flib_ipcconn_state(ipc->connection) == IPC_CONNECTED) {
			ipc->oldConnState = IPC_CONNECTED;
			ipc->onConnectCb(ipc->onConnectCtx);
		}
	}

	if(ipc->oldConnState == IPC_CONNECTED) {
		uint8_t msgbuffer[257];
		int len;
		while(!ipc->destroyRequested && (len = flib_ipcconn_recv_message(ipc->connection, msgbuffer))>=0) {
			if(len<2) {
				flib_log_w("Received short message from IPC (<2 bytes)");
				continue;
			}
			msgbuffer[len] = 0;
			flib_log_i("[IPC in] %s", msgbuffer+1);
			switch(msgbuffer[1]) {
			case '?':
				flib_ipcconn_send_messagestr(ipc->connection, "!");
				break;
			case 'C':
				ipc->onConfigQueryCb(ipc->onConfigQueryCtx);
				break;
			case 'E':
				if(len>=3) {
					msgbuffer[len-2] = 0;
					ipc->onEngineErrorCb(ipc->onEngineErrorCtx, msgbuffer+2);
				}
				break;
			case 'i':
				// TODO
				break;
			case 'Q':
				ipc->onGameEndCb(ipc->onGameEndCtx, GAME_END_INTERRUPTED);
				break;
			case 'q':
				ipc->onGameEndCb(ipc->onGameEndCtx, GAME_END_FINISHED);
				break;
			case 'H':
				ipc->onGameEndCb(ipc->onGameEndCtx, GAME_END_HALTED);
				break;
			case 's':
				if(len>=3) {
					msgbuffer[len-2] = 0;
					ipc->onChatCb(ipc->onChatCtx, msgbuffer+2, 0);
				}
				break;
			case 'b':
				if(len>=3) {
					msgbuffer[len-2] = 0;
					ipc->onChatCb(ipc->onChatCtx, msgbuffer+2, 1);
				}
				break;
			default:
				ipc->onEngineMessageCb(ipc->onEngineMessageCtx, msgbuffer, len);
				break;
			}
		}
	}

	if(flib_ipcconn_state(ipc->connection) == IPC_NOT_CONNECTED) {
		ipc->oldConnState = IPC_NOT_CONNECTED;
		ipc->onDisconnectCb(ipc->onDisconnectCtx);
	}
}

void flib_ipc_tick(flib_ipc ipc) {
	if(!ipc) {
		flib_log_w("Call to flib_ipc_tick with ipc==null");
		return;
	}
	if(ipc->running) {
		flib_log_w("Call to flib_ipc_tick from a callback");
		return;
	}

	ipc->running = true;
	flib_ipc_wrappedtick(ipc);
	ipc->running = false;

	if(ipc->destroyRequested) {
		flib_ipc_destroy(&ipc);
	}
}

int flib_ipc_send_raw(flib_ipc ipc, void *data, size_t len) {
	if(!ipc) {
		flib_log_w("Call to flib_ipc_send_raw with ipc==null");
		return -1;
	}
	return flib_ipcconn_send_raw(ipc->connection, data, len);
}

int flib_ipc_send_message(flib_ipc ipc, void *data, size_t len) {
	if(!ipc) {
		flib_log_w("Call to flib_ipc_send_message with ipc==null");
		return -1;
	}
	return flib_ipcconn_send_message(ipc->connection, data, len);
}

int flib_ipc_send_messagestr(flib_ipc ipc, char *data) {
	if(!ipc) {
		flib_log_w("Call to flib_ipc_send_messagestr with ipc==null");
		return -1;
	}
	return flib_ipcconn_send_messagestr(ipc->connection, data);
}

uint16_t flib_ipc_port(flib_ipc ipc) {
	if(!ipc) {
		flib_log_w("Call to flib_ipc_send_messagestr with ipc==null");
		return 0;
	}
	return flib_ipcconn_port(ipc->connection);
}

flib_constbuffer flib_ipc_getdemo(flib_ipc ipc) {
	if(!ipc) {
		flib_log_w("Call to flib_ipc_send_messagestr with ipc==null");
		flib_constbuffer result = {NULL, 0};
		return result;
	}
	return flib_ipcconn_getrecord(ipc->connection, false);
}
