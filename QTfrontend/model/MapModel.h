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
 * @brief MapModel class definition
 */

#ifndef HEDGEWARS_MAPMODEL_H
#define HEDGEWARS_MAPMODEL_H

#include <QStandardItemModel>
#include <QSortFilterProxyModel>
#include <QStringList>
#include <QTextStream>
#include <QHash>
#include <QMap>
#include <QIcon>
#include <QComboBox>

#include "DataManager.h"

/**
 * @brief A model that vertically lists available maps
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
            GeneratedPerlin,
            HandDrawnMap,
            MissionMap,
            StaticMap,
            FortsMap
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
            QString desc; ///< The brief 1-2 sentence description of the mission, for mission-maps.
            bool dlc; ///< True if this map was not packaged with the game
        };

        MapModel(MapType maptype, QObject *parent = 0);

        /**
         * @brief Searches maps in model to find out if one exists
         * @param map map of which to check existence
         * @return true if it exists
         */
        bool mapExists(const QString & map);

        /**
         * @brief Finds a map index (column, row) for a map name
         * @param map map of which to find index+column
         * @return QPair<int, int> with column, index, or (-1, -1) if map not found
         */
        //QPair<int, int> findMap(const QString & map) const;

        /**
         * @brief Finds a map index for a map name
         * @param map map of which to find index
         * @return int of index, or -1 if map not found
         */
        int findMap(const QString & map);

        /**
         * @brief Finds and returns a map item for a map name
         * @param map map
         * @return QStandardItem of map, or NULL if map not found
         */
        QStandardItem * getMap(const QString & map);

        // Static MapInfos for drawn and generated maps
        static MapInfo MapInfoRandom, MapInfoMaze, MapInfoPerlin, MapInfoDrawn, MapInfoForts;

        /// Loads the maps
        bool loadMaps();

        /// returns this model but excluding DLC themes
        QSortFilterProxyModel * withoutDLC();

    private:
        /// map index lookup table. QPair<int, int> contains: <column, index>
        //QHash<QString, QPair<int, int> > m_mapIndexes;
        QHash<QString, int> m_mapIndexes;
        MapType m_maptype;
        bool m_loaded;
        QSortFilterProxyModel * m_filteredNoDLC;

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
         * @param desc mission map: description of mission.
         * @return pointer to item representing the map info: at Qt::UserRole + 1.
         */
        static QStandardItem * infoToItem(
            const QIcon & icon,
            const QString caption,
            MapType type = Invalid,
            QString name = "",
            QString theme = "",
            quint32 limit = 0,
            QString scheme = "",
            QString weapons = "",
            QString desc = "",
            bool dlc = false);
};

Q_DECLARE_METATYPE(MapModel::MapInfo)

#endif // HEDGEWARS_MAPMODEL_H
