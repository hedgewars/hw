/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

#if !defined(TARGET_OS_IPHONE)
#include <QString>
#include <QDir>
#include <QStringList>
#include <QPair>

extern QString * cProtoVer;
extern QString * cVersionString;
extern QString * cDataDir;
extern QString * cConfigDir;

extern QDir * bindir;
extern QDir * cfgdir;
extern QDir * datadir;

extern bool custom_config;
extern bool custom_data;

extern int cMaxTeams;
extern int cMinServerVersion;

extern QStringList * Themes;
extern QStringList * mapList;
extern QStringList * scriptList;

extern QString * cDefaultAmmoStore;
extern int cAmmoNumber;
extern QList< QPair<QString, QString> > cDefaultAmmos;

extern unsigned int colors[];

extern QString * netHost;
extern quint16 netPort;

extern bool haveServer;
extern bool isDevBuild;
#endif

#define AMMOLINE_DEFAULT_QT     "939192942219912103223511100120100000021111010101111991"
#define AMMOLINE_DEFAULT_PROB   "040504054160065554655446477657666666615551010111541111"
#define AMMOLINE_DEFAULT_DELAY  "000000000000020550000004000700400000000022000000060000"
#define AMMOLINE_DEFAULT_CRATE  "131111031211111112311411111111111111121111110111111111"

//TODO: Remove Piano's unlimited uses!
#define AMMOLINE_CRAZY_QT       "999999999999999999299999999999999929999999990999999229"
#define AMMOLINE_CRAZY_PROB     "111111011111111111111111111111111111111111110111111111"
#define AMMOLINE_CRAZY_DELAY    "000000000000000000000000000000000000000000000000000000"
#define AMMOLINE_CRAZY_CRATE    "131111031211111112311411111111111111121111010111111111"

#define AMMOLINE_PROMODE_QT     "909000900000000000000900000000000000000000000000000000"
#define AMMOLINE_PROMODE_PROB   "000000000000000000000000000000000000000000000000000000"
#define AMMOLINE_PROMODE_DELAY  "000000000000020550000004000700400000000020000000000000"
#define AMMOLINE_PROMODE_CRATE  "111111111111111111111111111111111111111110010111111111"

#define AMMOLINE_SHOPPA_QT      "000000990000000000000000000000000000000000000000000000"
#define AMMOLINE_SHOPPA_PROB    "444441004424440221011212122242200000000200040001001111"
#define AMMOLINE_SHOPPA_DELAY   "000000000000000000000000000000000000000000000000000000"
#define AMMOLINE_SHOPPA_CRATE   "111111111111111111111111111111111111111110110111111111"

#define AMMOLINE_CLEAN_QT       "101000900001000001100000000000000000000000000000100000"
#define AMMOLINE_CLEAN_PROB     "040504054160065554655446477657666666615551010111541111"
#define AMMOLINE_CLEAN_DELAY    "000000000000000000000000000000000000000000000000000000"
#define AMMOLINE_CLEAN_CRATE    "131111031211111112311411111111111111121111110111111111"

#define AMMOLINE_MINES_QT       "000000990009000000030000000000000000000000000000000000"
#define AMMOLINE_MINES_PROB     "000000000000000000000000000000000000000000000000000000"
#define AMMOLINE_MINES_DELAY    "000000000000020550000004000700400000000020000000060000"
#define AMMOLINE_MINES_CRATE    "111111111111111111111111111111111111111111110111111111"

#define AMMOLINE_PORTALS_QT     "900000900200000000210000000000000011000009000000000000"
#define AMMOLINE_PORTALS_PROB   "040504054160065554655446477657666666615551010111541111"
#define AMMOLINE_PORTALS_DELAY  "000000000000020550000004000700400000000020000000060000"
#define AMMOLINE_PORTALS_CRATE  "131111031211111112311411111111111111121111110111111111"


#define NETGAME_DEFAULT_PORT 46631


// see http://en.wikipedia.org/wiki/List_of_colors
#define HW_TEAMCOLOR_ARRAY  { 0xff007fff, /* azure */ \
                              0xffdd0000, /* classic red */ \
                              0xff3e9321, /* classic green */ \
                              0xffa23dbb, /* classic purple */ \
                              0xffffb347, /* pastel orange */ \
                              0xffcfcfc4, /* pastel gray */ \
                              0xffbff000, /* lime */ \
                              0xffffef00, /* yellow */ \
                              /* add new colors here */ \
                              0 }
