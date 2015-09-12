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
 * @brief GameStyleModel class definition
 */

#ifndef HEDGEWARS_GAMESTYLEMODEL_H
#define HEDGEWARS_GAMESTYLEMODEL_H

#include <QStandardItemModel>
#include <QStringList>
#include <QMap>

#include "DataManager.h"

/**
 * @brief A model listing available game styles
 */
class GameStyleModel : public QStandardItemModel
{
        Q_OBJECT

    public:
        enum DataRoles { ScriptRole = Qt::UserRole+1, SchemeRole, WeaponsRole, IsDlcRole };

    public slots:
        /// reloads the themes from the DataManager
        void loadGameStyles();
};

#endif // HEDGEWARS_GAMESTYLEMODEL_H
