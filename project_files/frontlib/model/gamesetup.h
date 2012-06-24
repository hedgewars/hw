/**
 * A complete game configuration that contains all settings for a
 * local or networked game.
 */

#ifndef MODEL_GAMESETUP_H_
#define MODEL_GAMESETUP_H_

#include "cfg.h"
#include "weapon.h"
#include "map.h"
#include "team.h"

typedef struct {
    char *script;
    flib_cfg *gamescheme;
    flib_map *map;
	int teamCount;
	flib_team **teams;
} flib_gamesetup;

#endif
