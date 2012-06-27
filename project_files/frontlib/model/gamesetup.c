#include "gamesetup.h"

#include <stdlib.h>

void flib_gamesetup_destroy(flib_gamesetup *gamesetup) {
	if(gamesetup) {
		free(gamesetup->script);
		flib_cfg_release(gamesetup->gamescheme);
		flib_map_release(gamesetup->map);
		flib_teamlist_destroy(gamesetup->teamlist);
		free(gamesetup);
	}
}
