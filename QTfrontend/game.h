/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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
#include <QByteArray>
#include <QString>
#include "team.h"

#include <map>

#include "tcpBase.h"

class GameUIConfig;
class GameCFGWidget;

class HWGame : public TCPBase
{
	Q_OBJECT
public:
	HWGame(GameUIConfig * config, GameCFGWidget * gamecfg);
	void AddTeam(const QString & team, unsigned char numHedgedogs);
	void PlayDemo(const QString & demofilename);
	void StartLocal();
	void StartQuick();
	void StartNet();

 protected:
	virtual QStringList setArguments();
	virtual void onClientRead();
	virtual void onClientDisconnect();

signals:
	void SendNet(const QByteArray & msg);

public slots:
	void FromNet(const QByteArray & msg);
	void LocalCFG(const QString & teamname);
	void LocalCFG(quint8 num);

private:
    enum GameType {
        gtLocal  = 1,
        gtQLocal = 2,
        gtDemo   = 3,
        gtNet    = 4
    };
	char msgbuf[MAXMSGCHARS];
	QString teams[5];
	std::map<QString, unsigned char> hdNum;
	QString seed;
	int TeamCount;
	GameUIConfig * config;
	GameCFGWidget * gamecfg;
	GameType gameType;

	void SendConfig();
	void SendQuickConfig();
	void SendTeamConfig(int index);
	void ParseMessage(const QByteArray & msg);
	void SaveDemo(const QString & filename);
};

#endif
