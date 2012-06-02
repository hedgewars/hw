#include "socket.h"
#include "logging.h"
#include <stdlib.h>
#include <SDL_net.h>
#include <time.h>

typedef struct _flib_tcpsocket {
	TCPsocket sock;
	SDLNet_SocketSet sockset;
} _flib_tcpsocket;

typedef struct _flib_acceptor {
	TCPsocket sock;
	uint16_t port;
} _flib_acceptor;

static uint32_t get_peer_ip(TCPsocket sock) {
	IPaddress *addr = SDLNet_TCP_GetPeerAddress(sock);
	return SDLNet_Read32(&addr->host);
}

static bool connection_is_local(TCPsocket sock) {
	return get_peer_ip(sock) == (uint32_t)((127UL<<24)+1); // 127.0.0.1
}

flib_acceptor flib_acceptor_create(uint16_t port) {
	flib_acceptor result = malloc(sizeof(_flib_acceptor));
	if(!result) {
		flib_log_e("Out of memory!");
		return NULL;
	}

	IPaddress addr;
	addr.host = INADDR_ANY;

	if(port > 0) {
		result->port = port;
		SDLNet_Write16(port, &addr.port);
		result->sock = SDLNet_TCP_Open(&addr);
		if(result->sock) {
			return result;
		} else {
			flib_log_e("Unable to listen on port %u: %s", port, SDLNet_GetError());
			free(result);
			return NULL;
		}
	} else {
		/* SDL_net does not seem to have a way to listen on a random unused port
		   and find out which port that is, so let's try to find one ourselves. */
		// TODO: Is socket binding fail-fast on all platforms?
		srand(time(NULL));
		rand();
		for(int i=0; i<1000; i++) {
			// IANA suggests using ports in the range 49152-65535 for things like this
			result->port = 49152+(rand()%(65535-49152));
			SDLNet_Write16(result->port, &addr.port);
			result->sock = SDLNet_TCP_Open(&addr);
			if(result->sock) {
				return result;
			} else {
				flib_log_i("Unable to listen on port %u: %s", result->port, SDLNet_GetError());
			}
		}
		flib_log_e("Unable to listen on a random unused port.");
		free(result);
		return NULL;
	}
}

uint16_t flib_acceptor_listenport(flib_acceptor acceptor) {
	return acceptor->port;
}

void flib_acceptor_close(flib_acceptor *acceptorptr) {
	if(acceptorptr == NULL || *acceptorptr == NULL) {
		return;
	}
	SDLNet_TCP_Close((*acceptorptr)->sock);
	free(*acceptorptr);
	*acceptorptr = NULL;
}

flib_tcpsocket flib_socket_accept(flib_acceptor acceptor, bool localOnly) {
	flib_tcpsocket result = NULL;
	if(!acceptor) {
		return NULL;
	}
	while(result==NULL) {
		TCPsocket sock = SDLNet_TCP_Accept(acceptor->sock);
		if(!sock) {
			// No incoming connections
			return NULL;
		}
		if(localOnly && !connection_is_local(sock)) {
			flib_log_i("Rejected nonlocal connection attempt from %s", flib_format_ip(get_peer_ip(sock)));
			SDLNet_TCP_Close(sock);
		} else {
			result = malloc(sizeof(_flib_tcpsocket));
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

void flib_socket_close(flib_tcpsocket *sockptr) {
	if(sockptr==NULL || *sockptr == NULL) {
		return;
	}
	flib_tcpsocket sock = *sockptr;
	SDLNet_DelSocket(sock->sockset, (SDLNet_GenericSocket)sock->sock);
	SDLNet_TCP_Close(sock->sock);
	SDLNet_FreeSocketSet(sock->sockset);
	free(sock);
	*sockptr = NULL;
}

int flib_socket_nbrecv(flib_tcpsocket sock, void *data, int maxlen) {
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

int flib_socket_send(flib_tcpsocket sock, void *data, int len) {
	return SDLNet_TCP_Send(sock->sock, data, len);
}
