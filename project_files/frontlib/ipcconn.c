#include "ipcconn.h"
#include "logging.h"
#include "socket.h"

#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>

typedef struct _flib_ipcconn {
	char playerName[256];

	uint8_t readBuffer[256];
	int readBufferSize;

	flib_acceptor acceptor;
	uint16_t port;

	flib_tcpsocket sock;
	flib_vector demoBuffer;
} _flib_ipcconn;

flib_ipcconn flib_ipcconn_create(bool recordDemo, const char *localPlayerName) {
	flib_ipcconn result = malloc(sizeof(_flib_ipcconn));
	flib_acceptor acceptor = flib_acceptor_create(0);

	if(!result || !acceptor) {
		free(result);
		flib_acceptor_close(&acceptor);
		return NULL;
	}

	result->acceptor = acceptor;
	result->sock = NULL;
	result->readBufferSize = 0;
	result->port = flib_acceptor_listenport(acceptor);

	if(localPlayerName) {
		strncpy(result->playerName, localPlayerName, 255);
	} else {
		strncpy(result->playerName, "Player", 255);
	}

	if(recordDemo) {
		result->demoBuffer = flib_vector_create();
	}

	flib_log_i("Started listening for IPC connections on port %u", result->port);
	return result;
}

uint16_t flib_ipcconn_port(flib_ipcconn ipc) {
	return ipc->port;
}

void flib_ipcconn_destroy(flib_ipcconn *ipcptr) {
	if(!ipcptr || !*ipcptr) {
		return;
	}
	flib_ipcconn ipc = *ipcptr;
	flib_acceptor_close(&ipc->acceptor);
	flib_socket_close(&ipc->sock);
	flib_vector_destroy(&ipc->demoBuffer);
	free(ipc);
	*ipcptr = NULL;
}

IpcConnState flib_ipcconn_state(flib_ipcconn ipc) {
	if(ipc && ipc->sock) {
		return IPC_CONNECTED;
	} else if(ipc && ipc->acceptor) {
		return IPC_LISTENING;
	} else {
		return IPC_NOT_CONNECTED;
	}
}

static void demo_record(flib_ipcconn ipc, const void *data, size_t len) {
	if(ipc->demoBuffer) {
		if(flib_vector_append(ipc->demoBuffer, data, len) < len) {
			// Out of memory, fail demo recording
			flib_vector_destroy(&ipc->demoBuffer);
		}
	}
}

static void demo_record_from_engine(flib_ipcconn ipc, const uint8_t *message) {
	if(!ipc->demoBuffer || message[0]==0) {
		return;
	}
	if(strchr("?CEiQqHb", message[1])) {
		// Those message types are not recorded in a demo.
		return;
	}

	if(message[1] == 's') {
		if(message[0] >= 3) {
			// Chat messages get a special once-over to make them look as if they were received, not sent.
			// Get the actual chat message as c string
			char chatMsg[256];
			memcpy(chatMsg, message+2, message[0]-3);
			chatMsg[message[0]-3] = 0;

			char converted[257];
			bool memessage = message[0] >= 7 && !memcmp(message+2, "/me ", 4);
			const char *template = memessage ? "s\x02* %s %s  " : "s\x01%s: %s  ";
			int size = snprintf(converted+1, 256, template, ipc->playerName, chatMsg);
			converted[0] = size>255 ? 255 : size;
			demo_record(ipc, converted, converted[0]+1);
		}
	} else {
		demo_record(ipc, message, message[0]+1);
	}
}

/**
 * Receive a single message and copy it into the data buffer.
 * Returns the length of the received message, -1 when nothing is received.
 */
int flib_ipcconn_recv_message(flib_ipcconn ipc, void *data) {
	flib_ipcconn_tick(ipc);

	if(ipc->sock) {
		int size = flib_socket_nbrecv(ipc->sock, ipc->readBuffer+ipc->readBufferSize, sizeof(ipc->readBuffer)-ipc->readBufferSize);
		if(size>=0) {
			ipc->readBufferSize += size;
		} else {
			flib_socket_close(&ipc->sock);
		}
	}

	int msgsize = ipc->readBuffer[0];
	if(ipc->readBufferSize > msgsize) {
		demo_record_from_engine(ipc, ipc->readBuffer);
		memcpy(data, ipc->readBuffer+1, msgsize);
		memmove(ipc->readBuffer, ipc->readBuffer+msgsize+1, ipc->readBufferSize-(msgsize+1));
		ipc->readBufferSize -= (msgsize+1);
		return msgsize;
	} else if(!ipc->sock && ipc->readBufferSize>0) {
		flib_log_w("Last message from engine data stream is incomplete (received %u of %u bytes)", ipc->readBufferSize-1, msgsize);
		ipc->readBufferSize = 0;
		return -1;
	} else {
		return -1;
	}
}

int flib_ipcconn_send_raw(flib_ipcconn ipc, void *data, size_t len) {
	flib_ipcconn_tick(ipc);

	if(!ipc->sock) {
		flib_log_w("flib_ipcconn_send_message: Not connected.");
		return -1;
	}

	if(flib_socket_send(ipc->sock, data, len) == len) {
		demo_record(ipc, data, len);
		return 0;
	} else {
		flib_log_w("Failed or incomplete ICP write: engine connection lost.");
		flib_socket_close(&ipc->sock);
		return -1;
	}
}

int flib_ipcconn_send_message(flib_ipcconn ipc, void *data, size_t len) {
	if(len>255) {
		flib_log_e("Attempt to send too much data to the engine in a single message.");
		return -1;
	}

	uint8_t sendbuf[256];
	sendbuf[0] = len;
	memcpy(sendbuf+1, data, len);

	return flib_ipcconn_send_raw(ipc, sendbuf, len+1);
}

int flib_ipcconn_send_messagestr(flib_ipcconn ipc, char *data) {
	return flib_ipcconn_send_message(ipc, data, strlen(data));
}

void flib_ipcconn_tick(flib_ipcconn ipc) {
	if(!ipc->sock && ipc->acceptor) {
		ipc->sock = flib_socket_accept(ipc->acceptor, true);
		if(ipc->sock) {
			flib_acceptor_close(&ipc->acceptor);
		}
	}
}

static void replace_gamemode(flib_buffer buf, char gamemode) {
	size_t msgStart = 0;
	char *data = (char*)buf.data;
	while(msgStart+2 < buf.size) {
		if(!memcmp(data+msgStart, "\x02T", 2)) {
			data[msgStart+2] = gamemode;
		}
		msgStart += (uint8_t)data[msgStart]+1;
	}
}

flib_constbuffer flib_ipcconn_getdemo(flib_ipcconn ipc) {
	if(!ipc->demoBuffer) {
		flib_constbuffer result = {NULL, 0};
		return result;
	}
	replace_gamemode(flib_vector_as_buffer(ipc->demoBuffer), 'D');
	return flib_vector_as_constbuffer(ipc->demoBuffer);
}

flib_constbuffer flib_ipcconn_getsave(flib_ipcconn ipc) {
	if(!ipc->demoBuffer) {
		flib_constbuffer result = {NULL, 0};
		return result;
	}
	replace_gamemode(flib_vector_as_buffer(ipc->demoBuffer), 'S');
	return flib_vector_as_constbuffer(ipc->demoBuffer);
}
