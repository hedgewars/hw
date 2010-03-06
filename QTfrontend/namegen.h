/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2009 Martin Minarik <ttsmj@pokec.sk>
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

#ifndef NAMEGEN_H
#define NAMEGEN_H

#include <QString>

class HWForm;
class HWTeam;

class HWNamegen
{
public:
    HWNamegen();
    ~HWNamegen();

    void TeamRandomName(HWTeam*& team, const int &i);
    void TeamRandomNames(HWTeam*& team, const bool changeteamname);
    void RandomNameByHat(HWTeam*& team, const int &i);

private:

        QList<QStringList> TypesTeamnames;
        QList<QStringList> TypesHatnames;
        bool TypesAvliable;
        void TypesLoad();
        void DictLoad(const QString filename, QStringList &list);
        void HatCfgLoad(const QString hatname, QStringList &list);
};



#endif
