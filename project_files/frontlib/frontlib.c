#include "frontlib.h"
#include "util/logging.h"
#include "model/map.h"
#include "ipc/mapconn.h"
#include "ipc/gameconn.h"

#include <SDL.h>
#include <SDL_net.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <assert.h>

static int flib_initflags;

int flib_init(int flags) {
	flib_initflags = flags;

	if(!(flib_initflags | FRONTLIB_SDL_ALREADY_INITIALIZED)) {
		if(SDL_Init(0)==-1) {
		    flib_log_e("Error in SDL_Init: %s", SDL_GetError());
		    return -1;
		}
	}

	if(SDLNet_Init()==-1) {
		flib_log_e("Error in SDLNet_Init: %s", SDLNet_GetError());
		if(!(flib_initflags | FRONTLIB_SDL_ALREADY_INITIALIZED)) {
			SDL_Quit();
		}
		return -1;
	}

	return 0;
}

void flib_quit() {
	SDLNet_Quit();
	if(!(flib_initflags | FRONTLIB_SDL_ALREADY_INITIALIZED)) {
		SDL_Quit();
	}
}

static void onDisconnect(void *context, int reason) {
	flib_log_i("Connection closed. Reason: %i", reason);
	flib_gameconn **connptr = context;
	flib_gameconn_destroy(*connptr);
	*connptr = NULL;
}

static void onGameRecorded(void *context, const uint8_t *record, int size, bool isSavegame) {
	flib_log_i("Writing %s (%i bytes)...", isSavegame ? "savegame" : "demo", size);
	FILE *file = fopen(isSavegame ? "testsave.42.hws" : "testdemo.42.hwd", "wb");
	fwrite(record, 1, size, file);
	fclose(file);
}

int main(int argc, char *argv[]) {
	flib_init(0);

	flib_cfg_meta *metaconf = flib_cfg_meta_from_ini("basicsettings.ini", "gamemods.ini");
	assert(metaconf);
	flib_gamesetup setup;
	setup.gamescheme = flib_cfg_from_ini(metaconf, "scheme_shoppa.ini");
	setup.map = flib_map_create_maze("Jungle", MAZE_SIZE_MEDIUM_TUNNELS);
	setup.seed = "apsfooasdgnds";
	setup.teamcount = 2;
	setup.teams = calloc(2, sizeof(flib_team));
	setup.teams[0].color = 0xffff0000;
	setup.teams[0].flag = "australia";
	setup.teams[0].fort = "Plane";
	setup.teams[0].grave = "Bone";
	setup.teams[0].hogsInGame = 2;
	setup.teams[0].name = "Team Awesome";
	setup.teams[0].voicepack = "British";
	setup.teams[0].weaponset = flib_weaponset_create("Defaultweaps");
	setup.teams[0].hogs[0].difficulty = 2;
	setup.teams[0].hogs[0].hat = "NoHat";
	setup.teams[0].hogs[0].initialHealth = 100;
	setup.teams[0].hogs[0].name = "Harry 120";
	setup.teams[0].hogs[1].difficulty = 2;
	setup.teams[0].hogs[1].hat = "chef";
	setup.teams[0].hogs[1].initialHealth = 100;
	setup.teams[0].hogs[1].name = "Chefkoch";
	setup.teams[1].color = 0xff0000ff;
	setup.teams[1].flag = "germany";
	setup.teams[1].fort = "Cake";
	setup.teams[1].grave = "Cherry";
	setup.teams[1].hogsInGame = 2;
	setup.teams[1].name = "The Krauts";
	setup.teams[1].voicepack = "Pirate";
	setup.teams[1].weaponset = flib_weaponset_create("Defaultweaps");
	setup.teams[1].hogs[0].difficulty = 0;
	setup.teams[1].hogs[0].hat = "quotecap";
	setup.teams[1].hogs[0].initialHealth = 100;
	setup.teams[1].hogs[0].name = "Quote";
	setup.teams[1].hogs[1].difficulty = 0;
	setup.teams[1].hogs[1].hat = "chef";
	setup.teams[1].hogs[1].initialHealth = 100;
	setup.teams[1].hogs[1].name = "Chefkoch2";

	flib_gameconn *gameconn = flib_gameconn_create("Medo42", metaconf, &setup, false);
	assert(gameconn);

	flib_gameconn_onDisconnect(gameconn, &onDisconnect, &gameconn);
	flib_gameconn_onGameRecorded(gameconn, &onGameRecorded, &gameconn);

	while(gameconn) {
		flib_gameconn_tick(gameconn);
	}
	flib_log_i("Shutting down...");
	flib_quit();
	return 0;
}
