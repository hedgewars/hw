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
 * @brief HatModel class definition
 */

#ifndef HEDGEWARS_HATMODEL_H
#define HEDGEWARS_HATMODEL_H

#include <QAbstractListModel>
#include <QStringList>
#include <QVector>
#include <QPair>
#include <QIcon>

class HatModel : public QAbstractListModel
{
        Q_OBJECT

    public:
        HatModel(QObject *parent = 0);

        QVariant headerData(int section, Qt::Orientation orientation, int role) const;
        int rowCount(const QModelIndex & parent) const;
        //int columnCount(const QModelIndex & parent) const;

    public slots:
        /// Reloads hats using the DataManager.
        void loadHats();

        QVariant data(const QModelIndex &index, int role) const;
    protected:
        QVector<QPair<QString, QIcon> > hats;
};

#endif // HEDGEWARS_HATMODEL_H
