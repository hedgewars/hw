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
 * @brief MapModel class implementation
 */

#include <QSettings>

#include "physfs.h"
#include "MapModel.h"
#include "HWApplication.h"
#include "hwconsts.h"

MapModel::MapInfo MapModel::MapInfoRandom = {MapModel::GeneratedMap, "+rnd+", "", 0, "", "", "", false};
MapModel::MapInfo MapModel::MapInfoMaze = {MapModel::GeneratedMaze, "+maze+", "", 0, "", "", "", false};
MapModel::MapInfo MapModel::MapInfoPerlin = {MapModel::GeneratedMaze, "+perlin+", "", 0, "", "", "", false};
MapModel::MapInfo MapModel::MapInfoDrawn = {MapModel::HandDrawnMap, "+drawn+", "", 0, "", "", "", false};
MapModel::MapInfo MapModel::MapInfoForts = {MapModel::FortsMap, "+forts+", "", 0, "", "", "", false};

MapModel::MapModel(MapType maptype, QObject *parent) : QStandardItemModel(parent)
{
    m_maptype = maptype;
    m_loaded = false;
    m_filteredNoDLC = NULL;
}

QSortFilterProxyModel * MapModel::withoutDLC()
{
    if (m_filteredNoDLC == NULL)
    {
        m_filteredNoDLC = new QSortFilterProxyModel(this);
        m_filteredNoDLC->setSourceModel(this);
        // filtering based on IsDlcRole would be nicer
        // but seems this model can only do string-based filtering :|
        m_filteredNoDLC->setFilterRegExp(QRegExp("^[^*]"));
    }
    return m_filteredNoDLC;
}

bool MapModel::loadMaps()
{
    if(m_loaded)
        return false;

    m_loaded = true;

    qDebug("[LAZINESS] MapModel::loadMaps()");

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
            bool dlc;

            // if there is a lua file for this map, then it's a mission
            bool isMission = mapLuaFile.exists();
            MapType type = isMission ? MissionMap : StaticMap;

            // if we're supposed to ignore this type, continue
            if (type != m_maptype) continue;

            // load map info from file
            QTextStream input(&mapCfgFile);
            theme = input.readLine();
            limit = input.readLine().toInt();
            if (isMission) { // scheme and weapons are only relevant for missions
                scheme = input.readLine();
                weapons = input.readLine();
            }
            mapCfgFile.close();

            // load description (if applicable)
            if (isMission)
            {
                // get locale
                QSettings settings(datamgr.settingsFileName(), QSettings::IniFormat);
                QString locale = settings.value("misc/locale", "").toString();
                if (locale.isEmpty())
                    locale = QLocale::system().name();

                QSettings descSettings(QString("physfs://Maps/%1/desc.txt").arg(map), QSettings::IniFormat);
                descSettings.setIniCodec("UTF-8");
                desc = descSettings.value(locale, QString()).toString();
                // If not found, try with lanague-only code
                if (desc.isEmpty())
                {
                    QString localeSimple = locale.remove(QRegExp("_.*$"));
                    desc = descSettings.value(localeSimple, QString()).toString();
                }
                desc = desc.replace("_n", "\n").replace("_c", ",").replace("__", "_");
            }

            // detect if map is dlc
            QString mapDir = PHYSFS_getRealDir(QString("Maps/%1/map.cfg").arg(map).toLocal8Bit().data());
            dlc = !mapDir.startsWith(datadir->absolutePath());

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
                QIcon(), caption, type, map, theme, limit, scheme, weapons, desc, dlc);

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

    return true;
}

bool MapModel::mapExists(const QString & map)
{
    return findMap(map) >= 0;
}

int MapModel::findMap(const QString & map)
{
    loadMaps();

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
    QString desc,
    bool dlc)
{
    QStandardItem * item = new QStandardItem(icon, (dlc ? "*" : "") + caption);
    MapInfo mapInfo;
    QVariant qvar(QVariant::UserType);

    mapInfo.type = type;
    mapInfo.name = name;
    mapInfo.theme = theme;
    mapInfo.limit = limit;
    mapInfo.scheme = scheme;
    mapInfo.weapons = weapons;
    mapInfo.desc = desc.isEmpty() ? tr("No description available.") : desc;
    mapInfo.dlc = dlc;

    qvar.setValue(mapInfo);
    item->setData(qvar, Qt::UserRole + 1);

    return item;
}
