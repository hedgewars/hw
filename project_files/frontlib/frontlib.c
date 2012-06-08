#include "frontlib.h"
#include "logging.h"
#include "model/map.h"
#include "ipc/mapconn.h"
#include "ipc.h"

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

static void onConfigQuery(void *context) {
	flib_log_i("Sending config...");
	flib_ipc ipc = (flib_ipc)context;
	flib_ipc_send_messagestr(ipc, "TL");
	flib_ipc_send_messagestr(ipc, "eseed loremipsum");
	flib_ipc_send_messagestr(ipc, "e$mapgen 0");
	flib_ipc_send_messagestr(ipc, "e$template_filter 0");
	flib_ipc_send_messagestr(ipc, "etheme Jungle");
	flib_ipc_send_messagestr(ipc, "eaddteam 11111111111111111111111111111111 255 Medo42");
}

static void onDisconnect(void *context) {
	flib_log_i("Connection closed.");
	flib_ipc_destroy((flib_ipc*)context);
}

static void onGameEnd(void *context, int gameEndType) {
	switch(gameEndType) {
	case GAME_END_FINISHED:
		flib_log_i("Game finished.");
		flib_constbuffer demobuf = flib_ipc_getdemo(context);
		flib_log_i("Writing demo (%u bytes)...", (unsigned)demobuf.size);
		FILE *file = fopen("testdemo.dem", "wb");
		fwrite(demobuf.data, 1, demobuf.size, file);
		fclose(file);
		file = NULL;
		break;
	case GAME_END_HALTED:
		flib_log_i("Game halted.");
		break;
	case GAME_END_INTERRUPTED:
		flib_log_i("Game iterrupted.");
		break;
	}
}

static void handleMapSuccess(void *context, const uint8_t *bitmap, int numHedgehogs) {
	printf("Drawing map for %i brave little hogs...", numHedgehogs);
	int pixelnum = 0;
	for(int y=0; y<MAPIMAGE_HEIGHT; y++) {
		for(int x=0; x<MAPIMAGE_WIDTH; x++) {
			if(bitmap[pixelnum>>3] & (1<<(7-(pixelnum&7)))) {
				printf("#");
			} else {
				printf(" ");
			}
			pixelnum++;
		}
		printf("\n");
	}

	flib_mapconn **connptr = context;
	flib_mapconn_destroy(*connptr);
	*connptr = NULL;
}

static void handleMapFailure(void *context, const char *errormessage) {
	flib_log_e("Map rendering failed: %s", errormessage);

	flib_mapconn **connptr = context;
	flib_mapconn_destroy(*connptr);
	*connptr = NULL;
}

int main(int argc, char *argv[]) {
/*	flib_init(0);

	flib_cfg_meta *meta = flib_cfg_meta_from_ini("basicsettings.ini", "gamemods.ini");
	flib_cfg *cfg = flib_cfg_create(meta, "DefaultScheme");
	flib_cfg_to_ini(meta, "defaulttest.ini", cfg);

	flib_cfg_meta_destroy(meta);

	flib_quit();
	return 0;*/

	flib_init(0);
	flib_map *mapconf = flib_map_create_regular("Jungle", TEMPLATEFILTER_CAVERN);
	assert(mapconf);

	flib_mapconn *mapconn = flib_mapconn_create("foobart", mapconf);
	assert(mapconn);

	flib_map_destroy(mapconf);
	mapconf = NULL;

	flib_mapconn_onFailure(mapconn, &handleMapFailure, &mapconn);
	flib_mapconn_onSuccess(mapconn, &handleMapSuccess, &mapconn);

	while(mapconn) {
		flib_mapconn_tick(mapconn);
	}
	flib_log_i("Shutting down...");
	flib_quit();
	return 0;
}
