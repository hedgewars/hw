/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef NET_H
#define NET_H

#include <QObject>
#include <QTcpSocket>
#include <QRegExp>
#include <QStringList>
#include <QTimer>
#include "team.h"

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
