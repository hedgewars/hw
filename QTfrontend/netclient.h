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

#ifndef NET_H
#define NET_H

#include <QObject>
#include <QTcpSocket>
#include <QRegExp>
#include <QStringList>
#include <QTimer>
#include "team.h"
#include "rndstr.h"

#define MAGIC_CHAR "\x2f"

struct netTeam
{
	QString nick;
	QStringList hhs;
};

class GameUIConfig;

class HWNet : public QObject
{
	Q_OBJECT

public:
    HWNet(GameUIConfig * config);
	void Connect(const QString & hostName, quint16 port, const QString & nick);
	void Disconnect();
	void JoinGame(const QString & game);
	void AddTeam(const HWTeam & team);
	void StartGame();

signals:
	void Connected();
	void AddGame(const QString & chan);
	void EnteredGame();
	void FromNet(const QByteArray & buf);
	void LocalCFG(const QString & team);
	void ChangeInTeams(const QStringList & teams);

public slots:
	void SendNet(const QByteArray & buf);

private:
	enum NetState {
		nsDisconnected	= 0,
		nsConnecting	= 1,
		nsConnected	= 3,
		nsJoining	= 4,
		nsJoined	= 5,
		nsStarting	= 6,
		nsGaming	= 7,
		nsQuitting	= 8
	};

	QTcpSocket NetSocket;
	NetState state;
	QRegExp * IRCmsg_cmd_text;
	QRegExp * IRCmsg_number_param;
	QRegExp * IRCmsg_who_cmd_target;
	QRegExp * IRCmsg_who_cmd_target_text;
	QRegExp * IRCmsg_who_cmd_text;
	QString mynick;
	QString opnick;
	QString channel;
	QString seed;
	bool isOp;
	quint32 opCount;
	netTeam teams[5];
	quint8 teamsCount;
	RNDStr seedgen;
	int playerscnt;
	int configasks;
	QByteArray NetBuffer;
	QTimer * TimerFlusher;
	GameUIConfig * config;

	void RawSendNet(const QString & buf);
	void RawSendNet(const QByteArray & buf);

	void ParseLine(const QByteArray & line);
	void msgcmd_textHandler(const QString & msg);
	void msgnumber_paramHandler(const QString & msg);
	void msgwho_cmd_targetHandler(const QString & msg);
	void msgwho_cmd_textHandler(const QString & msg);
	void msgwho_cmd_target_textHandler(const QString & msg);

	void hwp_opmsg(const QString & who, const QString & msg);
	void hwp_chanmsg(const QString & who, const QString & msg);
	void ConfigAsked();
	void NetTeamAdded(const QString & msg);

	void RunGame();


private slots:
	void ClientRead();
	void OnConnect();
	void OnDisconnect();
	void Perform();
	void displayError(QAbstractSocket::SocketError socketError);
	void FlushNetBuf();
};

#define SENDCFGSTRNET(a)   {\
							QByteArray strmsg; \
							strmsg.append(a); \
							quint8 sz = strmsg.size(); \
							QByteArray enginemsg = QByteArray((char *)&sz, 1) + strmsg; \
							QString _msg = MAGIC_CHAR MAGIC_CHAR + QString(enginemsg.toBase64()); \
							hwp_chanmsg(mynick, _msg); \
							RawSendNet(QString("PRIVMSG %1 :").arg(channel) + _msg); \
						}

#define SENDCFGSTRLOC(a)   {\
							QByteArray strmsg; \
							strmsg.append(QString(a).toUtf8()); \
							quint8 sz = strmsg.size(); \
							QByteArray enginemsg = QByteArray((char *)&sz, 1) + strmsg; \
							emit FromNet(enginemsg); \
						}

#endif
