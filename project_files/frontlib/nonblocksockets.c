#include "nonblocksockets.h"
#include "logging.h"
#include <stdlib.h>

static uint32_t get_peer_ip(TCPsocket sock) {
	IPaddress *addr = SDLNet_TCP_GetPeerAddress(sock);
	return SDLNet_Read32(&addr->host);
}

static bool connection_is_local(TCPsocket sock) {
	return get_peer_ip(sock) == (uint32_t)((127UL<<24)+1); // 127.0.0.1
}

void flib_nbsocket_close(NonBlockSocket *nbsockptr) {
	NonBlockSocket nbsock = *nbsockptr;
	if(nbsock!=NULL) {
		SDLNet_DelSocket(nbsock->sockset, (SDLNet_GenericSocket)nbsock->sock);
		SDLNet_TCP_Close(nbsock->sock);
		SDLNet_FreeSocketSet(nbsock->sockset);
	}
	free(nbsock);
	*nbsockptr = NULL;
}

NonBlockSocket flib_nbsocket_accept(TCPsocket listensocket, bool localOnly) {
	NonBlockSocket result = NULL;
	if(!listensocket) {
		flib_log_e("Attempt to accept a connection on a NULL socket.");
		return NULL;
	}
	while(result==NULL) {
		TCPsocket sock = SDLNet_TCP_Accept(listensocket);
		if(!sock) {
			// No incoming connections
			return NULL;
		}
		if(localOnly && !connection_is_local(sock)) {
			flib_log_i("Rejected nonlocal connection attempt from %s", flib_format_ip(get_peer_ip(sock)));
			SDLNet_TCP_Close(sock);
		} else {
			result = malloc(sizeof(_NonBlockSocket));
			if(result==NULL) {
				flib_log_e("Out of memory!");
				SDLNet_TCP_Close(sock);
				return NULL;
			}
			result->sock = sock;
			result->sockset = SDLNet_AllocSocketSet(1);
			if(result->sockset==NULL) {
				flib_log_e("Out of memory!");
				SDLNet_TCP_Close(sock);
				free(result);
				return NULL;
			}
			SDLNet_AddSocket(result->sockset, (SDLNet_GenericSocket)result->sock);
		}
	}
	return result;
}

int flib_nbsocket_recv(NonBlockSocket sock, void *data, int maxlen) {
	if(!sock) {
		flib_log_e("Attempt to receive on a NULL socket.");
		return -1;
	}
	int readySockets = SDLNet_CheckSockets(sock->sockset, 0);
	if(readySockets>0) {
		int size = SDLNet_TCP_Recv(sock->sock, data, maxlen);
		return size>0 ? size : -1;
	} else if(readySockets==0) {
		return 0;
	} else {
		flib_log_e("Error in select system call: %s", SDLNet_GetError());
		return -1;
	}
}
