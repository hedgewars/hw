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

#ifndef IPCPROTOCOL_H_
#define IPCPROTOCOL_H_

#include "../util/buffer.h"
#include "../model/map.h"
#include "../model/team.h"
#include "../model/scheme.h"
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
 * Append a script to the buffer (e.g. "Missions/Training/Basic_Training_-_Bazooka.lua")
 *
 * Returns nonzero if something goes wrong. In that case the buffer
 * contents are unaffected.
 */
int flib_ipc_append_script(flib_vector *vec, const char *script);

/**
 * Append a game style to the buffer. (e.g. "Capture the Flag")
 *
 * Returns nonzero if something goes wrong. In that case the buffer
 * contents are unaffected.
 */
int flib_ipc_append_style(flib_vector *vec, const char *style);

/**
 * Append the game scheme to the buffer.
 *
 * Returns nonzero if something goes wrong. In that case the buffer
 * contents are unaffected.
 */
int flib_ipc_append_gamescheme(flib_vector *vec, const flib_scheme *scheme);

/**
 * Append the entire game config to the buffer (including the final "!" that marks the
 * end of configuration data for the engine)
 *
 * Returns nonzero if something goes wrong. In that case the buffer
 * contents are unaffected.
 */
int flib_ipc_append_fullconfig(flib_vector *vec, const flib_gamesetup *setup, bool netgame);

#endif /* IPCPROTOCOL_H_ */
