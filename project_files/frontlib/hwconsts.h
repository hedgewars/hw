/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
 * Copyright (c) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

/**
 * This file contains important constants which might need to be changed to adapt to
 * changes in the engine or protocols.
 */

#ifndef HWCONSTS_H_
#define HWCONSTS_H_

#include <inttypes.h>
#include <stddef.h>

#define HEDGEHOGS_PER_TEAM 8
#define NETGAME_DEFAULT_PORT 46631
#define PROTOCOL_VERSION 42
#define MIN_SERVER_VERSION 1

// Used for sending scripts to the engine
#define MULTIPLAYER_SCRIPT_PATH "Scripts/Multiplayer/"

#define WEAPONS_COUNT 55

/* A merge of mikade/bugq colours w/ a bit of channel feedback */
#define HW_TEAMCOLOR_ARRAY  { UINT32_C(0xffff0204), /* red    */ \
                              UINT32_C(0xff4980c1), /* blue   */ \
                              UINT32_C(0xff1de6ba), /* teal   */ \
                              UINT32_C(0xffb541ef), /* purple */ \
                              UINT32_C(0xffe55bb0), /* pink   */ \
                              UINT32_C(0xff20bf00), /* green  */ \
                              UINT32_C(0xfffe8b0e), /* orange */ \
                              UINT32_C(0xff5f3605), /* brown  */ \
                              UINT32_C(0xffffff01), /* yellow */ \
                              /* add new colors here */ \
                              0 } /* Keep this 0 at the end or the length will be calculated wrong */

// TODO allow setting alternative color lists?
extern const size_t flib_teamcolor_defaults_len;
extern const uint32_t flib_teamcolor_defaults[];

#endif
