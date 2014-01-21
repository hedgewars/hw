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

/**
 * A complete game configuration that contains all settings the engine needs to start a
 * local or networked game.
 */

#ifndef MODEL_GAMESETUP_H_
#define MODEL_GAMESETUP_H_

#include "scheme.h"
#include "weapon.h"
#include "map.h"
#include "teamlist.h"

typedef struct {
    char *style;                //!< e.g. "Capture the Flag"
    flib_scheme *gamescheme;
    flib_map *map;
    flib_teamlist *teamlist;
} flib_gamesetup;

void flib_gamesetup_destroy(flib_gamesetup *gamesetup);

/**
 * Deep-copy of the flib_gamesetup.
 */
flib_gamesetup *flib_gamesetup_copy(const flib_gamesetup *gamesetup);

#endif
