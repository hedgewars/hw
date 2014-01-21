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

#ifndef TEAMLIST_H_
#define TEAMLIST_H_

#include "team.h"

typedef struct {
    int teamCount;
    flib_team **teams;
} flib_teamlist;

flib_teamlist *flib_teamlist_create();

void flib_teamlist_destroy(flib_teamlist *list);

/**
 * Insert a team into the list. The list takes ownership of the team. Returns 0 on success.
 */
int flib_teamlist_insert(flib_teamlist *list, flib_team *team, int pos);

/**
 * Delete the team with the name [name] from the list and destroys it.
 * Returns 0 on success.
 */
int flib_teamlist_delete(flib_teamlist *list, const char *name);

/**
 * Returns the team with the name [name] from the list if it exists, NULL otherwise
 */
flib_team *flib_teamlist_find(const flib_teamlist *list, const char *name);

/**
 * Removes all items from the list and destroys them.
 */
void flib_teamlist_clear(flib_teamlist *list);

/**
 * Create a copy of the list and all the teams it contains. Weaponsets are not copied, but
 * kept as references
 */
flib_teamlist *flib_teamlist_copy(flib_teamlist *list);

#endif
