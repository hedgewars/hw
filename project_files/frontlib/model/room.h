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
 * Models the room information for the lobby roomlist.
 */

#ifndef ROOM_H_
#define ROOM_H_

#include <stdbool.h>

typedef struct {
    bool inProgress;    //!< true if the game is running
    char *name;
    int playerCount;
    int teamCount;
    char *owner;
    char *map;          //!< This is either a map name, or one of +rnd+, +maze+ or +drawn+.
    char *scheme;
    char *weapons;
} flib_room;

void flib_room_destroy();

#endif
