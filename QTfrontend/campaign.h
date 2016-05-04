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

#ifndef CAMPAIGN_H
#define CAMPAIGN_H

#include <QString>
#include <QSettings>

class MissionInfo
{
    public:
        QString name;
        QString description;
        QString script;
        QString image;
};


QSettings* getCampTeamFile(QString & campaignName, QString & teamName);
QSettings* getCampMetaInfo();
bool isCampWon(QString & campaignName, QString & teamName);
bool isMissionWon(QString & campaignName, int missionInList, QString & teamName);
QString getRealCampName(QString & campaignName);
QList<MissionInfo> getCampMissionList(QString & campaignName, QString & teamName);

#endif
