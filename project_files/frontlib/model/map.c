#include "map.h"

#include "../util/inihelper.h"
#include "../util/util.h"
#include "../util/logging.h"
#include "../util/refcounter.h"

#include <stdlib.h>

static void flib_map_destroy(flib_map *map) {
	if(map) {
		free(map->seed);
		free(map->drawData);
		free(map->name);
		free(map->theme);
		free(map);
	}
}

flib_map *flib_map_create_regular(const char *seed, const char *theme, int templateFilter) {
	flib_map *result = NULL;
	if(!seed || !theme) {
		flib_log_e("null parameter in flib_map_create_regular");
	} else {
		flib_map newmap = {0};
		newmap.mapgen = MAPGEN_REGULAR;
		newmap.name = "+rnd+";
		newmap.seed = (char*)seed;
		newmap.theme = (char*)theme;
		newmap.templateFilter = templateFilter;
		result = flib_map_copy(&newmap);
	}
	return result;
}

flib_map *flib_map_create_maze(const char *seed, const char *theme, int mazeSize) {
	flib_map *result = NULL;
	if(!seed || !theme) {
		flib_log_e("null parameter in flib_map_create_maze");
	} else {
		flib_map newmap = {0};
		newmap.mapgen = MAPGEN_MAZE;
		newmap.name = "+maze+";
		newmap.seed = (char*)seed;
		newmap.theme = (char*)theme;
		newmap.mazeSize = mazeSize;
		result = flib_map_copy(&newmap);
	}
	return result;
}

flib_map *flib_map_create_named(const char *seed, const char *name) {
	flib_map *result = NULL;
	if(!seed || !name) {
		flib_log_e("null parameter in flib_map_create_named");
	} else {
		flib_map newmap = {0};
		newmap.mapgen = MAPGEN_NAMED;
		newmap.name = (char*)name;
		newmap.seed = (char*)seed;
		result = flib_map_copy(&newmap);
	}
	return result;
}

flib_map *flib_map_create_drawn(const char *seed, const char *theme, const uint8_t *drawData, int drawDataSize) {
	flib_map *result = NULL;
	if(!seed || !theme || (!drawData && drawDataSize)) {
		flib_log_e("null parameter in flib_map_create_drawn");
	} else {
		flib_map newmap = {0};
		newmap.mapgen = MAPGEN_DRAWN;
		newmap.name = "+drawn+";
		newmap.seed = (char*)seed;
		newmap.theme = (char*)theme;
		newmap.drawData = (uint8_t*) drawData;
		newmap.drawDataSize = drawDataSize;
		result = flib_map_copy(&newmap);
	}
	return result;
}

flib_map *flib_map_copy(const flib_map *map) {
	flib_map *result = NULL;
	if(map) {
		flib_map *newmap = flib_map_retain(flib_calloc(1, sizeof(flib_map)));
		if(newmap) {
			newmap->mapgen = map->mapgen;
			newmap->drawDataSize = map->drawDataSize;
			newmap->drawData = flib_bufdupnull(map->drawData, map->drawDataSize);
			newmap->mazeSize = map->mazeSize;
			newmap->name = flib_strdupnull(map->name);
			newmap->seed = flib_strdupnull(map->seed);
			newmap->templateFilter = map->templateFilter;
			newmap->theme = flib_strdupnull(map->theme);
			if((newmap->drawData || !map->drawData) && (newmap->name || !map->name) && (newmap->seed || !map->seed) && (newmap->theme || !map->theme)) {
				result = newmap;
				newmap = NULL;
			}
		}
		flib_map_release(newmap);
	}
	return result;
}

flib_map *flib_map_retain(flib_map *map) {
	if(map) {
		flib_retain(&map->_referenceCount, "flib_map");
	}
	return map;
}

void flib_map_release(flib_map *map) {
	if(map && flib_release(&map->_referenceCount, "flib_map")) {
		flib_map_destroy(map);
	}
}
