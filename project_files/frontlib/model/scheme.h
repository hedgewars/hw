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
 * Data structures for game scheme information.
 *
 * The scheme consists of settings (integers) and mods (booleans). These are not fixed, but
 * described in a "metascheme", which describes how each setting and mod is sent to the
 * engine, and in which order they appear in the network protocol. The metascheme is defined
 * in hwconsts.h
 */

#ifndef SCHEME_H_
#define SCHEME_H_

#include <stdbool.h>
#include <stddef.h>
#include "../hwconsts.h"

/**
 * The settings and mods arrays have the same number and order of elements
 * as the corresponding arrays in the metascheme.
 */
typedef struct {
    char *name;
    int *settings;
    bool *mods;
} flib_scheme;

/**
 * Create a new configuration with everything set to default or false
 * Returns NULL on error.
 */
flib_scheme *flib_scheme_create(const char *schemeName);

/**
 * Create a copy of the scheme. Returns NULL on error or if NULL was passed.
 */
flib_scheme *flib_scheme_copy(const flib_scheme *scheme);

/**
 * Decrease the reference count of the object and free it if this was the last reference.
 */
void flib_scheme_destroy(flib_scheme* scheme);

/**
 * Retrieve a mod setting by its name. If the mod is not found, logs an error and returns false.
 */
bool flib_scheme_get_mod(const flib_scheme *scheme, const char *name);

/**
 * Retrieve a game setting by its name. If the setting is not found, logs an error and returns def.
 */
int flib_scheme_get_setting(const flib_scheme *scheme, const char *name, int def);

#endif /* SCHEME_H_ */
