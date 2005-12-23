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

class HWNet : public QObject
{
	Q_OBJECT

public:
    HWNet();
	void Connect(const QString & hostName, quint16 port, const QString & nick);
	void Disconnect();
	void SendNet(const QString & buf);
	void SendNet(const QByteArray & buf);

signals:
	void Connected();
	void AddGame(const QString & chan);

private:
	enum NetState {
		nsDisconnected = 0,
		nsConnecting   = 1,
		nsConnected    = 3,
		nsQuitting     = 5
	};

	QTcpSocket NetSocket;
	NetState state;
	QRegExp * IRCmsg_cmd_param;
	QRegExp * IRCmsg_number_param;
	QRegExp * IRCmsg_who_cmd_param;
	QRegExp * IRCmsg_who_cmd_param_text;
	QString mynick;
	QString opnick;
	bool isOp;
	quint32 opCount;

	void ParseLine(const QString & msg);
	void msgcmd_paramHandler(const QString & msg);
	void msgnumber_paramHandler(const QString & msg);
	void msgwho_cmd_paramHandler(const QString & msg);
	void msgwho_cmd_param_textHandler(const QString & msg);

private slots:
	void ClientRead();
	void OnConnect();
	void OnDisconnect();
	void Perform();
	void displayError(QAbstractSocket::SocketError socketError);
};

#endif
