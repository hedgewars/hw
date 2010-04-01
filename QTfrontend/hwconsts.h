/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QString>
#include <QDir>
#include <QStringList>
#include <QColor>
#include <QPair>

extern QString * cProtoVer;
extern QString * cVersionString;
extern QString * cDataDir;
extern QString * cConfigDir;

extern QDir * bindir;
extern QDir * cfgdir;
extern QDir * datadir;

extern QStringList * Themes;
extern QStringList * mapList;

extern QString * cDefaultAmmoStore;
extern int cAmmoNumber;
extern QList< QPair<QString, QString> > cDefaultAmmos;

extern QColor * color1;
extern QColor * color2;
extern QColor * color3;
extern QColor * color4;
extern QColor * color5;
extern QColor * color6;

extern QString * netHost;
extern quint16 netPort;

extern bool haveServer;
extern bool isDevBuild;
