/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2007 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <QUdpSocket>

#include "netudpwidget.h"
#include "hwconsts.h"

HWNetUdpModel::HWNetUdpModel(QObject* parent) :
    HWNetServersModel(parent)
{
    pUdpSocket = new QUdpSocket(this);

    pUdpSocket->bind();
    connect(pUdpSocket, SIGNAL(readyRead()), this, SLOT(onClientRead()));
}

void HWNetUdpModel::updateList()
{
  beginResetModel();

  games.clear();

  endResetModel();

  pUdpSocket->writeDatagram("hedgewars client", QHostAddress::Broadcast, NETGAME_DEFAULT_PORT);
}

void HWNetUdpModel::onClientRead()
{
    beginResetModel();

    while (pUdpSocket->hasPendingDatagrams())
    {
        QByteArray datagram;
        datagram.resize(pUdpSocket->pendingDatagramSize());
        QHostAddress clientAddr;
        quint16 clientPort;

        pUdpSocket->readDatagram(datagram.data(), datagram.size(), &clientAddr, &clientPort);

        QString packet = QString::fromUtf8(datagram.data());
        if(packet.startsWith("hedgewars server"))
        {
            QStringList sl;
            sl << packet.remove(0, 17) << clientAddr.toString() << QString::number(NETGAME_DEFAULT_PORT);
            games.append(sl);
        }
    }

    endResetModel();
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
