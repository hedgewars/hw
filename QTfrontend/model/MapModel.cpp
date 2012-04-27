
#include "MapModel.h"

MapModel::MapInfo MapModel::mapInfoFromData(const QVariant data)
{
    MapInfo mapInfo;

    mapInfo.type = Invalid;
    mapInfo.name = "";
    mapInfo.theme = "";
    mapInfo.limit = 0;
    mapInfo.scheme = "";
    mapInfo.weapons = "";

    if (data.isValid())
    {
        QList<QVariant> list = data.toList();
        if (list.size() < 1) {
            mapInfo.type = Invalid;
            return mapInfo;
        }
        mapInfo.type = (MapType)list[0].toInt();
        switch (mapInfo.type)
        {
            case GeneratedMap:
            case GeneratedMaze:
            case HandDrawnMap:
                return mapInfo;

            default:
                mapInfo.name = list[1].toString();
                mapInfo.theme = list[2].toString();
                mapInfo.limit = list[3].toInt();
                mapInfo.scheme = list[4].toString();
                mapInfo.weapons = list[5].toString();
        }
    }

    return mapInfo;
}

MapModel::MapModel(QObject *parent) :
    QAbstractListModel(parent)
{
    m_data = QList<QMap<int, QVariant> >();
}

int MapModel::rowCount(const QModelIndex &parent) const
{
    if(parent.isValid())
        return 0;
    else
        return m_data.size();
}


QVariant MapModel::data(const QModelIndex &index, int role) const
{
    if(index.column() > 0 || index.row() >= m_data.size())
        return QVariant();
    else
        return m_data.at(index.row()).value(role, QVariant());
}


void MapModel::loadMaps()
{
    beginResetModel();


    DataManager & datamgr = DataManager::instance();

    QStringList maps =
        datamgr.entryList("Maps", QDir::AllDirs | QDir::NoDotAndDotDot);

    m_data.clear();

#if QT_VERSION >= QT_VERSION_CHECK(4, 7, 0)
    m_data.reserve(maps.size());
#endif

    QMap<int, QVariant> tmp;
    QList<QVariant> mapInfo;

    // TODO: icons for these
    tmp.insert(Qt::DisplayRole, QComboBox::tr("generated map..."));
    mapInfo.append(GeneratedMap);
    tmp.insert(Qt::UserRole, mapInfo);
    m_data.append(tmp);
    tmp.insert(Qt::DisplayRole, QComboBox::tr("generated maze..."));
    mapInfo.replace(0, GeneratedMaze);
    tmp.insert(Qt::UserRole, mapInfo);
    m_data.append(tmp);
    tmp.insert(Qt::DisplayRole, QComboBox::tr("hand drawn map..."));
    mapInfo.replace(0, HandDrawnMap);
    tmp.insert(Qt::UserRole, mapInfo);
    m_data.append(tmp);

    m_nGenerators = 3;


    m_nMissions = 0;

    QFile mapLuaFile;
    QFile mapCfgFile;

    foreach (QString map, maps)
    {
        mapCfgFile.setFileName(
            datamgr.findFileForRead(QString("Maps/%1/map.cfg").arg(map)));
        mapLuaFile.setFileName(
            datamgr.findFileForRead(QString("Maps/%1/map.lua").arg(map)));

        QMap<int, QVariant> dataset;


        if (mapCfgFile.open(QFile::ReadOnly))
        {
            QString theme;
            quint32 limit = 0;
            QString scheme;
            QString weapons;
            QList<QVariant> mapInfo;
            bool isMission = mapLuaFile.exists();
            int type = isMission?MissionMap:StaticMap;

            QTextStream input(&mapCfgFile);
            input >> theme;
            input >> limit;
            input >> scheme;
            input >> weapons;
            mapInfo.push_back(type);
            mapInfo.push_back(map);
            mapInfo.push_back(theme);
            if (limit)
                mapInfo.push_back(limit);
            else
                mapInfo.push_back(18);


            if (scheme.isEmpty())
                scheme = "locked";
            scheme.replace("_", " ");

            if (weapons.isEmpty())
                weapons = "locked";
            weapons.replace("_", " ");

            mapInfo.push_back(scheme);
            mapInfo.push_back(weapons);

            if(isMission)
            {
                // TODO: icon
                map = QComboBox::tr("Mission") + ": " + map;
                m_nMissions++;
            }

            mapCfgFile.close();

            // set name
            dataset.insert(Qt::DisplayRole, map);

            // TODO
            // dataset.insert(Qt::DecorationRole, icon);

            // set mapinfo
            dataset.insert(Qt::UserRole, mapInfo);

            if (isMission) // insert missions before regular maps
                m_data.insert(m_nGenerators + m_nMissions, dataset);
            else
                m_data.append(dataset);
        
        }

    }

    endResetModel();
}

int MapModel::generatorCount() const
{
    return m_nGenerators;
}

int MapModel::missionCount() const
{
    return m_nMissions;
}
