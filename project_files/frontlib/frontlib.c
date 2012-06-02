#include "frontlib.h"
#include "logging.h"
#include "socket.h"
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

	return 0;
}

void flib_quit() {
	SDLNet_Quit();
	if(!(flib_initflags | FRONTLIB_SDL_ALREADY_INITIALIZED)) {
		SDL_Quit();
	}
}

int main(int argc, char *argv[]) {
	flib_init(0);

	flib_ipcconn ipc = flib_ipcconn_create(true, "Medo42");
	char data[256];
	while(flib_ipcconn_state(ipc) != IPC_NOT_CONNECTED) {
		flib_ipcconn_tick(ipc);
		int size = flib_ipcconn_recv_message(ipc, data);
		if(size>0) {
			data[size]=0;
			switch(data[0]) {
			case 'C':
				flib_log_i("Sending config...");
				flib_ipcconn_send_messagestr(ipc, "TL");
				flib_ipcconn_send_messagestr(ipc, "eseed loremipsum");
				flib_ipcconn_send_messagestr(ipc, "escript Missions/Training/Basic_Training_-_Bazooka.lua");
				break;
			case '?':
				flib_log_i("Sending pong...");
				flib_ipcconn_send_messagestr(ipc, "!");
				break;
			case 'Q':
				flib_log_i("Game interrupted.");
				break;
			case 'q':
				flib_log_i("Game finished.");
				flib_constbuffer demobuf = flib_ipcconn_getdemo(ipc);
				flib_log_i("Writing demo (%u bytes)...", demobuf.size);
				FILE *file = fopen("testdemo.dem", "wb");
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
	flib_ipcconn_destroy(&ipc);
	flib_quit();
	return 0;
}
