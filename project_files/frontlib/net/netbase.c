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

#include "netbase.h"
#include "../util/buffer.h"
#include "../util/logging.h"
#include "../util/util.h"
#include "../socket.h"

#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>

#define NET_READBUFFER_LIMIT (1024*1024)

struct _flib_netbase {
    flib_vector *readBuffer;
    flib_tcpsocket *sock;
};

flib_netbase *flib_netbase_create(const char *server, uint16_t port) {
    if(log_badargs_if2(server==NULL, port==0)) {
        return NULL;
    }

    flib_netbase *result = NULL;
    flib_netbase *newNet =  flib_calloc(1, sizeof(flib_netbase));

    if(newNet) {
        newNet->readBuffer = flib_vector_create();
        newNet->sock = flib_socket_connect(server, port);
        if(newNet->readBuffer && newNet->sock) {
            flib_log_i("Connected to server %s:%u", server, (unsigned)port);
            result = newNet;
            newNet = NULL;
        }
    }
    flib_netbase_destroy(newNet);

    return result;
}

void flib_netbase_destroy(flib_netbase *net) {
    if(net) {
        flib_socket_close(net->sock);
        flib_vector_destroy(net->readBuffer);
        free(net);
    }
}

bool flib_netbase_connected(flib_netbase *net) {
    if(!log_badargs_if(net==NULL) && net->sock) {
        return true;
    }
    return false;
}

/**
 * Parses and returns a message, and removes it from the vector.
 */
static flib_netmsg *parseMessage(flib_vector *vec) {
    const uint8_t *partStart = flib_vector_data(vec);
    const uint8_t *end = partStart+flib_vector_size(vec);
    flib_netmsg *result = flib_netmsg_create();
    if(!result) {
        return NULL;
    }

    while(1) {
        const uint8_t *partEnd = memchr(partStart, '\n', end-partStart);
        if(!partEnd) {
            // message incomplete
            flib_netmsg_destroy(result);
            return NULL;
        } else if(partEnd-partStart == 0) {
            // Zero-length part, message end marker. Remove the message from the vector.
            uint8_t *vectorStart = flib_vector_data(vec);
            size_t msgLen = partEnd+1-vectorStart;
            memmove(vectorStart, partEnd+1, flib_vector_size(vec)-msgLen);
            flib_vector_resize(vec, flib_vector_size(vec)-msgLen);
            return result;
        } else {
            if(flib_netmsg_append_part(result, partStart, partEnd-partStart)) {
                flib_netmsg_destroy(result);
                return NULL;
            }
            partStart = partEnd+1; // Skip the '\n'
        }
    }
    return NULL; // Never reached
}

/**
 * Receive some bytes and add them to the buffer.
 * Returns the number of bytes received.
 * Automatically closes the socket if an error occurs
 * and sets sock=NULL.
 */
static int receiveToBuffer(flib_netbase *net) {
    uint8_t buffer[256];
    if(!net->sock) {
        return 0;
    } else if(flib_vector_size(net->readBuffer) > NET_READBUFFER_LIMIT) {
        flib_log_e("Net connection closed: Net message too big");
        flib_socket_close(net->sock);
        net->sock = NULL;
        return 0;
    } else {
        int size = flib_socket_nbrecv(net->sock, buffer, sizeof(buffer));
        if(size>=0 && !flib_vector_append(net->readBuffer, buffer, size)) {
            return size;
        } else {
            flib_socket_close(net->sock);
            net->sock = NULL;
            return 0;
        }
    }
}

flib_netmsg *flib_netbase_recv_message(flib_netbase *net) {
    if(log_badargs_if(net==NULL)) {
        return NULL;
    }

    flib_netmsg *msg;
    while(!(msg=parseMessage(net->readBuffer))
            && receiveToBuffer(net)) {}

    if(msg) {
        return msg;
    } else if(!net->sock && flib_vector_size(net->readBuffer)>0) {
        // Connection is down and we didn't get a complete message, just flush the rest.
        flib_vector_resize(net->readBuffer, 0);
    }
    return NULL;
}

static void logSentMsg(const uint8_t *data, size_t len) {
    if(flib_log_isActive(FLIB_LOGLEVEL_DEBUG)) {
        flib_log_d("[NET OUT][%03u]%*.*s",(unsigned)len, (unsigned)len, (unsigned)len, data);
    }
}

int flib_netbase_send_raw(flib_netbase *net, const void *data, size_t len) {
    if(log_badargs_if2(net==NULL, data==NULL && len>0)) {
        return -1;
    }
    if(!net->sock) {
        flib_log_w("flib_netbase_send_raw: Not connected.");
        return -1;
    }

    if(flib_socket_send(net->sock, data, len) == len) {
        logSentMsg(data, len);
        return 0;
    } else {
        flib_log_w("Failed or incomplete write: net connection lost.");
        flib_socket_close(net->sock);
        net->sock = NULL;
        return -1;
    }
}

int flib_netbase_send_message(flib_netbase *net, const flib_netmsg *msg) {
    if(log_badargs_if2(net==NULL, msg==NULL)) {
        return -1;
    }

    size_t totalSize = 0;
    for(int i=0; i<msg->partCount; i++) {
        totalSize += strlen(msg->parts[i]) + 1;
    }
    totalSize++; // Last part ends in two '\n' instead of one

    uint8_t *buffer = flib_malloc(totalSize);
    if(!buffer) {
        return -1;
    }
    size_t pos = 0;
    for(int i=0; i<msg->partCount; i++) {
        size_t partsize = strlen(msg->parts[i]);
        memcpy(buffer+pos, msg->parts[i], partsize);
        pos += partsize;
        buffer[pos++] = '\n';
    }
    buffer[pos++] = '\n';
    return flib_netbase_send_raw(net, buffer, pos);
}

int flib_netbase_sendf(flib_netbase *net, const char *format, ...) {
    int result = -1;
    if(!log_badargs_if2(net==NULL, format==NULL)) {
        va_list argp;
        va_start(argp, format);
        char *buffer = flib_vasprintf(format, argp);
        if(buffer) {
            result = flib_netbase_send_raw(net, buffer, strlen(buffer));
        }
        free(buffer);
        va_end(argp);
    }
    return result;
}

flib_netmsg *flib_netmsg_create() {
    flib_netmsg *result = flib_calloc(1, sizeof(flib_netmsg));
    if(result) {
        result->partCount = 0;
        result->parts = NULL;
        return result;
    } else {
        return NULL;
    }
}

void flib_netmsg_destroy(flib_netmsg *msg) {
    if(msg) {
        for(int i=0; i<msg->partCount; i++) {
            free(msg->parts[i]);
        }
        free(msg->parts);
        free(msg);
    }
}

int flib_netmsg_append_part(flib_netmsg *msg, const void *part, size_t partlen) {
    int result = -1;
    if(!log_badargs_if2(msg==NULL, part==NULL && partlen>0)) {
        char **newParts = realloc(msg->parts, (msg->partCount+1)*sizeof(*msg->parts));
        if(newParts) {
            msg->parts = newParts;
            msg->parts[msg->partCount] = flib_malloc(partlen+1);
            if(msg->parts[msg->partCount]) {
                memcpy(msg->parts[msg->partCount], part, partlen);
                msg->parts[msg->partCount][partlen] = 0;
                msg->partCount++;
                result = 0;
            }
        }
    }
    return result;
}
