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
 * Low-level protocol support for the network connection
 */

#ifndef NETBASE_H_
#define NETBASE_H_

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

struct _flib_netbase;
typedef struct _flib_netbase flib_netbase;

typedef struct {
    int partCount;
    char **parts;
} flib_netmsg;

/**
 * Start a connection to the specified Hedgewars server.
 *
 * Returns NULL on error. Destroy the created object with flib_netconn_destroy.
 */
flib_netbase *flib_netbase_create(const char *server, uint16_t port);

/**
 * Free resources and close sockets.
 */
void flib_netbase_destroy(flib_netbase *net);

/**
 * Determine the current connection state. Starts out true, and turns to
 * false when we are disconnected from the server.
 */
bool flib_netbase_connected(flib_netbase *net);

/**
 * Receive a new message and return it as a flib_netmsg. The netmsg has to be
 * destroyed with flib_netmsg_destroy after use.
 * Returns NULL if no message is available.
 *
 * Note: When a connection is closed, you probably want to call this function until
 * no further message is returned, to ensure you see all messages that were sent
 * before the connection closed.
 */
flib_netmsg *flib_netbase_recv_message(flib_netbase *net);

int flib_netbase_send_raw(flib_netbase *net, const void *data, size_t len);

/**
 * Write a single message to the server. This call blocks until the
 * message is completely written or the connection is closed or an error occurs.
 *
 * Returns a negative value on failure.
 */
int flib_netbase_send_message(flib_netbase *net, const flib_netmsg *msg);

/**
 * Send a message printf-style.
 *
 * flib_netbase_sendf(net, "%s\n\n", "TOGGLE_READY");
 * flib_netbase_sendf(net, "%s\n%s\n%i\n\n", "CFG", "MAPGEN", MAPGEN_MAZE);
 */
int flib_netbase_sendf(flib_netbase *net, const char *format, ...);

flib_netmsg *flib_netmsg_create();
void flib_netmsg_destroy(flib_netmsg *msg);
int flib_netmsg_append_part(flib_netmsg *msg, const void *param, size_t len);

#endif /* NETBASE_H_ */

