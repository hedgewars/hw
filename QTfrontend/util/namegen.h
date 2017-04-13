/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2009 Martin Minarik <ttsmj@pokec.sk>
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

#ifndef NAMEGEN_H
#define NAMEGEN_H

#include <QString>

class HWForm;
class HWTeam;

class HWNamegen
{
    public:

        static void teamRandomGrave(HWTeam & team);
        static void teamRandomFort(HWTeam & team);
        static void teamRandomFlag(HWTeam & team);
        static void teamRandomVoice(HWTeam & team);
        static void teamRandomHogName(HWTeam & team, const int HedgehogNumber);
        static void teamRandomEverything(HWTeam & team, const bool changeteamname);

    private:
        HWNamegen();

        static QString getRandomGrave();
        static QString getRandomFort();
        static QString getRandomFlag();
        static QString getRandomVoice();

        static QList<QStringList> TypesTeamnames;
        static QList<QStringList> TypesHatnames;
        static bool typesAvailable;

        static bool loadTypes();
        static QStringList dictContents(const QString filename);
        static QStringList dictsForHat(const QString hatname);

        static void teamRandomHogName(HWTeam & team, const int HedgehogNumber, const QStringList & dict);
};



#endif
