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
 * Sockets for TCP networking.
 *
 * This layer offers some functionality over what SDL_net offers directly: listening
 * sockets (called acceptors here) can be bound to port 0, which will make them listen
 * on a random unused port, if one can be found. To support this feature, you can also
 * query the local port that an acceptor is listening on.
 *
 * Further, we support nonblocking reads here.
 */

#ifndef SOCKET_H_
#define SOCKET_H_

#include <stdbool.h>
#include <stdint.h>

typedef struct _flib_tcpsocket flib_tcpsocket;
typedef struct _flib_acceptor flib_acceptor;

/**
 * Create a new acceptor which will listen for incoming TCP connections
 * on the given port. If port is 0, this will listen on a random
 * unused port which can then be queried with flib_acceptor_listenport.
 *
 * Returns NULL on error.
 */
flib_acceptor *flib_acceptor_create(uint16_t port);

/**
 * Return the port on which the acceptor is listening.
 */
uint16_t flib_acceptor_listenport(flib_acceptor *acceptor);

/**
 * Close the acceptor and free its memory. NULL-safe.
 */
void flib_acceptor_close(flib_acceptor *acceptor);

/**
 * Try to accept a connection from an acceptor (listening socket).
 * if localOnly is true, this will only accept connections which came from 127.0.0.1
 * Returns NULL if nothing can be accepted.
 */
flib_tcpsocket *flib_socket_accept(flib_acceptor *acceptor, bool localOnly);

/**
 * Try to connect to the server at the given address.
 */
flib_tcpsocket *flib_socket_connect(const char *host, uint16_t port);

/**
 * Close the socket and free its memory. NULL-safe.
 */
void flib_socket_close(flib_tcpsocket *socket);

/**
 * Attempt to receive up to maxlen bytes from the socket, but does not
 * block if nothing is available.
 * Returns the ammount of data received, 0 if there was nothing to receive,
 * or a negative number if the connection was closed or an error occurred.
 */
int flib_socket_nbrecv(flib_tcpsocket *sock, void *data, int maxlen);

/**
 * Blocking send all the data in the data buffer. Returns the actual ammount
 * of data sent, or a negative value on error. If the value returned here
 * is less than len, either the connection closed or an error occurred.
 */
int flib_socket_send(flib_tcpsocket *sock, const void *data, int len);

#endif /* SOCKET_H_ */
