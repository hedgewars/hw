/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2011 Andrey Korotaev <unC0Rr@gmail.com>
 * Copyright (c) 2007 Igor Ulyanov <iulyanov@gmail.com>
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

#ifndef TEAM_H
#define TEAM_H

#include <QColor>
#include <QString>
#include "binds.h"
#include "achievements.h"

class HWForm;
class GameUIConfig;

class HWTeamConstructException
{
};

struct HWHog
{
    QString Name;
    QString Hat;
    int Rounds, Kills, Deaths, Suicides;
};

class HWTeam
{
    public:
        HWTeam(const QString & teamname);
        HWTeam(const QStringList& strLst);
        HWTeam();

        bool isNetTeam() const;

        QString TeamName;
        QString Grave;
        QString Fort;
        QString Flag;
        QString Voicepack;
        QString Owner;
        int Rounds;
        int Wins;
        int CampaignProgress;
        HWHog Hedgehogs[8];
        unsigned int AchievementProgress[MAX_ACHIEVEMENTS];
        unsigned int difficulty;
        BindAction binds[BINDS_NUMBER];

        unsigned char numHedgehogs;
        QColor teamColor;

        bool LoadFromFile();
        bool DeleteFile();
        bool SaveToFile();
        bool FileExists();
        void SetToPage(HWForm * hwform);
        void GetFromPage(HWForm * hwform);
        QStringList TeamGameConfig(quint32 InitHealth) const;

        bool operator==(const HWTeam& t1) const;
        bool operator<(const HWTeam& t1) const;
    private:
        bool m_isNetTeam;
        QString OldTeamName;

};

#endif
