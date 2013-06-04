/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2013 Andrey Korotaev <unC0Rr@gmail.com>
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
 * @brief ThemeModel class definition
 */

#ifndef HEDGEWARS_THEMEMODEL_H
#define HEDGEWARS_THEMEMODEL_H

#include <QAbstractListModel>
#include <QStringList>
#include <QMap>
#include <QIcon>

#include "DataManager.h"

/**
 * @brief A model listing available themes
 */
class ThemeModel : public QAbstractListModel
{
        Q_OBJECT

    public:
        enum Roles { ActualNameRole = Qt::UserRole, IsDlcRole, IconPathRole };
        explicit ThemeModel(QObject *parent = 0);

        int rowCount(const QModelIndex &parent = QModelIndex()) const;
        QVariant data(const QModelIndex &index, int role) const;


    public slots:
        /// reloads the themes from the DataManager
        void loadThemes();


    private:
        QList<QMap<int, QVariant> > m_data;
};

#endif // HEDGEWARS_THEMEMODEL_H
