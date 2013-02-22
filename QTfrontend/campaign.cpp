/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QPushButton>
#include <QListWidget>
#include <QStackedLayout>
#include <QLineEdit>
#include <QLabel>
#include <QRadioButton>
#include <QSpinBox>
#include <QCloseEvent>
#include <QCheckBox>
#include <QTextBrowser>
#include <QAction>
#include <QTimer>
#include <QScrollBar>
#include <QDataWidgetMapper>
#include <QTableView>
#include <QCryptographicHash>
#include <QSignalMapper>
#include <QShortcut>
#include <QDesktopServices>
#include <QInputDialog>
#include <QPropertyAnimation>
#include <QSettings>

#include "campaign.h"
#include "gameuiconfig.h"
#include "hwconsts.h"
#include "gamecfgwidget.h"
#include "bgwidget.h"
#include "mouseoverfilter.h"
#include "tcpBase.h"

#include "DataManager.h"

extern QString campaign, campaignTeam;

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

unsigned int getCampProgress(QString & teamName, QString & campName)
{
    QSettings teamfile(cfgdir->absolutePath() + "/Teams/" + teamName + ".hwt", QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    return teamfile.value("Campaign " + campName + "/Progress", 0).toInt();
}

QString getCampaignScript(QString campaign, unsigned int mNum)
{
    QSettings campfile("physfs://Missions/Campaign/" + campaign + "/campaign.ini", QSettings::IniFormat, 0);
    campfile.setIniCodec("UTF-8");
    return campfile.value(QString("Mission %1/Script").arg(mNum)).toString();
}
