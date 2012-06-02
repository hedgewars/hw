#include "frontlib.h"
#include "logging.h"
#include "nonblocksockets.h"
#include "ipcconn.h"

#include <SDL.h>
#include <SDL_net.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

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

	flib_ipcconn_init();
	return 0;
}

void flib_quit() {
	flib_ipcconn_quit();

	SDLNet_Quit();
	if(!(flib_initflags | FRONTLIB_SDL_ALREADY_INITIALIZED)) {
		SDL_Quit();
	}
}

int main(int argc, char *argv[]) {
	flib_init(FRONTLIB_SDL_ALREADY_INITIALIZED);
	flib_ipcconn_start(true);
	char data[256];
	while(flib_ipcconn_state() != IPC_NOT_CONNECTED) {
		flib_ipcconn_tick();
		int size = flib_ipcconn_recv_message(data);
		if(size>0) {
			data[size]=0;
			flib_log_i("IPC IN: %s", data);
			switch(data[0]) {
			case 'C':
				flib_log_i("Sending config...");
				flib_ipcconn_send_messagestr("TL");
				flib_ipcconn_send_messagestr("eseed loremipsum");
				flib_ipcconn_send_messagestr("escript Missions/Training/Basic_Training_-_Bazooka.lua");
				break;
			case '?':
				flib_log_i("Sending pong...");
				flib_ipcconn_send_messagestr("!");
				break;
			case 'Q':
				flib_log_i("Game interrupted.");
				break;
			case 'q':
				flib_log_i("Game finished.");
				flib_constbuffer demobuf = flib_ipcconn_getdemo();
				flib_log_i("Writing demo (%u bytes)...", demobuf.size);
				FILE *file = fopen("testdemo.dem", "w");
				fwrite(demobuf.data, 1, demobuf.size, file);
				fclose(file);
				file = NULL;
				break;
			case 'H':
				flib_log_i("Game halted.");
				break;
			}
		}
	}
	flib_log_i("IPC connection lost.");
	flib_quit();
	return 0;
}
