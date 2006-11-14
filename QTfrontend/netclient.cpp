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
#include <QUuid>
#include "netclient.h"
#include "game.h"
#include "gameuiconfig.h"
#include "proto.h"

HWNet::HWNet(GameUIConfig * config)
	: QObject()
{
	this->config = config;
	state = nsDisconnected;
	IRCmsg_cmd_text = new QRegExp("^[A-Z]+ :.+$");
	IRCmsg_number_param = new QRegExp("^:\\S+ [0-9]{3} .+$");
	IRCmsg_who_cmd_target = new QRegExp("^:\\S+ [A-Z]+ \\S+$"); // last \\S should mean 'the 1st char is not ":"'
	IRCmsg_who_cmd_text = new QRegExp("^:\\S+ [A-Z]+ :.+$");
	IRCmsg_who_cmd_target_text = new QRegExp("^:\\S+ [A-Z]+ \\S+ :.+$");
	isOp = false;
	teamsCount = 0;

	connect(&NetSocket, SIGNAL(readyRead()), this, SLOT(ClientRead()));
	connect(&NetSocket, SIGNAL(connected()), this, SLOT(OnConnect()));
	connect(&NetSocket, SIGNAL(disconnected()), this, SLOT(OnDisconnect()));
	connect(&NetSocket, SIGNAL(error(QAbstractSocket::SocketError)), this,
			SLOT(displayError(QAbstractSocket::SocketError)));
}

void HWNet::ClientRead()
{
	while (NetSocket.canReadLine())
	{
		ParseLine(NetSocket.readLine().trimmed());
	}
}

void HWNet::displayError(QAbstractSocket::SocketError socketError)
{
	switch (socketError)
	{
		case QAbstractSocket::RemoteHostClosedError:
			break;
		case QAbstractSocket::HostNotFoundError:
			QMessageBox::information(0, tr("Error"),
					tr("The host was not found. Please check the host name and port settings."));
			break;
		case QAbstractSocket::ConnectionRefusedError:
			QMessageBox::information(0, tr("Error"),
					tr("Connection refused"));
			break;
		default:
			QMessageBox::information(0, tr("Error"),
					NetSocket.errorString());
    }
}

void HWNet::Connect(const QString & hostName, quint16 port, const QString & nick)
{
	state = nsConnecting;
	NetSocket.connectToHost(hostName, port);
	mynick = nick;
	opnick = "";
	opCount = 0;
}


void HWNet::OnConnect()
{
	state = nsConnected;
	RawSendNet(QString("USER hwgame 1 2 Hedgewars game"));
	RawSendNet(QString("NICK %1").arg(mynick));
}

void HWNet::OnDisconnect()
{
	state = nsDisconnected;
}

void HWNet::Perform()
{

}

void HWNet::JoinGame(const QString & game)
{
	state = nsJoining;
	RawSendNet(QString("JOIN %1").arg(game));
}

void HWNet::Disconnect()
{
	switch (state)
	{
		case nsDisconnected:
		{
			break;
		}
		case nsConnecting:
		case nsQuitting:
		{
			NetSocket.disconnect();
			break;
		}
		default:
		{
			state = nsQuitting;
			RawSendNet(QString("QUIT :oops"));
		}
	}
}

void HWNet::RawSendNet(const QString & str)
{
	RawSendNet(str.toUtf8());
}

void HWNet::RawSendNet(const QByteArray & buf)
{
	if (buf.size() > 510) return;
	NetSocket.write(buf);
	NetSocket.write("\x0d\x0a", 2);
}

void HWNet::SendNet(const QByteArray & buf)
{
	if ((state == nsGaming) || (state == nsStarting))
	{
		QString msg = QString(buf.toBase64());
		if ((msg == "AUM=") && (mynick == opnick))
		{
			ConfigAsked();
		} else
		if (msg == "AT8=")
		{
			// its ping ("?")
		} else
		{
			if (state == nsGaming)
			{
				NetBuffer += buf;
			} else
			{
				RawSendNet(QString("PRIVMSG %1 :"MAGIC_CHAR MAGIC_CHAR"%2").arg(channel, msg));
			}
		}
	}
}

void HWNet::FlushNetBuf()
{
	if (NetBuffer.size() > 0)
	{
		RawSendNet(QString("PRIVMSG %1 :"MAGIC_CHAR MAGIC_CHAR"%2").arg(channel, QString(NetBuffer.toBase64())));
		NetBuffer.clear();
	}
}

void HWNet::ParseLine(const QByteArray & line)
{
	QString msg = QString::fromUtf8 (line.data(), line.size());
	//QMessageBox::information(0, "", msg);
	if (IRCmsg_cmd_text->exactMatch(msg))
	{
		msgcmd_textHandler(msg);
	} else
	if (IRCmsg_number_param->exactMatch(msg))
	{
		msgnumber_paramHandler(msg);
	} else
	if (IRCmsg_who_cmd_text->exactMatch(msg))
	{
		msgwho_cmd_textHandler(msg);
	} else
	if (IRCmsg_who_cmd_target->exactMatch(msg))
	{
		msgwho_cmd_targetHandler(msg);
	} else
	if (IRCmsg_who_cmd_target_text->exactMatch(msg))
	{
		msgwho_cmd_target_textHandler(msg);
	}
}

void HWNet::msgcmd_textHandler(const QString & msg)
{
	QStringList list = msg.split(" :");
	if (list[0] == "PING")
	{
		RawSendNet(QString("PONG %1").arg(list[1]));
	}
}

void HWNet::msgnumber_paramHandler(const QString & msg)
{
	int pos = msg.indexOf(" :");
	QString text = msg.mid(pos + 2);
	QStringList list = msg.mid(0, pos).split(" ");
	bool ok;
	quint16 number = list[1].toInt(&ok);
	if (!ok)
		return ;
	switch (number)
	{
		case 001 :
		{
			Perform();
			emit Connected();
			break;
		}
		case 322 : // RPL_LIST
		{
			emit AddGame(list[3]);
			break;
		}
		case 353 : // RPL_NAMREPLY
		{
			QStringList ops = text.split(" ").filter(QRegExp("^@\\S+$"));
			opCount += ops.size();
			if (ops.size() == 1)
			{
				opnick = ops[0].mid(1);
			}
			break;
		}
		case 366 : // RPL_ENDOFNAMES
		{
			if (opCount != 1)
			{
				opnick = "";
			}
			opCount = 0;
			break;
		}
		case 432 : // ERR_ERRONEUSNICKNAME
		case 433 : // ERR_NICKNAMEINUSE
		{
			QMessageBox::information(0, "Your net nickname is in use or cannot be used", msg);
			// ask for another nick
		}
	}
}

void HWNet::msgwho_cmd_targetHandler(const QString & msg)
{
	QStringList list = msg.split(" ");
	QString who = list[0].mid(1).split("!")[0];
	if (list[1] == "NICK")
	{
		if (mynick == who)
			mynick = list[2];
		if (opnick == who)
			opnick = list[2];
	}
}

void HWNet::msgwho_cmd_textHandler(const QString & msg)
{
	int pos = msg.indexOf(" :");
	QString text = msg.mid(pos + 2);
	QStringList list = msg.mid(0, pos).split(" ");
	QString who = list[0].mid(1).split("!")[0];
	if (list[1] == "JOIN")
	{
		if (who == mynick)
		{
			channel = text;
			state = nsJoined;
			emit EnteredGame();
			RawSendNet(QString("PRIVMSG %1 :Hello!").arg(channel));
		}
	}
}
void HWNet::msgwho_cmd_target_textHandler(const QString & msg)
{
	int pos = msg.indexOf(" :");
	QString text = msg.mid(pos + 2);
	QStringList list = msg.mid(0, pos).split(" ");
	QString who = list[0].mid(1).split("!")[0];
	if (list[1] == "PRIVMSG")
	{
		if (list[2] == opnick)
		{
			hwp_opmsg(who, text);
		} else
		if (list[2] == channel)
		{
			hwp_chanmsg(who, text);
		}
	}
}

void HWNet::hwp_opmsg(const QString & who, const QString & msg)
{
	if (state != nsJoined)
		return ;
	if (!msg.startsWith(MAGIC_CHAR))
		return ;
	QStringList list = msg.split(MAGIC_CHAR, QString::SkipEmptyParts);
	if (list[0] == "A")
	{
		list.removeFirst();
		if (list.size() != 9)
			return ;
		if (teamsCount < 5)
		{
			teams[teamsCount].nick = who;
			teams[teamsCount].hhs = list;
			teamsCount++;
			QString teamnames;
			for(int i = 0; i < teamsCount; i++)
			{
				teamnames += MAGIC_CHAR;
				teamnames += teams[i].hhs[0];
			}
			QString tmsg = QString(MAGIC_CHAR"=%2").arg(teamnames);
			RawSendNet(QString("PRIVMSG %1 :").arg(channel) + tmsg);
			hwp_chanmsg(mynick, tmsg);
		}
	}
}

void HWNet::ConfigAsked()
{
	configasks++;
	if (configasks == playerscnt)
	{
		quint32 color = 65535;
		{
			QByteArray cache;
			HWProto::addStringToBuffer(cache, "eseed " + seed);
			HWProto::addStringToBuffer(cache, "e$gmflags 0");
			HWProto::addStringToBuffer(cache, QString("etheme %1").arg(config->GetRandomTheme()));
			QString _msg = MAGIC_CHAR MAGIC_CHAR + QString(cache.toBase64());
			RawSendNet(QString("PRIVMSG %1 :%2").arg(channel, _msg));
			hwp_chanmsg(mynick, _msg);
		}
		for (int i = 0; i < teamsCount; i++)
		{
			QString msg;
			msg = MAGIC_CHAR "T" MAGIC_CHAR + teams[i].nick + MAGIC_CHAR + teams[i].hhs.join(MAGIC_CHAR);
			RawSendNet(QString("PRIVMSG %1 :%2").arg(channel, msg));
			hwp_chanmsg(mynick, msg);
			QByteArray cache;
			HWProto::addStringToBuffer(cache, QString("ecolor %1").arg(color));
			HWProto::addStringToBuffer(cache, "eadd hh0 0");
			HWProto::addStringToBuffer(cache, "eadd hh1 0");
			HWProto::addStringToBuffer(cache, "eadd hh2 0");
			HWProto::addStringToBuffer(cache, "eadd hh3 0");
			HWProto::addStringToBuffer(cache, "eadd hh4 0");
			QString _msg = MAGIC_CHAR MAGIC_CHAR + QString(cache.toBase64());
			RawSendNet(QString("PRIVMSG %1 :%2").arg(channel, _msg));
			hwp_chanmsg(mynick, _msg);
			color <<= 8;
		}
		SENDCFGSTRNET("!");
	}
}

void HWNet::hwp_chanmsg(const QString & who, const QString & msg)
{
	if ((state < nsJoined) || (state > nsGaming))
	{
		return ;
	}
	if (state == nsJoined)
	{
		if (msg.startsWith(MAGIC_CHAR"Start!") && (who == opnick))
		{
			state = nsStarting;
			RunGame();
			return ;
		}
		if (msg.startsWith(MAGIC_CHAR"="MAGIC_CHAR) && (who == opnick))
		{
			emit ChangeInTeams(msg.mid(3).split(MAGIC_CHAR));
		}
	}
	if (state == nsStarting)
	{
		if (msg == MAGIC_CHAR MAGIC_CHAR "AUM=")
		{
			if (mynick == opnick) ConfigAsked();
			return ;
		}
		if (msg == MAGIC_CHAR MAGIC_CHAR "ASE=")
		{
			state = nsGaming;
			TimerFlusher = new QTimer();
			connect(TimerFlusher, SIGNAL(timeout()), this, SLOT(FlushNetBuf()));
			TimerFlusher->start(2000);
		}
		if (msg.startsWith(MAGIC_CHAR"T"MAGIC_CHAR))
		{
			NetTeamAdded(msg.mid(3));
		}
	}
	if ((state < nsStarting) || (state > nsGaming))
	{
		return;
	}
	if (msg.startsWith(MAGIC_CHAR MAGIC_CHAR)) // HWP message
	{
		QByteArray em = QByteArray::fromBase64(msg.mid(2).toAscii());
		emit FromNet(em);
	} else // smth other
	{

	}
}

void HWNet::NetTeamAdded(const QString & msg)
{
	QStringList list = msg.split(MAGIC_CHAR, QString::SkipEmptyParts);
	if (list.size() != 10)
		return ;
	SENDCFGSTRLOC("eaddteam");
	if (list[0] == mynick)
	{
		emit LocalCFG(list[1]);
	} else
	{
		SENDCFGSTRLOC("erdriven");
		SENDCFGSTRLOC(QString("ename team %1").arg(list[1]));
		for (int i = 0; i < 8; i++)
		{
			SENDCFGSTRLOC(QString("ename hh%1 ").arg(i) + list[i + 2]);
		}
	}
}

void HWNet::AddTeam(const HWTeam & team)
{
	if (state != nsJoined)
	{
		return ;
	}
	RawSendNet(QString("PRIVMSG %1 :").arg(opnick) + MAGIC_CHAR "A" MAGIC_CHAR +
			team.TeamName + MAGIC_CHAR + team.HHName[0] + MAGIC_CHAR + team.HHName[1] + MAGIC_CHAR +
			team.HHName[2] + MAGIC_CHAR + team.HHName[3] + MAGIC_CHAR + team.HHName[4] + MAGIC_CHAR +
			team.HHName[5] + MAGIC_CHAR + team.HHName[6] + MAGIC_CHAR + team.HHName[7]);
}

void HWNet::StartGame()
{
	if ((opnick != mynick) || (state != nsJoined))
	{
		return ;
	}
	QStringList players;
	for (int i = 0; i < teamsCount; i++)
	{
		if (!players.contains(teams[i].nick))
		{
			players.append(teams[i].nick);
		}
	}
	playerscnt = players.size();
	configasks = 0;

	seed = QUuid::createUuid().toString();
	QString msg = QString(MAGIC_CHAR"Start!");
	RawSendNet(QString("PRIVMSG %1 :%2").arg(channel, msg));
	hwp_chanmsg(mynick, msg);
}

void HWNet::RunGame()
{
	HWGame * game = new HWGame(config, 0);
	connect(game, SIGNAL(SendNet(const QByteArray &)), this, SLOT(SendNet(const QByteArray &)));
	connect(this, SIGNAL(FromNet(const QByteArray &)), game, SLOT(FromNet(const QByteArray &)));
	connect(this, SIGNAL(LocalCFG(const QString &)), game, SLOT(LocalCFG(const QString &)));
	game->StartNet();
}
