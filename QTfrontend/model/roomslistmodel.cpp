/*
 * Hedgewars, a free turn based strategy game
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

/**
 * @file
 * @brief RoomsListModel class implementation
 */

#include <QBrush>
#include <QColor>
#include <QIcon>

#include "roomslistmodel.h"
#include "MapModel.h"
#include "hwconsts.h"

RoomsListModel::RoomsListModel(QObject *parent) :
    QAbstractTableModel(parent),
    c_nColumns(10)
{
    m_headerData = QStringList();
    m_headerData << tr("In progress");
    m_headerData << tr("Room Name");
    //: Caption of the column for the number of connected clients in the list of rooms
    m_headerData << tr("C");
    //: Caption of the column for the number of teams in the list of rooms
    m_headerData << tr("T");
    m_headerData << tr("Owner");
    m_headerData << tr("Map");
    m_headerData << tr("Script");
    m_headerData << tr("Rules");
    m_headerData << tr("Weapons");
    m_headerData << tr("Version");

    m_staticMapModel = DataManager::instance().staticMapModel();
    m_missionMapModel = DataManager::instance().missionMapModel();
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
        return c_nColumns;
}


QString RoomsListModel::protoToVersion(const QString & proto)
{
    bool ok;
    uint protoNum = proto.toUInt(&ok);
    if (!ok)
        return "Unknown";
    switch (protoNum) {
    case 17: return "0.9.7-dev";
    case 19: return "0.9.7";
    case 20: return "0.9.8-dev";
    case 21: return "0.9.8";
    case 22: return "0.9.9-dev";
    case 23: return "0.9.9";
    case 24: return "0.9.10-dev";
    case 25: return "0.9.10";
    case 26: return "0.9.11-dev";
    case 27: return "0.9.11";
    case 28: return "0.9.12-dev";
    case 29: return "0.9.12";
    case 30: return "0.9.13-dev";
    case 31: return "0.9.13";
    case 32: return "0.9.14-dev";
    case 33: return "0.9.14";
    case 34: return "0.9.15-dev";
    case 35: return "0.9.14.1";
    case 37: return "0.9.15";
    case 38: return "0.9.16-dev";
    case 39: return "0.9.16";
    case 40: return "0.9.17-dev";
    case 41: return "0.9.17";
    case 42: return "0.9.18-dev";
    case 43: return "0.9.18";
    case 44: return "0.9.19-dev";
    case 45: return "0.9.19";
    case 46: return "0.9.20-dev";
    case 47: return "0.9.20";
    case 48: return "0.9.21-dev";
    case 49: return "0.9.21";
    case 50: return "0.9.22-dev";
    case 51: return "0.9.22";
    case 52: return "0.9.23-dev";
    case 53: return "0.9.23";
    case 54: return "0.9.24-dev";
    case 55: return "0.9.24";
    case 56: return "0.9.25-dev";
    case 57: return "0.9.25";
    case 58: return "1.0.0-dev";
    case 59: return "1.0.0";
    case 60: return "1.1.0-dev";
    default: return "Unknown";
    }
}

QVariant RoomsListModel::data(const QModelIndex &index, int role) const
{
    int column = index.column();
    int row = index.row();

    // invalid index
    if (!index.isValid())
        return QVariant();

    // invalid row
    if ((row < 0) || (row >= m_data.size()))
        return QVariant();

    // invalid column
    if ((column < 0) || (column >= c_nColumns))
        return QVariant();

    // not a role we have data for
    if (role != Qt::DisplayRole)
        // only custom-align counters
        if ((role != Qt::TextAlignmentRole)
            || ((column != PlayerCountColumn) && (column != TeamCountColumn)))
                // only decorate name column
                if ((role != Qt::DecorationRole) || (column != NameColumn))
                    if ((role != Qt::ForegroundRole))
                        // UserRole is used for version column filtering
                        if ((role != Qt::UserRole))
                            return QVariant();

    // decorate room name based on room state
    if (role == Qt::DecorationRole)
    {
        const QIcon roomBusyIcon(":/res/iconDamage.png");
        const QIcon roomBusyIconGreen(":/res/iconDamageLockG.png");
        const QIcon roomBusyIconRed(":/res/iconDamageLockR.png");
        const QIcon roomWaitingIcon(":/res/iconTime.png");
        const QIcon roomWaitingIconGreen(":/res/iconTimeLockG.png");
        const QIcon roomWaitingIconRed(":/res/iconTimeLockR.png");

        QString flags = m_data.at(row).at(StateColumn);

        if (flags.contains("g"))
        {
            if (flags.contains("j"))
                return QVariant(roomBusyIconRed);
            else if (flags.contains("p"))
                return QVariant(roomBusyIconGreen);
            else
                return QVariant(roomBusyIcon);
        }
        else
        {
            if (flags.contains("j"))
                return QVariant(roomWaitingIconRed);
            else if (flags.contains("p"))
                return QVariant(roomWaitingIconGreen);
            else
                return QVariant(roomWaitingIcon);
        }
    }

    QString content = m_data.at(row).at(column);

    if (role == Qt::DisplayRole)
    {
        // display room names
        if (column == 5)
        {
            // special names
            if (content[0] == '+')
            {
                if (content == "+rnd+") return tr("Random Map");
                if (content == "+maze+") return tr("Random Maze");
                if (content == "+perlin+") return tr("Random Perlin");
                if (content == "+drawn+") return tr("Hand-drawn");
                if (content == "+forts+") return tr("Forts");
            }

            // prefix ? if map not available
            if (!m_staticMapModel->mapExists(content) &&
                !m_missionMapModel->mapExists(content))
                return QString ("? %1").arg(content);
        }
        else if (column == VersionColumn)
        {
            return protoToVersion(content);
        }

        return content;
    }

    // dye map names red if map not available
    if (role == Qt::ForegroundRole)
    {
        if (m_data[row][VersionColumn] != *cProtoVer)
            return QBrush(QColor("darkgrey"));

        if (column == MapColumn)
        {
            if (content == "+rnd+" ||
                content == "+maze+" ||
                content == "+perlin+" ||
                content == "+drawn+" ||
                content == "+forts+" ||
                m_staticMapModel->mapExists(content) ||
                m_missionMapModel->mapExists(content))
                return QVariant();
            else
                return QBrush(QColor("darkred"));
        }
        return QVariant();
    }

    if (role == Qt::TextAlignmentRole)
    {
        return (int)(Qt::AlignHCenter | Qt::AlignVCenter);
    }

    if (role == Qt::UserRole && column == VersionColumn)
        return content;

    Q_ASSERT(false);
    return QVariant();
}


void RoomsListModel::setRoomsList(const QStringList & rooms)
{
    beginResetModel();

    m_data.clear();

    int nRooms = rooms.size();

    for (int i = 0; i < nRooms; i += c_nColumns)
    {
        QStringList l;

#if QT_VERSION >= QT_VERSION_CHECK(4, 7, 0)
        l.reserve(c_nColumns);  // small optimisation not supported in old Qt
#endif

        for (int t = 0; t < c_nColumns; t++)
        {
            l.append(rooms[i + t]);
        }

        m_data.append(l);
    }

    endResetModel();
}


void RoomsListModel::addRoom(const QStringList & info)
{
    beginInsertRows(QModelIndex(), 0, 0);

    m_data.prepend(info);

    endInsertRows();
}


int RoomsListModel::rowOfRoom(const QString & name)
{
    int size = m_data.size();

    if (size < 1)
        return -1;

    int i = 0;

    // search for record with matching room name
    while(m_data[i].at(NameColumn) != name)
    {
        i++;
        if(i >= size)
            return -1;
    }

    return i;
}


void RoomsListModel::removeRoom(const QString & name)
{
    int i = rowOfRoom(name);

    if (i < 0)
        return;

    beginRemoveRows(QModelIndex(), i, i);

    m_data.removeAt(i);

    endRemoveRows();
}


void RoomsListModel::updateRoom(const QString & name, const QStringList & info)
{
    int i = rowOfRoom(name);

    if (i < 0)
        return;

    m_data[i] = info;

    emit dataChanged(index(i, 0), index(i, columnCount(QModelIndex()) - 1));
}
