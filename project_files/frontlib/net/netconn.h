#ifndef NETCONN_H_
#define NETCONN_H_

#include "../model/gamesetup.h"

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define NETCONN_STATE_AWAIT_CONNECTED 0
#define NETCONN_STATE_LOBBY 1
#define NETCONN_STATE_ROOM 2
#define NETCONN_STATE_INGAME 3
#define NETCONN_STATE_DISCONNECTED 10

#define NETCONN_ERROR_SERVER_TOO_OLD 1
#define NETCONN_ERROR_FROM_SERVER 2

struct _flib_netconn;
typedef struct _flib_netconn flib_netconn;

flib_netconn *flib_netconn_create(const char *playerName, const char *host, uint16_t port);
void flib_netconn_destroy(flib_netconn *conn);

/**
 * This is called when we can't stay connected due to a problem, e.g. because the
 * server version is too old, or we are unexpectedly disconnected.
 *
 * Once this callback has been called, you should destroy the flib_netconn.
 */
void flib_netconn_onError(flib_netconn *conn, void (*callback)(void *context, int errorCode, const char *errormsg), void* context);

/**
 * This is called when we receive a CONNECTED message from the server, which should be the first
 * message arriving from the server.
 */
void flib_netconn_onConnected(flib_netconn *conn, void (*callback)(void *context, const char *serverMessage), void* context);

/**
 * Perform I/O operations and call callbacks if something interesting happens.
 * Should be called regularly.
 */
void flib_netconn_tick(flib_netconn *conn);

#endif
