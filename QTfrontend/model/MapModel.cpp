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
    beginResetModel();


    DataManager & datamgr = DataManager::instance();

    QStringList maps =
        datamgr.entryList("Maps", QDir::AllDirs | QDir::NoDotAndDotDot);

    QStandardItemModel::clear();

    QList<QStandardItem *> genMaps;
    QList<QStandardItem *> missionMaps;
    QList<QStandardItem *> staticMaps;

    // TODO: icons for these

    genMaps.append(
        infoToItem(QIcon(), QComboBox::tr("generated map..."), GeneratedMap, "+rnd+"));
    genMaps.append(
        infoToItem(QIcon(), QComboBox::tr("generated maze..."), GeneratedMaze, "+maze+"));
    genMaps.append(
        infoToItem(QIcon(), QComboBox::tr("hand drawn map..."), HandDrawnMap, "+drawn+"));


    QFile mapLuaFile;
    QFile mapCfgFile;

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
            bool isMission = mapLuaFile.exists();
            MapType type = isMission?MissionMap:StaticMap;

            QTextStream input(&mapCfgFile);
            input >> theme;
            input >> limit;
            input >> scheme;
            input >> weapons;
            mapCfgFile.close();

            if (limit == 0)
                limit = 18;


            if (scheme.isEmpty())
                scheme = "locked";
            else
                scheme.replace("_", " ");

            if (weapons.isEmpty())
                weapons = "locked";
            else
                weapons.replace("_", " ");

            if (isMission)
            {
                // TODO: icon
                caption = QComboBox::tr("Mission") + ": " + map;
                m_nMissions++;
            }
            else
                caption = map;

            QStandardItem * item = infoToItem(
                QIcon(), caption, type, map, theme, limit, scheme, weapons);

            if (isMission)
                missionMaps.append(item);
            else
                staticMaps.append(item);
        
        }

    }

    m_nMissions = missionMaps.size();

    QStandardItem separator("---");
    separator.setData(QLatin1String("separator"), Qt::AccessibleDescriptionRole);
    separator.setFlags(separator.flags() & ~( Qt::ItemIsEnabled | Qt::ItemIsSelectable ) );

    QList<QStandardItem * > items;
    items.append(genMaps);
    items.append(separator.clone());
    items.append(separator.clone());
    items.append(missionMaps);
    items.append(separator.clone());
    items.append(staticMaps);

    QStandardItemModel::appendColumn(items);

    endResetModel();
}


int MapModel::missionCount() const
{
    return m_nMissions;
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
