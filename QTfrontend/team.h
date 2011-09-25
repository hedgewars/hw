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
#include "hwconsts.h"

class HWForm;
class GameUIConfig;

class HWTeamConstructException
{
};

// structure for customization and statistics of a single hedgehog
struct HWHog
{
    QString Name;
    QString Hat;
    int Rounds, Kills, Deaths, Suicides;
};

// class representing a team
class HWTeam
{
    public:

        // constructors
        HWTeam(const QString & teamname);
        HWTeam(const QStringList& strLst);
        HWTeam();

        // file operations
        bool loadFromFile();
        bool deleteFile();
        bool saveToFile();
        bool fileExists();

        // attribute getters
         unsigned int campaignProgress() const;
               QColor color() const;
         unsigned int difficulty() const;
              QString flag() const;
              QString fort() const;
              QString grave() const;
        const HWHog & hedgehog(unsigned int idx) const;
                 bool isNetTeam() const;
              QString name() const;
        unsigned char numHedgehogs() const;
              QString owner() const;
              QString voicepack() const;

        // attribute setters
        void setColor(const QColor & color);
        void setDifficulty(unsigned int level);
        void setFlag(const QString & flag);
        void setFort(const QString & fort);
        void setGrave(const QString & grave);
        void setHedgehog(unsigned int idx, const HWHog & hh);
        void setName(const QString & name);
        void setNumHedgehogs(unsigned char num);
        void setVoicepack(const QString & voicepack);

        // increments for statistical info
        void incRounds();
        void incWins();

        // pages... wait... wth is THIS doing in this class? FIXME!!!!
        void SetToPage(HWForm * hwform);
        void GetFromPage(HWForm * hwform);

        // convert team info into strings for further computation
        QStringList teamGameConfig(quint32 InitHealth) const;

        // comparison operators
        bool operator==(const HWTeam& t1) const;
        bool operator<(const HWTeam& t1) const;



    private:

        QString OldTeamName;

        // class members that contain the general team info and settings
        QString m_name;
        QString m_grave;
        QString m_fort;
        QString m_flag;
        QString m_voicepack;
        HWHog m_hedgehogs[HEDGEHOGS_PER_TEAM];
        unsigned int m_difficulty;
        BindAction binds[BINDS_NUMBER];

        // class members that contain info for the current game setup
        unsigned char m_numHedgehogs;
        QColor m_color;
        bool m_isNetTeam;
        QString m_owner;

        // class members that contain statistics, etc.
        unsigned int m_campaignProgress;
        unsigned int m_rounds;
        unsigned int m_wins;
        unsigned int AchievementProgress[MAX_ACHIEVEMENTS];


};

#endif
