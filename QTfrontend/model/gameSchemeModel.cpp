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
#include <QFile>
#include <QSettings>
#include <QTextStream>
#include <QHash>

#include "gameSchemeModel.h"
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

GameSchemeModel::GameSchemeModel(QObject* parent, const QString & directory) :
    QAbstractTableModel(parent)
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
                         << "Space Invasion"
                         << "HedgeEditor"
                         ;

    numberOfDefaultSchemes = predefSchemesNames.size();

    spNames = QStringList()
              << "name"                //  0 | Name should be first forever
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
            << QVariant(0)             // air mines      35
            << QVariant(0)             // health case pct 36
            << QVariant(25)            // health case amt 37
            << QVariant(0)             // water rise amt 38
            << QVariant(0)             // health dec amt 39
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
            // NOTE: If you change this, also change the defaults in the Construction Mode script
            << QVariant("initialenergy=550, energyperround=50, maxenergy=1000, cratesperround=5") // scriptparam    43
            ;

    QList<QVariant> spaceinvasion;
    spaceinvasion
            << predefSchemesNames[11]  // name           0
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
            << QVariant(45)            // turn time      27
            << QVariant(100)           // init health    28
            << QVariant(50)            // sudden death   29
            << QVariant(0)             // case prob      30
            << QVariant(3)             // mines time     31
            << QVariant(0)             // mines number   32
            << QVariant(0)             // mine dud pct   33
            << QVariant(0)             // explosives     34
            << QVariant(0)             // air mines      35
            << QVariant(0)             // health case pct 36
            << QVariant(25)            // health case amt 37
            << QVariant(0)             // water rise amt 38
            << QVariant(0)             // health dec amt 39
            << QVariant(100)           // rope modfier   40
            << QVariant(100)           // get away time  41
            << QVariant(0)             // world edge     42
            // NOTE: If you change this, also change the defaults in the Space Invasion script
            << QVariant("rounds=3, shield=30, barrels=5, pings=2, barrelbonus=3, shieldbonus=30, timebonus=4") // scriptparam    43
            ;

    QList<QVariant> hedgeeditor;
    hedgeeditor
            << predefSchemesNames[12]  // name           0
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
            << QVariant(false)         // random order   12
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
            << QVariant(50)            // sudden death   29
            << QVariant(0)             // case prob      30
            << QVariant(3)             // mines time     31
            << QVariant(0)             // mines number   32
            << QVariant(0)             // mine dud pct   33
            << QVariant(0)             // explosives     34
            << QVariant(0)             // air mines      35
            << QVariant(35)            // health case pct 36
            << QVariant(25)            // health case amt 37
            << QVariant(0)            // water rise amt 38
            << QVariant(0)             // health dec amt 39
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
    schemes.append(spaceinvasion);
    schemes.append(hedgeeditor);

    if (!QDir(cfgdir->absolutePath() + "/Schemes").exists()) {
        QDir().mkdir(cfgdir->absolutePath() + "/Schemes");
    }
    if (!QDir(directory).exists()) {
        QDir().mkdir(directory);

        qDebug("No /Schemes/Game directory found. Trying to import game schemes from schemes.ini.");

        QSettings legacyFileConfig(cfgdir->absolutePath() + "/schemes.ini", QSettings::IniFormat);
        int size = legacyFileConfig.beginReadArray("schemes");
        int imported = 0;
        for (int i = 0; i < size; ++i)
        {
            legacyFileConfig.setArrayIndex(i);

            QString schemeName = legacyFileConfig.value(spNames[0]).toString();
            if (!schemeName.isNull() && !predefSchemesNames.contains(schemeName))
            {
                QList<QVariant> scheme;
                QFile file(directory + "/" + schemeName + ".hwg");

                // Add keys to scheme info and create file
                if (file.open(QIODevice::WriteOnly)) {
                    QTextStream stream(&file);

                    for (int k = 0; k < spNames.size(); ++k) {
                        scheme << legacyFileConfig.value(spNames[k], defaultScheme[k]);

                        // File handling
                        // We skip the name key (k==0), it is not stored redundantly in file.
                        // The file name is used for that already.
                        if(k != 0) {
                            // The file is just a list of key=value pairs
                            stream << spNames[k] << "=" << legacyFileConfig.value(spNames[k], defaultScheme[k]).toString();
                            stream << endl;
                        }
                    }
                    file.close();
                }
                imported++;

                schemes.append(scheme);
            }
        }
        qDebug("%d game scheme(s) imported.", imported);
        legacyFileConfig.endArray();
    } else {
        QStringList scheme_dir = QDir(directory).entryList(QDir::Files);

        for(int i = 0; i < scheme_dir.size(); i++)
        {
            QList<QVariant> scheme;
            QFile file(directory + "/" + scheme_dir[i]);

            // Chop off file name suffix
            QString schemeName = scheme_dir[i];
            if (schemeName.endsWith(".hwg", Qt::CaseInsensitive)) {
                schemeName.chop(4);
            }
            // Parse game scheme file
            if (file.open(QIODevice::ReadOnly)) {
                QTextStream stream(&file);
                QString line, key, value;
                QHash<QString, QString> fileKeyValues;
                do {
                    // Read line and get key and value
                    line = stream.readLine();
                    key = line.section(QChar('='), 0, 0);
                    value = line.section(QChar('='), 1);
                    if(!key.isNull() && !value.isNull()) {
                        fileKeyValues[key] = value;
                    }
                } while (!line.isNull());

                // Add scheme name manually
                scheme << schemeName;
                // Add other keys from the QHash.
                for (int k = 1; k < spNames.size(); ++k) {
                    key = spNames[k];
                    if (fileKeyValues.contains(key)) {
                        scheme << fileKeyValues.value(key);
                    } else {
                        // Use default value in case the key is not set
                        scheme << defaultScheme[k];
                    }
                }
                schemes.append(scheme);

                file.close();
            }
        }
    }
}

QVariant GameSchemeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    Q_UNUSED(section);
    Q_UNUSED(orientation);
    Q_UNUSED(role);

    return QVariant();
}

int GameSchemeModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    else
        return schemes.size();
}

int GameSchemeModel::columnCount(const QModelIndex & parent) const
{
    if (parent.isValid())
        return 0;
    else
        return defaultScheme.size();
}

bool GameSchemeModel::hasScheme(QString name)
{
    for(int i=0; i<schemes.size(); i++)
    {
        if(schemes[i][0] == name)
        {
            return true;
        }
    }
    return false;
}

Qt::ItemFlags GameSchemeModel::flags(const QModelIndex & index) const
{
    Q_UNUSED(index);

    return
        Qt::ItemIsEnabled
        | Qt::ItemIsSelectable
        | Qt::ItemIsEditable;
}

bool GameSchemeModel::setData(const QModelIndex & index, const QVariant & value, int role)
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

bool GameSchemeModel::insertRows(int row, int count, const QModelIndex & parent)
{
    Q_UNUSED(count);

    beginInsertRows(parent, schemes.size(), schemes.size());

    if (row == -1)
    {
        QList<QVariant> newScheme = defaultScheme;

        QString newName = tr("New");
        if(hasScheme(newName))
        {
            //name already used -> look for an appropriate name:
            int i=2;
            while(hasScheme(newName = tr("New (%1)").arg(i++))) ;
        }
        newScheme[0] = QVariant(newName);
        schemes.insert(schemes.size(), newScheme);
    }
    else
    {
        QList<QVariant> newScheme = schemes[row];
        QString oldName = newScheme[0].toString();
        QString newName = tr("Copy of %1").arg(oldName);
        if(hasScheme(newName))
        {
            //name already used -> look for an appropriate name:
            int i=2;
            while(hasScheme(newName = tr("Copy of %1 (%2)").arg(oldName).arg(i++)));
        }
        newScheme[0] = QVariant(newName);
        schemes.insert(schemes.size(), newScheme);
    }

    endInsertRows();

    return true;
}

bool GameSchemeModel::removeRows(int row, int count, const QModelIndex & parent)
{
    if(count != 1
            || row < numberOfDefaultSchemes
            || row >= schemes.size())
        return false;

    beginRemoveRows(parent, row, row);

    QList<QVariant> scheme = schemes[row];
    int j = spNames.indexOf("name");
    QFile(cfgdir->absolutePath() + "/Schemes/Game/" + scheme[j].toString() + ".hwg").remove();
    schemes.removeAt(row);

    endRemoveRows();

    return true;
}

QVariant GameSchemeModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0
            || index.row() >= schemes.size()
            || index.column() >= defaultScheme.size()
            || (role != Qt::EditRole && role != Qt::DisplayRole)
       )
        return QVariant();

    return schemes[index.row()][index.column()];
}

void GameSchemeModel::Save()
{
    for (int i = 0; i < schemes.size() - numberOfDefaultSchemes; ++i)
    {
        QList<QVariant> scheme = schemes[i + numberOfDefaultSchemes];
        int j = spNames.indexOf("name");

        QString schemeName = scheme[j].toString();
        QFile file(cfgdir->absolutePath() + "/Schemes/Game/" + schemeName + ".hwg");

        if (file.open(QIODevice::WriteOnly)) {
            QTextStream stream(&file);
            for (int k = 0; k < spNames.size(); ++k) {
                // We skip the name key
                if(k != j) {
                    // The file is just a list of key=value pairs
                    stream << spNames[k] << "=" << scheme[k].toString();
                    stream << endl;
                }
            }
            file.close();
        }
    }
}


NetGameSchemeModel::NetGameSchemeModel(QObject * parent) :
    QAbstractTableModel(parent)
{
    netScheme = defaultScheme;
}

QVariant NetGameSchemeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    Q_UNUSED(section);
    Q_UNUSED(orientation);
    Q_UNUSED(role);

    return QVariant();
}

int NetGameSchemeModel::rowCount(const QModelIndex & parent) const
{
    if (parent.isValid())
        return 0;
    else
        return 1;
}

int NetGameSchemeModel::columnCount(const QModelIndex & parent) const
{
    if (parent.isValid())
        return 0;
    else
        return defaultScheme.size();
}

QVariant NetGameSchemeModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0
            || index.row() > 1
            || index.column() >= defaultScheme.size()
            || (role != Qt::EditRole && role != Qt::DisplayRole)
       )
        return QVariant();

    return netScheme[index.column()];
}

void NetGameSchemeModel::setNetSchemeConfig(QStringList cfg)
{
    if(cfg.size() != netScheme.size())
    {
        qWarning("Incorrect scheme cfg size");
        return;
    }

    beginResetModel();

    cfg[cfg.size()-1] = cfg[cfg.size()-1].mid(1);

    for(int i = 0; i < cfg.size(); ++i)
        netScheme[i] = QVariant(cfg[i]);

    endResetModel();
}
