/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2007 Ulyanov Igor <iulyanov@gmail.com>
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
#include <QListWidget>

#include "netudpwidget.h"

HWNetUdpWidget::HWNetUdpWidget(QWidget* parent) :
  QWidget(parent), mainLayout(this)
{
  serversList = new QListWidget(this);
  mainLayout.setMargin(0);
  mainLayout.addWidget(serversList);
  pUdpSocket = new QUdpSocket(this);

  pUdpSocket->bind();
  connect(pUdpSocket, SIGNAL(readyRead()), this, SLOT(onClientRead()));
  updateList();
}

void HWNetUdpWidget::updateList()
{
  serversList->clear();
  pUdpSocket->writeDatagram("hedgewars client", QHostAddress::Broadcast, 46631);
}

void HWNetUdpWidget::onClientRead()
{
  while (pUdpSocket->hasPendingDatagrams()) {
    QByteArray datagram;
    datagram.resize(pUdpSocket->pendingDatagramSize());
    QHostAddress clientAddr;
    quint16 clientPort;
    pUdpSocket->readDatagram(datagram.data(), datagram.size(), &clientAddr, &clientPort);
    if(QString("%1").arg(datagram.data())==QString("hedgewars server")) {
      serversList->addItem(clientAddr.toString());
    }
  }
}
