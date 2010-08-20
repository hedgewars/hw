/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2010 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QDebug>
#include <QModelIndex>

#include "ammoSchemeModel.h"
#include "hwconsts.h"

QList<QVariant> defaultScheme = QList<QVariant>()
        << QVariant("Default")     // name           0
        << QVariant(false)         // fortsmode      1
        << QVariant(false)         // team divide    2
        << QVariant(false)         // solid land     3
        << QVariant(false)         // border         4
        << QVariant(false)         // low gravity    5
        << QVariant(false)         // laser sight    6
        << QVariant(false)         // invulnerable   7
        << QVariant(true)          // add mines      8
        << QVariant(false)         // vampiric       9
        << QVariant(false)         // karma          10
        << QVariant(false)         // artillery      11
        << QVariant(true)          // random order   12
        << QVariant(false)         // king           13
        << QVariant(false)         // place hog      14
        << QVariant(false)         // shared ammo    15
        << QVariant(false)         //disable girders 16
        << QVariant(false)         // disable land objects 17
        << QVariant(false)         // AI survival    18
        << QVariant(100)           // damage modfier 19
        << QVariant(45)            // turn time      20
        << QVariant(100)           // init health    21
        << QVariant(15)            // sudden death   22
        << QVariant(5)             // case prob      23
        << QVariant(3)             //  mines time    24
        << QVariant(4)             //  landadds      25
        << QVariant(0)             // mine dud pct   26
        << QVariant(2)             // explosives     27
        ;

AmmoSchemeModel::AmmoSchemeModel(QObject* parent, const QString & fileName) :
    QAbstractTableModel(parent),
    fileConfig(fileName, QSettings::IniFormat)
{
    QStringList predefSchemesNames;
    predefSchemesNames
        << "Default"
        << "Pro Mode"
        << "Shoppa"
        << "Basketball"
        << "Minefield"
        << "Barrel Mayhem"
        << "Tunnel Hogs";

    numberOfDefaultSchemes = predefSchemesNames.size();

    spNames = QStringList()
        << "name"             //  0
        << "fortsmode"        //  1
        << "divteams"         //  2
        << "solidland"        //  3
        << "border"           //  4
        << "lowgrav"          //  5
        << "laser"            //  6
        << "invulnerability"  //  7
        << "mines"            //  8
        << "vampiric"         //  9
        << "karma"            // 10
        << "artillery"        // 11
        << "randomorder"      // 12
        << "king"             // 13
        << "placehog"         // 14
        << "sharedammo"       // 15
        << "disablegirders"   // 16
        << "disablelandobjects" // 17
        << "aisurvival"       // 18
        << "damagefactor"     // 19
        << "turntime"         // 20
        << "health"           // 21
        << "suddendeath"      // 22
        << "caseprobability"  // 23
        << "minestime"        // 24
        << "landadds"         // 25
        << "minedudpct"       // 26
        << "explosives"       // 27
        ;

    QList<QVariant> proMode;
    proMode
        << predefSchemesNames[1]   // name           0
        << QVariant(false)         // fortsmode      1
        << QVariant(false)         // team divide    2
        << QVariant(false)         // solid land     3
        << QVariant(false)         // border         4
        << QVariant(false)         // low gravity    5
        << QVariant(false)         // laser sight    6
        << QVariant(false)         // invulnerable   7
        << QVariant(false)         // add mines      8
        << QVariant(false)         // vampiric       9
        << QVariant(false)         // karma          10
        << QVariant(false)         // artillery      11
        << QVariant(true)          // random order   12
        << QVariant(false)         // king           13
        << QVariant(false)         // place hog      14
        << QVariant(true)          // shared ammo    15
        << QVariant(false)         //disable girders 16
        << QVariant(false)         // disable land objects 17
        << QVariant(false)         // AI survival    18
        << QVariant(100)           // damage modfier 19
        << QVariant(15)            // turn time      20
        << QVariant(100)           // init health    21
        << QVariant(15)            // sudden death   22
        << QVariant(0)             // case prob      23
        << QVariant(3)             //  mines time    24
        << QVariant(4)             //  landadds      25
        << QVariant(0)             // mine dud pct   26
        << QVariant(2)             // explosives     27
        ;

    QList<QVariant> shoppa;
    shoppa
        << predefSchemesNames[2]   // name           0
        << QVariant(false)         // fortsmode      1
        << QVariant(false)         // team divide    2
        << QVariant(true)          // solid land     3
        << QVariant(true)          // border         4
        << QVariant(false)         // low gravity    5
        << QVariant(false)         // laser sight    6
        << QVariant(false)         // invulnerable   7
        << QVariant(false)         // add mines      8
        << QVariant(false)         // vampiric       9
        << QVariant(false)         // karma          10
        << QVariant(false)         // artillery      11
        << QVariant(true)          // random order   12
        << QVariant(false)         // king           13
        << QVariant(false)         // place hog      14
        << QVariant(true)          // shared ammo    15
        << QVariant(true)          //disable girders 16
        << QVariant(false)         // disable land objects 17
        << QVariant(false)         // AI survival    18
        << QVariant(100)           // damage modfier 19
        << QVariant(30)            // turn time      20
        << QVariant(100)           // init health    21
        << QVariant(50)            // sudden death   22
        << QVariant(1)             // case prob      23
        << QVariant(3)             //  mines time    24
        << QVariant(4)             //  landadds      25
        << QVariant(0)             // mine dud pct   26
        << QVariant(0)             // explosives     27
        ;

    QList<QVariant> basketball;
    basketball
        << predefSchemesNames[3]   // name           0
        << QVariant(false)         // fortsmode      1
        << QVariant(false)         // team divide    2
        << QVariant(true)          // solid land     3
        << QVariant(true)          // border         4
        << QVariant(true)          // low gravity    5
        << QVariant(false)         // laser sight    6
        << QVariant(true)          // invulnerable   7
        << QVariant(false)         // add mines      8
        << QVariant(false)         // vampiric       9
        << QVariant(false)         // karma          10
        << QVariant(false)         // artillery      11
        << QVariant(true)          // random order   12
        << QVariant(false)         // king           13
        << QVariant(false)         // place hog      14
        << QVariant(true)          // shared ammo    15
        << QVariant(true)          //disable girders 16
        << QVariant(false)         // disable land objects 17
        << QVariant(false)         // AI survival    18
        << QVariant(100)           // damage modfier 19
        << QVariant(30)            // turn time      20
        << QVariant(100)           // init health    21
        << QVariant(15)            // sudden death   22
        << QVariant(0)             // case prob      23
        << QVariant(3)             //  mines time    24
        << QVariant(4)             //  landadds      25
        << QVariant(0)             // mine dud pct   26
        << QVariant(0)             // explosives     27
        ;

    QList<QVariant> minefield;
    minefield
        << predefSchemesNames[4]   // name           0
        << QVariant(false)         // fortsmode      1
        << QVariant(false)         // team divide    2
        << QVariant(false)         // solid land     3
        << QVariant(false)         // border         4
        << QVariant(false)         // low gravity    5
        << QVariant(false)         // laser sight    6
        << QVariant(false)         // invulnerable   7
        << QVariant(true)          // add mines      8
        << QVariant(false)         // vampiric       9
        << QVariant(false)         // karma          10
        << QVariant(false)         // artillery      11
        << QVariant(true)          // random order   12
        << QVariant(false)         // king           13
        << QVariant(false)         // place hog      14
        << QVariant(true)          // shared ammo    15
        << QVariant(true)          //disable girders 16
        << QVariant(false)         // disable land objects 17
        << QVariant(false)         // AI survival    18
        << QVariant(150)           // damage modfier 19
        << QVariant(30)            // turn time      20
        << QVariant(50)            // init health    21
        << QVariant(15)            // sudden death   22
        << QVariant(0)             // case prob      23
        << QVariant(0)             //  mines time    24
        << QVariant(80)            //  landadds      25
        << QVariant(0)             // mine dud pct   26
        << QVariant(0)             // explosives     27
        ;

    QList<QVariant> barrelmayhem;
    barrelmayhem
        << predefSchemesNames[5]   // name           0
        << QVariant(false)         // fortsmode      1
        << QVariant(false)         // team divide    2
        << QVariant(false)         // solid land     3
        << QVariant(false)         // border         4
        << QVariant(false)         // low gravity    5
        << QVariant(false)         // laser sight    6
        << QVariant(false)         // invulnerable   7
        << QVariant(false)         // add mines      8
        << QVariant(false)         // vampiric       9
        << QVariant(false)         // karma          10
        << QVariant(false)         // artillery      11
        << QVariant(true)          // random order   12
        << QVariant(false)         // king           13
        << QVariant(false)         // place hog      14
        << QVariant(true)          // shared ammo    15
        << QVariant(false)         //disable girders 16
        << QVariant(false)         // disable land objects 17
        << QVariant(false)         // AI survival    18
        << QVariant(100)           // damage modfier 19
        << QVariant(30)            // turn time      20
        << QVariant(100)           // init health    21
        << QVariant(15)            // sudden death   22
        << QVariant(0)             // case prob      23
        << QVariant(0)             // mines time     24
        << QVariant(0)             // landadds       25
        << QVariant(0)             // mine dud pct   26
        << QVariant(80)            // explosives     27
        ;

    QList<QVariant> tunnelhogs;
    tunnelhogs
        << predefSchemesNames[6]   // name           0
        << QVariant(false)         // fortsmode      1
        << QVariant(false)         // team divide    2
        << QVariant(false)         // solid land     3
        << QVariant(true)          // border         4
        << QVariant(false)         // low gravity    5
        << QVariant(false)         // laser sight    6
        << QVariant(false)         // invulnerable   7
        << QVariant(true)          // add mines      8
        << QVariant(false)         // vampiric       9
        << QVariant(false)         // karma          10
        << QVariant(false)         // artillery      11
        << QVariant(true)          // random order   12
        << QVariant(false)         // king           13
        << QVariant(false)         // place hog      14
        << QVariant(true)          // shared ammo    15
        << QVariant(true)          //disable girders 16
        << QVariant(true)          // disable land objects 17
        << QVariant(false)         // AI survival    18
        << QVariant(100)           // damage modfier 19
        << QVariant(30)            // turn time      20
        << QVariant(100)           // init health    21
        << QVariant(15)            // sudden death   22
        << QVariant(5)             // case prob      23
        << QVariant(3)             // mines time     24
        << QVariant(10)            // landadds       25
        << QVariant(10)            // mine dud pct   26
        << QVariant(10)            // explosives     27
        ;

    schemes.append(defaultScheme);
    schemes.append(proMode);
    schemes.append(shoppa);
    schemes.append(basketball);
    schemes.append(minefield);
    schemes.append(barrelmayhem);
    schemes.append(tunnelhogs);


    int size = fileConfig.beginReadArray("schemes");
    for (int i = 0; i < size; ++i) {
        fileConfig.setArrayIndex(i);

        if (!predefSchemesNames.contains(fileConfig.value(spNames[0]).toString()))
        {
            QList<QVariant> scheme;

            for (int k = 0; k < spNames.size(); ++k)
                scheme << fileConfig.value(spNames[k], defaultScheme[k]);

            schemes.append(scheme);
        }
    }
    fileConfig.endArray();
}

QVariant AmmoSchemeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    return QVariant();
}

int AmmoSchemeModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    else
        return schemes.size();
}

int AmmoSchemeModel::columnCount(const QModelIndex & parent) const
{
    if (parent.isValid())
        return 0;
    else
        return defaultScheme.size();
}

Qt::ItemFlags AmmoSchemeModel::flags(const QModelIndex & index) const
{
    return
        Qt::ItemIsEnabled
        | Qt::ItemIsSelectable
        | Qt::ItemIsEditable;
}

bool AmmoSchemeModel::setData(const QModelIndex & index, const QVariant & value, int role)
{
    if (!index.isValid() || index.row() < numberOfDefaultSchemes
        || index.row() >= schemes.size()
        || index.column() >= defaultScheme.size()
        || role != Qt::EditRole)
        return false;

    schemes[index.row()][index.column()] = value;

    emit dataChanged(index, index);
    return true;
}

bool AmmoSchemeModel::insertRows(int row, int count, const QModelIndex & parent)
{
    beginInsertRows(parent, row, row);

    QList<QVariant> newScheme = defaultScheme;
    newScheme[0] = QVariant(tr("new"));

    schemes.insert(row, newScheme);

    endInsertRows();

    return true;
}

bool AmmoSchemeModel::removeRows(int row, int count, const QModelIndex & parent)
{
    if(count != 1
        || row < numberOfDefaultSchemes
        || row >= schemes.size())
        return false;

    beginRemoveRows(parent, row, row);

    schemes.removeAt(row);

    endRemoveRows();

    return true;
}

QVariant AmmoSchemeModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0
        || index.row() >= schemes.size()
        || index.column() >= defaultScheme.size()
        || (role != Qt::EditRole && role != Qt::DisplayRole)
        )
        return QVariant();

    return schemes[index.row()][index.column()];
}

void AmmoSchemeModel::Save()
{
    fileConfig.beginWriteArray("schemes", schemes.size() - numberOfDefaultSchemes);

    for (int i = 0; i < schemes.size() - numberOfDefaultSchemes; ++i) {
        fileConfig.setArrayIndex(i);

        QList<QVariant> scheme = schemes[i + numberOfDefaultSchemes];

        for (int k = 0; k < scheme.size(); ++k)
            fileConfig.setValue(spNames[k], scheme[k]);
    }
    fileConfig.endArray();
}


NetAmmoSchemeModel::NetAmmoSchemeModel(QObject * parent) :
    QAbstractTableModel(parent)
{
    netScheme = defaultScheme;
}

QVariant NetAmmoSchemeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    return QVariant();
}

int NetAmmoSchemeModel::rowCount(const QModelIndex & parent) const
{
    if (parent.isValid())
        return 0;
    else
        return 1;
}

int NetAmmoSchemeModel::columnCount(const QModelIndex & parent) const
{
    if (parent.isValid())
        return 0;
    else
        return defaultScheme.size();
}

QVariant NetAmmoSchemeModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0
        || index.row() > 1
        || index.column() >= defaultScheme.size()
        || (role != Qt::EditRole && role != Qt::DisplayRole)
        )
        return QVariant();

    return netScheme[index.column()];
}

void NetAmmoSchemeModel::setNetSchemeConfig(QStringList & cfg)
{
    if(cfg.size() != netScheme.size())
    {
        qWarning("Incorrect scheme cfg size");
        return;
    }

    for(int i = 0; i < cfg.size(); ++i)
        netScheme[i] = QVariant(cfg[i]);

    reset();
}
