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
        enum RandomTeamMode
        {
            rtmEverything = 0,
            rtmHogNames = 1,
        };

        static void teamRandomTeamName(HWTeam & team);
        static void teamRandomGrave(HWTeam & team, bool withDLC = true);
        static void teamRandomFort(HWTeam & team, bool withDLC = true);
        static void teamRandomFlag(HWTeam & team, bool withDLC = true);
        static void teamRandomVoice(HWTeam & team, bool withDLC = true);
        static void teamRandomHats(HWTeam & team, bool withDLC = true);
        static void teamRandomHat(HWTeam & team, const int HedgehogNumber, bool withDLC = true);
        static void teamRandomHogName(HWTeam & team, const int HedgehogNumber);
        static void teamRandomEverything(HWTeam & team, const enum RandomTeamMode mode);

    private:
        HWNamegen();

        static QString getRandomTeamName(int kind);
        static QString getRandomHat(bool withDLC = true);
        static QString getRandomGrave(bool withDLC = true);
        static QString getRandomFort(bool withDLC = true);
        static QString getRandomFlag(bool withDLC = true);
        static QString getRandomVoice(bool withDLC = true);

        static QList<QStringList> TypesTeamnames;
        static QList<QStringList> TypesHatnames;
        static bool typesAvailable;

        static bool loadTypes();
        static QStringList dictContents(const QString filename);
        static QStringList dictsForHat(const QString hatname);

        static void teamRandomHat(HWTeam & team, const int HedgehogNumber, const QStringList & dict);
        static void teamRandomHogName(HWTeam & team, const int HedgehogNumber, const QStringList & dict);
};



#endif
