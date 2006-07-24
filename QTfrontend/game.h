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

#ifndef GAME_H
#define GAME_H

#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QByteArray>
#include <QString>
#include <QDir>
#include "team.h"
#include "rndstr.h"

#define IPC_PORT 46631
#define MAXMSGCHARS 255
#define SENDIPC(a) SendIPC(a, sizeof(a) - 1)

class GameConfig;

class HWGame : public QObject
{
	Q_OBJECT
public:
	HWGame(GameConfig * config);
	void AddTeam(const QString & team);
	void PlayDemo(const QString & demofilename);
	void StartLocal();
	void StartNet(const QString & netseed);

signals:
	void SendNet(const QByteArray & msg);

public slots:
	void FromNet(const QByteArray & msg);
	void LocalCFG(const QString & teamname);

private:
    enum GameType {
        gtLocal = 1,
        gtDemo  = 2,
        gtNet   = 3
    };
    QTcpServer * IPCServer;
	QTcpSocket * IPCSocket;
	char msgbuf[MAXMSGCHARS];
	QByteArray readbuffer;
	QString teams[5];
	QString seed;
	int TeamCount;
	RNDStr seedgen;
	QByteArray * demo;
	QByteArray toSendBuf;
	GameConfig * config;
	GameType gameType;

	void Start();
	void SendConfig();
	void SendTeamConfig(int index);
	void ParseMessage(const QByteArray & msg);
	void SendIPC(const char * msg, quint8 len);
	void SendIPC(const QByteArray & buf);
	void SendIPC(const QString & buf);
	void RawSendIPC(const QByteArray & buf);
	void SaveDemo(const QString & filename);
	QString GetThemeBySeed();

private slots:
	void NewConnection();
	void ClientDisconnect();
	void ClientRead();
};

#endif
