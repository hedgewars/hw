/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

extern QDir * bindir;
extern QDir * cfgdir;
extern QDir * datadir;

extern bool custom_config;
extern bool custom_data;

extern int cMaxTeams;
extern int cMinServerVersion;

class QStandardItemModel;

extern QString * cDefaultAmmoStore;
extern int cAmmoNumber;
extern QList< QPair<QString, QString> > cDefaultAmmos;

extern unsigned int colors[];

extern QString * netHost;
extern quint16 netPort;

extern bool haveServer;
extern bool isDevBuild;

//Current season, SEASON_NONE by default
extern int season;
//On the day of hedgewars birthday (Oct 31st) this variable is assigned
//with number of years past 2004 (foundation of hedgewars)
//Could be used to implement a text/graphic like "This is the xxth birthday of hedgewars" or similar
extern int years_since_foundation;

#endif

#define HEDGEHOGS_PER_TEAM           8

#define AMMOLINE_DEFAULT_QT     "9391929422199121032235111001201000000211110101011111101"
#define AMMOLINE_DEFAULT_PROB   "0405040541600655546554464776576666666155510101115411101"
#define AMMOLINE_DEFAULT_DELAY  "0000000000000205500000040007004000000000220000000600000"
#define AMMOLINE_DEFAULT_CRATE  "1311110312111111123114111111111111111211111101111111101"

#define AMMOLINE_CRAZY_QT       "9999999999999999992999999999999999299999999909999992909"
#define AMMOLINE_CRAZY_PROB     "1111110111111111111111111111111111111111111101111111101"
#define AMMOLINE_CRAZY_DELAY    "0000000000000000000000000000000000000000000000000000000"
#define AMMOLINE_CRAZY_CRATE    "1311110312111111123114111111111111111211110101111111101"

#define AMMOLINE_PROMODE_QT     "9090009000000000000009000000000000000000000000000000000"
#define AMMOLINE_PROMODE_PROB   "0000000000000000000000000000000000000000000000000000000"
#define AMMOLINE_PROMODE_DELAY  "0000000000000205500000040007004000000000200000000000002"
#define AMMOLINE_PROMODE_CRATE  "1111111111111111111111111111111111111111100101111111101"

#define AMMOLINE_SHOPPA_QT      "0000009900000000000000000000000000000000000000000000000"
#define AMMOLINE_SHOPPA_PROB    "4444410044244402210112121222422000000002000400010011001"
#define AMMOLINE_SHOPPA_DELAY   "0000000000000000000000000000000000000000000000000000000"
#define AMMOLINE_SHOPPA_CRATE   "1111111111111111111111111111111111111111101101111111001"

#define AMMOLINE_CLEAN_QT       "1010009000010000011000000000000000000000000000001000000"
#define AMMOLINE_CLEAN_PROB     "0405040541600655546554464776576666666155510101115411101"
#define AMMOLINE_CLEAN_DELAY    "0000000000000000000000000000000000000000000000000000000"
#define AMMOLINE_CLEAN_CRATE    "1311110312111111123114111111111111111211111101111111101"

#define AMMOLINE_MINES_QT       "0000009900090000000300000000000000000000000000000000000"
#define AMMOLINE_MINES_PROB     "0000000000000000000000000000000000000000000000000000000"
#define AMMOLINE_MINES_DELAY    "0000000000000205500000040007004000000000200000000600000"
#define AMMOLINE_MINES_CRATE    "1111111111111111111111111111111111111111111101111111101"

#define AMMOLINE_PORTALS_QT     "9000009002000000002100000000000000110000090000000000000"
#define AMMOLINE_PORTALS_PROB   "0405040541600655546554464776576666666155510101115411101"
#define AMMOLINE_PORTALS_DELAY  "0000000000000205500000040007004000000000200000000600000"
#define AMMOLINE_PORTALS_CRATE  "1311110312111111123114111111111111111211111101111111101"

//Different seasons; assigned to season (int)
#define SEASON_NONE 0
#define SEASON_CHRISTMAS 2
#define SEASON_HWBDAY 4
#define SEASON_EASTER 8

#define NETGAME_DEFAULT_PORT 46631


// see http://en.wikipedia.org/wiki/List_of_colors
/*define HW_TEAMCOLOR_ARRAY  {0xff007fff, /. azure          ./ \
                              0xffdd0000, /. classic red    ./ \
                              0xff3e9321, /. classic green  ./ \
                              0xffa23dbb, /. classic purple ./ \
                              0xffffb347, /. pastel orange  ./ \
                              0xffcfcfc4, /. pastel gray    ./ \
                              0xffbff000, /. lime           ./ \
                              0xffffef00, /. yellow         ./ \
                              // add new colors here
                              0 }*/
/*
#define HW_TEAMCOLOR_ARRAY  { 0xffd12b42, /. red    ./ \
                              0xff4980c1, /. blue   ./ \
                              0xff6ab530, /. green  ./ \
                              0xffbc64c4, /. purple ./ \
                              0xffe76d14, /. orange ./ \
                              0xff3fb6e6, /. cyan   ./ \
                              0xffe3e90c, /. yellow ./ \
                              0xff61d4ac, /. mint   ./ \
                              0xfff1c3e1, /. pink   ./ \
                              // add new colors here
                              0 }*/
/* another set. this one is a merge of mikade/bugq colours w/ a bit of channel feedback */
#define HW_TEAMCOLOR_ARRAY  { 0xffff0204, /* red    */ \
                              0xff4980c1, /* blue   */ \
                              0xff1de6ba, /* teal   */ \
                              0xffb541ef, /* purple */ \
                              0xffe55bb0, /* pink   */ \
                              0xff20bf00, /* green  */ \
                              0xfffe8b0e, /* orange */ \
                              0xff5f3605, /* brown  */ \
                              0xffffff01, /* yellow */ \
                              /* add new colors here */ \
                              0 }
