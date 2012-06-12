#include "map.h"

#include "../util/inihelper.h"
#include "../util/util.h"
#include "../util/logging.h"

#include <stdlib.h>

flib_map *flib_map_create_regular(const char *theme, int templateFilter) {
	flib_map *result = NULL;
	if(!theme) {
		flib_log_e("null parameter in flib_map_create_regular");
	} else {
		flib_map *newmap = flib_calloc(1, sizeof(flib_map));
		if(newmap) {
			newmap->mapgen = MAPGEN_REGULAR;
			newmap->templateFilter = templateFilter;
			newmap->theme = flib_strdupnull(theme);
			if(newmap->theme) {
				result = newmap;
				newmap = NULL;
			}
		}
		flib_map_destroy(newmap);
	}
	return result;
}

flib_map *flib_map_create_maze(const char *theme, int mazeSize) {
	flib_map *result = NULL;
	if(!theme) {
		flib_log_e("null parameter in flib_map_create_maze");
	} else {
		flib_map *newmap = flib_calloc(1, sizeof(flib_map));
		if(newmap) {
			newmap->mapgen = MAPGEN_MAZE;
			newmap->mazeSize = mazeSize;
			newmap->theme = flib_strdupnull(theme);
			if(newmap->theme) {
				result = newmap;
				newmap = NULL;
			}
		}
		flib_map_destroy(newmap);
	}
	return result;
}

flib_map *flib_map_create_named(const char *name) {
	flib_map *result = NULL;
	if(!name) {
		flib_log_e("null parameter in flib_map_create_named");
	} else {
		flib_map *newmap = flib_calloc(1, sizeof(flib_map));
		if(newmap) {
			newmap->mapgen = MAPGEN_NAMED;
			newmap->name = flib_strdupnull(name);
			if(newmap->name) {
				result = newmap;
				newmap = NULL;
			}
		}
		flib_map_destroy(newmap);
	}
	return result;
}

flib_map *flib_map_create_drawn(const char *theme, const uint8_t *drawData, int drawDataSize) {
	flib_map *result = NULL;
	if(!theme || !drawData) {
		flib_log_e("null parameter in flib_map_create_named");
	} else {
		flib_map *newmap = flib_calloc(1, sizeof(flib_map));
		if(newmap) {
			newmap->mapgen = MAPGEN_DRAWN;
			newmap->drawData = flib_bufdupnull(drawData, drawDataSize);
			newmap->drawDataSize = drawDataSize;
			if(newmap->drawData) {
				result = newmap;
				newmap = NULL;
			}
		}
		flib_map_destroy(newmap);
	}
	return result;
}

void flib_map_destroy(flib_map *map) {
	if(map) {
		free(map->drawData);
		free(map->name);
		free(map->theme);
		free(map);
	}
}
