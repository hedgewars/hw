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

#include <QMessageBox>
#include <QProcess>
#include <QTimer>
#include <QFile>
#include <QString>
#include <QByteArray>
#include <QTextStream>
#include "game.h"
#include "hwconsts.h"

HWGame::HWGame()
{
	IPCServer = new QTcpServer(this);
	IPCServer->setMaxPendingConnections(1);
	if (!IPCServer->listen(QHostAddress("127.0.0.1"), IPC_PORT)) 
	{
		QMessageBox::critical(this, tr("Error"),
				tr("Unable to start the server: %1.")
				.arg(IPCServer->errorString()));
	}
	connect(IPCServer, SIGNAL(newConnection()), this, SLOT(NewConnection()));
	IPCSocket = 0;
	TeamCount = 0;
	seed = "seed";
}

void HWGame::NewConnection()
{
	QTcpSocket * client = IPCServer->nextPendingConnection();
	if(!IPCSocket)
	{
		IPCSocket = client;
		connect(client, SIGNAL(disconnected()), this, SLOT(ClientDisconnect()));
		connect(client, SIGNAL(readyRead()), this, SLOT(ClientRead()));
		msgsize = 0;
	} else
	{
		client->disconnectFromHost();
		delete client;
	}
}

void HWGame::ClientDisconnect()
{
	IPCSocket = 0;
	delete this;
}

void HWGame::SendTeamConfig(int index)
{
	QFile teamcfg(teams[index]);
	if (!teamcfg.open(QIODevice::ReadOnly))
	{
		return ;
	}
	QTextStream stream(&teamcfg);
	stream.setCodec("UTF-8");	
	QString str;
	
	while (!stream.atEnd())
	{
		str = stream.readLine();
		if (str.startsWith(";")) continue;
		str.prepend("e");
		SendIPC(str.toLocal8Bit());
	}
	teamcfg.close();
}

void HWGame::SendConfig()
{
	SENDIPC("TL");
	SENDIPC("e$gmflags 0");
	SENDIPC("eaddteam");
	SendTeamConfig(0);
	SENDIPC("ecolor 65535");
	SENDIPC("eadd hh0 0");
	SENDIPC("eadd hh1 0");
	SENDIPC("eadd hh2 0");
	SENDIPC("eadd hh3 0");
	SENDIPC("eaddteam");
	SendTeamConfig(1);
	SENDIPC("ecolor 16776960");
	SENDIPC("eadd hh0 1");
	SENDIPC("eadd hh1 1");
	SENDIPC("eadd hh2 1");
	SENDIPC("eadd hh3 1");
}

void HWGame::ParseMessage()
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

void HWGame::SendIPC(const char* msg, unsigned char len)
{
	IPCSocket->write((char *)&len, 1);
	IPCSocket->write(msg, len);
}

void HWGame::SendIPC(const QByteArray buf)
{
	if (buf.size() > 255) return;
	unsigned char len = buf.size();
	IPCSocket->write((char *)&len, 1);
	IPCSocket->write(buf);
}

void HWGame::ClientRead()
{
	qint64 readbytes = 1;
	while (readbytes > 0) 
	{
		if (msgsize == 0) 
		{
			msgbufsize = 0;
			readbytes = IPCSocket->read((char *)&msgsize, 1);
		} else
		{
			msgbufsize += 
			readbytes = IPCSocket->read((char *)&msgbuf[msgbufsize], msgsize - msgbufsize);
			if (msgbufsize = msgsize)
			{
				ParseMessage();
				msgsize = 0;
			}
		}
	}
}

void HWGame::Start(int Resolution, bool Fullscreen)
{
	if (TeamCount < 2) return;
	QProcess * process;
	QStringList arguments;
	seedgen.GenRNDStr(seed, 10);
	process = new QProcess;
	arguments << resolutions[0][Resolution];
	arguments << resolutions[1][Resolution];
	arguments << "avematan";
	arguments << "46631";
	arguments << seed;
	arguments << (Fullscreen ? "1" : "0");
	process->start("hw", arguments);
}

void HWGame::AddTeam(const QString & teamname)
{
	if (TeamCount == 5) return;
	teams[TeamCount] = teamname;
	TeamCount++;
}
