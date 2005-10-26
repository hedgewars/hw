/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <qserversocket.h>
#include <qsocket.h>

#define MAXMSGCHARS 255
#define SENDIPC(a) SendIPC(a, sizeof(a) - 1)

class QSocket;
class QServerSocket;

class IPCServer : public QServerSocket
{
	Q_OBJECT
public:
	IPCServer( const QHostAddress & address, Q_UINT16 port, QObject *parent ) :
	QServerSocket(address, port, 1, parent, 0)
	{
		if ( !ok() )
		{
			qWarning("Failed to bind");
			exit( 1 );
		}
		msgsize = 0; 
	}
	
private:
	char msgbuf[MAXMSGCHARS];
	unsigned char msgbufsize; 
	unsigned char msgsize;	
	QSocket* ipcsock;
	
	void SendConfig()
	{
		SENDIPC("TL");
		SENDIPC("e$gmflags 0");
		SENDIPC("eaddteam");
		SENDIPC("ename team \"C0CuCKAzZz\"");
		SENDIPC("ename hh0 \"Йожык\"");
		SENDIPC("ename hh1 \"Ёжик\"");
		SENDIPC("ename hh2 \"Ёжык\"");
		SENDIPC("ename hh3 \"Йожик\"");
		SENDIPC("ename hh4 \"Ёжик без ножек\"");
		SENDIPC("ename hh5 \"Just hedgehog\"");
		SENDIPC("ename hh6 \"Ёжик без головы\"");
		SENDIPC("ename hh7 \"Валасатый йож\"");
		SENDIPC("ebind left  \"+left\"");
		SENDIPC("ebind right \"+right\"");
		SENDIPC("ebind up    \"+up\"");
		SENDIPC("ebind down  \"+down\"");
		SENDIPC("ebind F1  \"slot 1\"");
		SENDIPC("ebind F2  \"slot 2\"");
		SENDIPC("ebind F3  \"slot 3\"");
		SENDIPC("ebind F4  \"slot 4\"");
		SENDIPC("ebind F5  \"slot 5\"");
		SENDIPC("ebind F6  \"slot 6\"");
		SENDIPC("ebind F7  \"slot 7\"");
		SENDIPC("ebind F8  \"slot 8\"");
		SENDIPC("ebind F10 \"quit\"");
		SENDIPC("ebind F11 \"capture\"");
		SENDIPC("ebind space     \"+attack\"");
		SENDIPC("ebind return    \"ljump\"");
		SENDIPC("ebind backspace \"hjump\"");
		SENDIPC("ebind tab       \"switch\"");
		SENDIPC("ebind 1 \"timer 1\"");
		SENDIPC("ebind 2 \"timer 2\"");
		SENDIPC("ebind 3 \"timer 3\"");
		SENDIPC("ebind 4 \"timer 4\"");
		SENDIPC("ebind 5 \"timer 5\"");
		SENDIPC("ebind mousel \"put\"");
		SENDIPC("egrave \"coffin\"");
		SENDIPC("efort \"Barrelhouse\"");
		SENDIPC("ecolor 65535");
		SENDIPC("eadd hh0 0");
		SENDIPC("eadd hh1 0");
		SENDIPC("eadd hh2 0");
		SENDIPC("eadd hh3 0");
		SENDIPC("eaddteam");
		SENDIPC("ename team \"-= ЕЖЫ =-\"");
		SENDIPC("ename hh0 \"Маленький\"");
		SENDIPC("ename hh1 \"Удаленький\"");
		SENDIPC("ename hh2 \"Игольчатый\"");
		SENDIPC("ename hh3 \"Стреляный\"");
		SENDIPC("ename hh4 \"Ежиха\"");
		SENDIPC("ename hh5 \"Ежонок\"");
		SENDIPC("ename hh6 \"Инфернальный\"");
		SENDIPC("ename hh7 \"X\"");
		SENDIPC("egrave Bone");
		SENDIPC("ecolor 16776960");
		SENDIPC("eadd hh0 1");
		SENDIPC("eadd hh1 1");
		SENDIPC("eadd hh2 1");
		SENDIPC("eadd hh3 1");
		SENDIPC("efort Barrelhouse");		
	}
	
	void ParseMessage()
	{
		switch(msgsize) {
			case 1: switch(msgbuf[0]) {
				case '?': {
					SENDIPC("!");
					break;
				}
			}
			case 5: switch(msgbuf[0]) {
				case 'C': {
					SendConfig();
					break;
				}
			}
		}
	}
	
	void SendIPC(const char* msg, unsigned char len)
	{
		ipcsock->writeBlock((char *)&len, 1);
		ipcsock->writeBlock(msg, len);
	}

private slots:
	void newConnection( int socket )
	{
    	ipcsock = new QSocket( this );
		connect( ipcsock, SIGNAL(readyRead()), this, SLOT(readClient()) );
		connect( ipcsock, SIGNAL(delayedCloseFinished()), this, SLOT(discardClient()) );
		ipcsock->setSocket( socket );
	}

	void readClient()
	{
		Q_ULONG readbytes = 1;
		while (readbytes > 0) {
			if (msgsize == 0) {
				msgbufsize = 0;
				readbytes = ipcsock->readBlock((char *)&msgsize, 1);
			}
			else {
				msgbufsize += readbytes = ipcsock->readBlock((char *)&msgbuf[msgbufsize], msgsize - msgbufsize);
				if (msgbufsize = msgsize) {
					ParseMessage();
					msgsize = 0;
				}
			}
		}
	}

	void discardClient()
	{
    	delete ipcsock;
	}
};
