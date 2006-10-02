/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Igor Ulyanov <iulyanov@gmail.com>
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

#include "tcpBase.h"

#include <QMessageBox>
#include <QList>

#include <QImage>

#include "hwconsts.h"

QList<TCPBase*> srvsList;

TCPBase::TCPBase(bool demoMode) :
  m_isDemoMode(demoMode)
{
  IPCServer = new QTcpServer(this);
  connect(IPCServer, SIGNAL(newConnection()), this, SLOT(NewConnection()));
  IPCServer->setMaxPendingConnections(1);
}

void TCPBase::NewConnection()
{
  QTcpSocket * client = IPCServer->nextPendingConnection();
  if(!IPCSocket) {
    IPCServer->close();
    IPCSocket = client;
    connect(client, SIGNAL(disconnected()), this, SLOT(ClientDisconnect()));
    connect(client, SIGNAL(readyRead()), this, SLOT(ClientRead()));
    SendToClientFirst();
  } else {
    qWarning("2nd IPC client?!");
    client->disconnectFromHost();
  }
}

void TCPBase::RealStart()
{
  IPCSocket = 0;
  if (!IPCServer->listen(QHostAddress::LocalHost, IPC_PORT)) {
    QMessageBox::critical(0, tr("Error"),
			  tr("Unable to start the server: %1.")
			  .arg(IPCServer->errorString()));
  }
  
  QProcess * process;
  process = new QProcess;
  connect(process, SIGNAL(error(QProcess::ProcessError)), this, SLOT(StartProcessError(QProcess::ProcessError)));
  QStringList arguments=setArguments();
  process->start(bindir->absolutePath() + "/hwengine", arguments);
}

void TCPBase::ClientDisconnect()
{
  IPCSocket->close();
  IPCServer->close();

  onClientDisconnect();

  readbuffer.clear();

  if(srvsList.size()==1) srvsList.pop_front();
  emit isReadyNow();
}

void TCPBase::ClientRead()
{
  readbuffer.append(IPCSocket->readAll());
  onClientRead();
}

void TCPBase::StartProcessError(QProcess::ProcessError error)
{
  QMessageBox::critical(0, tr("Error"),
			tr("Unable to run engine: %1 (")
			.arg(error) + bindir->absolutePath() + "/hwengine)");
}

void TCPBase::tcpServerReady()
{
  disconnect(srvsList.front(), SIGNAL(isReadyNow()), *(++srvsList.begin()), SLOT(tcpServerReady()));
  srvsList.pop_front();

  RealStart();
}

void TCPBase::Start()
{
  if(srvsList.isEmpty()) {
    srvsList.push_back(this);
  } else {
    connect(srvsList.back(), SIGNAL(isReadyNow()), this, SLOT(tcpServerReady()));
    srvsList.push_back(this);
    return;
  }
  
  RealStart();
}

void TCPBase::onClientRead()
{
}

void TCPBase::onClientDisconnect()
{
}

void TCPBase::SendToClientFirst()
{
}

void TCPBase::SendIPC(const QByteArray & buf)
{
	if (buf.size() > MAXMSGCHARS) return;
	quint8 len = buf.size();
	RawSendIPC(QByteArray::fromRawData((char *)&len, 1) + buf);
}

void TCPBase::RawSendIPC(const QByteArray & buf)
{
	if (!IPCSocket)
	{
		toSendBuf += buf;
	} else
	{
		if (toSendBuf.size() > 0)
		{
			IPCSocket->write(toSendBuf);
			if(m_isDemoMode) demo->append(toSendBuf);
			toSendBuf.clear();
		}
		IPCSocket->write(buf);
		if(m_isDemoMode) demo->append(buf);
	}
}
