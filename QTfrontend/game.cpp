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

#include <QMessageBox>
#include <QProcess>
#include <QTimer>
#include <QString>
#include <QByteArray>
#include <QFile>
#include <QTextStream>
#include <QUuid>

#include "game.h"
#include "hwconsts.h"
#include "gameuiconfig.h"
#include "gamecfgwidget.h"
#include "kb.h"

HWGame::HWGame(GameUIConfig * config, GameCFGWidget * gamecfg) :
  TCPBase(true)
{
	this->config = config;
	this->gamecfg = gamecfg;
	TeamCount = 0;
	seed = "";
}

void HWGame::onClientDisconnect()
{
	SaveDemo(cfgdir->absolutePath() + "/Demos/LastRound.hwd_1");
}

void HWGame::SendTeamConfig(int index)
{
	LocalCFG(teams[index]);
}

void HWGame::SendConfig()
{
	SendIPC(QString("eseed %1").arg(seed).toAscii());
	SendIPC(QString("etheme %1").arg(config->GetRandomTheme()).toAscii());
	SendIPC("TL");
	SendIPC(QString("e$gmflags %1").arg(gamecfg->getGameFlags()).toAscii());

	for (int i = 0; i < TeamCount; i++)
	{
		SendIPC("eaddteam");
		LocalCFG(teams[i]);
		SendIPC(QString("ecolor %1").arg(65535 << i * 8).toAscii());
		for (int t = 0; t < hdNum[teams[i]]; t++)
			SendIPC(QString("eadd hh%1 0").arg(t).toAscii());
	}
}

void HWGame::SendQuickConfig()
{
	SendIPC(QString("eseed %1").arg(seed).toAscii());
	SendIPC(QString("etheme %1").arg(config->GetRandomTheme()).toAscii());
	SendIPC("TL");
	SendIPC(QString("e$gmflags %1").arg(gamecfg->getGameFlags()).toAscii());
	SendIPC("eaddteam");
	LocalCFG(0);
	SendIPC("ecolor 65535");
	SendIPC("eadd hh0 0");
	SendIPC("eadd hh1 0");
	SendIPC("eadd hh2 0");
	SendIPC("eadd hh3 0");
	SendIPC("eaddteam");
	LocalCFG(2);
	SendIPC("ecolor 16776960");
	SendIPC("eadd hh0 1");
	SendIPC("eadd hh1 1");
	SendIPC("eadd hh2 1");
	SendIPC("eadd hh3 1");
}

void HWGame::ParseMessage(const QByteArray & msg)
{
	switch(msg.data()[1]) {
		case '?': {
			if (gameType == gtNet)
				emit SendNet(QByteArray("\x01""?"));
			else
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
					SendIPC("TN");
					emit SendNet(QByteArray("\x01""C"));
					break;
				}
			}
			break;
		}
		case 'E': {
			QMessageBox::critical(0,
					"Hedgewars: error message",
					QString().append(msg.mid(2)).left(msg.size() - 6),
					QMessageBox::Ok,
					QMessageBox::NoButton,
					QMessageBox::NoButton);
			return;
		}
		case 'K': {
			ulong kb = msg.mid(2).toULong();
			if (kb && kb <= KBmsgsCount)
			{
				QMessageBox::information(0,
						"Hedgewars: information",
						KBMessages[kb - 1],
						QMessageBox::Ok,
						QMessageBox::NoButton,
						QMessageBox::NoButton);
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
	while (((bufsize = readbuffer.size()) > 0) &&
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
	arguments << resolutions[0][config->vid_Resolution()];
	arguments << resolutions[1][config->vid_Resolution()];
	arguments << "16";
	arguments << "46631";
	arguments << (config->vid_Fullscreen() ? "1" : "0");
	arguments << (config->isSoundEnabled() ? "1" : "0");
	arguments << tr("en.txt");
	arguments << "128";
	return arguments;
}

void HWGame::AddTeam(const QString & teamname, unsigned char numHedgedogs)
{
	if (TeamCount == 5) return;
	teams[TeamCount] = teamname;
	TeamCount++;
	hdNum[teamname]=numHedgedogs;
}

void HWGame::SaveDemo(const QString & filename)
{
	demo->replace(QByteArray("\x02TL"), QByteArray("\x02TD"));
	demo->replace(QByteArray("\x02TN"), QByteArray("\x02TD"));

	QFile demofile(filename);
	if (!demofile.open(QIODevice::WriteOnly))
	{
		QMessageBox::critical(0,
				tr("Error"),
				tr("Cannot save demo to file %1").arg(filename),
				tr("Quit"));
		return ;
	}
	QDataStream stream(&demofile);
	stream.writeRawData(demo->constData(), demo->size());
	demofile.close();
	delete demo;
}

void HWGame::PlayDemo(const QString & demofilename)
{
	gameType = gtDemo;
	QFile demofile(demofilename);
	if (!demofile.open(QIODevice::ReadOnly))
	{
		QMessageBox::critical(0,
				tr("Error"),
				tr("Cannot open demofile %1").arg(demofilename),
				tr("Quit"));
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
}

void HWGame::StartNet()
{
	gameType = gtNet;
	demo = new QByteArray;
	Start();
}

void HWGame::StartLocal()
{
	gameType = gtLocal;
	if (TeamCount < 2) return;
	seed = gamecfg->getCurrentSeed();//QUuid::createUuid().toString();
	demo = new QByteArray;
	Start();
}

void HWGame::StartQuick()
{
	gameType = gtQLocal;
	seed = gamecfg->getCurrentSeed();//QUuid::createUuid().toString();
	demo = new QByteArray;
	Start();
}


void HWGame::LocalCFG(const QString & teamname)
{
	HWTeam team(teamname);
	if (!team.LoadFromFile()) {
		QMessageBox::critical(0,
				"Error",
				QString("Cannot load team config ""%1""").arg(teamname),
				QMessageBox::Ok,
				QMessageBox::NoButton,
				QMessageBox::NoButton);
		return;
	}
	RawSendIPC(team.IPCTeamInfo());
}

void HWGame::LocalCFG(quint8 num)
{
	HWTeam team(num);
	RawSendIPC(team.IPCTeamInfo());
}
