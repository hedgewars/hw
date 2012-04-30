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
 * @brief RoomsListModel class definition
 */

#ifndef HEDGEWARS_ROOMSLISTMODEL_H
#define HEDGEWARS_ROOMSLISTMODEL_H

#include <QAbstractTableModel>
#include <QStringList>

class RoomsListModel : public QAbstractTableModel
{
    Q_OBJECT
public:
    explicit RoomsListModel(QObject *parent = 0);

    QVariant headerData(int section, Qt::Orientation orientation, int role) const;
    int rowCount(const QModelIndex & parent) const;
    int columnCount(const QModelIndex & parent) const;
    QVariant data(const QModelIndex &index, int role) const;

public slots:
    void setRoomsList(const QStringList & rooms);
    void addRoom(const QStringList & info);
    void removeRoom(const QString & name);
    void updateRoom(const QString & name, const QStringList & info);

private:
    QList<QStringList> m_data;
    QStringList m_headerData;

    QStringList roomInfo2RoomRecord(const QStringList & info);
};

#endif // HEDGEWARS_ROOMSLISTMODEL_H
