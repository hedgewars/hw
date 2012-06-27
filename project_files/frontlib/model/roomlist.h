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
 * Models the list of rooms on a server for netplay.
 */

#ifndef ROOMLIST_H_
#define ROOMLIST_H_

#include <stdbool.h>

typedef struct {
    bool inProgress;	// true if the game is running
    char *name;
    int playerCount;
    int teamCount;
    char *owner;
    char *map;			// This is either a map name, or one of +rnd+, +maze+ or +drawn+.
    char *scheme;
    char *weapons;
} flib_room;

typedef struct {
	int roomCount;
	flib_room **rooms;
} flib_roomlist;

flib_roomlist *flib_roomlist_create();

void flib_roomlist_destroy(flib_roomlist *list);

/**
 * Insert a new room at the start of the list. The room is defined by the params-array,
 * which must consist of 8 non-null strings, as sent by the server in netplay.
 *
 * Returns 0 on success.
 */
int flib_roomlist_add(flib_roomlist *list, char **params);

/**
 * Update the room with the name [name] with parameters sent by the server.
 *
 * Returns 0 on success.
 */
int flib_roomlist_update(flib_roomlist *list, const char *name, char **params);

/**
 * Returns the room with the name [name] from the list if it exists, NULL otherwise
 */
flib_room *flib_roomlist_find(const flib_roomlist *list, const char *name);

/**
 * Removes all rooms from the list
 */
void flib_roomlist_clear(flib_roomlist *list);

/**
 * Delete the room with the name [name] from the room list.
 * Returns 0 on success.
 */
int flib_roomlist_delete(flib_roomlist *list, const char *name);

#endif
