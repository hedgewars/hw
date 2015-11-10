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

#include "map.h"

#include "../util/inihelper.h"
#include "../util/util.h"
#include "../util/logging.h"

#include <stdlib.h>

flib_map *flib_map_create_regular(const char *seed, const char *theme, int templateFilter) {
    if(log_badargs_if2(seed==NULL, theme==NULL)) {
        return NULL;
    }
    flib_map newmap = {0};
    newmap.mapgen = MAPGEN_REGULAR;
    newmap.name = "+rnd+";
    newmap.seed = (char*)seed;
    newmap.theme = (char*)theme;
    newmap.templateFilter = templateFilter;
    return flib_map_copy(&newmap);
}

flib_map *flib_map_create_maze(const char *seed, const char *theme, int mazeSize) {
    if(log_badargs_if2(seed==NULL, theme==NULL)) {
        return NULL;
    }
    flib_map newmap = {0};
    newmap.mapgen = MAPGEN_MAZE;
    newmap.name = "+maze+";
    newmap.seed = (char*)seed;
    newmap.theme = (char*)theme;
    newmap.mazeSize = mazeSize;
    return flib_map_copy(&newmap);
}

flib_map *flib_map_create_named(const char *seed, const char *name) {
    if(log_badargs_if2(seed==NULL, name==NULL)) {
        return NULL;
    }
    flib_map newmap = {0};
    newmap.mapgen = MAPGEN_NAMED;
    newmap.name = (char*)name;
    newmap.seed = (char*)seed;
    return flib_map_copy(&newmap);
}

flib_map *flib_map_create_drawn(const char *seed, const char *theme, const uint8_t *drawData, size_t drawDataSize) {
    if(log_badargs_if3(seed==NULL, theme==NULL, drawData==NULL)) {
        return NULL;
    }
    flib_map newmap = {0};
    newmap.mapgen = MAPGEN_DRAWN;
    newmap.name = "+drawn+";
    newmap.seed = (char*)seed;
    newmap.theme = (char*)theme;
    newmap.drawData = (uint8_t*) drawData;
    newmap.drawDataSize = drawDataSize;
    return flib_map_copy(&newmap);
}

flib_map *flib_map_copy(const flib_map *map) {
    flib_map *result = NULL;
    if(map) {
        flib_map *newmap = flib_calloc(1, sizeof(flib_map));
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
        flib_map_destroy(newmap);
    }
    return result;
}

void flib_map_destroy(flib_map *map) {
    if(map) {
        free(map->seed);
        free(map->drawData);
        free(map->name);
        free(map->theme);
        free(map);
    }
}
