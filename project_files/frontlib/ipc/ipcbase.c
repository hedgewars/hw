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

#include "ipcbase.h"
#include "../util/logging.h"
#include "../util/util.h"
#include "../socket.h"

#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>

/*
 * The receive buffer has to be able to hold any message that might be received. Normally
 * the messages are at most 256 bytes, but the map preview contains 4097 bytes (4096 for a
 * bitmap, 1 for the number of hogs which fit on the map).
 *
 * We don't need to worry about wasting a few kb though, and I like powers of two...
 */
struct _flib_ipcbase {
    uint8_t readBuffer[8192];
    int readBufferSize;

    flib_acceptor *acceptor;
    uint16_t port;

    flib_tcpsocket *sock;
};

flib_ipcbase *flib_ipcbase_create() {
    flib_ipcbase *result = flib_calloc(1, sizeof(flib_ipcbase));
    flib_acceptor *acceptor = flib_acceptor_create(0);

    if(!result || !acceptor) {
        free(result);
        flib_acceptor_close(acceptor);
        return NULL;
    }

    result->acceptor = acceptor;
    result->sock = NULL;
    result->readBufferSize = 0;
    result->port = flib_acceptor_listenport(acceptor);

    flib_log_i("Started listening for IPC connections on port %u", (unsigned)result->port);
    return result;
}

uint16_t flib_ipcbase_port(flib_ipcbase *ipc) {
    if(log_badargs_if(ipc==NULL)) {
        return 0;
    }
    return ipc->port;
}

void flib_ipcbase_destroy(flib_ipcbase *ipc) {
    if(ipc) {
        flib_acceptor_close(ipc->acceptor);
        flib_socket_close(ipc->sock);
        if(ipc->sock) {
            flib_log_d("IPC connection closed.");
        }
        free(ipc);
    }
}

IpcState flib_ipcbase_state(flib_ipcbase *ipc) {
    if(log_badargs_if(ipc==NULL)) {
        return IPC_NOT_CONNECTED;
    } else if(ipc->sock) {
        return IPC_CONNECTED;
    } else if(ipc->acceptor) {
        return IPC_LISTENING;
    } else {
        return IPC_NOT_CONNECTED;
    }
}

static void receiveToBuffer(flib_ipcbase *ipc) {
    if(ipc->sock) {
        int size = flib_socket_nbrecv(ipc->sock, ipc->readBuffer+ipc->readBufferSize, sizeof(ipc->readBuffer)-ipc->readBufferSize);
        if(size>=0) {
            ipc->readBufferSize += size;
        } else {
            flib_log_d("IPC connection lost.");
            flib_socket_close(ipc->sock);
            ipc->sock = NULL;
        }
    }
}

static bool isMessageReady(flib_ipcbase *ipc) {
    return ipc->readBufferSize >= ipc->readBuffer[0]+1;
}

static void logSentMsg(const uint8_t *data, size_t len) {
    if(flib_log_isActive(FLIB_LOGLEVEL_DEBUG)) {
        size_t msgStart = 0;
        while(msgStart < len) {
            uint8_t msglen = data[msgStart];
            if(msgStart+msglen < len) {
                flib_log_d("[IPC OUT][%03u]%*.*s",(unsigned)msglen, (unsigned)msglen, (unsigned)msglen, data+msgStart+1);
            } else {
                uint8_t msglen2 = len-msgStart-1;
                flib_log_d("[IPC OUT][%03u/%03u]%*.*s",(unsigned)msglen2, (unsigned)msglen, (unsigned)msglen2, (unsigned)msglen2, data+msgStart+1);
            }
            msgStart += (uint8_t)data[msgStart]+1;
        }
    }
}

static void logRecvMsg(const uint8_t *data) {
    if(flib_log_isActive(FLIB_LOGLEVEL_DEBUG)) {
        uint8_t msglen = data[0];
        flib_log_d("[IPC IN][%03u]%*.*s",(unsigned)msglen, (unsigned)msglen, (unsigned)msglen, data+1);
    }
}

static void popFromReadBuffer(flib_ipcbase *ipc, uint8_t *outbuf, size_t size) {
    memcpy(outbuf, ipc->readBuffer, size);
    memmove(ipc->readBuffer, ipc->readBuffer+size, ipc->readBufferSize-size);
    ipc->readBufferSize -= size;
}

int flib_ipcbase_recv_message(flib_ipcbase *ipc, void *data) {
    if(log_badargs_if2(ipc==NULL, data==NULL)) {
        return -1;
    }

    if(!isMessageReady(ipc)) {
        receiveToBuffer(ipc);
    }

    if(isMessageReady(ipc)) {
        int msgsize = ipc->readBuffer[0]+1;
        popFromReadBuffer(ipc, data, msgsize);
        logRecvMsg(data);
        return msgsize;
    } else if(!ipc->sock && ipc->readBufferSize>0) {
        flib_log_w("Last message from engine data stream is incomplete (received %u of %u bytes)", (unsigned)ipc->readBufferSize, (unsigned)(ipc->readBuffer[0])+1);
        ipc->readBufferSize = 0;
        return -1;
    } else {
        return -1;
    }
}

int flib_ipcbase_recv_map(flib_ipcbase *ipc, void *data) {
    if(log_badargs_if2(ipc==NULL, data==NULL)) {
        return -1;
    }

    receiveToBuffer(ipc);

    if(ipc->readBufferSize >= IPCBASE_MAPMSG_BYTES) {
        popFromReadBuffer(ipc, data, IPCBASE_MAPMSG_BYTES);
        return IPCBASE_MAPMSG_BYTES;
    } else {
        return -1;
    }
}

int flib_ipcbase_send_raw(flib_ipcbase *ipc, const void *data, size_t len) {
    if(log_badargs_if2(ipc==NULL, data==NULL && len>0)
            || log_w_if(!ipc->sock, "flib_ipcbase_send_raw: Not connected.")) {
        return -1;
    }
    if(flib_socket_send(ipc->sock, data, len) == len) {
        logSentMsg(data, len);
        return 0;
    } else {
        flib_log_w("Failed or incomplete IPC write: engine connection lost.");
        flib_socket_close(ipc->sock);
        ipc->sock = NULL;
        return -1;
    }
}

int flib_ipcbase_send_message(flib_ipcbase *ipc, void *data, size_t len) {
    if(log_badargs_if3(ipc==NULL, data==NULL && len>0, len>255)) {
        return -1;
    }

    uint8_t sendbuf[256];
    sendbuf[0] = len;
    memcpy(sendbuf+1, data, len);
    return flib_ipcbase_send_raw(ipc, sendbuf, len+1);
}

void flib_ipcbase_accept(flib_ipcbase *ipc) {
    if(!log_badargs_if(ipc==NULL) && !ipc->sock && ipc->acceptor) {
        ipc->sock = flib_socket_accept(ipc->acceptor, true);
        if(ipc->sock) {
            flib_log_d("IPC connection accepted.");
            flib_acceptor_close(ipc->acceptor);
            ipc->acceptor = NULL;
        }
    }
}
