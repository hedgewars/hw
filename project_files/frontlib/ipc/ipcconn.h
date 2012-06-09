/*
 * Low-level protocol support for the IPC connection to the engine.
 */

#ifndef IPCCONN_H_
#define IPCCONN_H_

#include "../util/buffer.h"

#include <stddef.h>
#include <stdbool.h>

#define IPCCONN_MAPMSG_BYTES 4097

typedef enum {IPC_NOT_CONNECTED, IPC_LISTENING, IPC_CONNECTED} IpcConnState;

struct _flib_ipcconn;
typedef struct _flib_ipcconn *flib_ipcconn;

/**
 * TODO move demo recording up by one layer?
 *
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

/**
 * Try to receive 4097 bytes. This is the size of the reply the engine sends
 * when successfully queried for map data. The first 4096 bytes are a bit-packed
 * twocolor image of the map (256x128), the last byte is the number of hogs that
 * fit on the map.
 */
int flib_ipcconn_recv_map(flib_ipcconn ipc, void *data);

int flib_ipcconn_send_raw(flib_ipcconn ipc, const void *data, size_t len);

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
void flib_ipcconn_accept(flib_ipcconn ipc);

/**
 * Get a record of the connection. This should be called after
 * the connection is closed and all messages have been received.
 *
 * If demo recording was not enabled, or if the recording failed for some reason,
 * the buffer will be empty.
 *
 * If save=true is passed, the result will be a savegame, otherwise it will be a
 * demo.
 *
 * The buffer is only valid until flib_ipcconn_getsave is called again or the ipcconn
 * is destroyed.
 */
flib_constbuffer flib_ipcconn_getrecord(flib_ipcconn ipc, bool save);

#endif /* IPCCONN_H_ */

