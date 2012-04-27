/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2007 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2007-2012 Andrey Korotaev <unC0Rr@gmail.com>
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
 * @brief MapModel class definition
 */

#ifndef HEDGEWARS_MAPMODEL_H
#define HEDGEWARS_MAPMODEL_H

#include <QAbstractListModel>
#include <QStringList>
#include <QTextStream>
#include <QMap>
#include <QIcon>
#include <QComboBox>

#include "DataManager.h"

/**
 * @brief A model listing available themes
 *
 * @author sheepluva
 * @since 0.9.18
 */
class MapModel : public QAbstractListModel
{
        Q_OBJECT

    public:
        enum MapType {
            Invalid,
            GeneratedMap,
            GeneratedMaze,
            HandDrawnMap,
            MissionMap,
            StaticMap
        };

        struct MapInfo
        {
            MapType type;
            QString name;
            QString theme;
            quint32 limit;
            QString scheme;
            QString weapons;
        };

        static MapInfo mapInfoFromData(const QVariant data); 

        explicit MapModel(QObject *parent = 0);

        int rowCount(const QModelIndex &parent = QModelIndex()) const;
        QVariant data(const QModelIndex &index, int role) const;
        int generatorCount() const;
        int missionCount() const;


    public slots:
        /// reloads the maps from the DataManager
        void loadMaps();


    private:
        QList<QMap<int, QVariant> > m_data;
        int m_nGenerators;
        int m_nMissions;
};

#endif // HEDGEWARS_MAPMODEL_H
