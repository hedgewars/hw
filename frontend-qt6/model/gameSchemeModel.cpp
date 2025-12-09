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
                                << QVariant(false)         // switchhog      1
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
                                << QVariant(0)             // sentries       36
                                << QVariant(35)            // health case pct 37
                                << QVariant(25)            // health case amt 38
                                << QVariant(47)            // water rise amt 39
                                << QVariant(5)             // health dec amt 40
                                << QVariant(100)           // rope modfier   41
                                << QVariant(100)           // get away time  42
                                << QVariant(0)             // world edge     43
                                << QVariant()              // scriptparam    44
                                ;

GameSchemeModel::GameSchemeModel(QObject* parent, const QString & directory) :
    QAbstractTableModel(parent)
{
    predefSchemesNames = QStringList()
                         << QStringLiteral("Default")
                         << QStringLiteral("Pro Mode")
                         << QStringLiteral("Shoppa")
                         << QStringLiteral("Clean Slate")
                         << QStringLiteral("Minefield")
                         << QStringLiteral("Barrel Mayhem")
                         << QStringLiteral("Tunnel Hogs")
                         << QStringLiteral("Timeless")
                         << QStringLiteral("Thinking with Portals")
                         << QStringLiteral("King Mode")
                         << QStringLiteral("Mutant")
                         << QStringLiteral("Construction Mode")
                         << QStringLiteral("The Specialists")
                         << QStringLiteral("Space Invasion")
                         << QStringLiteral("HedgeEditor")
                         << QStringLiteral("Racer")
                         ;

    numberOfDefaultSchemes = predefSchemesNames.size();

    spNames = QStringList()
              << QStringLiteral("name")                //  0 | Name should be first forever
              << QStringLiteral("switchhog")           //  1
              << QStringLiteral("divteams")            //  2
              << QStringLiteral("solidland")           //  3
              << QStringLiteral("border")              //  4
              << QStringLiteral("lowgrav")             //  5
              << QStringLiteral("laser")               //  6
              << QStringLiteral("invulnerability")     //  7
              << QStringLiteral("resethealth")         //  8
              << QStringLiteral("vampiric")            //  9
              << QStringLiteral("karma")               // 10
              << QStringLiteral("artillery")           // 11
              << QStringLiteral("randomorder")         // 12
              << QStringLiteral("king")                // 13
              << QStringLiteral("placehog")            // 14
              << QStringLiteral("sharedammo")          // 15
              << QStringLiteral("disablegirders")      // 16
              << QStringLiteral("disablelandobjects")  // 17
              << QStringLiteral("aisurvival")          // 18
              << QStringLiteral("infattack")           // 19
              << QStringLiteral("resetweps")           // 20
              << QStringLiteral("perhogammo")          // 21
              << QStringLiteral("disablewind")         // 22
              << QStringLiteral("morewind")            // 23
              << QStringLiteral("tagteam")             // 24
              << QStringLiteral("bottomborder")        // 25
              << QStringLiteral("damagefactor")        // 26
              << QStringLiteral("turntime")            // 27
              << QStringLiteral("health")              // 28
              << QStringLiteral("suddendeath")         // 29
              << QStringLiteral("caseprobability")     // 30
              << QStringLiteral("minestime")           // 31
              << QStringLiteral("minesnum")            // 32
              << QStringLiteral("minedudpct")          // 33
              << QStringLiteral("explosives")          // 34
              << QStringLiteral("airmines")            // 35
              << QStringLiteral("sentries")            // 36
              << QStringLiteral("healthprobability")   // 37
              << QStringLiteral("healthcaseamount")    // 38
              << QStringLiteral("waterrise")           // 39
              << QStringLiteral("healthdecrease")      // 40
              << QStringLiteral("ropepct")             // 41
              << QStringLiteral("getawaytime")         // 42
              << QStringLiteral("worldedge")           // 43
              << QStringLiteral("scriptparam")         // scriptparam    44
              ;

    QList<QVariant> proMode;
    proMode
            << predefSchemesNames[1]   // name           0
            << QVariant(false)         // switchhog      1
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
            << QVariant(0)             // sentries       36
            << QVariant(35)            // health case pct 37
            << QVariant(25)            // health case amt 38
            << QVariant(47)            // water rise amt 39
            << QVariant(5)             // health dec amt 40
            << QVariant(100)           // rope modfier   41
            << QVariant(100)           // get away time  42
            << QVariant(0)             // world edge     43
            << QVariant()              // scriptparam    44
            ;

    QList<QVariant> shoppa;
    shoppa
            << predefSchemesNames[2]   // name           0
            << QVariant(false)         // switchhog      1
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
            << QVariant(0)             // sentries       36
            << QVariant(0)             // health case pct 37
            << QVariant(25)            // health case amt 38
            << QVariant(0)             // water rise amt 39
            << QVariant(0)             // health dec amt 40
            << QVariant(100)           // rope modfier   41
            << QVariant(100)           // get away time  42
            << QVariant(0)             // world edge     43
            << QVariant()              // scriptparam    44
            ;

    QList<QVariant> cleanslate;
    cleanslate
            << predefSchemesNames[3]   // name           0
            << QVariant(false)         // switchhog      1
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
            << QVariant(0)             // sentries       36
            << QVariant(35)            // health case pct 37
            << QVariant(25)            // health case amt 38
            << QVariant(47)            // water rise amt 39
            << QVariant(5)             // health dec amt 40
            << QVariant(100)           // rope modfier   41
            << QVariant(100)           // get away time  42
            << QVariant(0)             // world edge     43
            << QVariant()              // scriptparam    44
            ;

    QList<QVariant> minefield;
    minefield
            << predefSchemesNames[4]   // name           0
            << QVariant(false)         // switchhog      1
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
            << QVariant(0)             // sentries       36
            << QVariant(35)            // health case pct 37
            << QVariant(25)            // health case amt 38
            << QVariant(47)            // water rise amt 39
            << QVariant(5)             // health dec amt 40
            << QVariant(100)           // rope modfier   41
            << QVariant(100)           // get away time  42
            << QVariant(0)             // world edge     43
            << QVariant()              // scriptparam    44
            ;

    QList<QVariant> barrelmayhem;
    barrelmayhem
            << predefSchemesNames[5]   // name           0
            << QVariant(false)         // switchhog      1
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
            << QVariant(0)             // sentries       36
            << QVariant(35)            // health case pct 37
            << QVariant(25)            // health case amt 38
            << QVariant(47)            // water rise amt 39
            << QVariant(5)             // health dec amt 40
            << QVariant(100)           // rope modfier   41
            << QVariant(100)           // get away time  42
            << QVariant(0)             // world edge     43
            << QVariant()              // scriptparam    44
            ;

    QList<QVariant> tunnelhogs;
    tunnelhogs
            << predefSchemesNames[6]   // name           0
            << QVariant(false)         // switchhog      1
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
            << QVariant(0)             // sentries       36
            << QVariant(35)            // health case pct 37
            << QVariant(25)            // health case amt 38
            << QVariant(47)            // water rise amt 39
            << QVariant(5)             // health dec amt 40
            << QVariant(100)           // rope modfier   41
            << QVariant(100)           // get away time  42
            << QVariant(0)             // world edge     43
            << QVariant()              // scriptparam    44
            ;

    QList<QVariant> timeless;
    timeless
            << predefSchemesNames[7]   // name           0
            << QVariant(false)         // switchhog      1
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
            << QVariant(0)             // sentries       36
            << QVariant(35)            // health case pct 37
            << QVariant(30)            // health case amt 38
            << QVariant(0)             // water rise amt 39
            << QVariant(0)             // health dec amt 40
            << QVariant(100)           // rope modfier   41
            << QVariant(100)           // get away time  42
            << QVariant(0)             // world edge     43
            << QVariant()              // scriptparam    44
            ;

    QList<QVariant> thinkingportals;
    thinkingportals
            << predefSchemesNames[8]   // name           0
            << QVariant(false)         // switchhog      1
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
            << QVariant(0)             // sentries       36
            << QVariant(25)            // health case pct 37
            << QVariant(25)            // health case amt 38
            << QVariant(47)            // water rise amt 39
            << QVariant(5)             // health dec amt 40
            << QVariant(100)           // rope modfier   41
            << QVariant(100)           // get away time  42
            << QVariant(0)             // world edge     43
            << QVariant()              // scriptparam    44
            ;

    QList<QVariant> kingmode;
    kingmode
            << predefSchemesNames[9]  // name           0
            << QVariant(false)         // switchhog      1
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
            << QVariant(0)             // sentries       36
            << QVariant(35)            // health case pct 37
            << QVariant(25)            // health case amt 38
            << QVariant(47)            // water rise amt 39
            << QVariant(5)             // health dec amt 40
            << QVariant(100)           // rope modfier   41
            << QVariant(100)           // get away time  42
            << QVariant(0)             // world edge     43
            << QVariant()              // scriptparam    44
            ;

    QList<QVariant> mutant;
    mutant
            << predefSchemesNames[10]  // name           0
            << QVariant(false)         // switchhog      1
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
            << QVariant(true)          // reset weps     20
            << QVariant(false)         // per hog ammo   21
            << QVariant(false)         // no wind        22
            << QVariant(false)         // more wind      23
            << QVariant(false)         // tag team       24
            << QVariant(false)         // bottom border  25
            << QVariant(100)           // damage modfier 26
            << QVariant(20)            // turn time      27
            << QVariant(100)           // init health    28
            << QVariant(15)            // sudden death   29
            << QVariant(2)             // case prob      30
            << QVariant(1)             // mines time     31
            << QVariant(4)             // mines number   32
            << QVariant(0)             // mine dud pct   33
            << QVariant(2)             // explosives     34
            << QVariant(0)             // air mines      35
            << QVariant(0)             // sentries       36
            << QVariant(0)             // health case pct 37
            << QVariant(25)            // health case amt 38
            << QVariant(0)             // water rise amt 39
            << QVariant(0)             // health dec amt 40
            << QVariant(100)           // rope modfier   41
            << QVariant(100)           // get away time  42
            << QVariant(0)             // world edge     43
            << QVariant()              // scriptparam    44
            ;

    QList<QVariant> construction;
    construction
            << predefSchemesNames[11]  // name           0
            << QVariant(false)         // switchhog      1
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
            << QVariant(0)             // sentries       36
            << QVariant(35)            // health case pct 37
            << QVariant(25)            // health case amt 38
            << QVariant(47)            // water rise amt 39
            << QVariant(5)             // health dec amt 40
            << QVariant(100)           // rope modfier   41
            << QVariant(100)           // get away time  42
            << QVariant(0)             // world edge     43
            // NOTE: If you change this, also change the defaults in the Construction Mode script
            << QVariant("initialenergy=550, energyperround=50, maxenergy=1000, cratesperround=5") // scriptparam    44
            ;

    QList<QVariant> specialists;
    specialists
            << predefSchemesNames[12]  // name           0
            << QVariant(true)          // switchhog      1
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
            << QVariant(true)          // place hog      14
            << QVariant(false)         // shared ammo    15
            << QVariant(false)         // disable girders 16
            << QVariant(false)         // disable land objects 17
            << QVariant(false)         // AI survival    18
            << QVariant(true)          // inf. attack    19
            << QVariant(true)          // reset weps     20
            << QVariant(true)          // per hog ammo   21
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
            << QVariant(0)             // sentries       36
            << QVariant(100)           // health case pct 37
            << QVariant(25)            // health case amt 38
            << QVariant(47)            // water rise amt 39
            << QVariant(5)             // health dec amt 40
            << QVariant(100)           // rope modfier   41
            << QVariant(100)           // get away time  42
            << QVariant(0)             // world edge     43
            // NOTE: If you change this, also change the defaults in the The Specialists script
            << QVariant("t=SENDXHPL")  // scriptparam    44
            ;

    QList<QVariant> spaceinvasion;
    spaceinvasion
            << predefSchemesNames[13]  // name           0
            << QVariant(false)         // switchhog      1
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
            << QVariant(0)             // sentries       36
            << QVariant(0)             // health case pct 37
            << QVariant(25)            // health case amt 38
            << QVariant(0)             // water rise amt 39
            << QVariant(0)             // health dec amt 40
            << QVariant(100)           // rope modfier   41
            << QVariant(100)           // get away time  42
            << QVariant(0)             // world edge     43
            // NOTE: If you change this, also change the defaults in the Space Invasion script
            << QVariant("rounds=3, shield=30, barrels=5, pings=2, barrelbonus=3, shieldbonus=30, timebonus=4") // scriptparam    44
            ;

    QList<QVariant> hedgeeditor;
    hedgeeditor
            << predefSchemesNames[14]  // name           0
            << QVariant(false)         // switchhog      1
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
            << QVariant(0)             // sentries       36
            << QVariant(35)            // health case pct 37
            << QVariant(25)            // health case amt 38
            << QVariant(0)            // water rise amt 39
            << QVariant(0)             // health dec amt 40
            << QVariant(100)           // rope modfier   41
            << QVariant(100)           // get away time  42
            << QVariant(0)             // world edge     43
            << QVariant()              // scriptparam    44
            ;

    QList<QVariant> racer;
    racer
            << predefSchemesNames[15]   // name           0
            << QVariant(false)         // switchhog      1
            << QVariant(false)         // team divide    2
            << QVariant(true)          // solid land     3
            << QVariant(true)          // border         4
            << QVariant(false)         // low gravity    5
            << QVariant(false)         // laser sight    6
            << QVariant(true)          // invulnerable   7
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
            << QVariant(true)          // inf. attack    19
            << QVariant(true)          // reset weps     20
            << QVariant(false)         // per hog ammo   21
            << QVariant(false)         // no wind        22
            << QVariant(false)         // more wind      23
            << QVariant(false)         // tag team       24
            << QVariant(false)         // bottom border  25
            << QVariant(100)           // damage modfier 26
            << QVariant(90)            // turn time      27
            << QVariant(100)           // init health    28
            << QVariant(50)            // sudden death   29
            << QVariant(0)             // case prob      30
            << QVariant(0)             // mines time     31
            << QVariant(0)             // mines number   32
            << QVariant(0)             // mine dud pct   33
            << QVariant(0)             // explosives     34
            << QVariant(0)             // air mines      35
            << QVariant(0)             // sentries       36            
            << QVariant(0)             // health case pct 37
            << QVariant(25)            // health case amt 38
            << QVariant(0)             // water rise amt 39
            << QVariant(0)             // health dec amt 40
            << QVariant(100)           // rope modfier   41
            << QVariant(100)           // get away time  42
            << QVariant(0)             // world edge     43
            << QVariant()              // scriptparam    44
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
    schemes.append(mutant);
    schemes.append(construction);
    schemes.append(specialists);
    schemes.append(spaceinvasion);
    schemes.append(hedgeeditor);
    schemes.append(racer);

    if (!QDir(cfgdir.absolutePath() + QStringLiteral("/Schemes")).exists()) {
      QDir().mkdir(cfgdir.absolutePath() + QStringLiteral("/Schemes"));
    }
    QStringList predefSchemesNamesLower;
    for (int i = 0; i < predefSchemesNames.size(); ++i)
    {
        predefSchemesNamesLower.append(predefSchemesNames[i].toLower());
    }
    if (!QDir(directory).exists()) {
        QDir().mkdir(directory);

        qDebug("No /Schemes/Game directory found. Trying to import game schemes from schemes.ini.");

        QSettings legacyFileConfig(cfgdir.absolutePath() + QStringLiteral("/schemes.ini"),
                                   QSettings::IniFormat);
        int size = legacyFileConfig.beginReadArray("schemes");
        int imported = 0;
        for (int i = 0; i < size; ++i)
        {
            legacyFileConfig.setArrayIndex(i);

            QString schemeName = legacyFileConfig.value(spNames[0]).toString();
            if (!schemeName.isNull() && !predefSchemesNamesLower.contains(schemeName.toLower()))
            {
                QList<QVariant> scheme;
                QFile file(directory + QStringLiteral("/") + schemeName + QStringLiteral(".hwg"));

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
                            stream << spNames[k] << "="
                                   << legacyFileConfig
                                          .value(spNames[k], defaultScheme[k])
                                          .toString()
                                   << "\n";
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
            QFile file(directory + QStringLiteral("/") + scheme_dir[i]);

            // Chop off file name suffix
            QString schemeName = scheme_dir[i];
            if (schemeName.endsWith(QLatin1String(".hwg"), Qt::CaseInsensitive)) {
                schemeName.chop(4);
            }
            // Don't load scheme if name collides with default scheme
            if (predefSchemesNamesLower.contains(schemeName.toLower())) {
                qWarning("Game scheme \"%s\" not loaded from file, name collides with a default scheme!", qPrintable(schemeName));
                continue;
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
    return hasScheme(name, -1);
}

bool GameSchemeModel::hasScheme(QString name, int ignoreID)
{
    QString nameLower = name.toLower();
    for(int i=0; i<schemes.size(); i++)
    {
        if(((ignoreID == -1) || (i != ignoreID)) && (schemes[i][0].toString().toLower() == nameLower))
        {
            return true;
        }
    }
    return false;
}

bool GameSchemeModel::renameScheme(int index, QString newName)
{
    return setData(QAbstractItemModel::createIndex(index, 0), QVariant(newName));
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

    Q_EMIT dataChanged(index, index);
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
    QFile(cfgdir.absolutePath() + QStringLiteral("/Schemes/Game/") + scheme[j].toString() +
          QStringLiteral(".hwg"))
        .remove();
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
        QFile file(cfgdir.absolutePath() + QStringLiteral("/Schemes/Game/") + schemeName +
                   QStringLiteral(".hwg"));

        if (file.open(QIODevice::WriteOnly)) {
            QTextStream stream(&file);
            for (int k = 0; k < spNames.size(); ++k) {
                // We skip the name key
                if(k != j) {
                    // The file is just a list of key=value pairs
                    stream << spNames[k] << "=" << scheme[k].toString() << "\n";
                }
            }
            file.close();
        }
    }
}

NetGameSchemeModel::NetGameSchemeModel(QObject *parent)
    : QAbstractTableModel(parent), netScheme{defaultScheme} {}

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
