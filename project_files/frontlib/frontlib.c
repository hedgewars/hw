#include "frontlib.h"
#include "util/logging.h"
#include <SDL.h>
#include <SDL_net.h>

static int flib_initflags;

int flib_init(int flags) {
	flib_initflags = flags;

	flib_log_d("Initializing frontlib");
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
	flib_log_d("Shutting down frontlib");
	SDLNet_Quit();
	if(!(flib_initflags | FRONTLIB_SDL_ALREADY_INITIALIZED)) {
		SDL_Quit();
	}
}
