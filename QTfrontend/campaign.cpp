/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2013 Andrey Korotaev <unC0Rr@gmail.com>
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

#include "campaign.h"
#include "hwconsts.h"
#include "DataManager.h"
#include <QSettings>
#include <QMap>
#include <QDebug>
#include <QObject>

QStringList getCampMissionList(QString & campaign)
{
    QSettings campfile("physfs://Missions/Campaign/" + campaign + "/campaign.ini", QSettings::IniFormat, 0);
    campfile.setIniCodec("UTF-8");
    unsigned int mNum = campfile.value("MissionNum", 0).toInt();

    QStringList missionList;
    for (unsigned int i = 0; i < mNum; i++)
    {
      missionList += campfile.value(QString("Mission %1/Name").arg(i + 1)).toString();
    }
    return missionList;
}

// works ok
QStringList getCampMissionList2(QString & campaignName, QString & teamName)
{    
    QStringList missionList;
	QSettings teamfile(cfgdir->absolutePath() + "/Teams/" + teamName + ".hwt", QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    unsigned int progress = teamfile.value("Campaign " + campaignName + "/Progress", 0).toInt();
    qDebug("HERE is progress : %d",progress);
    unsigned int unlockedMissions = teamfile.value("Campaign " + campaignName + "/UnlockedMissions", 0).toInt();
    qDebug("HERE is unlocked missions : %d",unlockedMissions);
    
    QSettings campfile("physfs://Missions/Campaign/" + campaignName + "/campaign.ini", QSettings::IniFormat, 0);
    campfile.setIniCodec("UTF-8");
    unsigned int missionsNumber = campfile.value("MissionNum", 0).toInt();
    qDebug("HERE is number of missions : %d",missionsNumber);  
    
    if(progress>=0 and unlockedMissions==0)
    {
		for(unsigned int i=progress+1;i>0;i--)
		{
			missionList += campfile.value(QString("Mission %1/Name").arg(i)).toString();
		}
	} 
	else if(unlockedMissions>0)
	{
		qDebug("IN HERE !!!");  
		for(unsigned int i=1;i<=unlockedMissions;i++)
		{
			QString missionNum = QString("%1").arg(i);
			int missionNumber = teamfile.value("Campaign " + campaignName + "/Mission"+missionNum, -1).toInt();
			qDebug("Campaign %s Mission %d",campaignName.toUtf8().constData(),i);  
			qDebug("MISSION NUMBER : %d",missionNumber);  
			missionList += campfile.value(QString("Mission %1/Name").arg(missionNumber)).toString();
			qDebug(campfile.value(QString("Mission %1/Name").arg(missionNumber)).toString().toUtf8().constData());
		}
	}
	return missionList;
}

QStringList getDescriptions(QString & campaignName, QString & teamName)
{    
    QStringList descriptionList;
	QSettings teamfile(cfgdir->absolutePath() + "/Teams/" + teamName + ".hwt", QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    unsigned int progress = teamfile.value("Campaign " + campaignName + "/Progress", 0).toInt();
    qDebug("HERE is progress : %d",progress);
    unsigned int unlockedMissions = teamfile.value("Campaign " + campaignName + "/UnlockedMissions", 0).toInt();
    qDebug("HERE is unlocked missions : %d",unlockedMissions);
    
    QSettings campfile("physfs://Missions/Campaign/" + campaignName + "/campaign.ini", QSettings::IniFormat, 0);
    campfile.setIniCodec("UTF-8");
    unsigned int missionsNumber = campfile.value("MissionNum", 0).toInt();
    qDebug("HERE is number of missions : %d",missionsNumber);  
    
    
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
			//update descruiptions here
			descriptionList += m_info.value(campaignName+"-"+ getCampaignMissionName(campaignName,i) + ".desc",
                                            QObject::tr("No description available")).toString();
		}
	} 
	else if(unlockedMissions>0)
	{
		qDebug("IN HERE !!!");  
		for(unsigned int i=1;i<=unlockedMissions;i++)
		{
			QString missionNum = QString("%1").arg(i);
			descriptionList += m_info.value(campaignName+"-"+ getCampaignMissionName(campaignName,i) + ".desc",
                                            QObject::tr("No description available")).toString();
		}
	}
	return descriptionList;
}

QStringList getImages(QString & campaignName, QString & teamName)
{    
    QStringList imageList;
	QSettings teamfile(cfgdir->absolutePath() + "/Teams/" + teamName + ".hwt", QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    unsigned int progress = teamfile.value("Campaign " + campaignName + "/Progress", 0).toInt();
    qDebug("HERE is progress : %d",progress);
    unsigned int unlockedMissions = teamfile.value("Campaign " + campaignName + "/UnlockedMissions", 0).toInt();
    qDebug("HERE is unlocked missions : %d",unlockedMissions);
    
    QSettings campfile("physfs://Missions/Campaign/" + campaignName + "/campaign.ini", QSettings::IniFormat, 0);
    campfile.setIniCodec("UTF-8");
    unsigned int missionsNumber = campfile.value("MissionNum", 0).toInt();
    qDebug("HERE is number of missions : %d",missionsNumber);  
    
    
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
			//update descruiptions here
			imageList += campfile.value(QString("Mission %1/Script").arg(i)).toString().replace(QString(".lua"),QString(".png"));
		}
	} 
	else if(unlockedMissions>0)
	{
		qDebug("IN HERE !!!");  
		for(unsigned int i=1;i<=unlockedMissions;i++)
		{
			QString missionNum = QString("%1").arg(i);
			imageList += campfile.value(QString("Mission %1/Script").arg(i)).toString().replace(QString(".lua"),QString(".png"));
		}
	}
	return imageList;
}

unsigned int getCampProgress(QString & teamName, QString & campName)
{
    QSettings teamfile(cfgdir->absolutePath() + "/Teams/" + teamName + ".hwt", QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    return teamfile.value("Campaign " + campName + "/Progress", 0).toInt();
}

QMap<QString,QString> getUnlockedMissions2(QString & campaignName, QString & teamName)
{
	QMap<QString,QString> hash;
	QSettings teamfile(cfgdir->absolutePath() + "/Teams/" + teamName + ".hwt", QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    unsigned int progress = teamfile.value("Campaign " + campaignName + "/Progress", 0).toInt();
    qDebug("HERE is progress : %d",progress);
    unsigned int unlockedMissions = teamfile.value("Campaign " + campaignName + "/UnlockedMissions", 0).toInt();
    qDebug("HERE is unlocked missions : %d",unlockedMissions);
    
    QSettings campfile("physfs://Missions/Campaign/" + campaignName + "/campaign.ini", QSettings::IniFormat, 0);
    campfile.setIniCodec("UTF-8");
    unsigned int missionsNumber = campfile.value("MissionNum", 0).toInt();
    qDebug("HERE is number of missions : %d",missionsNumber);  
    
    if(progress>=0 and unlockedMissions==0)
    {
		for(unsigned int i=1;i<=progress+1;i++)
		{
			hash[getCampaignScript(campaignName,i)] = campfile.value(QString("Mission %1/Name").arg(i)).toString();
		}
	} 
	else if(unlockedMissions>0)
	{
		for(unsigned int i=1;i<=unlockedMissions;i++)
		{
			int missionNumber = teamfile.value("Campaign " + campaignName + "/Mission"+i, -1).toInt();
			hash[getCampaignScript(campaignName,missionNumber)] = campfile.value(QString("Mission %1/Name").arg(missionNumber)).toString();
		}
	}
	return hash;
}

QStringList getUnlockedMissions(QString & teamName, QString & campName)
{
	QSettings teamfile(cfgdir->absolutePath() + "/Teams/" + teamName + ".hwt", QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    unsigned int mNum = teamfile.value("UnlockedMissions", 0).toInt();
    
    QStringList missionList;
    for (unsigned int i = 0; i < mNum; i++)
    {
      missionList += teamfile.value(QString("Mission%1").arg(i + 1)).toString();
    }
    return missionList;
}

QString getCampaignScript(QString campaign, unsigned int mNum)
{
    QSettings campfile("physfs://Missions/Campaign/" + campaign + "/campaign.ini", QSettings::IniFormat, 0);
    campfile.setIniCodec("UTF-8");
    return campfile.value(QString("Mission %1/Script").arg(mNum)).toString();
}

QString getCampaignImage(QString campaign, unsigned int mNum)
{
    return getCampaignScript(campaign,mNum).replace(QString(".lua"),QString(".png"));
}

QString getCampaignMissionName(QString campaign, unsigned int mNum)
{
    return getCampaignScript(campaign,mNum).replace(QString(".lua"),QString(""));
}

