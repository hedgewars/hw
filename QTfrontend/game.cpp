/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005-2007 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QMessageBox>
#include <QProcess>
#include <QTimer>
#include <QString>
#include <QByteArray>
#include <QFile>
#include <QTextStream>
#include <QUuid>
#include <QTextStream>

#include "game.h"
#include "hwconsts.h"
#include "gameuiconfig.h"
#include "gamecfgwidget.h"
#include "teamselect.h"
#include "KB.h"
#include "proto.h"

HWGame::HWGame(GameUIConfig * config, GameCFGWidget * gamecfg, TeamSelWidget* pTeamSelWidget) :
  TCPBase(true),
  m_pTeamSelWidget(pTeamSelWidget)
{
	this->config = config;
	this->gamecfg = gamecfg;
	TeamCount = 0;
	seed = "";
}

HWGame::~HWGame()
{
}

void HWGame::onClientDisconnect()
{
	SaveDemo(cfgdir->absolutePath() + "/Demos/LastRound.hwd_" + cProtoVer);
	emit GameStateChanged(gsStopped);
}

void HWGame::commonConfig()
{
	QByteArray buf;
	QString gt;
	switch (gameType) {
		case gtDemo:
			gt = "TD";
			break;
		case gtNet:
			gt = "TN";
			break;
		default:
			gt = "TL";
	}
	HWProto::addStringToBuffer(buf, gt);
	HWProto::addStringListToBuffer(buf, gamecfg->getFullConfig());

	if (m_pTeamSelWidget)
	{
		QList<HWTeam> teams = m_pTeamSelWidget->getPlayingTeams();
		for(QList<HWTeam>::iterator it = teams.begin(); it != teams.end(); ++it)
		{
			HWProto::addStringListToBuffer(buf,
				(*it).TeamGameConfig(gamecfg->getInitHealth()));
		}
	}
	RawSendIPC(buf);
}

void HWGame::SendConfig()
{
	commonConfig();
}

void HWGame::SendQuickConfig()
{
	commonConfig();

	QByteArray teamscfg;
	HWTeam team1(0);
	team1.difficulty = 0;
	team1.teamColor = QColor(65535);
	team1.numHedgehogs = 4;
	HWProto::addStringListToBuffer(teamscfg,
			team1.TeamGameConfig(gamecfg->getInitHealth()));

	HWTeam team2(2);
	team2.difficulty = 4;
	team2.teamColor = QColor(16776960);
	team2.numHedgehogs = 4;
	RawSendIPC(HWProto::addStringListToBuffer(teamscfg,
			team2.TeamGameConfig(gamecfg->getInitHealth())));
}

void HWGame::SendNetConfig()
{
	commonConfig();
}

void HWGame::ParseMessage(const QByteArray & msg)
{
	switch(msg.at(1)) {
		case '?': {
			SendIPC("!");
			break;
		}
		case 'C': {
			switch (gameType) {
				case gtLocal: {
				 	SendConfig();
					break;
				}
				case gtQLocal: {
				 	SendQuickConfig();
					break;
				}
				case gtDemo: break;
				case gtNet: {
					SendNetConfig();
					break;
				}
			}
			break;
		}
		case 'E': {
			emit ErrorMessage(QString().append(msg.mid(2)).left(msg.size() - 6));
			return;
		}
		case 'K': {
			ulong kb = msg.mid(2).toULong();
			if (kb==1) {
			  qWarning("%s", KBMessages[kb - 1].toLocal8Bit().constData());
			  return;
			}
			if (kb && kb <= KBmsgsCount)
			{
				emit ErrorMessage(KBMessages[kb - 1]);
			}
			return;
		}
		case '+': {
			if (gameType == gtNet)
			{
				emit SendNet(msg);
			}
			break;
		}
		case 'i': {
			emit GameStats(msg.at(2), QString::fromUtf8(msg.mid(3)));
			break;
		}
		case 'Q': {
			emit GameStateChanged(gsInterrupted);
			break;
		}
		case 'q': {
			emit GameStateChanged(gsFinished);
			break;
		}
		default: {
			if (gameType == gtNet)
			{
				emit SendNet(msg);
			}
			demo->append(msg);
		}
	}
}

void HWGame::FromNet(const QByteArray & msg)
{
	RawSendIPC(msg);
}

void HWGame::onClientRead()
{
	quint8 msglen;
	quint32 bufsize;
	while (!readbuffer.isEmpty() && ((bufsize = readbuffer.size()) > 0) &&
			((msglen = readbuffer.data()[0]) < bufsize))
	{
		QByteArray msg = readbuffer.left(msglen + 1);
		readbuffer.remove(0, msglen + 1);
		ParseMessage(msg);
	}
}

QStringList HWGame::setArguments()
{
	QStringList arguments;
	arguments << cfgdir->absolutePath();
	arguments << resolutions[0][config->vid_Resolution()];
	arguments << resolutions[1][config->vid_Resolution()];
	arguments << "16"; // bpp
	arguments << QString("%1").arg(ipc_port);
	arguments << (config->vid_Fullscreen() ? "1" : "0");
	arguments << (config->isSoundEnabled() ? "1" : "0");
	arguments << tr("en.txt");
	arguments << "128"; // sound volume
	arguments << QString::number(config->timerInterval());
	arguments << datadir->absolutePath();
	arguments << (config->isShowFPSEnabled() ? "1" : "0");
	return arguments;
}

void HWGame::AddTeam(const QString & teamname)
{
	if (TeamCount == 5) return;
	teams[TeamCount] = teamname;
	TeamCount++;
}

void HWGame::SaveDemo(const QString & filename)
{
	demo->replace(QByteArray("\x02TL"), QByteArray("\x02TD"));
	demo->replace(QByteArray("\x02TN"), QByteArray("\x02TD"));

	QFile demofile(filename);
	if (!demofile.open(QIODevice::WriteOnly))
	{
		emit ErrorMessage(tr("Cannot save demo to file %1").arg(filename));
		return ;
	}
	QDataStream stream(&demofile);
	stream.writeRawData(demo->constData(), demo->size());
	demofile.close();
	delete demo;
	demo=0;
}

void HWGame::PlayDemo(const QString & demofilename)
{
	gameType = gtDemo;
	QFile demofile(demofilename);
	if (!demofile.open(QIODevice::ReadOnly))
	{
		emit ErrorMessage(tr("Cannot open demofile %1").arg(demofilename));
		return ;
	}

	// read demo
	QDataStream stream(&demofile);
	char buf[512];
	int readbytes;
	do
	{
		readbytes = stream.readRawData((char *)&buf, 512);
		toSendBuf.append(QByteArray((char *)&buf, readbytes));
		//SendIPC(QByteArray((char *)&buf, readbytes));

	} while (readbytes > 0);
	demofile.close();

	// run engine
	demo = new QByteArray;
	Start();
	emit GameStateChanged(gsStarted);
}

void HWGame::StartNet()
{
	gameType = gtNet;
	demo = new QByteArray;
	Start();
	emit GameStateChanged(gsStarted);
}

void HWGame::StartLocal()
{
	gameType = gtLocal;
	seed = gamecfg->getCurrentSeed();
	demo = new QByteArray;
	Start();
	emit GameStateChanged(gsStarted);
}

void HWGame::StartQuick()
{
	gameType = gtQLocal;
	seed = gamecfg->getCurrentSeed();
	demo = new QByteArray;
	Start();
	emit GameStateChanged(gsStarted);
}
