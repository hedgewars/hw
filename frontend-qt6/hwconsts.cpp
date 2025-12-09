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


#include <QStandardItemModel>

#include "hwconsts.h"
#include "weapons.h"

// cDataDir gets 'Data' appended later (in main.cpp)
QString cDataDir = QStringLiteral(HEDGEWARS_DATADIR);
const QString cProtoVer = QStringLiteral(HEDGEWARS_PROTO_VER);
const QString cVersionString = QStringLiteral(HEDGEWARS_VERSION);
const QString cRevisionString = QStringLiteral(HEDGEWARS_REVISION);
const QString cHashString = QStringLiteral(HEDGEWARS_HASH);

// For disallowing some characters that would screw up file name
const QString cSafeFileNameRegExp = QStringLiteral("[^:/\\\\]*");

QDir bindir;
QDir cfgdir;
QDir datadir;

bool custom_config = false;
bool custom_data = false;

int cMaxTeams = 8;
int cMaxHHs = HEDGEHOGS_PER_TEAM * cMaxTeams;
int cMinServerVersion = 3;
unsigned char cInvertTextColorAt = 64;

const QString cDefaultAmmoStore =
    QStringLiteral(AMMOLINE_DEFAULT_QT AMMOLINE_DEFAULT_PROB
                       AMMOLINE_DEFAULT_DELAY AMMOLINE_DEFAULT_CRATE);
const QString cEmptyAmmoStore =
    QStringLiteral(AMMOLINE_EMPTY_QT AMMOLINE_EMPTY_PROB AMMOLINE_EMPTY_DELAY
                       AMMOLINE_EMPTY_CRATE);
int cAmmoNumber = cDefaultAmmoStore.size() / 4;
unsigned int ammoMenuAmmos[] = HW_AMMOMENU_ARRAY;
int cAmmoMenuRows = 6;

QList<QPair<QString, QString> > cDefaultAmmos =
    QList<QPair<QString, QString> >()
    << qMakePair(QStringLiteral("Default"), cDefaultAmmoStore)
    << qMakePair(QStringLiteral("Crazy"),
                 QString(AMMOLINE_CRAZY_QT AMMOLINE_CRAZY_PROB
                             AMMOLINE_CRAZY_DELAY AMMOLINE_CRAZY_CRATE))
    << qMakePair(QStringLiteral("Pro Mode"),
                 QString(AMMOLINE_PROMODE_QT AMMOLINE_PROMODE_PROB
                             AMMOLINE_PROMODE_DELAY AMMOLINE_PROMODE_CRATE))
    << qMakePair(QStringLiteral("Shoppa"),
                 QString(AMMOLINE_SHOPPA_QT AMMOLINE_SHOPPA_PROB
                             AMMOLINE_SHOPPA_DELAY AMMOLINE_SHOPPA_CRATE))
    << qMakePair(QStringLiteral("Clean Slate"),
                 QString(AMMOLINE_CLEAN_QT AMMOLINE_CLEAN_PROB
                             AMMOLINE_CLEAN_DELAY AMMOLINE_CLEAN_CRATE))
    << qMakePair(QStringLiteral("Minefield"),
                 QString(AMMOLINE_MINES_QT AMMOLINE_MINES_PROB
                             AMMOLINE_MINES_DELAY AMMOLINE_MINES_CRATE))
    << qMakePair(QStringLiteral("Thinking with Portals"),
                 QString(AMMOLINE_PORTALS_QT AMMOLINE_PORTALS_PROB
                             AMMOLINE_PORTALS_DELAY AMMOLINE_PORTALS_CRATE))
    << qMakePair(QStringLiteral("One of Everything"),
                 QString(AMMOLINE_ONEEVERY_QT AMMOLINE_ONEEVERY_PROB
                             AMMOLINE_ONEEVERY_DELAY AMMOLINE_ONEEVERY_CRATE))
    << qMakePair(
           QStringLiteral("Highlander"),
           QString(AMMOLINE_HIGHLANDER_QT AMMOLINE_HIGHLANDER_PROB
                       AMMOLINE_HIGHLANDER_DELAY AMMOLINE_HIGHLANDER_CRATE))
    << qMakePair(QStringLiteral("Balanced Random Weapon"),
                 QString(AMMOLINE_BRW_QT AMMOLINE_BRW_PROB AMMOLINE_BRW_DELAY
                             AMMOLINE_BRW_CRATE))
    << qMakePair(
           QStringLiteral("Construction Mode"),
           QString(AMMOLINE_CONSTRUCTION_QT AMMOLINE_CONSTRUCTION_PROB
                       AMMOLINE_CONSTRUCTION_DELAY AMMOLINE_CONSTRUCTION_CRATE))
    << qMakePair(QStringLiteral("Shoppa Pro"),
                 QString(AMMOLINE_SHOPPAPRO_QT AMMOLINE_SHOPPAPRO_PROB
                             AMMOLINE_SHOPPAPRO_DELAY AMMOLINE_SHOPPAPRO_CRATE))
    << qMakePair(
           QStringLiteral("HedgeEditor"),
           QString(AMMOLINE_HEDGEEDITOR_QT AMMOLINE_HEDGEEDITOR_PROB
                       AMMOLINE_HEDGEEDITOR_DELAY AMMOLINE_HEDGEEDITOR_CRATE));

QStringList cQuickGameMaps = QStringList()
    << QStringLiteral("Bamboo")
    << QStringLiteral("Bath")
    << QStringLiteral("Battlefield")
    << QStringLiteral("Blox")
    << QStringLiteral("Bubbleflow")
    << QStringLiteral("Cake")
    << QStringLiteral("Castle")
    << QStringLiteral("Cheese")
    << QStringLiteral("Cogs")
    << QStringLiteral("CrazyMission")
    << QStringLiteral("EarthRise")
    << QStringLiteral("Eyes")
    << QStringLiteral("Hammock")
    << QStringLiteral("HedgeFortress")
    << QStringLiteral("Hedgelove")
    << QStringLiteral("Hedgewars")
    << QStringLiteral("Hydrant")
    << QStringLiteral("Lonely_Island")
    << QStringLiteral("Mushrooms")
    << QStringLiteral("Octorama")
    << QStringLiteral("PirateFlag")
    << QStringLiteral("Plane")
    << QStringLiteral("Sheep")
    << QStringLiteral("Trash")
    << QStringLiteral("Tree");

unsigned int colors[] = HW_TEAMCOLOR_ARRAY;

QString netHost;
quint16 netPort = NETGAME_DEFAULT_PORT;

int season = SEASON_NONE;
int years_since_foundation = 0;
