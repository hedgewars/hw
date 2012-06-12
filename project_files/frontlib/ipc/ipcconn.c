#include "ipcconn.h"
#include "../util/logging.h"
#include "../util/util.h"
#include "../socket.h"

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
	int readBufferSize;

	flib_acceptor *acceptor;
	uint16_t port;

	flib_tcpsocket *sock;
} _flib_ipcconn;

flib_ipcconn *flib_ipcconn_create() {
	flib_ipcconn *result = flib_malloc(sizeof(_flib_ipcconn));
	flib_acceptor *acceptor = flib_acceptor_create(0);

	if(!result || !acceptor) {
		free(result);
		flib_acceptor_close(acceptor);
		return NULL;
	}

	result->acceptor = acceptor;
	result->sock = NULL;
	result->readBufferSize = 0;
	result->port = flib_acceptor_listenport(acceptor);

	flib_log_i("Started listening for IPC connections on port %u", (unsigned)result->port);
	return result;
}

uint16_t flib_ipcconn_port(flib_ipcconn *ipc) {
	if(!ipc) {
		flib_log_e("null parameter in flib_ipcconn_port");
		return 0;
	}
	return ipc->port;
}

void flib_ipcconn_destroy(flib_ipcconn *ipc) {
	if(ipc) {
		flib_acceptor_close(ipc->acceptor);
		flib_socket_close(ipc->sock);
		free(ipc);
	}
}

IpcConnState flib_ipcconn_state(flib_ipcconn *ipc) {
	if(!ipc) {
		flib_log_e("null parameter in flib_ipcconn_state");
		return IPC_NOT_CONNECTED;
	} else if(ipc->sock) {
		return IPC_CONNECTED;
	} else if(ipc->acceptor) {
		return IPC_LISTENING;
	} else {
		return IPC_NOT_CONNECTED;
	}
}

static bool isMessageReady(flib_ipcconn *ipc) {
	return ipc->readBufferSize >= ipc->readBuffer[0]+1;
}

static void receiveToBuffer(flib_ipcconn *ipc) {
	if(ipc->sock) {
		int size = flib_socket_nbrecv(ipc->sock, ipc->readBuffer+ipc->readBufferSize, sizeof(ipc->readBuffer)-ipc->readBufferSize);
		if(size>=0) {
			ipc->readBufferSize += size;
		} else {
			flib_socket_close(ipc->sock);
			ipc->sock = NULL;
		}
	}
}

int flib_ipcconn_recv_message(flib_ipcconn *ipc, void *data) {
	if(!ipc || !data) {
		flib_log_e("null parameter in flib_ipcconn_recv_message");
		return -1;
	}

	if(!isMessageReady(ipc)) {
		receiveToBuffer(ipc);
	}

	if(isMessageReady(ipc)) {
		int msgsize = ipc->readBuffer[0]+1;
		memcpy(data, ipc->readBuffer, msgsize);
		memmove(ipc->readBuffer, ipc->readBuffer+msgsize, ipc->readBufferSize-msgsize);
		ipc->readBufferSize -= msgsize;
		return msgsize;
	} else if(!ipc->sock && ipc->readBufferSize>0) {
		flib_log_w("Last message from engine data stream is incomplete (received %u of %u bytes)", (unsigned)ipc->readBufferSize, (unsigned)(ipc->readBuffer[0])+1);
		ipc->readBufferSize = 0;
		return -1;
	} else {
		return -1;
	}
}

int flib_ipcconn_recv_map(flib_ipcconn *ipc, void *data) {
	if(!ipc || !data) {
		flib_log_e("null parameter in flib_ipcconn_recv_map");
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

static void logSentMsg(const uint8_t *data, size_t len) {
	if(flib_log_isActive(FLIB_LOGLEVEL_DEBUG)) {
		size_t msgStart = 0;
		while(msgStart < len) {
			uint8_t msglen = data[msgStart];
			if(msgStart+msglen < len) {
				flib_log_d("[IPC OUT][%03u]%*.*s",(unsigned)msglen, (unsigned)msglen, (unsigned)msglen, data+msgStart+1);
			} else {
				uint8_t msglen2 = len-msgStart-1;
				flib_log_d("[IPC OUT][%03u/%03u]%*.*s",(unsigned)msglen2, (unsigned)msglen, (unsigned)msglen2, (unsigned)msglen2, data+msgStart+1);
			}
			msgStart += (uint8_t)data[msgStart]+1;
		}
	}
}

int flib_ipcconn_send_raw(flib_ipcconn *ipc, const void *data, size_t len) {
	if(!ipc || (!data && len>0)) {
		flib_log_e("null parameter in flib_ipcconn_send_raw");
		return -1;
	}
	if(!ipc->sock) {
		flib_log_w("flib_ipcconn_send_raw: Not connected.");
		return -1;
	}

	if(flib_socket_send(ipc->sock, data, len) == len) {
		logSentMsg(data, len);
		return 0;
	} else {
		flib_log_w("Failed or incomplete ICP write: engine connection lost.");
		flib_socket_close(ipc->sock);
		ipc->sock = NULL;
		return -1;
	}
}

int flib_ipcconn_send_message(flib_ipcconn *ipc, void *data, size_t len) {
	if(!ipc || (!data && len>0)) {
		flib_log_e("null parameter in flib_ipcconn_send_message");
		return -1;
	} else if(len>255) {
		flib_log_e("Overlong message (%zu bytes) in flib_ipcconn_send_message", len);
		return -1;
	}

	uint8_t sendbuf[256];
	sendbuf[0] = len;
	memcpy(sendbuf+1, data, len);
	return flib_ipcconn_send_raw(ipc, sendbuf, len+1);
}

int flib_ipcconn_send_messagestr(flib_ipcconn *ipc, char *data) {
	return flib_ipcconn_send_message(ipc, data, strlen(data));
}

void flib_ipcconn_accept(flib_ipcconn *ipc) {
	if(!ipc) {
		flib_log_e("null parameter in flib_ipcconn_accept");
	} else if(!ipc->sock && ipc->acceptor) {
		ipc->sock = flib_socket_accept(ipc->acceptor, true);
		if(ipc->sock) {
			flib_acceptor_close(ipc->acceptor);
			ipc->acceptor = NULL;
		}
	}
}
