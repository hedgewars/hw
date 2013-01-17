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
 * @brief MapModel class implementation
 */

#include <QSettings>

#include "MapModel.h"
#include "HWApplication.h"

MapModel::MapInfo MapModel::MapInfoRandom = {MapModel::GeneratedMap, "+rnd+", "", 0, "", "", ""};
MapModel::MapInfo MapModel::MapInfoMaze = {MapModel::GeneratedMaze, "+maze+", "", 0, "", "", ""};
MapModel::MapInfo MapModel::MapInfoDrawn = {MapModel::HandDrawnMap, "+drawn+", "", 0, "", "", ""};

void MapModel::loadMaps(MapType maptype)
{
    // this method resets the contents of this model (important to know for views).
    beginResetModel();

    // we'll need the DataManager a few times, so let's get a reference to it
    DataManager & datamgr = DataManager::instance();

    // fetch list of available maps
    QStringList maps =
        datamgr.entryList("Maps", QDir::AllDirs | QDir::NoDotAndDotDot);

    // empty list, so that we can (re)fill it
    QStandardItemModel::clear();

    //QList<QStandardItem *> staticMaps;
    //QList<QStandardItem *> missionMaps;
    QList<QStandardItem *> mapList;

    // add mission/static maps to lists
    foreach (QString map, maps)
    {
        // only 2 map relate files are relevant:
        // - the cfg file that contains the settings/info of the map
        // - the lua file - if it exists it's a mission, otherwise it isn't
        QFile mapLuaFile(QString("physfs://Maps/%1/map.lua").arg(map));
        QFile mapCfgFile(QString("physfs://Maps/%1/map.cfg").arg(map));

        if (mapCfgFile.open(QFile::ReadOnly))
        {
            QString caption;
            QString theme;
            quint32 limit = 0;
            QString scheme;
            QString weapons;
            QString desc;

            // if there is a lua file for this map, then it's a mission
            bool isMission = mapLuaFile.exists();
            MapType type = isMission ? MissionMap : StaticMap;

            // If we're supposed to ignore this type, continue
            if (type != maptype) continue;

            // load map info from file
            QTextStream input(&mapCfgFile);
            theme = input.readLine();
            limit = input.readLine().toInt();
            if (isMission) { // scheme and weapons are only relevant for missions
                scheme = input.readLine();
                weapons = input.readLine();
            }
            mapCfgFile.close();

            // Load description (if applicable)
            if (isMission)
            {
                QString locale = HWApplication::keyboardInputLocale().name();

                QSettings descSettings(QString("physfs://Maps/%1/desc.txt").arg(map), QSettings::IniFormat);
                desc = descSettings.value(locale, QString()).toString().replace("|", "\n").replace("\\,", ",");
            }

            // let's use some semi-sane hedgehog limit, rather than none
            if (limit == 0)
                limit = 18;

            // the default scheme/weaponset for missions.
            // if empty we assume the map sets these internally -> locked
            if (isMission)
            {
                if (scheme.isEmpty())
                    scheme = "locked";
                else
                    scheme.replace("_", " ");

                if (weapons.isEmpty())
                    weapons = "locked";
                else
                    weapons.replace("_", " ");
            }

            // caption
            caption = map;

            // we know everything there is about the map, let's get am item for it
            QStandardItem * item = MapModel::infoToItem(
                QIcon(), caption, type, map, theme, limit, scheme, weapons, desc);

            // append item to the list
            mapList.append(item);
        }

    }

    // Create column-index lookup table

    m_mapIndexes.clear();


    int count = mapList.size();
    for (int i = 0; i < count; i++)
    {
        QStandardItem * si = mapList.at(i);
        QVariant v = si->data(Qt::UserRole + 1);
        if (v.canConvert<MapInfo>())
            m_mapIndexes.insert(v.value<MapInfo>().name, i);
    }

    QStandardItemModel::appendColumn(mapList);

    endResetModel();
}

bool MapModel::mapExists(const QString & map) const
{
    return findMap(map) >= 0;
}

int MapModel::findMap(const QString & map) const
{
    return m_mapIndexes.value(map, -1);
}

QStandardItem * MapModel::getMap(const QString & map)
{
    int loc = findMap(map);
    if (loc < 0) return NULL;
    return item(loc);
}

QStandardItem * MapModel::infoToItem(
    const QIcon & icon,
    const QString caption,
    MapType type,
    QString name,
    QString theme,
    quint32 limit,
    QString scheme,
    QString weapons,
    QString desc)
{
    QStandardItem * item = new QStandardItem(icon, caption);
    MapInfo mapInfo;
    QVariant qvar(QVariant::UserType);

    mapInfo.type = type;
    mapInfo.name = name;
    mapInfo.theme = theme;
    mapInfo.limit = limit;
    mapInfo.scheme = scheme;
    mapInfo.weapons = weapons;
    mapInfo.desc = desc.isEmpty() ? tr("No description available.") : desc;

    qvar.setValue(mapInfo);
    item->setData(qvar, Qt::UserRole + 1);

    return item;
}
