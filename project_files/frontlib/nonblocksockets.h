/*
 * nonblocksockets.h
 *
 *  Created on: 31.05.2012
 *      Author: simmax
 */

#ifndef NONBLOCKSOCKETS_H_
#define NONBLOCKSOCKETS_H_

#include <SDL_net.h>
#include <stdbool.h>

typedef struct {
	TCPsocket sock;
	SDLNet_SocketSet sockset;
} _NonBlockSocket;

typedef _NonBlockSocket *NonBlockSocket;

/**
 * Close the indicated socket, free its memory and set it to NULL.
 * If the socket is already NULL, nothing happens.
 */
void flib_nbsocket_close(NonBlockSocket *socket);

/**
 * Try to accept a connection from a listening socket.
 * if localOnly is true, this will only accept connections which came from 127.0.0.1
 * Returns NULL if nothing can be accepted.
 */
NonBlockSocket flib_nbsocket_accept(TCPsocket listensocket, bool localOnly);

/**
 * Attempt to receive up to maxlen bytes from the socket, but does not
 * block if nothing is available.
 * Returns the ammount of data received, 0 if there was nothing to receive,
 * or a negative number if the connection was closed or an error occurred.
 */
int flib_nbsocket_recv(NonBlockSocket sock, void *data, int maxlen);

/**
 * We can't do a nonblocking send over SDL_net, so this function just forwards
 * to SDLNet_TCP_Send for convenience, which blocks until all data is sent or an
 * error occurs. The ammount of data actually sent is returned, negative value on error.
 */
static inline int flib_nbsocket_blocksend(NonBlockSocket sock, void *data, int len) {
	return SDLNet_TCP_Send(sock->sock, data, len);
}

#endif /* NONBLOCKSOCKETS_H_ */
