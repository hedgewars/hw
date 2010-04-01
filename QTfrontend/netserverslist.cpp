/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2007-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

#include "netserverslist.h"

HWNetServersModel::HWNetServersModel(QObject* parent) :
  QAbstractTableModel(parent)
{

}

void HWNetServersModel::updateList()
{

}

QVariant HWNetServersModel::headerData(int section,
            Qt::Orientation orientation, int role) const
{
    if (role != Qt::DisplayRole)
        return QVariant();

    if (orientation == Qt::Horizontal)
    {
        switch (section)
        {
            case 0: return tr("Title");
            case 1: return tr("IP");
            case 2: return tr("Port");
            default: return QVariant();
        }
    } else
        return QString("%1").arg(section + 1);
}

int HWNetServersModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    else
        return games.size();
}

int HWNetServersModel::columnCount(const QModelIndex & parent) const
{
    if (parent.isValid())
        return 0;
    else
        return 3;
}
