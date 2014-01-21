/*
 * Hedgewars, a free turn based strategy game
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include "socket.h"
#include "util/logging.h"
#include "util/util.h"
#include <stdlib.h>
#include <SDL_net.h>
#include <time.h>

struct _flib_tcpsocket {
    TCPsocket sock;
    SDLNet_SocketSet sockset;
};

struct _flib_acceptor {
    TCPsocket sock;
    uint16_t port;
};

static uint32_t getPeerIp(TCPsocket sock) {
    IPaddress *addr = SDLNet_TCP_GetPeerAddress(sock);
    return SDLNet_Read32(&addr->host);
}

static bool connectionIsLocal(TCPsocket sock) {
    return getPeerIp(sock) == (uint32_t)((127UL<<24)+1); // 127.0.0.1
}

static flib_tcpsocket *createSocket(TCPsocket sdlsock) {
    flib_tcpsocket *result = flib_calloc(1, sizeof(flib_tcpsocket));
    if(result) {
        result->sock = sdlsock;
        result->sockset = SDLNet_AllocSocketSet(1);

        if(!result->sockset) {
            flib_log_e("Can't allocate socket: Out of memory!");
            SDLNet_FreeSocketSet(result->sockset);
            free(result);
            result = NULL;
        } else {
            SDLNet_AddSocket(result->sockset, (SDLNet_GenericSocket)result->sock);
        }
    }
    return result;
}

TCPsocket listen(uint16_t port) {
    IPaddress addr;
    addr.host = INADDR_ANY;
    SDLNet_Write16(port, &addr.port);
    TCPsocket sock = SDLNet_TCP_Open(&addr);
    if(!sock) {
        flib_log_w("Unable to listen on port %u: %s", (unsigned)port, SDLNet_GetError());
    }
    return sock;
}

flib_acceptor *flib_acceptor_create(uint16_t port) {
    flib_acceptor *result = flib_calloc(1, sizeof(flib_acceptor));
    if(result) {
        if(port > 0) {
            result->port = port;
            result->sock = listen(result->port);
        } else {
            /* SDL_net does not seem to have a way to listen on a random unused port
               and find out which port that is, so let's try to find one ourselves. */
            srand(time(NULL));
            for(int i=0; !result->sock && i<1000; i++) {
                // IANA suggests using ports in the range 49152-65535 for things like this
                result->port = 49152+(rand()%(65536-49152));
                result->sock = listen(result->port);
            }
        }
        if(!result->sock) {
            flib_log_e("Failed to create acceptor.");
            free(result);
            result = NULL;
        }
    }
    return result;
}

uint16_t flib_acceptor_listenport(flib_acceptor *acceptor) {
    if(!acceptor) {
        flib_log_e("Call to flib_acceptor_listenport with acceptor==null");
        return 0;
    }
    return acceptor->port;
}

void flib_acceptor_close(flib_acceptor *acceptor) {
    if(acceptor) {
        SDLNet_TCP_Close(acceptor->sock);
        free(acceptor);
    }
}

flib_tcpsocket *flib_socket_accept(flib_acceptor *acceptor, bool localOnly) {
    flib_tcpsocket *result = NULL;
    if(!acceptor) {
        flib_log_e("Call to flib_socket_accept with acceptor==null");
    } else {
        TCPsocket sock = NULL;
        while(!result && (sock = SDLNet_TCP_Accept(acceptor->sock))) {
            if(localOnly && !connectionIsLocal(sock)) {
                flib_log_i("Rejected nonlocal connection attempt from %s", flib_format_ip(getPeerIp(sock)));
            } else {
                result = createSocket(sock);
            }
            if(!result) {
                SDLNet_TCP_Close(sock);
            }
        }
    }
    return result;
}

flib_tcpsocket *flib_socket_connect(const char *host, uint16_t port) {
    flib_tcpsocket *result = NULL;
    if(!host || port==0) {
        flib_log_e("Invalid parameter in flib_socket_connect");
    } else {
        IPaddress ip;
        if(SDLNet_ResolveHost(&ip,host,port)==-1) {
           flib_log_e("SDLNet_ResolveHost: %s\n", SDLNet_GetError());
        } else {
            TCPsocket sock=SDLNet_TCP_Open(&ip);
            if(!sock) {
                flib_log_e("SDLNet_TCP_Open: %s\n", SDLNet_GetError());
            } else {
                result = createSocket(sock);
                if(result) {
                    sock = NULL;
                }
            }
            SDLNet_TCP_Close(sock);
        }
    }
    return result;
}

void flib_socket_close(flib_tcpsocket *sock) {
    if(sock) {
        SDLNet_DelSocket(sock->sockset, (SDLNet_GenericSocket)sock->sock);
        SDLNet_TCP_Close(sock->sock);
        SDLNet_FreeSocketSet(sock->sockset);
        free(sock);
    }
}

int flib_socket_nbrecv(flib_tcpsocket *sock, void *data, int maxlen) {
    if(!sock || (maxlen>0 && !data)) {
        flib_log_e("Call to flib_socket_nbrecv with sock==null or data==null");
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

int flib_socket_send(flib_tcpsocket *sock, const void *data, int len) {
    if(!sock || (len>0 && !data)) {
        flib_log_e("Call to flib_socket_send with sock==null or data==null");
        return -1;
    }
    return SDLNet_TCP_Send(sock->sock, data, len);
}
