/*
 * Low-level protocol support for the IPC connection to the engine.
 */

#ifndef IPCCONN_H_
#define IPCCONN_H_

#include "buffer.h"

#include <stddef.h>
#include <stdbool.h>

typedef enum {IPC_NOT_CONNECTED, IPC_LISTENING, IPC_CONNECTED} IpcConnState;

/**
 * Called by flib_init(). Initialize everything related to ipc.
 */
void flib_ipcconn_init();

/**
 * Called by flib_quit(). Free resources and shut down.
 */
void flib_ipcconn_quit();

/**
 * Start listening for a connection from the engine. The system has to be in state
 * IPC_NOT_CONNECTED when calling this function, and will be in state IPC_LISTENING
 * if the function returns successfully.
 *
 * The parameter "recordDemo" can be used to control whether demo recording should
 * be enabled for this connection.
 *
 * Returns the port we started listening on, or a negative value if there is an error.
 *
 * We stop listening once a connection has been established, so if you want to start
 * the engine again and talk to it you need to call this function again after the old
 * connection is closed.
 */
int flib_ipcconn_start(bool recordDemo);

/**
 * Close the current IPC connection and/or stop listening for an incoming one.
 * This also discards all unread messages.
 */
void flib_ipcconn_close();

/**
 * Determine the current connection state
 */
IpcConnState flib_ipcconn_state();

/**
 * Receive a single message (up to 255 bytes) and copy it into the data buffer.
 * Returns the length of the received message, a negative value if no message could
 * be read.
 *
 * Note: When a connection is closed, you probably want to call this function until
 * no further message is returned, to ensure you see all messages that were sent
 * before the connection closed.
 */
int flib_ipcconn_recv_message(void *data);

/**
 * Write a single message (up to 255 bytes) to the engine. This call blocks until the
 * message is completely written or the connection is closed or an error occurs.
 *
 * Calling this function in a state other than IPC_CONNECTED will fail immediately.
 * Returns a negative value on failure.
 */
int flib_ipcconn_send_message(void *data, size_t len);

/**
 * Convenience function for sending a 0-delimited string.
 */
int flib_ipcconn_send_messagestr(char *data);

/**
 * Call regularly to allow background work to proceed
 */
void flib_ipcconn_tick();

/**
 * Get a demo record of the last connection. This should be called after
 * the connection is closed and all messages have been received.
 *
 * If demo recording was not enabled in the last call to flib_ipcconn_start(),
 * or if the recording failed for some reason, the buffer will be empty.
 *
 * The buffer is only valid until the next call to flib_ipcconn_start() or
 * a call to flib_ipcconn_getsave() (save and demo records have some minor
 * differences, and those are performed directly on the buffer before returning it).
 */
flib_constbuffer flib_ipcconn_getdemo();

/**
 * Get a savegame record of the last connection. This should be called after
 * the connection is closed and all messages have been received.
 *
 * If demo recording was not enabled in the last call to flib_ipcconn_start(),
 * or if the recording failed for some reason, the buffer will be empty.
 *
 * The buffer is only valid until the next call to flib_ipcconn_start() or
 * a call to flib_ipcconn_getdemo() (save and demo records have some minor
 * differences, and those are performed directly on the buffer before returning it).
 */
flib_constbuffer flib_ipcconn_getsave();

#endif /* IPCCONN_H_ */

