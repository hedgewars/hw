/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
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
