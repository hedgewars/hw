#include "frontlib.h"
#include "logging.h"

#include <SDL.h>
#include <SDL_net.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

static int flib_initflags;
static TCPsocket ipcListenSocket;
static int ipcPort;
static uint8_t ipcReadBuffer[256];
static int ipcReadBufferSize;

static TCPsocket ipcConnSocket;
static SDLNet_SocketSet ipcConnSocketSet;

static TCPsocket serverConnSocket;
static SDLNet_SocketSet serverConnSocketSet;


#include <time.h>
void flib_logtime() {
    time_t timer;
    char buffer[25];
    struct tm* tm_info;

    time(&timer);
    tm_info = localtime(&timer);

    strftime(buffer, 25, "%H:%M:%S", tm_info);
    printf("%s", buffer);
}

int flib_init(int flags) {
	flib_initflags = flags;
	ipcListenSocket = NULL;
	ipcConnSocket = NULL;
	serverConnSocket = NULL;
	ipcReadBufferSize = 0;

	if(!(flib_initflags | FRONTLIB_SDL_ALREADY_INITIALIZED)) {
		if(SDL_Init(0)==-1) {
		    flib_log_e("Error in SDL_Init: %s\n", SDL_GetError());
		    return -1;
		}
	}

	if(SDLNet_Init()==-1) {
		flib_log_e("Error in SDLNet_Init: %s\n", SDLNet_GetError());
		if(!(flib_initflags | FRONTLIB_SDL_ALREADY_INITIALIZED)) {
			SDL_Quit();
		}
		return -1;
	}

	ipcConnSocketSet = SDLNet_AllocSocketSet(1);
	serverConnSocketSet = SDLNet_AllocSocketSet(1);
	return 0;
}

/**
 * Free resources associated with the library. Call this function once
 * the library is no longer needed. You can re-initialize the library by calling
 * flib_init again.
 */
void flib_quit() {
	// TODO: Send a "quit" message first?
	SDLNet_FreeSocketSet(ipcConnSocketSet);
	SDLNet_FreeSocketSet(serverConnSocketSet);

	if(ipcListenSocket) {
		SDLNet_TCP_Close(ipcListenSocket);
		ipcListenSocket = NULL;
	}
	if(ipcConnSocket) {
		SDLNet_TCP_Close(ipcConnSocket);
		ipcConnSocket = NULL;
	}
	if(serverConnSocket) {
		SDLNet_TCP_Close(serverConnSocket);
		serverConnSocket = NULL;
	}

	SDLNet_Quit();
	if(!(flib_initflags | FRONTLIB_SDL_ALREADY_INITIALIZED)) {
		SDL_Quit();
	}
}

/**
 * Start listening for a connection from the engine, if we are not listening already.
 * Returns the port we are listening on, which needs to be passed to the engine,
 * or -1 if there is an error.
 *
 * We stop listening once a connection has been established, so if you want to start
 * the engine again and talk to it you need to call this function again after the old
 * connection is closed.
 */
int flib_ipc_listen() {
	if(ipcListenSocket) {
		return ipcPort;
	}
	IPaddress addr;
	addr.host = INADDR_ANY;

	/* SDL_net does not seem to have a way to listen on a random unused port
	   and find out which port that is, so let's try to find one ourselves. */
	// TODO: Is socket binding fail-fast on all platforms?
	srand(time(NULL));
	rand();
	for(int i=0; i<1000; i++) {
		// IANA suggests using ports in the range 49152-65535 for things like this
		ipcPort = 49152+(rand()%(65535-49152));
		SDLNet_Write16(ipcPort, &addr.port);
		flib_log_i("Attempting to listen on port %i...\n", ipcPort);
		ipcListenSocket = SDLNet_TCP_Open(&addr);
		if(!ipcListenSocket) {
			flib_log_w("Unable to listen on port %i: %s\n", ipcPort, SDLNet_GetError());
		} else {
			flib_log_i("ok.\n");
			return ipcPort;
		}
	}
	flib_log_e("Unable to find a usable IPC port.");
	return -1;
}

void flib_accept_ipc() {
	if(!ipcListenSocket) {
		flib_log_e("Attempt to accept IPC connection while not listening.");
		return;
	}
	do {
		TCPsocket sock = SDLNet_TCP_Accept(ipcListenSocket);
		if(!sock) {
			// No incoming connections
			return;
		}
		// Check if it is a local connection
		IPaddress *addr = SDLNet_TCP_GetPeerAddress(sock);
		uint32_t numip = SDLNet_Read32(&addr->host);
		if(numip != (uint32_t)((127UL<<24)+1)) { // 127.0.0.1
			flib_log_w("Rejected IPC connection attempt from %s\n", flib_format_ip(numip));
		} else {
			ipcConnSocket = sock;
			SDLNet_AddSocket(ipcConnSocketSet, (SDLNet_GenericSocket)ipcConnSocket);
			SDLNet_TCP_Close(ipcListenSocket);
			ipcListenSocket = NULL;
		}
	} while(!ipcConnSocket);
	return;
}

/**
 * Receive a single message and copy it into the data buffer.
 * Returns the length of the received message, -1 when nothing is received.
 */
int flib_engine_read_message(void *data) {
	if(!ipcConnSocket && ipcListenSocket) {
		flib_accept_ipc();
	}

	if(ipcConnSocket && SDLNet_CheckSockets(ipcConnSocketSet, 0)>0) {
		int size = SDLNet_TCP_Recv(ipcConnSocket, ipcReadBuffer+ipcReadBufferSize, sizeof(ipcReadBuffer)-ipcReadBufferSize);
		if(size>0) {
			ipcReadBufferSize += size;
		} else {
			SDLNet_DelSocket(ipcConnSocketSet, (SDLNet_GenericSocket)ipcConnSocket);
			SDLNet_TCP_Close(ipcConnSocket);
			ipcConnSocket = NULL;
			// TODO trigger "IPC disconnect" event, possibly delayed until after the messages are processed
		}
	}

	int msgsize = ipcReadBuffer[0];
	if(ipcReadBufferSize > msgsize) {
		memcpy(data, ipcReadBuffer+1, msgsize);
		memmove(ipcReadBuffer, ipcReadBuffer+msgsize+1, ipcReadBufferSize-(msgsize+1));
		ipcReadBufferSize -= (msgsize+1);
		return msgsize;
	} else if(!ipcConnSocket && ipcReadBufferSize>0) {
		flib_log_w("Last message from engine data stream is incomplete (received %u of %u bytes)", ipcReadBufferSize-1, msgsize);
		ipcReadBufferSize = 0;
		return -1;
	} else {
		return -1;
	}
}

void flib_engine_write_message(void *data, size_t len) {
	uint8_t sendbuf[256];
	if(len>255) {
		flib_log_e("Attempt to send too much data to the engine in a single message.");
		return;
	}
	sendbuf[0] = len;
	memcpy(sendbuf+1, data, len);
	SDLNet_TCP_Send(ipcConnSocket, sendbuf, len+1);
}

int main(int argc, char *argv[]) {
	flib_init(0);
	int port = flib_ipc_listen();
	printf("%i", port);
	fflush(stdout);
	char data[256];
	while(ipcListenSocket||ipcConnSocket) {
		int size = flib_engine_read_message(data);
		if(size>0) {
			if(data[0]=='?') {
				flib_engine_write_message("!", 1);
			}
		}
	}
	return 0;
}
