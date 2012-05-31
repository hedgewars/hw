#include "ipcconn.h"
#include "logging.h"
#include "nonblocksockets.h"

#include <SDL_net.h>
#include <time.h>
static TCPsocket ipcListenSocket;
static NonBlockSocket ipcConnSocket;

static uint8_t ipcReadBuffer[256];
static int ipcReadBufferSize;

void flib_ipcconn_init() {
	ipcListenSocket = NULL;
	ipcConnSocket = NULL;
	ipcReadBufferSize = 0;
}

void flib_ipcconn_quit() {
	flib_ipcconn_close();
}

int flib_ipcconn_listen() {
	if(ipcListenSocket || ipcConnSocket) {
		flib_log_e("flib_ipcconn_listen: Already listening or connected.");
		return -1;
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
		int ipcPort = 49152+(rand()%(65535-49152));
		SDLNet_Write16(ipcPort, &addr.port);
		ipcListenSocket = SDLNet_TCP_Open(&addr);
		if(!ipcListenSocket) {
			flib_log_w("Failed to start an IPC listening socket on port %i: %s", ipcPort, SDLNet_GetError());
		} else {
			flib_log_i("Listening for IPC connections on port %i.", ipcPort);
			return ipcPort;
		}
	}
	flib_log_e("Unable to find a free port for IPC.");
	return -1;
}

void flib_ipcconn_close() {
	if(ipcListenSocket) {
		SDLNet_TCP_Close(ipcListenSocket);
		ipcListenSocket = NULL;
	}
	flib_nbsocket_close(&ipcConnSocket);
	ipcReadBufferSize = 0;
}

IpcConnState flib_ipcconn_state() {
	if(ipcConnSocket) {
		return IPC_CONNECTED;
	} else if(ipcListenSocket) {
		return IPC_LISTENING;
	} else {
		return IPC_NOT_CONNECTED;
	}
}

/**
 * Receive a single message and copy it into the data buffer.
 * Returns the length of the received message, -1 when nothing is received.
 */
int flib_ipcconn_recv_message(void *data) {
	flib_ipcconn_tick();

	if(ipcConnSocket) {
		int size = flib_nbsocket_recv(ipcConnSocket, ipcReadBuffer+ipcReadBufferSize, sizeof(ipcReadBuffer)-ipcReadBufferSize);
		if(size>=0) {
			ipcReadBufferSize += size;
		} else {
			flib_nbsocket_close(&ipcConnSocket);
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

int flib_ipcconn_send_message(void *data, size_t len) {
	flib_ipcconn_tick();

	if(!ipcConnSocket) {
		flib_log_w("flib_ipcconn_send_message: Not connected.");
		return -1;
	}
	if(len>255) {
		flib_log_e("Attempt to send too much data to the engine in a single message.");
		return -1;
	}

	uint8_t sendbuf[256];
	sendbuf[0] = len;
	memcpy(sendbuf+1, data, len);
	if(flib_nbsocket_blocksend(ipcConnSocket, sendbuf, len+1) < len+1) {
		flib_log_w("Failed or incomplete ICP write: engine connection lost.");
		flib_nbsocket_close(&ipcConnSocket);
		return -1;
	} else {
		return 0;
	}
}

void flib_ipcconn_tick() {
	if(!ipcConnSocket && ipcListenSocket) {
		ipcConnSocket = flib_nbsocket_accept(ipcListenSocket, true);
		if(ipcConnSocket) {
			SDLNet_TCP_Close(ipcListenSocket);
			ipcListenSocket = NULL;
		}
	}
}
