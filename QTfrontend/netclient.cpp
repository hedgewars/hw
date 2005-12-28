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
#include "netclient.h"
#include "game.h"

HWNet::HWNet(int Resolution, bool Fullscreen)
	: QObject()
{
	gameResolution = Resolution;
	gameFullscreen = Fullscreen;
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
	RawSendNet(str.toLatin1());
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
			RawSendNet(QString("PRIVMSG %1 :"MAGIC_CHAR MAGIC_CHAR"%2").arg(channel, msg));
		}
	}
}

void HWNet::ParseLine(const QString & msg)
{
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
		for (int i = 0; i < teamsCount; i++)
		{
			QString msg;
			msg = MAGIC_CHAR "T" MAGIC_CHAR + teams[i].nick + MAGIC_CHAR + teams[i].hhs.join(MAGIC_CHAR);
			RawSendNet(QString("PRIVMSG %1 :%2").arg(channel, msg));
			hwp_chanmsg(mynick, msg);
			SENDCFGSTRNET(QString("ecolor %1").arg(color));
			SENDCFGSTRNET("eadd hh0 0");
			SENDCFGSTRNET("eadd hh1 0");
			SENDCFGSTRNET("eadd hh2 0");
			color <<= 8;
		}
		SENDCFGSTRNET("!");
		state = nsGaming;
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
		if (msg.startsWith(MAGIC_CHAR"Start!"MAGIC_CHAR) && (who == opnick))
		{
			state = nsStarting;
			RunGame(msg.mid(7));
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
		}
		if (msg.startsWith(MAGIC_CHAR"T"MAGIC_CHAR))
		{
			NetTeamAdded(msg.mid(3));
		}
	}
	if ((state != nsGaming) && (state != nsStarting))
	{
		return;
	}
	if (msg.startsWith(MAGIC_CHAR MAGIC_CHAR)) // HWP message
	{
		QByteArray em = QByteArray::fromBase64(msg.mid(2).toLocal8Bit());
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

	QString seed;
	seedgen.GenRNDStr(seed, 10);
	QString msg = QString(MAGIC_CHAR"Start!"MAGIC_CHAR"%1").arg(seed);
	RawSendNet(QString("PRIVMSG %1 :%2").arg(channel, msg));
	hwp_chanmsg(mynick, msg);
}

void HWNet::RunGame(const QString & seed)
{
	HWGame * game = new HWGame(gameResolution, gameFullscreen);
	connect(game, SIGNAL(SendNet(const QByteArray &)), this, SLOT(SendNet(const QByteArray &)));
	connect(this, SIGNAL(FromNet(const QByteArray &)), game, SLOT(FromNet(const QByteArray &)));
	connect(this, SIGNAL(LocalCFG(const QString &)), game, SLOT(LocalCFG(const QString &)));
	game->StartNet(seed);
}
