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
 * @brief MapModel class implementation
 */

#include "MapModel.h"


void MapModel::loadMaps()
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

    QList<QStandardItem *> genMaps;
    QList<QStandardItem *> missionMaps;
    QList<QStandardItem *> staticMaps;

    // add generated/handdrawn maps to list
    // TODO: icons for these

    genMaps.append(
        infoToItem(QIcon(), QComboBox::tr("generated map..."), GeneratedMap, "+rnd+"));
    genMaps.append(
        infoToItem(QIcon(), QComboBox::tr("generated maze..."), GeneratedMaze, "+maze+"));
    genMaps.append(
        infoToItem(QIcon(), QComboBox::tr("hand drawn map..."), HandDrawnMap, "+drawn+"));

    // only 2 map relate files are relevant:
    // - the cfg file that contains the settings/info of the map
    // - the lua file - if it exists it's a mission, otherwise it isn't
    QFile mapLuaFile;
    QFile mapCfgFile;

    // add mission/static maps to lists
    foreach (QString map, maps)
    {
        mapCfgFile.setFileName(
            datamgr.findFileForRead(QString("Maps/%1/map.cfg").arg(map)));
        mapLuaFile.setFileName(
            datamgr.findFileForRead(QString("Maps/%1/map.lua").arg(map)));


        if (mapCfgFile.open(QFile::ReadOnly))
        {
            QString caption;
            QString theme;
            quint32 limit = 0;
            QString scheme;
            QString weapons;
            // if there is a lua file for this map, then it's a mission
            bool isMission = mapLuaFile.exists();
            MapType type = isMission?MissionMap:StaticMap;

            // load map info from file
            QTextStream input(&mapCfgFile);
            input >> theme;
            input >> limit;
            if (isMission) { // scheme and weapons are only relevant for missions
                input >> scheme;
                input >> weapons;
            }
            mapCfgFile.close();

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

            // add a mission caption prefix to missions
            if (isMission)
            {
                // TODO: icon
                caption = QComboBox::tr("Mission") + ": " + map;
            }
            else
                caption = map;

            // we know everything there is about the map, let's get am item for it
            QStandardItem * item = infoToItem(
                QIcon(), caption, type, map, theme, limit, scheme, weapons);

            // append item to the list
            if (isMission)
                missionMaps.append(item);
            else
                staticMaps.append(item);
        
        }

    }


    // define a separator item
    QStandardItem separator("---");
    separator.setData(QLatin1String("separator"), Qt::AccessibleDescriptionRole);
    separator.setFlags(separator.flags() & ~( Qt::ItemIsEnabled | Qt::ItemIsSelectable ) );

    // create list:
    // generated+handdrawn maps, 2 saperators, missions, 1 separator, static maps
    QList<QStandardItem * > items;
    items.append(genMaps);
    items.append(separator.clone());
    items.append(separator.clone());
    items.append(missionMaps);
    items.append(separator.clone());
    items.append(staticMaps);

    // store start-index and count of relevant types
    typeLoc.insert(GeneratedMap, QPair<int,int>(0, 1));
    typeLoc.insert(GeneratedMaze, QPair<int,int>(1, 1));
    typeLoc.insert(HandDrawnMap, QPair<int,int>(2, 1));
    // mission maps
    int startIdx = genMaps.size() + 2; // start after genMaps and 2 separators
    int count = missionMaps.size();
    typeLoc.insert(MissionMap, QPair<int,int>(startIdx, count));
    // static maps
    startIdx += count + 1; // start after missions and 2 separators
    count = staticMaps.size();
    typeLoc.insert(StaticMap, QPair<int,int>(startIdx, count));

    // store list contents in the item model
    QStandardItemModel::appendColumn(items);


    endResetModel();
}


int MapModel::mapCount(MapType type) const
{
    // return the count for this type
    // fetch it from the second int in typeLoc, return 0 if no entry
    return typeLoc.value(type, QPair<int,int>(0,0)).second;
}


int MapModel::randomMap(MapType type) const
{
    // return a random index for this type or -1 if none available
    QPair<int,int> loc = typeLoc.value(type, QPair<int,int>(-1,0));

    int startIdx = loc.first;
    int count = loc.second;

    if (count < 1)
        return -1;
    else
        return startIdx + (rand() % count);
}


QStandardItem * MapModel::infoToItem(
    const QIcon & icon,
    const QString caption,
    MapType type,
    QString name,
    QString theme,
    quint32 limit,
    QString scheme,
    QString weapons)
const
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


    qvar.setValue(mapInfo);
    item->setData(qvar, Qt::UserRole + 1);

    if (mapInfo.type == Invalid)
            Q_ASSERT(false);

    return item;
}
