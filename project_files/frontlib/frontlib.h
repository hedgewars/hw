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
 * Public header file for the hedgewars frontent networking library.
 *
 * This is the only header you should need to include from frontend code.
 */

#ifndef FRONTLIB_H_
#define FRONTLIB_H_

#include "ipc/gameconn.h"
#include "ipc/mapconn.h"
#include "net/netconn.h"
#include "util/logging.h"
#include "model/schemelist.h"

/**
 * Call this function before anything else in this library.
 * Returns 0 on success, -1 on error.
 */
int flib_init();

/**
 * Free resources associated with the library. Call this function once
 * the library is no longer needed. You can re-initialize the library by calling
 * flib_init again.
 */
void flib_quit();

#endif /* FRONTLIB_H_ */
