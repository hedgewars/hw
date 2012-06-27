/**
 * A complete game configuration that contains all settings for a
 * local or networked game.
 */

#ifndef MODEL_GAMESETUP_H_
#define MODEL_GAMESETUP_H_

#include "cfg.h"
#include "weapon.h"
#include "map.h"
#include "teamlist.h"

typedef struct {
    char *script;
    flib_cfg *gamescheme;
    flib_map *map;
	flib_teamlist *teamlist;
} flib_gamesetup;

void flib_gamesetup_destroy(flib_gamesetup *gamesetup);

#endif
