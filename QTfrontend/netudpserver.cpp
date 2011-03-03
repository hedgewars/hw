/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2007-2008 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2008-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QUdpSocket>

#include "netudpserver.h"

HWNetUdpServer::HWNetUdpServer(QObject *parent, const QString & descr, quint16 port) :
  HWNetRegisterServer(parent, descr, port)
{
  pUdpSocket = new QUdpSocket(this);
  pUdpSocket->bind(46631);
  connect(pUdpSocket, SIGNAL(readyRead()), this, SLOT(onClientRead()));
}

void HWNetUdpServer::onClientRead()
{
  while (pUdpSocket->hasPendingDatagrams()) {
    QByteArray datagram;
    datagram.resize(pUdpSocket->pendingDatagramSize());
    QHostAddress clientAddr;
    quint16 clientPort;
    pUdpSocket->readDatagram(datagram.data(), datagram.size(), &clientAddr, &clientPort);
    if(QString("%1").arg(datagram.data())==QString("hedgewars client")) {
      // send answer to client
      pUdpSocket->writeDatagram("hedgewars server", clientAddr, clientPort);
    }
  }
}

void HWNetUdpServer::unregister()
{
  deleteLater();
}
