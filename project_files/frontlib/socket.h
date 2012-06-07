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

struct _flib_tcpsocket;
typedef struct _flib_tcpsocket *flib_tcpsocket;

struct _flib_acceptor;
typedef struct _flib_acceptor *flib_acceptor;

/**
 * Create a new acceptor which will listen for incoming TCP connections
 * on the given port. If port is 0, this will listen on a random
 * unused port which can then be queried with flib_acceptor_listenport.
 *
 * Can return NULL on error.
 */
flib_acceptor flib_acceptor_create(uint16_t port);

/**
 * Return the port on which the acceptor is listening.
 */
uint16_t flib_acceptor_listenport(flib_acceptor acceptor);

/**
 * Close the acceptor, free its memory and set it to NULL.
 * If the acceptor is already NULL, nothing happens.
 */
void flib_acceptor_close(flib_acceptor *acceptorptr);

/**
 * Try to accept a connection from an acceptor (listening socket).
 * if localOnly is true, this will only accept connections which came from 127.0.0.1
 * Returns NULL if nothing can be accepted.
 */
flib_tcpsocket flib_socket_accept(flib_acceptor acceptor, bool localOnly);

/**
 * Close the socket, free its memory and set it to NULL.
 * If the socket is already NULL, nothing happens.
 */
void flib_socket_close(flib_tcpsocket *socket);

/**
 * Attempt to receive up to maxlen bytes from the socket, but does not
 * block if nothing is available.
 * Returns the ammount of data received, 0 if there was nothing to receive,
 * or a negative number if the connection was closed or an error occurred.
 */
int flib_socket_nbrecv(flib_tcpsocket sock, void *data, int maxlen);

int flib_socket_send(flib_tcpsocket sock, void *data, int len);

#endif /* SOCKET_H_ */
