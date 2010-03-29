/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2007 Igor Ulyanov <iulyanov@gmail.com>
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

#include "tcpBase.h"

#include <QMessageBox>
#include <QList>

#include <QImage>

#include "hwconsts.h"

QList<TCPBase*> srvsList;
QPointer<QTcpServer> TCPBase::IPCServer(0);

TCPBase::~TCPBase()
{
}

TCPBase::TCPBase(bool demoMode) :
  m_isDemoMode(demoMode),
  IPCSocket(0)
{
  if(!IPCServer) {
    IPCServer = new QTcpServer(0);
    IPCServer->setMaxPendingConnections(1);
    if (!IPCServer->listen(QHostAddress::LocalHost)) {
      QMessageBox::critical(0, tr("Error"),
                tr("Unable to start the server: %1.")
                .arg(IPCServer->errorString()));
      exit(0); // FIXME - should be graceful exit here
    }
  }
  ipc_port=IPCServer->serverPort();
}

void TCPBase::NewConnection()
{
  if(IPCSocket) {
    // connection should be already finished
    return;
  }
  disconnect(IPCServer, SIGNAL(newConnection()), this, SLOT(NewConnection()));
  IPCSocket = IPCServer->nextPendingConnection();
  if(!IPCSocket) return;
  connect(IPCSocket, SIGNAL(disconnected()), this, SLOT(ClientDisconnect()));
  connect(IPCSocket, SIGNAL(readyRead()), this, SLOT(ClientRead()));
  SendToClientFirst();
}

void TCPBase::RealStart()
{
  connect(IPCServer, SIGNAL(newConnection()), this, SLOT(NewConnection()));
  IPCSocket = 0;

  QProcess * process;
  process = new QProcess;
  connect(process, SIGNAL(error(QProcess::ProcessError)), this, SLOT(StartProcessError(QProcess::ProcessError)));
  QStringList arguments=setArguments();
  
  // redirect everything written on stdout/stderr
  if(isDevBuild)
    process->setProcessChannelMode(QProcess::ForwardedChannels);
  process->start(bindir->absolutePath() + "/hwengine", arguments);
}

void TCPBase::ClientDisconnect()
{
  disconnect(IPCSocket, SIGNAL(readyRead()), this, SLOT(ClientRead()));
  onClientDisconnect();

  if(srvsList.size()==1) srvsList.pop_front();
  emit isReadyNow();
  IPCSocket->deleteLater();
  deleteLater();
}

void TCPBase::ClientRead()
{
  QByteArray readed=IPCSocket->readAll();
  if(readed.isEmpty()) return;
  readbuffer.append(readed);
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
  disconnect(srvsList.takeFirst(), SIGNAL(isReadyNow()), this, SLOT(tcpServerReady()));

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
            if(m_isDemoMode) demo.append(toSendBuf);
            toSendBuf.clear();
        }
        if(!buf.isEmpty()) {
          IPCSocket->write(buf);
          if(m_isDemoMode) demo.append(buf);
        }
    }
}
