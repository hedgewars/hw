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
#include "hwconsts.h"
#include "DataManager.h"
#include <QSettings>
#include <QObject>
#include <QLocale>

QList<MissionInfo> getCampMissionList(QString & campaignName, QString & teamName)
{
    QList<MissionInfo> missionInfoList;
    QSettings teamfile(cfgdir->absolutePath() + "/Teams/" + teamName + ".hwt", QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");

    // if entry not found check if there is written without _
    // if then is found rename it to use _
    QString spaceCampName = campaignName;
    spaceCampName = spaceCampName.replace(QString("_"),QString(" "));
    if (!teamfile.childGroups().contains("Campaign " + campaignName) and
            teamfile.childGroups().contains("Campaign " + spaceCampName)){
        teamfile.beginGroup("Campaign " + spaceCampName);
        QStringList keys = teamfile.childKeys();
        teamfile.endGroup();
        for (int i=0;i<keys.size();i++) {
            QVariant value = teamfile.value("Campaign " + spaceCampName + "/" + keys[i]);
            teamfile.setValue("Campaign " + campaignName + "/" + keys[i], value);
        }
        teamfile.remove("Campaign " + spaceCampName);
    }

    int progress = teamfile.value("Campaign " + campaignName + "/Progress", 0).toInt();
    int unlockedMissions = teamfile.value("Campaign " + campaignName + "/UnlockedMissions", 0).toInt();

    QSettings campfile("physfs://Missions/Campaign/" + campaignName + "/campaign.ini", QSettings::IniFormat, 0);
    campfile.setIniCodec("UTF-8");

    DataManager & dataMgr = DataManager::instance();
        // get locale
        QSettings settings(dataMgr.settingsFileName(),
                           QSettings::IniFormat);
        QString loc = settings.value("misc/locale", "").toString();
        if (loc.isEmpty())
            loc = QLocale::system().name();
        QString campaignDescFile = QString("physfs://Locale/campaigns_" + loc + ".txt");
        // if file is non-existant try with language only
        if (!QFile::exists(campaignDescFile))
            campaignDescFile = QString("physfs://Locale/campaigns_" + loc.remove(QRegExp("_.*$")) + ".txt");

        // fallback if file for current locale is non-existant
        if (!QFile::exists(campaignDescFile))
            campaignDescFile = QString("physfs://Locale/campaigns_en.txt");

        QSettings m_info(campaignDescFile, QSettings::IniFormat, 0);
        m_info.setIniCodec("UTF-8");

    if(progress>=0 and unlockedMissions==0)
    {
        for(unsigned int i=progress+1;i>0;i--)
        {
            MissionInfo missionInfo;
            missionInfo.name = campfile.value(QString("Mission %1/Name").arg(i)).toString();
            QString script = campfile.value(QString("Mission %1/Script").arg(i)).toString();
            missionInfo.script = script;
            missionInfo.description = m_info.value(campaignName+"-"+ script.replace(QString(".lua"),QString("")) + ".desc",
                                            QObject::tr("No description available")).toString();
            QString image = campfile.value(QString("Mission %1/Script").arg(i)).toString().replace(QString(".lua"),QString(".png"));
            missionInfo.image = ":/res/campaign/"+campaignName+"/"+image;
            if (!QFile::exists(missionInfo.image))
                missionInfo.image = ":/res/CampaignDefault.png";
            missionInfoList.append(missionInfo);
        }
    }
    else if(unlockedMissions>0)
    {
        for(int i=1;i<=unlockedMissions;i++)
        {
            QString missionNum = QString("%1").arg(i);
            int missionNumber = teamfile.value("Campaign " + campaignName + "/Mission"+missionNum, -1).toInt();
            MissionInfo missionInfo;
            missionInfo.name = campfile.value(QString("Mission %1/Name").arg(missionNumber)).toString();
            QString script = campfile.value(QString("Mission %1/Script").arg(missionNumber)).toString();
            missionInfo.script = script;
            missionInfo.description = m_info.value(campaignName+"-"+ script.replace(QString(".lua"),QString("")) + ".desc",
                                            QObject::tr("No description available")).toString();
            QString image = campfile.value(QString("Mission %1/Script").arg(missionNumber)).toString().replace(QString(".lua"),QString(".png"));
            missionInfo.image = ":/res/campaign/"+campaignName+"/"+image;
            if (!QFile::exists(missionInfo.image))
                missionInfo.image = ":/res/CampaignDefault.png";
            missionInfoList.append(missionInfo);
        }
    }
    return missionInfoList;
}
