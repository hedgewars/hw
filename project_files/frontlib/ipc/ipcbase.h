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

/*
 * Low-level protocol support for the IPC connection to the engine.
 */
#ifndef IPCBASE_H_
#define IPCBASE_H_

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

#define IPCBASE_MAPMSG_BYTES 4097

typedef enum {IPC_NOT_CONNECTED, IPC_LISTENING, IPC_CONNECTED} IpcState;

typedef struct _flib_ipcbase flib_ipcbase;

/**
 * Start an engine connection by listening on a random port. The selected port can
 * be queried with flib_ipcbase_port and has to be passed to the engine.
 *
 * Returns NULL on error. Destroy the created object with flib_ipcbase_destroy.
 *
 * We stop accepting new connections once a connection has been established, so you
 * need to create a new ipcbase in order to start a new connection.
 */
flib_ipcbase *flib_ipcbase_create();

/**
 * Return the listening port
 */
uint16_t flib_ipcbase_port(flib_ipcbase *ipc);

/**
 * Free resources and close sockets. NULL safe.
 */
void flib_ipcbase_destroy(flib_ipcbase *ipc);

/**
 * Determine the current connection state
 */
IpcState flib_ipcbase_state(flib_ipcbase *ipc);

/**
 * Receive a single message (up to 256 bytes) and copy it into the data buffer.
 * Returns the length of the received message, a negative value if no message could
 * be read.
 *
 * The first byte of a message is its content length, which is one less than the returned
 * value.
 *
 * Note: When a connection is closed, you probably want to call this function until
 * no further message is returned, to ensure you see all messages that were sent
 * before the connection closed.
 */
int flib_ipcbase_recv_message(flib_ipcbase *ipc, void *data);

/**
 * Try to receive 4097 bytes. This is the size of the reply the engine sends
 * when successfully queried for map data. The first 4096 bytes are a bit-packed
 * twocolor image of the map (256x128), the last byte is the number of hogs that
 * fit on the map.
 */
int flib_ipcbase_recv_map(flib_ipcbase *ipc, void *data);

/**
 * Blocking send bytes over the socket. No message framing will be added.
 * Returns 0 on success.
 */
int flib_ipcbase_send_raw(flib_ipcbase *ipc, const void *data, size_t len);

/**
 * Write a single message (up to 255 bytes) to the engine. This call blocks until the
 * message is completely written or the connection is closed or an error occurs.
 *
 * Calling this function in a state other than IPC_CONNECTED will fail immediately.
 * Returns 0 on success.
 */
int flib_ipcbase_send_message(flib_ipcbase *ipc, void *data, size_t len);

/**
 * Try to accept a connection. Only has an effect in state IPC_LISTENING.
 */
void flib_ipcbase_accept(flib_ipcbase *ipc);

#endif /* IPCBASE_H_ */

