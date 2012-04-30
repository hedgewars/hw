/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

/**
 * @file
 * @brief RoomsListModel class implementation
 */

#include "roomslistmodel.h"

RoomsListModel::RoomsListModel(QObject *parent) :
    QAbstractTableModel(parent)
{
    m_headerData =
    QStringList()
     << QString()
     << tr("Room Name")
     << tr("C")
     << tr("T")
     << tr("Owner")
     << tr("Map")
     << tr("Rules")
     << tr("Weapons");
}

QVariant RoomsListModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if(orientation == Qt::Vertical || role != Qt::DisplayRole)
        return QVariant();
    else
        return QVariant(m_headerData.at(section));
}

int RoomsListModel::rowCount(const QModelIndex & parent) const
{
    if(parent.isValid())
        return 0;
    else
        return m_data.size();
}

int RoomsListModel::columnCount(const QModelIndex & parent) const
{
    if(parent.isValid())
        return 0;
    else
        return 8;
}

QVariant RoomsListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0
            || index.row() >= m_data.size()
            || index.column() >= 8
            || (role != Qt::EditRole && role != Qt::DisplayRole)
       )
        return QVariant();

    return m_data.at(index.row()).at(index.column());
}

void RoomsListModel::setRoomsList(const QStringList & rooms)
{
    if(m_data.size())
    {
        beginRemoveRows(QModelIndex(), 0, m_data.size() - 1);
        m_data.clear();
        endRemoveRows();
    }

    for(int i = 0; i < rooms.size(); i += 8)
    {
        QStringList l;
        //l.reserve(8);  not really that useful an optimisation and causes problems w/ old Qt.  Harmless to leave it out.
        for(int t = 0; t < 8; ++t)
            l.append(rooms[i + t]);

        m_data.append(roomInfo2RoomRecord(l));
    }

    beginInsertRows(QModelIndex(), 0, m_data.size() - 1);
    endInsertRows();
}

void RoomsListModel::addRoom(const QStringList & info)
{
    beginInsertRows(QModelIndex(), 0, 0);

    m_data.prepend(roomInfo2RoomRecord(info));

    endInsertRows();
}

void RoomsListModel::removeRoom(const QString & name)
{
    int i = 0;
    while(i < m_data.size() && m_data[i].at(0) != name)
        ++i;
    if(i >= m_data.size())
        return;

    beginRemoveRows(QModelIndex(), i, i);

    m_data.removeAt(i);

    endRemoveRows();
}

void RoomsListModel::updateRoom(const QString & name, const QStringList & info)
{
    int i = 0;
    while(i < m_data.size() && m_data[i].at(0) != name)
        ++i;
    if(i >= m_data.size())
        return;


    m_data[i] = roomInfo2RoomRecord(info);

    emit dataChanged(index(i, 0), index(i, columnCount(QModelIndex()) - 1));
}

QStringList RoomsListModel::roomInfo2RoomRecord(const QStringList & info)
{
    QStringList result;

    result = info;

    return result;
}
