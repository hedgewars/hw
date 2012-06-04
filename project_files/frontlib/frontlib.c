#include "frontlib.h"
#include "logging.h"
#include "socket.h"
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
	flib_ipc_send_messagestr(ipc, "escript Missions/Training/Basic_Training_-_Bazooka.lua");
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
		flib_log_i("Writing demo (%u bytes)...", demobuf.size);
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

int main(int argc, char *argv[]) {
	flib_init(0);

	flib_ipc ipc = flib_ipc_create(true, "Medo42");
	assert(ipc);
	flib_ipc_onConfigQuery(ipc, &onConfigQuery, ipc);
	flib_ipc_onDisconnect(ipc, &onDisconnect, &ipc);
	flib_ipc_onGameEnd(ipc, &onGameEnd, ipc);

	while(ipc) {
		flib_ipc_tick(ipc);
	}
	flib_log_i("Shutting down...");
	flib_quit();
	return 0;
}
