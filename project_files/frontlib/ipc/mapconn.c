#include "mapconn.h"
#include "ipcbase.h"
#include "ipcprotocol.h"

#include "../util/logging.h"
#include "../util/buffer.h"
#include "../util/util.h"

#include <stdlib.h>

typedef enum {
	AWAIT_CONNECTION,
	AWAIT_REPLY,
	FINISHED
} mapconn_state;

struct _flib_mapconn {
	uint8_t mapBuffer[IPCBASE_MAPMSG_BYTES];
	flib_ipcbase *ipcBase;
	flib_vector *configBuffer;

	mapconn_state progress;

	void (*onSuccessCb)(void*, const uint8_t*, int);
	void *onSuccessCtx;

	void (*onFailureCb)(void*, const char*);
	void *onFailureCtx;

	bool running;
	bool destroyRequested;
};

static void noop_handleSuccess(void *context, const uint8_t *bitmap, int numHedgehogs) {}
static void noop_handleFailure(void *context, const char *errormessage) {}

static void clearCallbacks(flib_mapconn *conn) {
	conn->onSuccessCb = &noop_handleSuccess;
	conn->onFailureCb = &noop_handleFailure;
}

static flib_vector *createConfigBuffer(flib_map *mapdesc) {
	flib_vector *result = NULL;
	flib_vector *tempbuffer = flib_vector_create();
	if(tempbuffer) {
		bool error = false;
		error |= flib_ipc_append_mapconf(tempbuffer, mapdesc, true);
		error |= flib_ipc_append_message(tempbuffer, "!");
		if(!error) {
			result = tempbuffer;
			tempbuffer = NULL;
		}
	}
	flib_vector_destroy(tempbuffer);
	return result;
}

flib_mapconn *flib_mapconn_create(flib_map *mapdesc) {
	flib_mapconn *result = NULL;
	flib_mapconn *tempConn = flib_calloc(1, sizeof(flib_mapconn));
	if(tempConn) {
		tempConn->ipcBase = flib_ipcbase_create();
		tempConn->configBuffer = createConfigBuffer(mapdesc);
		if(tempConn->ipcBase && tempConn->configBuffer) {
			tempConn->progress = AWAIT_CONNECTION;
			clearCallbacks(tempConn);
			result = tempConn;
			tempConn = NULL;
		}
	}
	flib_mapconn_destroy(tempConn);
	return result;
}

void flib_mapconn_destroy(flib_mapconn *conn) {
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
			flib_ipcbase_destroy(conn->ipcBase);
			flib_vector_destroy(conn->configBuffer);
			free(conn);
		}
	}
}

int flib_mapconn_getport(flib_mapconn *conn) {
	if(!conn) {
		flib_log_e("null parameter in flib_mapconn_getport");
		return 0;
	} else {
		return flib_ipcbase_port(conn->ipcBase);
	}
}

void flib_mapconn_onSuccess(flib_mapconn *conn, void (*callback)(void* context, const uint8_t *bitmap, int numHedgehogs), void *context) {
	if(!conn) {
		flib_log_e("null parameter in flib_mapconn_onSuccess");
	} else {
		conn->onSuccessCb = callback ? callback : &noop_handleSuccess;
		conn->onSuccessCtx = context;
	}
}

void flib_mapconn_onFailure(flib_mapconn *conn, void (*callback)(void* context, const char *errormessage), void *context) {
	if(!conn) {
		flib_log_e("null parameter in flib_mapconn_onError");
	} else {
		conn->onFailureCb = callback ? callback : &noop_handleFailure;
		conn->onFailureCtx = context;
	}
}

static void flib_mapconn_wrappedtick(flib_mapconn *conn) {
	if(conn->progress == AWAIT_CONNECTION) {
		flib_ipcbase_accept(conn->ipcBase);
		switch(flib_ipcbase_state(conn->ipcBase)) {
		case IPC_CONNECTED:
			{
				flib_constbuffer configBuffer = flib_vector_as_constbuffer(conn->configBuffer);
				if(flib_ipcbase_send_raw(conn->ipcBase, configBuffer.data, configBuffer.size)) {
					conn->progress = FINISHED;
					conn->onFailureCb(conn->onFailureCtx, "Error sending map information to the engine.");
					return;
				} else {
					conn->progress = AWAIT_REPLY;
				}
			}
			break;
		case IPC_NOT_CONNECTED:
			conn->progress = FINISHED;
			conn->onFailureCb(conn->onFailureCtx, "Engine connection closed unexpectedly.");
			return;
		default:
			break;
		}
	}

	if(conn->progress == AWAIT_REPLY) {
		if(flib_ipcbase_recv_map(conn->ipcBase, conn->mapBuffer) >= 0) {
			conn->progress = FINISHED;
			conn->onSuccessCb(conn->onSuccessCtx, conn->mapBuffer, conn->mapBuffer[IPCBASE_MAPMSG_BYTES-1]);
			return;
		} else if(flib_ipcbase_state(conn->ipcBase) != IPC_CONNECTED) {
			conn->progress = FINISHED;
			conn->onFailureCb(conn->onSuccessCtx, "Engine connection closed unexpectedly.");
			return;
		}
	}
}

void flib_mapconn_tick(flib_mapconn *conn) {
	if(!conn) {
		flib_log_e("null parameter in flib_mapconn_tick");
	} else if(conn->running) {
		flib_log_w("Call to flib_mapconn_tick from a callback");
	} else if(conn->progress == FINISHED) {
		flib_log_w("Call to flib_mapconn_tick, but we are already done. Best destroy your flib_mapconn object in the callbacks.");
	} else {
		conn->running = true;
		flib_mapconn_wrappedtick(conn);
		conn->running = false;

		if(conn->destroyRequested) {
			flib_mapconn_destroy(conn);
		}
	}
}
