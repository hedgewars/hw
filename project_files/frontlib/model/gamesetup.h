/**
 * A complete game configuration that contains all settings for a
 * local or networked game.
 *
 * It should be noted that the meta-configuration is not included.
 */

#ifndef MODEL_GAMESETUP_H_
#define MODEL_GAMESETUP_H_

#include "cfg.h"
#include "weapon.h"
#include "map.h"
#include "team.h"

typedef struct {
    char *seed;						// required
    char *script;					// optional
    flib_cfg *gamescheme;			// optional
    flib_map *map;					// optional
	flib_team **teams;				// optional
	int teamcount;
} flib_gamesetup;

#endif
