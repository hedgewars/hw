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
 */

#ifndef CFG_H_
#define CFG_H_

#include <stdbool.h>

// TODO: cfg/config -> scheme

typedef struct {
    char *name;
    char *engineCommand;
    bool maxMeansInfinity;
    bool times1000;
    int min;
    int max;
    int def;
} flib_cfg_setting_meta;

typedef struct {
    char *name;
    int bitmaskIndex;
} flib_cfg_mod_meta;

/**
 * The order of the meta information in the arrays is the same as the order
 * of the mod/setting information in the net protocol messages.
 */
typedef struct {
	int _referenceCount;
	int settingCount;
	int modCount;
    flib_cfg_setting_meta *settings;
    flib_cfg_mod_meta *mods;
} flib_cfg_meta;

typedef struct {
	int _referenceCount;
    flib_cfg_meta *meta;

    char *name;
    int *settings;
    bool *mods;
} flib_cfg;

/**
 * Read the meta-configuration from a .ini file (e.g. which settings exist,
 * what are their defaults etc.)
 *
 * Returns the meta-configuration or NULL.
 */
flib_cfg_meta *flib_cfg_meta_from_ini(const char *filename);

/**
 * Increase the reference count of the object. Call this if you store a pointer to it somewhere.
 * Returns the parameter.
 */
flib_cfg_meta *flib_cfg_meta_retain(flib_cfg_meta *metainfo);

/**
 * Decrease the reference count of the object and free it if this was the last reference.
 */
void flib_cfg_meta_release(flib_cfg_meta *metainfo);

/**
 * Create a new configuration with everything set to default or false
 * Returns NULL on error.
 */
flib_cfg *flib_cfg_create(flib_cfg_meta *meta, const char *schemeName);

/**
 * Create a copy of the scheme. Returns NULL on error or if NULL was passed.
 */
flib_cfg *flib_cfg_copy(const flib_cfg *cfg);

/**
 * Increase the reference count of the object. Call this if you store a pointer to it somewhere.
 * Returns the parameter.
 */
flib_cfg *flib_cfg_retain(flib_cfg *cfg);

/**
 * Decrease the reference count of the object and free it if this was the last reference.
 */
void flib_cfg_release(flib_cfg* cfg);

/**
 * Retrieve a mod setting by its name. If the mod is not found, logs an error and returns false.
 */
bool flib_cfg_get_mod(flib_cfg *cfg, const char *name);

/**
 * Retrieve a game setting by its name. If the setting is not found, logs an error and returns def.
 */
int flib_cfg_get_setting(flib_cfg *cfg, const char *name, int def);

#endif /* CFG_H_ */
