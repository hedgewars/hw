/**
 * Data structure for defining a map. Note that most maps also depend on the
 * random seed passed to the engine, if you store that in addition to the
 * flib_map structure you have the whole recipe to exactly recreate a particular
 * map. For named maps, you also need the corresponding files.
 */

#ifndef MODEL_MAP_H_
#define MODEL_MAP_H_

#include <stdint.h>

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

typedef struct {
	int mapgen;				// Always one of the MAPGEN_ constants
	char *theme;			// Used for all except MAPGEN_NAMED
	char *name;				// Used for MAPGEN_NAMED
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
flib_map *flib_map_create_regular(const char *theme, int templateFilter);

/**
 * Create a generated maze-type map. theme should be the name of a
 * directory in "Themes" and mazeSize should be one of the
 * MAZE_SIZE_* constants, but this is not checked before
 * passing it to the engine.
 *
 * Use flib_map_destroy to free the returned object.
 * No NULL parameters allowed, returns NULL on failure.
 */
flib_map *flib_map_create_maze(const char *theme, int mazeSize);

/**
 * Create a map from the Maps-Directory. name should be the name of a
 * directory in "Maps", but this is not checked before
 * passing it to the engine. If this is a mission, the corresponding
 * script is used automatically.
 *
 * Use flib_map_destroy to free the returned object.
 * No NULL parameters allowed, returns NULL on failure.
 */
flib_map *flib_map_create_named(const char *name);

/**
 * Create a hand-drawn map. Use flib_map_destroy to free the returned object.
 * No NULL parameters allowed, returns NULL on failure.
 */
flib_map *flib_map_create_drawn(const char *theme, const uint8_t *drawData, int drawDataSize);

/**
 * Free the memory taken up by the map. Passing NULL is allowed and does nothing.
 */
void flib_map_destroy(flib_map *map);


#endif
