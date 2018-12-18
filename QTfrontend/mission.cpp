/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2018 Andrey Korotaev <unC0Rr@gmail.com>
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

#include "mission.h"
#include "hwconsts.h"
#include "DataManager.h"
#include <QSettings>
#include <QObject>
#include <QLocale>

QSettings* getMissionTeamFile(QString & missionName, QString & teamName)
{
    QSettings* teamfile = new QSettings(cfgdir->absolutePath() + "/Teams/" + teamName + ".hwt", QSettings::IniFormat, 0);
    teamfile->setIniCodec("UTF-8");
    // if entry not found check if there is written without _
    // if then is found rename it to use _
    QString cleanedMissionName = missionName;
    cleanedMissionName = cleanedMissionName.replace(QString("_"),QString(" "));
    if (!teamfile->childGroups().contains("Mission " + cleanedMissionName) &&
            teamfile->childGroups().contains("Mission " + cleanedMissionName)){
        teamfile->beginGroup("Mission " + cleanedMissionName);
        QStringList keys = teamfile->childKeys();
        teamfile->endGroup();
        for (int i=0;i<keys.size();i++) {
            QVariant value = teamfile->value("Mission " + cleanedMissionName + "/" + keys[i]);
            teamfile->setValue("Mission " + missionName + "/" + keys[i], value);
        }
        teamfile->remove("Mission " + cleanedMissionName);
    }

    return teamfile;
}

/**
    Returns true if the specified mission has been completed
    missionName: Name of the mission in question
    teamName: Name of the playing team
*/
bool isMissionWon(QString & missionName, QString & teamName)
{
    QSettings* teamfile = getMissionTeamFile(missionName, teamName);
    bool won = teamfile->value("Mission " + missionName + "/Won", false).toBool();
    return won;
}
