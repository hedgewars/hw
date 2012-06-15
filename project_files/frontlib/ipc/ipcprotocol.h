#ifndef IPCPROTOCOL_H_
#define IPCPROTOCOL_H_

#include "../util/buffer.h"
#include "../model/map.h"
#include "../model/team.h"
#include "../model/cfg.h"
#include "../model/gamesetup.h"

#include <stdbool.h>

/**
 * Create a message in the IPC protocol format and add it to
 * the vector. Use a format string and extra parameters as with printf.
 *
 * Returns nonzero if something goes wrong. In that case the buffer
 * contents are unaffected.
 */
int flib_ipc_append_message(flib_vector *vec, const char *fmt, ...);

/**
 * Append IPC messages to the buffer that configure the engine for
 * this map.
 *
 * Unfortunately the engine needs a slightly different configuration
 * for generating a map preview.
 *
 * Returns nonzero if something goes wrong. In that case the buffer
 * contents are unaffected.
 */
int flib_ipc_append_mapconf(flib_vector *vec, const flib_map *map, bool mappreview);

/**
 * Append a seed message to the buffer.
 *
 * Returns nonzero if something goes wrong. In that case the buffer
 * contents are unaffected.
 */
int flib_ipc_append_seed(flib_vector *vec, const char *seed);

/**
 * Append the game scheme to the buffer.
 *
 * Returns nonzero if something goes wrong. In that case the buffer
 * contents are unaffected.
 */
int flib_ipc_append_gamescheme(flib_vector *vec, const flib_cfg *cfg);

int flib_ipc_append_addteam(flib_vector *vec, const flib_team *team, bool perHogAmmo, bool noAmmoStore);

int flib_ipc_append_fullconfig(flib_vector *vec, const flib_gamesetup *setup, bool netgame);

#endif /* IPCPROTOCOL_H_ */
