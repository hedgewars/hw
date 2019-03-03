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
    if (!teamfile->childGroups().contains("Mission " + missionName) &&
            teamfile->childGroups().contains("Mission " + missionName)){
        teamfile->beginGroup("Mission " + missionName);
        QStringList keys = teamfile->childKeys();
        teamfile->endGroup();
        for (int i=0;i<keys.size();i++) {
            QVariant value = teamfile->value("Mission " + missionName + "/" + keys[i]);
            teamfile->setValue("Mission " + missionName + "/" + keys[i], value);
        }
        teamfile->remove("Mission " + missionName);
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

/**
    Returns true if the mission value adressed with the provided
    missionName: Name of the mission in question
    teamName: Name of the playing team
    key: name of key to check
*/
bool missionValueExists(QString & missionName, QString & teamName, QString key)
{
    QSettings* teamfile = getMissionTeamFile(missionName, teamName);
    return teamfile->contains("Mission " + missionName + "/" + key);
}
/**
    Returns a mission value.
    NOTE: Check whether the mission value exists first, using missionValueExists.
    missionName: Name of the mission in question
    teamName: Name of the playing team
    key: name of key to read its value from
*/
QVariant getMissionValue(QString & missionName, QString & teamName, QString key)
{
    QSettings* teamfile = getMissionTeamFile(missionName, teamName);
    return teamfile->value("Mission " + missionName + "/" + key);
}
