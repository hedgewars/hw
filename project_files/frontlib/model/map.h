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

#ifndef MODEL_MAP_H_
#define MODEL_MAP_H_

#include <stdint.h>
#include <stdbool.h>

#define MAPGEN_REGULAR 0
#define MAPGEN_MAZE 1
#define MAPGEN_DRAWN 2
#define MAPGEN_NAMED 3

#define TEMPLATEFILTER_ALL 0
#define TEMPLATEFILTER_SMALL 1
#define TEMPLATEFILTER_MEDIUM 2
#define TEMPLATEFILTER_LARGE 3
#define TEMPLATEFILTER_CAVERN 4
#define TEMPLATEFILTER_WACKY 5

#define MAZE_SIZE_SMALL_TUNNELS 0
#define MAZE_SIZE_MEDIUM_TUNNELS 1
#define MAZE_SIZE_LARGE_TUNNELS 2
#define MAZE_SIZE_SMALL_ISLANDS 3
#define MAZE_SIZE_MEDIUM_ISLANDS 4
#define MAZE_SIZE_LARGE_ISLANDS 5

/**
 * Data structure for defining a map. This contains the whole recipe to
 * exactly recreate a particular map. For named maps, you also need the
 * corresponding files.
 *
 * The required fields depend on the map generator, see the comments
 * at the struct for details.
 */
typedef struct {
	int _referenceCount;
	int mapgen;				// Always one of the MAPGEN_ constants
	char *name;				// The name of the map for MAPGEN_NAMED, otherwise one of "+rnd+", "+maze+" or "+drawn+".
	char *seed;				// Used for all maps
	char *theme;			// Used for all maps
	uint8_t *drawData;		// Used for MAPGEN_DRAWN
	int drawDataSize;		// Used for MAPGEN_DRAWN
	int templateFilter;		// Used for MAPGEN_REGULAR
	int mazeSize;			// Used for MAPGEN_MAZE
} flib_map;

/**
 * Create a generated map. theme should be the name of a
 * directory in "Themes" and templateFilter should be one of the
 * TEMPLATEFILTER_* constants, but this is not checked before
 * passing it to the engine.
 *
 * Use flib_map_destroy to free the returned object.
 * No NULL parameters allowed, returns NULL on failure.
 */
flib_map *flib_map_create_regular(const char *seed, const char *theme, int templateFilter);

/**
 * Create a generated maze-type map. theme should be the name of a
 * directory in "Themes" and mazeSize should be one of the
 * MAZE_SIZE_* constants, but this is not checked before
 * passing it to the engine.
 *
 * Use flib_map_destroy to free the returned object.
 * No NULL parameters allowed, returns NULL on failure.
 */
flib_map *flib_map_create_maze(const char *seed, const char *theme, int mazeSize);

/**
 * Create a map from the Maps-Directory. name should be the name of a
 * directory in "Maps", but this is not checked before
 * passing it to the engine. If this is a mission, the corresponding
 * script is used automatically.
 *
 * Use flib_map_destroy to free the returned object.
 * No NULL parameters allowed, returns NULL on failure.
 */
flib_map *flib_map_create_named(const char *seed, const char *name);

/**
 * Create a hand-drawn map. Use flib_map_destroy to free the returned object.
 * No NULL parameters allowed, returns NULL on failure.
 */
flib_map *flib_map_create_drawn(const char *seed, const char *theme, const uint8_t *drawData, int drawDataSize);

/**
 * Create a deep copy of the map. Returns NULL on failure or if NULL was passed.
 */
flib_map *flib_map_copy(const flib_map *map);

/**
 * Increase the reference count of the object. Call this if you store a pointer to it somewhere.
 * Returns the parameter.
 */
flib_map *flib_map_retain(flib_map *map);

/**
 * Decrease the reference count of the object and free it if this was the last reference.
 */
void flib_map_release(flib_map *map);


#endif
