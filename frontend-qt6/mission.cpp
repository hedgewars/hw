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
  QSettings* teamfile =
      new QSettings(cfgdir.absolutePath() + QStringLiteral("/Teams/") + teamName + QStringLiteral(".hwt"),
                    QSettings::IniFormat, 0);
  if (!teamfile->childGroups().contains(QStringLiteral("Mission ") + missionName) &&
      teamfile->childGroups().contains(QStringLiteral("Mission ") + missionName)) {
    teamfile->beginGroup(QStringLiteral("Mission ") + missionName);
    QStringList keys = teamfile->childKeys();
    teamfile->endGroup();
    for (int i = 0; i < keys.size(); i++) {
      QVariant value =
          teamfile->value(QStringLiteral("Mission ") + missionName + QStringLiteral("/") + keys[i]);
      teamfile->setValue(QStringLiteral("Mission ") + missionName + QStringLiteral("/") + keys[i], value);
    }
    teamfile->remove(QStringLiteral("Mission ") + missionName);
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
    bool won = teamfile->value(QStringLiteral("Mission ") + missionName + QStringLiteral("/Won"), false).toBool();
    return won;
}

bool missionValueExists(QString& missionName, QString& teamName,
                        const QString& key) {
  QSettings* teamfile = getMissionTeamFile(missionName, teamName);
  return teamfile->contains(QStringLiteral("Mission ") + missionName +
                            QStringLiteral("/") + key);
}
/**
    Returns a mission value.
    NOTE: Check whether the mission value exists first, using missionValueExists.
    missionName: Name of the mission in question
    teamName: Name of the playing team
    key: name of key to read its value from
*/
QVariant getMissionValue(QString& missionName, QString& teamName,
                         const QString& key) {
  QSettings* teamfile = getMissionTeamFile(missionName, teamName);
  return teamfile->value(QStringLiteral("Mission ") + missionName +
                         QStringLiteral("/") + key);
}
