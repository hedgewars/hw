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
 * Functions for managing a list of schemes.
 * This is in here because the scheme config file of the QtFrontend (which we are staying compatible with) contains
 * all the schemes at once, so we need functions to work with a list like that.
 */

#ifndef SCHEMELIST_H_
#define SCHEMELIST_H_

#include "scheme.h"

typedef struct {
    int schemeCount;
    flib_scheme **schemes;
} flib_schemelist;

/**
 * Load a list of configurations from the ini file.
 * Returns NULL on error.
 */
flib_schemelist *flib_schemelist_from_ini(const char *filename);

/**
 * Store the list of configurations to an ini file.
 * Returns NULL on error.
 */
int flib_schemelist_to_ini(const char *filename, const flib_schemelist *config);

/**
 * Create an empty scheme list. Returns NULL on error.
 */
flib_schemelist *flib_schemelist_create();

/**
 * Insert a new scheme into the list at position pos, moving all higher schemes to make place.
 * pos must be at least 0 (insert at the start) and at most list->schemeCount (insert at the end).
 * Ownership of the scheme is transferred to the list.
 * Returns 0 on success.
 */
int flib_schemelist_insert(flib_schemelist *list, flib_scheme *cfg, int pos);

/**
 * Delete a scheme from the list at position pos, moving down all higher schemes.
 * The scheme is destroyed.
 * Returns 0 on success.
 */
int flib_schemelist_delete(flib_schemelist *list, int pos);

/**
 * Find the scheme with a specific name
 */
flib_scheme *flib_schemelist_find(flib_schemelist *list, const char *name);

/**
 * Free this schemelist and all contained schemes
 */
void flib_schemelist_destroy(flib_schemelist *list);


#endif /* SCHEMELIST_H_ */
