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

#if !(TARGET_OS_IPHONE)
#include <QString>
#include <QDir>
#include <QStringList>
#include <QPair>


extern QString * cProtoVer;
extern QString * cVersionString;
extern QString * cRevisionString;
extern QString * cHashString;
extern QString * cDataDir;
extern QString * cSafeFileNameRegExp;

extern QDir * bindir;
extern QDir * cfgdir;
extern QDir * datadir;

extern bool custom_config;
extern bool custom_data;

extern int cMaxTeams;
extern int cMaxHHs;
extern int cMinServerVersion;
extern unsigned char cInvertTextColorAt;

class QStandardItemModel;

extern QString * cDefaultAmmoStore;
extern QString * cEmptyAmmoStore;
extern int cAmmoNumber;
extern QList< QPair<QString, QString> > cDefaultAmmos;

extern unsigned int colors[];

extern QString * netHost;
extern quint16 netPort;


//Current season, SEASON_NONE by default
extern int season;
//On the day of hedgewars birthday (Oct 31st) this variable is assigned
//with number of years past 2004 (foundation of hedgewars)
//Could be used to implement a text/graphic like "This is the xxth birthday of hedgewars" or similar
extern int years_since_foundation;

#endif


//Different seasons; assigned to season (int)
#define SEASON_NONE 0
#define SEASON_CHRISTMAS 2
#define SEASON_HWBDAY 4
#define SEASON_EASTER 8
#define SEASON_APRIL1 16

#define NETGAME_DEFAULT_SERVER "netserver.hedgewars.org"
#define NETGAME_DEFAULT_PORT 46631
#define HEDGEHOGS_PER_TEAM 8

//Selected engine exit codes, see hedgewars/uConsts.pas
#define HWENGINE_EXITCODE_OK 0
#define HWENGINE_EXITCODE_FATAL 52

// Default clan colors
// NOTE: Always keep this in sync with hedgewars/uVariables.pas (ClanColorArray)

// see https://en.wikipedia.org/wiki/List_of_colors
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
                              0xff8f5902, /* brown  */ \
                              0xffffff01, /* yellow */ \
                              /* add new colors here */ \
                              0 }
