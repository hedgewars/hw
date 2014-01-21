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

#ifndef MODEL_WEAPON_H_
#define MODEL_WEAPON_H_

#include "../hwconsts.h"

/**
 * These values are all ASCII characters in the range '0'..'9'
 * The fields are zero-terminated so they can easily be used as strings.
 *
 * For loadout, 9 means inifinite ammo.
 * For the other setting, 9 is invalid.
 */
typedef struct {
    char loadout[WEAPONS_COUNT+1];
    char crateprob[WEAPONS_COUNT+1];
    char crateammo[WEAPONS_COUNT+1];
    char delay[WEAPONS_COUNT+1];
    char *name;
} flib_weaponset;

typedef struct {
    int weaponsetCount;
    flib_weaponset **weaponsets;
} flib_weaponsetlist;

/**
 * Returns a new weapon set, or NULL on error.
 * name must not be NULL.
 *
 * The new weapon set is pre-filled with default
 * settings (see hwconsts.h)
 */
flib_weaponset *flib_weaponset_create(const char *name);

/**
 * Free the memory used by this weaponset
 */
void flib_weaponset_destroy(flib_weaponset *weaponset);

flib_weaponset *flib_weaponset_copy(const flib_weaponset *weaponset);

/**
 * Create a weaponset from an ammostring. This format is used both in the ini files
 * and in the net protocol.
 */
flib_weaponset *flib_weaponset_from_ammostring(const char *name, const char *ammostring);

/**
 * Load a list of weaponsets from the ini file.
 * Returns NULL on error.
 */
flib_weaponsetlist *flib_weaponsetlist_from_ini(const char *filename);

/**
 * Store the list of weaponsets to an ini file.
 * Returns NULL on error.
 */
int flib_weaponsetlist_to_ini(const char *filename, const flib_weaponsetlist *weaponsets);

/**
 * Create an empty weaponset list. Returns NULL on error.
 */
flib_weaponsetlist *flib_weaponsetlist_create();

/**
 * Release all memory associated with the weaponsetlist and release all contained weaponsets
 */
void flib_weaponsetlist_destroy(flib_weaponsetlist *list);

/**
 * Insert a new weaponset into the list at position pos, moving all higher weaponsets to make place.
 * pos must be at least 0 (insert at the start) and at most list->weaponsetCount (insert at the end).
 * Ownership of the weaponset is transferred to the list.
 * Returns 0 on success.
 */
int flib_weaponsetlist_insert(flib_weaponsetlist *list, flib_weaponset *weaponset, int pos);

/**
 * Delete a weaponset from the list at position pos, moving down all higher weaponsets.
 * The weaponset is destroyed.
 * Returns 0 on success.
 */
int flib_weaponsetlist_delete(flib_weaponsetlist *list, int pos);

#endif
