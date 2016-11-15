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
                                << QVariant(false)         // reset health   8
                                << QVariant(false)         // vampiric       9
                                << QVariant(false)         // karma          10
                                << QVariant(false)         // artillery      11
                                << QVariant(true)          // random order   12
                                << QVariant(false)         // king           13
                                << QVariant(false)         // place hog      14
                                << QVariant(false)         // shared ammo    15
                                << QVariant(false)         // disable girders 16
                                << QVariant(false)         // disable land objects 17
                                << QVariant(false)         // AI survival    18
                                << QVariant(false)         // inf. attack    19
                                << QVariant(false)         // reset weps     20
                                << QVariant(false)         // per hog ammo   21
                                << QVariant(false)         // no wind        22
                                << QVariant(false)         // more wind      23
                                << QVariant(false)         // tag team       24
                                << QVariant(false)         // bottom border  25
                                << QVariant(100)           // damage modfier 26
                                << QVariant(45)            // turn time      27
                                << QVariant(100)           // init health    28
                                << QVariant(15)            // sudden death   29
                                << QVariant(5)             // case prob      30
                                << QVariant(3)             // mines time     31
                                << QVariant(4)             // mines number   32
                                << QVariant(0)             // mine dud pct   33
                                << QVariant(2)             // explosives     34
                                << QVariant(0)             // air mines      35
                                << QVariant(35)            // health case pct 36
                                << QVariant(25)            // health case amt 37
                                << QVariant(47)            // water rise amt 38
                                << QVariant(5)             // health dec amt 39
                                << QVariant(100)           // rope modfier   40
                                << QVariant(100)           // get away time  41
                                << QVariant(0)             // world edge     42
                                << QVariant()              // scriptparam    43
                                ;

AmmoSchemeModel::AmmoSchemeModel(QObject* parent, const QString & fileName) :
    QAbstractTableModel(parent),
    fileConfig(fileName, QSettings::IniFormat)
{
    predefSchemesNames = QStringList()
                         << "Default"
                         << "Pro Mode"
                         << "Shoppa"
                         << "Clean Slate"
                         << "Minefield"
                         << "Barrel Mayhem"
                         << "Tunnel Hogs"
                         << "Timeless"
                         << "Thinking with Portals"
                         << "King Mode"
						 << "Construction Mode"
                         ;

    numberOfDefaultSchemes = predefSchemesNames.size();

    spNames = QStringList()
              << "name"                //  0
              << "fortsmode"           //  1
              << "divteams"            //  2
              << "solidland"           //  3
              << "border"              //  4
              << "lowgrav"             //  5
              << "laser"               //  6
              << "invulnerability"     //  7
              << "resethealth"         //  8
              << "vampiric"            //  9
              << "karma"               // 10
              << "artillery"           // 11
              << "randomorder"         // 12
              << "king"                // 13
              << "placehog"            // 14
              << "sharedammo"          // 15
              << "disablegirders"      // 16
              << "disablelandobjects"  // 17
              << "aisurvival"          // 18
              << "infattack"           // 19
              << "resetweps"           // 20
              << "perhogammo"          // 21
              << "disablewind"         // 22
              << "morewind"            // 23
              << "tagteam"             // 24
              << "bottomborder"        // 25
              << "damagefactor"        // 26
              << "turntime"            // 27
              << "health"              // 28
              << "suddendeath"         // 29
              << "caseprobability"     // 30
              << "minestime"           // 31
              << "minesnum"            // 32
              << "minedudpct"          // 33
              << "explosives"          // 34
              << "airmines"            // 35
              << "healthprobability"   // 36
              << "healthcaseamount"    // 37
              << "waterrise"           // 38
              << "healthdecrease"      // 39
              << "ropepct"             // 40
              << "getawaytime"         // 41
              << "worldedge"           // 42
              << "scriptparam"         // scriptparam    43
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
            << QVariant(false)         // reset health   8
            << QVariant(false)         // vampiric       9
            << QVariant(false)         // karma          10
            << QVariant(false)         // artillery      11
            << QVariant(true)          // random order   12
            << QVariant(false)         // king           13
            << QVariant(false)         // place hog      14
            << QVariant(true)          // shared ammo    15
            << QVariant(false)         // disable girders 16
            << QVariant(false)         // disable land objects 17
            << QVariant(false)         // AI survival    18
            << QVariant(false)         // inf. attack    19
            << QVariant(false)         // reset weps     20
            << QVariant(false)         // per hog ammo   21
            << QVariant(false)         // no wind        22
            << QVariant(false)         // more wind      23
            << QVariant(false)         // tag team       24
            << QVariant(false)         // bottom border  25
            << QVariant(100)           // damage modfier 26
            << QVariant(15)            // turn time      27
            << QVariant(100)           // init health    28
            << QVariant(15)            // sudden death   29
            << QVariant(0)             // case prob      30
            << QVariant(3)             // mines time     31
            << QVariant(0)             // mines number   32
            << QVariant(0)             // mine dud pct   33
            << QVariant(2)             // explosives     34
            << QVariant(0)             // air mines      35
            << QVariant(35)            // health case pct 36
            << QVariant(25)            // health case amt 37
            << QVariant(47)            // water rise amt 38
            << QVariant(5)             // health dec amt 39
            << QVariant(100)           // rope modfier   40
            << QVariant(100)           // get away time  41
            << QVariant(0)             // world edge     42
            << QVariant()              // scriptparam    43
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
            << QVariant(false)         // reset health   8
            << QVariant(false)         // vampiric       9
            << QVariant(false)         // karma          10
            << QVariant(false)         // artillery      11
            << QVariant(true)          // random order   12
            << QVariant(false)         // king           13
            << QVariant(false)         // place hog      14
            << QVariant(true)          // shared ammo    15
            << QVariant(true)          // disable girders 16
            << QVariant(true)         // disable land objects 17
            << QVariant(false)         // AI survival    18
            << QVariant(false)         // inf. attack    19
            << QVariant(true)          // reset weps     20
            << QVariant(false)         // per hog ammo   21
            << QVariant(false)         // no wind        22
            << QVariant(false)         // more wind      23
            << QVariant(false)         // tag team       24
            << QVariant(false)         // bottom border  25
            << QVariant(100)           // damage modfier 26
            << QVariant(30)            // turn time      27
            << QVariant(100)           // init health    28
            << QVariant(50)            // sudden death   29
            << QVariant(1)             // case prob      30
            << QVariant(0)             // mines time     31
            << QVariant(0)             // mines number   32
            << QVariant(0)             // mine dud pct   33
            << QVariant(0)             // explosives     34
            << QVariant(8)             // air mines      35
            << QVariant(0)             // health case pct 36
            << QVariant(25)            // health case amt 37
            << QVariant(47)            // water rise amt 38
            << QVariant(5)             // health dec amt 39
            << QVariant(100)           // rope modfier   40
            << QVariant(100)           // get away time  41
            << QVariant(0)             // world edge     42
            << QVariant()              // scriptparam    43
            ;

    QList<QVariant> cleanslate;
    cleanslate
            << predefSchemesNames[3]   // name           0
            << QVariant(false)         // fortsmode      1
            << QVariant(false)         // team divide    2
            << QVariant(false)         // solid land     3
            << QVariant(false)         // border         4
            << QVariant(false)         // low gravity    5
            << QVariant(false)         // laser sight    6
            << QVariant(false)         // invulnerable   7
            << QVariant(true)          // reset health   8
            << QVariant(false)         // vampiric       9
            << QVariant(false)         // karma          10
            << QVariant(false)         // artillery      11
            << QVariant(true)          // random order   12
            << QVariant(false)         // king           13
            << QVariant(false)         // place hog      14
            << QVariant(false)         // shared ammo    15
            << QVariant(false)         // disable girders 16
            << QVariant(false)         // disable land objects 17
            << QVariant(false)         // AI survival    18
            << QVariant(true)          // inf. attack    19
            << QVariant(true)          // reset weps     20
            << QVariant(false)         // per hog ammo   21
            << QVariant(false)         // no wind        22
            << QVariant(false)         // more wind      23
            << QVariant(false)         // tag team       24
            << QVariant(false)         // bottom border  25
            << QVariant(100)           // damage modfier 26
            << QVariant(45)            // turn time      27
            << QVariant(100)           // init health    28
            << QVariant(15)            // sudden death   29
            << QVariant(5)             // case prob      30
            << QVariant(3)             // mines time     31
            << QVariant(4)             // mines number   32
            << QVariant(0)             // mine dud pct   33
            << QVariant(2)             // explosives     34
            << QVariant(0)             // air mines      35
            << QVariant(35)            // health case pct 36
            << QVariant(25)            // health case amt 37
            << QVariant(47)            // water rise amt 38
            << QVariant(5)             // health dec amt 39
            << QVariant(100)           // rope modfier   40
            << QVariant(100)           // get away time  41
            << QVariant(0)             // world edge     42
            << QVariant()              // scriptparam    43
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
            << QVariant(false)         // reset health   8
            << QVariant(false)         // vampiric       9
            << QVariant(false)         // karma          10
            << QVariant(false)         // artillery      11
            << QVariant(true)          // random order   12
            << QVariant(false)         // king           13
            << QVariant(false)         // place hog      14
            << QVariant(true)          // shared ammo    15
            << QVariant(true)          // disable girders 16
            << QVariant(false)         // disable land objects 17
            << QVariant(false)         // AI survival    18
            << QVariant(false)         // inf. attack    19
            << QVariant(false)         // reset weps     20
            << QVariant(false)         // per hog ammo   21
            << QVariant(false)         // no wind        22
            << QVariant(false)         // more wind      23
            << QVariant(false)         // tag team       24
            << QVariant(false)         // bottom border  25
            << QVariant(100)           // damage modfier 26
            << QVariant(30)            // turn time      27
            << QVariant(50)            // init health    28
            << QVariant(15)            // sudden death   29
            << QVariant(0)             // case prob      30
            << QVariant(0)             // mines time     31
            << QVariant(200)           // mines number   32
            << QVariant(0)             // mine dud pct   33
            << QVariant(0)             // explosives     34
            << QVariant(0)             // air mines      35
            << QVariant(35)            // health case pct 36
            << QVariant(25)            // health case amt 37
            << QVariant(47)            // water rise amt 38
            << QVariant(5)             // health dec amt 39
            << QVariant(100)           // rope modfier   40
            << QVariant(100)           // get away time  41
            << QVariant(0)             // world edge     42
            << QVariant()              // scriptparam    43
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
            << QVariant(false)         // reset health   8
            << QVariant(false)         // vampiric       9
            << QVariant(false)         // karma          10
            << QVariant(false)         // artillery      11
            << QVariant(true)          // random order   12
            << QVariant(false)         // king           13
            << QVariant(false)         // place hog      14
            << QVariant(true)          // shared ammo    15
            << QVariant(false)         // disable girders 16
            << QVariant(false)         // disable land objects 17
            << QVariant(false)         // AI survival    18
            << QVariant(false)         // inf. attack    19
            << QVariant(false)         // reset weps     20
            << QVariant(false)         // per hog ammo   21
            << QVariant(false)         // no wind        22
            << QVariant(false)         // more wind      23
            << QVariant(false)         // tag team       24
            << QVariant(false)         // bottom border  25
            << QVariant(100)           // damage modfier 26
            << QVariant(30)            // turn time      27
            << QVariant(100)           // init health    28
            << QVariant(15)            // sudden death   29
            << QVariant(0)             // case prob      30
            << QVariant(0)             // mines time     31
            << QVariant(0)             // mines number   32
            << QVariant(0)             // mine dud pct   33
            << QVariant(200)           // explosives     34
            << QVariant(0)             // air mines      35
            << QVariant(35)            // health case pct 36
            << QVariant(25)            // health case amt 37
            << QVariant(47)            // water rise amt 38
            << QVariant(5)             // health dec amt 39
            << QVariant(100)           // rope modfier   40
            << QVariant(100)           // get away time  41
            << QVariant(0)             // world edge     42
            << QVariant()              // scriptparam    43
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
            << QVariant(false)         // reset health   8
            << QVariant(false)         // vampiric       9
            << QVariant(false)         // karma          10
            << QVariant(false)         // artillery      11
            << QVariant(true)          // random order   12
            << QVariant(false)         // king           13
            << QVariant(false)         // place hog      14
            << QVariant(true)          // shared ammo    15
            << QVariant(true)          // disable girders 16
            << QVariant(true)          // disable land objects 17
            << QVariant(false)         // AI survival    18
            << QVariant(false)         // inf. attack    19
            << QVariant(false)         // reset weps     20
            << QVariant(false)         // per hog ammo   21
            << QVariant(false)         // no wind        22
            << QVariant(false)         // more wind      23
            << QVariant(false)         // tag team       24
            << QVariant(false)         // bottom border  25
            << QVariant(100)           // damage modfier 26
            << QVariant(30)            // turn time      27
            << QVariant(100)           // init health    28
            << QVariant(15)            // sudden death   29
            << QVariant(5)             // case prob      30
            << QVariant(3)             // mines time     31
            << QVariant(10)            // mines number   32
            << QVariant(10)            // mine dud pct   33
            << QVariant(10)            // explosives     34
            << QVariant(4)             // air mines      35
            << QVariant(35)            // health case pct 36
            << QVariant(25)            // health case amt 37
            << QVariant(47)            // water rise amt 38
            << QVariant(5)             // health dec amt 39
            << QVariant(100)           // rope modfier   40
            << QVariant(100)           // get away time  41
            << QVariant(0)             // world edge     42
            << QVariant()              // scriptparam    43
            ;

    QList<QVariant> timeless;
    timeless
            << predefSchemesNames[7]   // name           0
            << QVariant(false)         // fortsmode      1
            << QVariant(false)         // team divide    2
            << QVariant(false)         // solid land     3
            << QVariant(false)         // border         4
            << QVariant(false)         // low gravity    5
            << QVariant(false)         // laser sight    6
            << QVariant(false)         // invulnerable   7
            << QVariant(false)         // reset health   8
            << QVariant(false)         // vampiric       9
            << QVariant(false)         // karma          10
            << QVariant(false)         // artillery      11
            << QVariant(true)          // random order   12
            << QVariant(false)         // king           13
            << QVariant(false)         // place hog      14
            << QVariant(false)         // shared ammo    15
            << QVariant(false)         // disable girders 16
            << QVariant(false)         // disable land objects 17
            << QVariant(false)         // AI survival    18
            << QVariant(false)         // inf. attack    19
            << QVariant(false)         // reset weps     20
            << QVariant(true)          // per hog ammo   21
            << QVariant(false)         // no wind        22
            << QVariant(false)         // more wind      23
            << QVariant(false)         // tag team       24
            << QVariant(false)         // bottom border  25
            << QVariant(100)           // damage modfier 26
            << QVariant(9999)          // turn time      27
            << QVariant(100)           // init health    28
            << QVariant(15)            // sudden death   29
            << QVariant(5)             // case prob      30
            << QVariant(3)             // mines time     31
            << QVariant(5)             // mines number   32
            << QVariant(10)            // mine dud pct   33
            << QVariant(2)             // explosives     34
            << QVariant(0)             // air mines      35
            << QVariant(35)            // health case pct 36
            << QVariant(30)            // health case amt 37
            << QVariant(0)             // water rise amt 38
            << QVariant(0)             // health dec amt 39
            << QVariant(100)           // rope modfier   40
            << QVariant(100)           // get away time  41
            << QVariant(0)             // world edge     42
            << QVariant()              // scriptparam    43
            ;

    QList<QVariant> thinkingportals;
    thinkingportals
            << predefSchemesNames[8]   // name           0
            << QVariant(false)         // fortsmode      1
            << QVariant(false)         // team divide    2
            << QVariant(false)         // solid land     3
            << QVariant(false)         // border         4
            << QVariant(false)         // low gravity    5
            << QVariant(false)         // laser sight    6
            << QVariant(false)         // invulnerable   7
            << QVariant(false)         // reset health   8
            << QVariant(false)         // vampiric       9
            << QVariant(false)         // karma          10
            << QVariant(true)          // artillery      11
            << QVariant(true)          // random order   12
            << QVariant(false)         // king           13
            << QVariant(false)         // place hog      14
            << QVariant(false)         // shared ammo    15
            << QVariant(false)         // disable girders 16
            << QVariant(false)         // disable land objects 17
            << QVariant(false)         // AI survival    18
            << QVariant(false)         // inf. attack    19
            << QVariant(false)         // reset weps     20
            << QVariant(false)         // per hog ammo   21
            << QVariant(false)         // no wind        22
            << QVariant(false)         // more wind      23
            << QVariant(false)         // tag team       24
            << QVariant(false)         // bottom border  25
            << QVariant(100)           // damage modfier 26
            << QVariant(45)            // turn time      27
            << QVariant(100)           // init health    28
            << QVariant(15)            // sudden death   29
            << QVariant(2)             // case prob      30
            << QVariant(3)             // mines time     31
            << QVariant(5)             // mines number   32
            << QVariant(0)             // mine dud pct   33
            << QVariant(5)             // explosives     34
            << QVariant(4)             // air mines      35
            << QVariant(25)            // health case pct 36
            << QVariant(25)            // health case amt 37
            << QVariant(47)            // water rise amt 38
            << QVariant(5)             // health dec amt 39
            << QVariant(100)           // rope modfier   40
            << QVariant(100)           // get away time  41
            << QVariant(0)             // world edge     42
            << QVariant()              // scriptparam    43
            ;

    QList<QVariant> kingmode;
    kingmode
            << predefSchemesNames[9]  // name           0
            << QVariant(false)         // fortsmode      1
            << QVariant(false)         // team divide    2
            << QVariant(false)         // solid land     3
            << QVariant(false)         // border         4
            << QVariant(false)         // low gravity    5
            << QVariant(false)         // laser sight    6
            << QVariant(false)         // invulnerable   7
            << QVariant(false)         // reset health   8
            << QVariant(false)         // vampiric       9
            << QVariant(false)         // karma          10
            << QVariant(false)         // artillery      11
            << QVariant(true)          // random order   12
            << QVariant(true)          // king           13
            << QVariant(false)         // place hog      14
            << QVariant(false)         // shared ammo    15
            << QVariant(false)         // disable girders 16
            << QVariant(false)         // disable land objects 17
            << QVariant(false)         // AI survival    18
            << QVariant(false)         // inf. attack    19
            << QVariant(false)         // reset weps     20
            << QVariant(false)         // per hog ammo   21
            << QVariant(false)         // no wind        22
            << QVariant(false)         // more wind      23
            << QVariant(false)         // tag team       24
            << QVariant(false)         // bottom border  25
            << QVariant(100)           // damage modfier 26
            << QVariant(45)            // turn time      27
            << QVariant(100)           // init health    28
            << QVariant(15)            // sudden death   29
            << QVariant(5)             // case prob      30
            << QVariant(3)             // mines time     31
            << QVariant(4)             // mines number   32
            << QVariant(0)             // mine dud pct   33
            << QVariant(2)             // explosives     34
            << QVariant(0)             // air mines      35
            << QVariant(35)            // health case pct 36
            << QVariant(25)            // health case amt 37
            << QVariant(47)            // water rise amt 38
            << QVariant(5)             // health dec amt 39
            << QVariant(100)           // rope modfier   40
            << QVariant(100)           // get away time  41
            << QVariant(0)             // world edge     42
            << QVariant()              // scriptparam    43
            ;

	QList<QVariant> construction;
    construction
            << predefSchemesNames[10]  // name           0
            << QVariant(false)         // fortsmode      1
            << QVariant(false)         // team divide    2
            << QVariant(false)         // solid land     3
            << QVariant(false)         // border         4
            << QVariant(false)         // low gravity    5
            << QVariant(false)         // laser sight    6
            << QVariant(false)         // invulnerable   7
            << QVariant(false)         // reset health   8
            << QVariant(false)         // vampiric       9
            << QVariant(false)         // karma          10
            << QVariant(false)         // artillery      11
            << QVariant(true)          // random order   12
            << QVariant(false)          // king           13
            << QVariant(false)         // place hog      14
            << QVariant(false)         // shared ammo    15
            << QVariant(true)         // disable girders 16
            << QVariant(true)         // disable land objects 17
            << QVariant(false)         // AI survival    18
            << QVariant(true)         // inf. attack    19
            << QVariant(false)         // reset weps     20
            << QVariant(true)         // per hog ammo   21
            << QVariant(false)         // no wind        22
            << QVariant(false)         // more wind      23
            << QVariant(false)         // tag team       24
            << QVariant(false)         // bottom border  25
            << QVariant(100)           // damage modfier 26
            << QVariant(45)            // turn time      27
            << QVariant(100)           // init health    28
            << QVariant(15)            // sudden death   29
            << QVariant(5)             // case prob      30
            << QVariant(3)             // mines time     31
            << QVariant(0)             // mines number   32
            << QVariant(0)             // mine dud pct   33
            << QVariant(0)             // explosives     34
            << QVariant(0)             // air mines      35
            << QVariant(35)            // health case pct 36
            << QVariant(25)            // health case amt 37
            << QVariant(47)            // water rise amt 38
            << QVariant(5)             // health dec amt 39
            << QVariant(100)           // rope modfier   40
            << QVariant(100)           // get away time  41
            << QVariant(0)             // world edge     42
            << QVariant()              // scriptparam    43
            ;
			
    schemes.append(defaultScheme);
    schemes.append(proMode);
    schemes.append(shoppa);
    schemes.append(cleanslate);
    schemes.append(minefield);
    schemes.append(barrelmayhem);
    schemes.append(tunnelhogs);
    schemes.append(timeless);
    schemes.append(thinkingportals);
    schemes.append(kingmode);
	schemes.append(construction);


    int size = fileConfig.beginReadArray("schemes");
    for (int i = 0; i < size; ++i)
    {
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
    Q_UNUSED(section);
    Q_UNUSED(orientation);
    Q_UNUSED(role);

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
    Q_UNUSED(index);

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
    Q_UNUSED(count);

    beginInsertRows(parent, schemes.size(), schemes.size());

    if (row == -1)
    {
        QList<QVariant> newScheme = defaultScheme;
        newScheme[0] = QVariant(tr("New"));
        schemes.insert(schemes.size(), newScheme);
    }
    else
    {
        QList<QVariant> newScheme = schemes[row];
        newScheme[0] = QVariant(tr("Copy of %1").arg(newScheme[0].toString()));
        schemes.insert(schemes.size(), newScheme);
    }

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

    for (int i = 0; i < schemes.size() - numberOfDefaultSchemes; ++i)
    {
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
    Q_UNUSED(section);
    Q_UNUSED(orientation);
    Q_UNUSED(role);

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

void NetAmmoSchemeModel::setNetSchemeConfig(QStringList cfg)
{
    if(cfg.size() != netScheme.size())
    {
        qWarning("Incorrect scheme cfg size");
        return;
    }

    cfg[cfg.size()-1] = cfg[cfg.size()-1].mid(1);

    for(int i = 0; i < cfg.size(); ++i)
        netScheme[i] = QVariant(cfg[i]);

    reset();
}
