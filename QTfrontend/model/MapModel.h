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

#include <QStandardItemModel>
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
class MapModel : public QStandardItemModel
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

        /// a struct for holding the attributes of a map.
        struct MapInfo
        {
            MapType type; ///< The map-type
            QString name; ///< The internal name.
            QString theme; ///< The theme to be used. (can be empty)
            quint32 limit; ///< The maximum allowed number of hedgehogs.
            QString scheme; ///< Default scheme name or "locked", for mission-maps.
            QString weapons; ///< Default weaponset name or "locked", for missions-maps.
        };

        /**
         * @brief Returns the number of available mission maps.
         * @return mission map count.
         */
        int missionCount() const;


    public slots:
        /// reloads the maps using the DataManager
        void loadMaps();


    private:
        int m_nMissions; ///< used to keep track of the mission amount

        /**
         * @brief Creates a QStandardItem, that holds the map info and item appearance.
         * The used role for the data is Qt::UserRole + 1.
         * @param icon the icon to be displayed (can be an empty QIcon()).
         * @param caption the text to be displayed.
         * @param type the type of the map.
         * @param name the internal name of the map.
         * @param theme the theme of the map (or empty if none).
         * @param limit the hedgehog limit of the map.
         * @param scheme mission map: default scheme name or "locked".
         * @param weapons mission map: default weaponset name or "locked".
         * @return pointer to item representing the map info: at Qt::UserRole + 1.
         */
        QStandardItem * infoToItem(
            const QIcon & icon,
            const QString caption,
            MapType type = Invalid,
            QString name = "",
            QString theme = "",
            quint32 limit = 0,
            QString scheme = "",
            QString weapons = "") const;
};

Q_DECLARE_METATYPE(MapModel::MapInfo)

#endif // HEDGEWARS_MAPMODEL_H
