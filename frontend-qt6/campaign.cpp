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

#include "campaign.h"

#include <QLocale>
#include <QObject>
#include <QRegularExpression>
#include <QSettings>

#include "DataManager.h"
#include "hwconsts.h"
#include "physfs_integration.h"

QSettings* getCampTeamFile(QString& campaignName, QString& teamName) {
  QSettings* teamfile =
      new QSettings(cfgdir.absolutePath() + QStringLiteral("/Teams/") +
                        teamName + QStringLiteral(".hwt"),
                    QSettings::IniFormat, 0);
  // if entry not found check if there is written without _
  // if then is found rename it to use _
  QString spaceCampName = campaignName;
  spaceCampName =
      spaceCampName.replace(QStringLiteral("_"), QStringLiteral(" "));
  if (!teamfile->childGroups().contains(QStringLiteral("Campaign ") +
                                        campaignName) &&
      teamfile->childGroups().contains(QStringLiteral("Campaign ") +
                                       spaceCampName)) {
    teamfile->beginGroup(QStringLiteral("Campaign ") + spaceCampName);
    QStringList keys = teamfile->childKeys();
    teamfile->endGroup();
    for (int i = 0; i < keys.size(); i++) {
      QVariant value =
          teamfile->value(QStringLiteral("Campaign ") + spaceCampName +
                          QStringLiteral("/") + keys[i]);
      teamfile->setValue(QStringLiteral("Campaign ") + campaignName +
                             QStringLiteral("/") + keys[i],
                         value);
    }
    teamfile->remove(QStringLiteral("Campaign ") + spaceCampName);
  }

  return teamfile;
}

/**
    Returns true if the specified mission has been completed
    campaignName: Name of the campaign in question
    missionInList: QComboBox index of the mission as selected in the mission
   widget teamName: Name of the playing team
*/
bool isCampMissionWon(QString& campaignName, int missionInList,
                      QString& teamName) {
  QSettings* teamfile = getCampTeamFile(campaignName, teamName);
  int progress = teamfile
                     ->value(QStringLiteral("Campaign ") + campaignName +
                                 QStringLiteral("/Progress"),
                             0)
                     .toInt();
  int unlockedMissions =
      teamfile
          ->value(QStringLiteral("Campaign ") + campaignName +
                      QStringLiteral("/UnlockedMissions"),
                  0)
          .toInt();
  // FIXME: QSettings with physfs file
  QSettings campfile(QStringLiteral("/Missions/Campaign/") + campaignName +
                         QStringLiteral("/campaign.ini"),
                     QSettings::IniFormat, 0);
  int totalMissions = campfile.value("MissionNum", 1).toInt();
  // The CowardMode cheat unlocks all campaign missions.
  // Added to make it easier to test campaigns.
  bool cheat = teamfile->value("Team/CowardMode", false).toBool();
  if (progress > 0 && unlockedMissions == 0) {
    int maxMission;
    if (cheat)
      maxMission = totalMissions - (missionInList + 1);
    else
      maxMission = progress - missionInList;
    return (progress > maxMission) || (progress >= totalMissions);
  } else if (unlockedMissions > 0) {
    int fileMissionId = missionInList + 1;
    int actualMissionId;
    if (cheat)
      actualMissionId = totalMissions - missionInList;
    else
      actualMissionId =
          teamfile
              ->value(QStringLiteral("Campaign %1/Mission%2")
                          .arg(campaignName, QString::number(fileMissionId)),
                      false)
              .toInt();
    return teamfile
        ->value(QStringLiteral("Campaign %1/Mission%2Won")
                    .arg(campaignName, QString::number(actualMissionId)),
                false)
        .toBool();
  } else
    return false;
}

/** Returns true if the campaign has been won by the team */
bool isCampWon(QString& campaignName, QString& teamName) {
  QSettings* teamfile = getCampTeamFile(campaignName, teamName);
  bool won = teamfile
                 ->value(QStringLiteral("Campaign ") + campaignName +
                             QStringLiteral("/Won"),
                         false)
                 .toBool();
  return won;
}

QSettings* getCampMetaInfo() {
  auto& pfs = PhysFsManager::instance();
  DataManager& dataMgr = DataManager::instance();
  // get locale
  QSettings settings(dataMgr.settingsFileName(), QSettings::IniFormat);
  QString loc = QLocale().name();
  QString campaignDescFile = QString(QStringLiteral("/Locale/campaigns_") +
                                     loc + QStringLiteral(".txt"));
  // if file is non-existant try with language only
  if (!pfs.exists(campaignDescFile)) {
    QRegularExpression re(QStringLiteral("_.*$"));
    campaignDescFile = QStringLiteral("/Locale/campaigns_") + loc.remove(re) +
                       QStringLiteral(".txt");
  }

  // fallback if file for current locale is non-existant
  if (!pfs.exists(campaignDescFile))
    campaignDescFile = QStringLiteral("/Locale/campaigns_en.txt");

  // FIXME: QSettings from physfs
  QSettings* m_info = new QSettings(campaignDescFile, QSettings::IniFormat, 0);

  return m_info;
}

/** Returns the localized campaign name */
QString getRealCampName(const QString& campaignName) {
  QString campaignNameSpaces =
      QString(campaignName).replace(QStringLiteral("_"), QStringLiteral(" "));
  return getCampMetaInfo()
      ->value(campaignName + QStringLiteral(".name"), campaignNameSpaces)
      .toString();
}

QList<MissionInfo> getCampMissionList(QString& campaignName,
                                      QString& teamName) {
  QList<MissionInfo> missionInfoList;
  QSettings* teamfile = getCampTeamFile(campaignName, teamName);

  int progress = teamfile
                     ->value(QStringLiteral("Campaign ") + campaignName +
                                 QStringLiteral("/Progress"),
                             0)
                     .toInt();
  int unlockedMissions =
      teamfile
          ->value(QStringLiteral("Campaign ") + campaignName +
                      QStringLiteral("/UnlockedMissions"),
                  0)
          .toInt();
  bool cheat = teamfile->value("Team/CowardMode", false).toBool();

  // FIXME
  QSettings campfile(QStringLiteral("/Missions/Campaign/") + campaignName +
                         QStringLiteral("/campaign.ini"),
                     QSettings::IniFormat, 0);

  QSettings* m_info = getCampMetaInfo();

  auto& pfs = PhysFsManager::instance();

  if (cheat) {
    progress = campfile.value("MissionNum", 1).toInt();
  }
  if ((progress >= 0 && unlockedMissions == 0) || cheat) {
    for (unsigned int i = progress + 1; i > 0; i--) {
      MissionInfo missionInfo;
      QString script =
          campfile.value(QStringLiteral("Mission %1/Script").arg(i)).toString();
      if (!script.isNull()) {
        missionInfo.script = script;
        missionInfo.name =
            campfile.value(QStringLiteral("Mission %1/Name").arg(i)).toString();
        QString scriptPrefix =
            campaignName + QStringLiteral("-") +
            script.replace(QStringLiteral(".lua"), QLatin1String(""));
        missionInfo.realName =
            m_info
                ->value(scriptPrefix + QStringLiteral(".name"),
                        missionInfo.name)
                .toString();
        missionInfo.description =
            m_info
                ->value(scriptPrefix + QStringLiteral(".desc"),
                        QObject::tr("No description available"))
                .toString();
        QString image =
            campfile.value(QStringLiteral("Mission %1/Script").arg(i))
                .toString()
                .replace(QStringLiteral(".lua"), QStringLiteral("@2x.png"));
        missionInfo.image = QStringLiteral("/Graphics/Missions/Campaign/") +
                            campaignName + QStringLiteral("/") + image;
        if (!pfs.exists(missionInfo.image))
          missionInfo.image = QStringLiteral(":/res/CampaignDefault.png");
        missionInfoList.append(missionInfo);
      }
    }
  } else if (unlockedMissions > 0) {
    for (int i = 1; i <= unlockedMissions; i++) {
      QString missionNum = QStringLiteral("%1").arg(i);
      int missionNumber =
          teamfile
              ->value(QStringLiteral("Campaign ") + campaignName +
                          QStringLiteral("/Mission") + missionNum,
                      -1)
              .toInt();
      MissionInfo missionInfo;
      QString script =
          campfile.value(QStringLiteral("Mission %1/Script").arg(missionNumber))
              .toString();
      missionInfo.script = script;
      missionInfo.name =
          campfile.value(QStringLiteral("Mission %1/Name").arg(missionNumber))
              .toString();
      QString scriptPrefix =
          campaignName + QStringLiteral("-") +
          script.replace(QStringLiteral(".lua"), QLatin1String(""));
      missionInfo.realName =
          m_info
              ->value(scriptPrefix + QStringLiteral(".name"), missionInfo.name)
              .toString();
      missionInfo.description =
          m_info
              ->value(scriptPrefix + QStringLiteral(".desc"),
                      QObject::tr("No description available"))
              .toString();
      QString image =
          campfile.value(QStringLiteral("Mission %1/Script").arg(missionNumber))
              .toString()
              .replace(QStringLiteral(".lua"), QStringLiteral("@2x.png"));
      missionInfo.image = QStringLiteral("/Graphics/Missions/Campaign/") +
                          campaignName + QStringLiteral("/") + image;
      if (!pfs.exists(missionInfo.image))
        missionInfo.image = QStringLiteral(":/res/CampaignDefault.png");
      missionInfoList.append(missionInfo);
    }
  }
  return missionInfoList;
}
