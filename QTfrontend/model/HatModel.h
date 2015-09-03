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
 * @brief HatModel class definition
 */

#ifndef HEDGEWARS_HATMODEL_H
#define HEDGEWARS_HATMODEL_H

#include <QStandardItemModel>
#include <QStringList>
#include <QVector>
#include <QPair>
#include <QIcon>

class HatModel : public QStandardItemModel
{
        Q_OBJECT

    public:
        HatModel(QObject *parent = 0);

    public slots:
        /// Reloads hats using the DataManager.
        void loadHats();
};

#endif // HEDGEWARS_HATMODEL_H
