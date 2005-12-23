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

HWNet::HWNet()
	: QObject()
{
	state = nsDisconnected;
	IRCmsg_cmd_param = new QRegExp("^[A-Z]+ :.+$");
	IRCmsg_number_param = new QRegExp("^:\\S+ [0-9]{3} .+$");
	IRCmsg_who_cmd_param = new QRegExp("^:\\S+ [A-Z]+ \\S+");
	IRCmsg_who_cmd_param_text = new QRegExp("^:\\S+ [A-Z]+ \\S+ :.+$");
	isOp = false;

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
	SendNet(QString("USER hwgame 1 2 Hedgewars game"));
	SendNet(QString("NICK %1").arg(mynick));
}

void HWNet::OnDisconnect()
{
	state = nsDisconnected;
}

void HWNet::Perform()
{
//	SendNet(QString("LIST"));
	SendNet(QString("JOIN #alex"));
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
			SendNet(QString("QUIT :oops"));
		}
	}
}

void HWNet::SendNet(const QString & str)
{
	SendNet(str.toLatin1());
}

void HWNet::SendNet(const QByteArray & buf)
{
	if (buf.size() > 510) return;
	NetSocket.write(buf);
	NetSocket.write("\x0d\x0a", 2);
}

void HWNet::ParseLine(const QString & msg)
{
	//QMessageBox::information(0, "", msg);
	if (IRCmsg_cmd_param->exactMatch(msg))
	{
		msgcmd_paramHandler(msg);
	} else
	if (IRCmsg_number_param->exactMatch(msg))
	{
		msgnumber_paramHandler(msg);
	} else
	if (IRCmsg_who_cmd_param->exactMatch(msg))
	{
		msgwho_cmd_paramHandler(msg);
	} else
	if (IRCmsg_who_cmd_param_text->exactMatch(msg))
	{
		msgwho_cmd_param_textHandler(msg);
	}
}

void HWNet::msgcmd_paramHandler(const QString & msg)
{
	QStringList list = msg.split(" :");
	if (list[0] == "PING")
	{
		SendNet(QString("PONG %1").arg(list[1]));
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
			SendNet(QString("PRIVMSG #alex :%1 ops here").arg(opCount));
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

void HWNet::msgwho_cmd_paramHandler(const QString & msg)
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

void HWNet::msgwho_cmd_param_textHandler(const QString & msg)
{
	int pos = msg.indexOf(" :");
	QString text = msg.mid(pos + 2);
	QStringList list = msg.mid(0, pos).split(" ");
	QString who = list[0].mid(1).split("!")[0];
	if (list[1] == "PRIVMSG")
	{
		SendNet(QString("PRIVMSG #alex :%1 said \"%2\" to %3").arg(who, text, list[2]));
	}
}
