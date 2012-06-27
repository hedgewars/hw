#ifndef IPC_MAPCONN_H_
#define IPC_MAPCONN_H_

#include "../model/map.h"

#include <stdint.h>

#define MAPIMAGE_WIDTH 256
#define MAPIMAGE_HEIGHT 128
#define MAPIMAGE_BYTES (MAPIMAGE_WIDTH/8*MAPIMAGE_HEIGHT)

typedef struct _flib_mapconn flib_mapconn;

/**
 * Start a new map rendering connection (mapconn). This means a listening socket
 * will be started on a random unused port, waiting for a connection from the
 * engine process. Once this connection is established, the required information
 * will be sent to the engine, and the reply is read.
 *
 * The map must be a regular, maze or drawn map - for a preview of a named map,
 * use the preview images in the map's directory, and for the hog count read the
 * map information (flib_mapcfg_read).
 *
 * No NULL parameters allowed, returns NULL on failure.
 * Use flib_mapconn_destroy to free the returned object.
 */
flib_mapconn *flib_mapconn_create(const flib_map *mapdesc);

/**
 * Destroy the mapconn object. Passing NULL is allowed and does nothing.
 * flib_mapconn_destroy may be called from inside a callback function.
 */
void flib_mapconn_destroy(flib_mapconn *conn);

/**
 * Returns the port on which the mapconn is listening. Only fails if you
 * pass NULL (not allowed), in that case 0 is returned.
 */
int flib_mapconn_getport(flib_mapconn *conn);

/**
 * Set a callback which will receive the rendered map if the rendering succeeds.
 * You can pass callback=NULL to unset a callback.
 *
 * Expected callback signature:
 * void handleSuccess(void *context, const uint8_t *bitmap, int numHedgehogs)
 *
 * The context passed to the callback is the same pointer you provided when
 * registering the callback. bitmap is a pointer to a buffer of size MAPIMAGE_BYTES
 * containing a bit-packed image of size MAPIMAGE_WIDTH * MAPIMAGE_HEIGHT.
 * numHedgehogs is the number of hogs that fit on this map.
 *
 * The bitmap pointer passed to the callback belongs to the caller,
 * so it should not be stored elsewhere. Note that it remains valid
 * inside the callback method even if flib_mapconn_destroy is called.
 */
void flib_mapconn_onSuccess(flib_mapconn *conn, void (*callback)(void* context, const uint8_t *bitmap, int numHedgehogs), void *context);

/**
 * Set a callback which will receive an error message if rendering fails.
 * You can pass callback=NULL to unset a callback.
 *
 * Expected callback signature:
 * void handleFailure(void *context, const char *errormessage)
 *
 * The context passed to the callback is the same pointer you provided when
 * registering the callback.
 *
 * The error message passed to the callback belongs to the caller,
 * so it should not be stored elsewhere. Note that it remains valid
 * inside the callback method even if flib_mapconn_destroy is called.
 */
void flib_mapconn_onFailure(flib_mapconn *conn, void (*callback)(void* context, const char *errormessage), void *context);

/**
 * Perform I/O operations and call callbacks if something interesting happens.
 * Should be called regularly.
 */
void flib_mapconn_tick(flib_mapconn *conn);

#endif
