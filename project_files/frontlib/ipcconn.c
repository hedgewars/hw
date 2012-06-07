#include "ipcconn.h"
#include "logging.h"
#include "socket.h"
#include "demo.h"

#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>

/*
 * The receive buffer has to be able to hold any message that might be received. Normally
 * the messages are at most 256 bytes, but the map preview contains 4097 bytes (4096 for a
 * bitmap, 1 for the number of hogs which fit on the map).
 *
 * We don't need to worry about wasting a few kb though, and I like powers of two...
 */
typedef struct _flib_ipcconn {
	uint8_t readBuffer[8192];
	char playerName[256];

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
		flib_log_e("Can't create ipcconn.");
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
	if(!ipc) {
		flib_log_e("Call to flib_ipcconn_port with ipc==null");
		return 0;
	}
	return ipc->port;
}

void flib_ipcconn_destroy(flib_ipcconn *ipcptr) {
	if(!ipcptr) {
		flib_log_e("Call to flib_ipcconn_destroy with ipcptr==null");
	} else if(*ipcptr) {
		flib_ipcconn ipc = *ipcptr;
		flib_acceptor_close(&ipc->acceptor);
		flib_socket_close(&ipc->sock);
		flib_vector_destroy(&ipc->demoBuffer);
		free(ipc);
		*ipcptr = NULL;
	}
}

IpcConnState flib_ipcconn_state(flib_ipcconn ipc) {
	if(!ipc) {
		flib_log_e("Call to flib_ipcconn_state with ipc==null");
		return IPC_NOT_CONNECTED;
	} else if(ipc->sock) {
		return IPC_CONNECTED;
	} else if(ipc->acceptor) {
		return IPC_LISTENING;
	} else {
		return IPC_NOT_CONNECTED;
	}
}

static bool isMessageReady(flib_ipcconn ipc) {
	return ipc->readBufferSize >= ipc->readBuffer[0]+1;
}

static void receiveToBuffer(flib_ipcconn ipc) {
	if(ipc->sock) {
		int size = flib_socket_nbrecv(ipc->sock, ipc->readBuffer+ipc->readBufferSize, sizeof(ipc->readBuffer)-ipc->readBufferSize);
		if(size>=0) {
			ipc->readBufferSize += size;
		} else {
			flib_socket_close(&ipc->sock);
		}
	}
}

int flib_ipcconn_recv_message(flib_ipcconn ipc, void *data) {
	if(!ipc || !data) {
		flib_log_e("Call to flib_ipcconn_recv_message with ipc==null or data==null");
		return -1;
	}

	if(!isMessageReady(ipc)) {
		receiveToBuffer(ipc);
	}

	if(isMessageReady(ipc)) {
		if(ipc->demoBuffer) {
			if(flib_demo_record_from_engine(ipc->demoBuffer, ipc->readBuffer, ipc->playerName) < 0) {
				flib_log_w("Stopping demo recording due to an error.");
				flib_vector_destroy(&ipc->demoBuffer);
			}
		}
		int msgsize = ipc->readBuffer[0]+1;
		memcpy(data, ipc->readBuffer, msgsize);
		memmove(ipc->readBuffer, ipc->readBuffer+msgsize, ipc->readBufferSize-msgsize);
		ipc->readBufferSize -= msgsize;
		return msgsize;
	} else if(!ipc->sock && ipc->readBufferSize>0) {
		flib_log_w("Last message from engine data stream is incomplete (received %u of %u bytes)", ipc->readBufferSize, ipc->readBuffer[0]+1);
		ipc->readBufferSize = 0;
		return -1;
	} else {
		return -1;
	}
}

int flib_ipcconn_recv_map(flib_ipcconn ipc, void *data) {
	if(!ipc || !data) {
		flib_log_e("Call to flib_ipcconn_recv_map with ipc==null or data==null");
		return -1;
	}

	receiveToBuffer(ipc);

	if(ipc->readBufferSize >= IPCCONN_MAPMSG_BYTES) {
		memcpy(data, ipc->readBuffer, IPCCONN_MAPMSG_BYTES);
		memmove(ipc->readBuffer, ipc->readBuffer+IPCCONN_MAPMSG_BYTES, ipc->readBufferSize-IPCCONN_MAPMSG_BYTES);
		return IPCCONN_MAPMSG_BYTES;
	} else {
		return -1;
	}
}

int flib_ipcconn_send_raw(flib_ipcconn ipc, void *data, size_t len) {
	if(!ipc || (!data && len>0)) {
		flib_log_e("Call to flib_ipcconn_send_raw with ipc==null or data==null");
		return -1;
	}
	if(!ipc->sock) {
		flib_log_w("flib_ipcconn_send_raw: Not connected.");
		return -1;
	}

	if(flib_socket_send(ipc->sock, data, len) == len) {
		if(ipc->demoBuffer) {
			if(flib_demo_record_to_engine(ipc->demoBuffer, data, len) < 0) {
				flib_log_w("Stopping demo recording due to an error.");
				flib_vector_destroy(&ipc->demoBuffer);
			}
		}
		return 0;
	} else {
		flib_log_w("Failed or incomplete ICP write: engine connection lost.");
		flib_socket_close(&ipc->sock);
		return -1;
	}
}

int flib_ipcconn_send_message(flib_ipcconn ipc, void *data, size_t len) {
	if(!ipc || (!data && len>0) || len>255) {
		flib_log_e("Call to flib_ipcconn_send_message with ipc==null or data==null or len>255");
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

void flib_ipcconn_accept(flib_ipcconn ipc) {
	if(!ipc) {
		flib_log_e("Call to flib_ipcconn_accept with ipc==null");
	} else if(!ipc->sock && ipc->acceptor) {
		ipc->sock = flib_socket_accept(ipc->acceptor, true);
		if(ipc->sock) {
			flib_acceptor_close(&ipc->acceptor);
		}
	}
}

flib_constbuffer flib_ipcconn_getrecord(flib_ipcconn ipc, bool save) {
	if(!ipc) {
		flib_log_e("Call to flib_ipcconn_getrecord with ipc==null");
	}
	if(!ipc || !ipc->demoBuffer) {
		flib_constbuffer result = {NULL, 0};
		return result;
	}
	flib_demo_replace_gamemode(flib_vector_as_buffer(ipc->demoBuffer), save ? 'S' : 'D');
	return flib_vector_as_constbuffer(ipc->demoBuffer);
}
