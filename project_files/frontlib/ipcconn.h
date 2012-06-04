/*
 * Low-level protocol support for the IPC connection to the engine.
 */

#ifndef IPCCONN_H_
#define IPCCONN_H_

#include "buffer.h"

#include <stddef.h>
#include <stdbool.h>

typedef enum {IPC_NOT_CONNECTED, IPC_LISTENING, IPC_CONNECTED} IpcConnState;

struct _flib_ipcconn;
typedef struct _flib_ipcconn *flib_ipcconn;

/**
 * Start an engine connection by listening on a random port. The selected port can
 * be queried with flib_ipcconn_port and has to be passed to the engine.
 *
 * The parameter "recordDemo" can be used to control whether demo recording should
 * be enabled for this connection. The localPlayerName is needed for demo
 * recording purposes.
 *
 * Returns NULL on error. Destroy the created object with flib_ipcconn_destroy.
 *
 * We stop accepting new connections once a connection has been established, so you
 * need to create a new ipcconn in order to start a new connection.
 */
flib_ipcconn flib_ipcconn_create(bool recordDemo, const char *localPlayerName);

uint16_t flib_ipcconn_port(flib_ipcconn ipc);

/**
 * Free resources, close sockets, and set the pointer to NULL.
 */
void flib_ipcconn_destroy(flib_ipcconn *ipcptr);

/**
 * Determine the current connection state
 */
IpcConnState flib_ipcconn_state(flib_ipcconn ipc);

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
int flib_ipcconn_recv_message(flib_ipcconn ipc, void *data);

int flib_ipcconn_send_raw(flib_ipcconn ipc, void *data, size_t len);

/**
 * Write a single message (up to 255 bytes) to the engine. This call blocks until the
 * message is completely written or the connection is closed or an error occurs.
 *
 * Calling this function in a state other than IPC_CONNECTED will fail immediately.
 * Returns a negative value on failure.
 */
int flib_ipcconn_send_message(flib_ipcconn ipc, void *data, size_t len);

/**
 * Convenience function for sending a 0-delimited string.
 */
int flib_ipcconn_send_messagestr(flib_ipcconn ipc, char *data);

/**
 * Call regularly to allow background work to proceed
 */
void flib_ipcconn_tick(flib_ipcconn ipc);

/**
 * Get a demo record of the connection. This should be called after
 * the connection is closed and all messages have been received.
 *
 * If demo recording was not enabled, or if the recording failed for some reason,
 * the buffer will be empty.
 *
 * The buffer is only valid until a call to flib_ipcconn_getsave(), since save
 * and demo records have some minor differences, and those are performed directly
 * on the buffer before returning it).
 */
flib_constbuffer flib_ipcconn_getdemo(flib_ipcconn ipc);

/**
 * Get a savegame record of the connection. This should be called after
 * the connection is closed and all messages have been received.
 *
 * If demo recording was not enabled, or if the recording failed for some reason,
 * the buffer will be empty.
 *
 * The buffer is only valid until a call to flib_ipcconn_getdemo(), since save
 * and demo records have some minor differences, and those are performed directly
 * on the buffer before returning it).
 */
flib_constbuffer flib_ipcconn_getsave(flib_ipcconn ipc);

#endif /* IPCCONN_H_ */

