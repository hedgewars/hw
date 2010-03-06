/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2007 Ulyanov Igor <iulyanov@gmail.com>
 * Copyright (c) 2007, 2008 Andrey Korotaev <unC0Rr@gmail.com>
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

#include "netudpwidget.h"

HWNetUdpModel::HWNetUdpModel(QObject* parent) :
  HWNetServersModel(parent)
{
    pUdpSocket = new QUdpSocket(this);

    pUdpSocket->bind();
    connect(pUdpSocket, SIGNAL(readyRead()), this, SLOT(onClientRead()));
}

void HWNetUdpModel::updateList()
{
    games.clear();

    reset();

    pUdpSocket->writeDatagram("hedgewars client", QHostAddress::Broadcast, 46631);
}

void HWNetUdpModel::onClientRead()
{
    while (pUdpSocket->hasPendingDatagrams()) {
        QByteArray datagram;
        datagram.resize(pUdpSocket->pendingDatagramSize());
        QHostAddress clientAddr;
        quint16 clientPort;

        pUdpSocket->readDatagram(datagram.data(), datagram.size(), &clientAddr, &clientPort);

        if(QString("%1").arg(datagram.data())==QString("hedgewars server")) {
            QStringList sl;
            sl << "-" << clientAddr.toString() << "46631";
            games.append(sl);
        }
    }

    reset();
}

QVariant HWNetUdpModel::data(const QModelIndex &index,
                             int role) const
{
    if (!index.isValid() || index.row() < 0
        || index.row() >= games.size()
        || role != Qt::DisplayRole)
    return QVariant();

    return games[index.row()][index.column()];
}
