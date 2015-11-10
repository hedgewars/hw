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
    AWAIT_CLOSE,
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

static flib_vector *createConfigBuffer(const flib_map *mapdesc) {
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

flib_mapconn *flib_mapconn_create(const flib_map *mapdesc) {
    if(log_badargs_if(mapdesc==NULL)) {
        return NULL;
    }
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
    if(log_badargs_if(conn==NULL)) {
        return 0;
    }
    return flib_ipcbase_port(conn->ipcBase);
}

void flib_mapconn_onSuccess(flib_mapconn *conn, void (*callback)(void* context, const uint8_t *bitmap, int numHedgehogs), void *context) {
    if(!log_badargs_if(conn==NULL)) {
        conn->onSuccessCb = callback ? callback : &noop_handleSuccess;
        conn->onSuccessCtx = context;
    }
}

void flib_mapconn_onFailure(flib_mapconn *conn, void (*callback)(void* context, const char *errormessage), void *context) {
    if(!log_badargs_if(conn==NULL)) {
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
            conn->progress = AWAIT_CLOSE;
        } else if(flib_ipcbase_state(conn->ipcBase) != IPC_CONNECTED) {
            conn->progress = FINISHED;
            conn->onFailureCb(conn->onSuccessCtx, "Engine connection closed unexpectedly.");
            return;
        }
    }

    if(conn->progress == AWAIT_CLOSE) {
        // Just do throwaway reads so we find out when the engine disconnects
        uint8_t buf[256];
        flib_ipcbase_recv_message(conn->ipcBase, buf);
        if(flib_ipcbase_state(conn->ipcBase) != IPC_CONNECTED) {
            conn->progress = FINISHED;
            conn->onSuccessCb(conn->onSuccessCtx, conn->mapBuffer, conn->mapBuffer[IPCBASE_MAPMSG_BYTES-1]);
            return;
        }
    }
}

void flib_mapconn_tick(flib_mapconn *conn) {
    if(!log_badargs_if(conn==NULL)
            && !log_w_if(conn->running, "Call to flib_mapconn_tick from a callback")
            && !log_w_if(conn->progress == FINISHED, "We are already done.")) {
        conn->running = true;
        flib_mapconn_wrappedtick(conn);
        conn->running = false;

        if(conn->destroyRequested) {
            flib_mapconn_destroy(conn);
        }
    }
}
