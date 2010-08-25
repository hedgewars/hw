/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QFile>
#include <QTextStream>
#include <QApplication>
#include <QStringList>
#include <QLineEdit>
#include <QCryptographicHash>
#include <QSettings>
#include "team.h"
#include "hwform.h"
#include "pages.h"
#include "hwconsts.h"
#include "hats.h"

HWTeam::HWTeam(const QString & teamname) :
    difficulty(0),
    numHedgehogs(4),
    m_isNetTeam(false)
{
    TeamName = teamname;
    OldTeamName = TeamName;
    for (int i = 0; i < 8; i++)
    {
        Hedgehogs[i].Name.sprintf("hedgehog %d", i);
        Hedgehogs[i].Hat = "NoHat";
    }
    Grave = "Statue";
    Fort = "Plane";
    Voicepack = "Default";
    Flag = "hedgewars";
    for(int i = 0; i < BINDS_NUMBER; i++)
    {
        binds[i].action = cbinds[i].action;
        binds[i].strbind = cbinds[i].strbind;
    }
    Rounds = 0;
    Wins = 0;
    CampaignProgress = 0;
}

HWTeam::HWTeam(const QStringList& strLst) :
  numHedgehogs(4),
  m_isNetTeam(true)
{
    // net teams are configured from QStringList
    if(strLst.size() != 23) throw HWTeamConstructException();
    TeamName = strLst[0];
    Grave = strLst[1];
    Fort = strLst[2];
    Voicepack = strLst[3];
    Flag = strLst[4];
    Owner = strLst[5];
    difficulty = strLst[6].toUInt();
    for(int i = 0; i < 8; i++)
    {
        Hedgehogs[i].Name=strLst[i * 2 + 7];
        Hedgehogs[i].Hat=strLst[i * 2 + 8];
// Somehow claymore managed an empty hat.  Until we figure out how, this should avoid a repeat
// Checking net teams is probably pointless, but can't hurt.
        if (Hedgehogs[i].Hat.length() == 0) Hedgehogs[i].Hat = "NoHat";
    }
    Rounds = 0;
    Wins = 0;
    CampaignProgress = 0;
}

HWTeam::HWTeam() :
  difficulty(0),
  numHedgehogs(4),
  m_isNetTeam(false)
{
    TeamName = QString("Team");
    for (int i = 0; i < 8; i++)
    {
        Hedgehogs[i].Name.sprintf("hedgehog %d", i);
        Hedgehogs[i].Hat = "NoHat";
    }

    Grave = QString("Simple"); // default
    Fort = QString("Island"); // default
    Voicepack = "Default";
    Flag = "hedgewars";

    for(int i = 0; i < BINDS_NUMBER; i++)
    {
        binds[i].action = cbinds[i].action;
        binds[i].strbind = cbinds[i].strbind;
    }
    Rounds = 0;
    Wins = 0;
    CampaignProgress = 0;
}


bool HWTeam::LoadFromFile()
{
    QSettings teamfile(cfgdir->absolutePath() + "/Teams/" + TeamName + ".hwt", QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    TeamName = teamfile.value("Team/Name", TeamName).toString();
    Grave = teamfile.value("Team/Grave", "Statue").toString();
    Fort = teamfile.value("Team/Fort", "Plane").toString();
    Voicepack = teamfile.value("Team/Voicepack", "Default").toString();
    Flag = teamfile.value("Team/Flag", "hedgewars").toString();
    difficulty = teamfile.value("Team/Difficulty", 0).toInt();
    Rounds = teamfile.value("Team/Rounds", 0).toInt();
    Wins = teamfile.value("Team/Wins", 0).toInt();
    CampaignProgress = teamfile.value("Team/CampaignProgress", 0).toInt();
    for(int i = 0; i < 8; i++)
    {
        QString hh = QString("Hedgehog%1/").arg(i);
        Hedgehogs[i].Name = teamfile.value(hh + "Name", QString("hedgehog %1").arg(i)).toString();
        Hedgehogs[i].Hat = teamfile.value(hh + "Hat", "NoHat").toString();
        Hedgehogs[i].Rounds = teamfile.value(hh + "Rounds", 0).toInt();
        Hedgehogs[i].Kills = teamfile.value(hh + "Kills", 0).toInt();
        Hedgehogs[i].Deaths = teamfile.value(hh + "Deaths", 0).toInt();
        Hedgehogs[i].Suicides = teamfile.value(hh + "Suicides", 0).toInt();
    }
    for(int i = 0; i < BINDS_NUMBER; i++)
        binds[i].strbind = teamfile.value(QString("Binds/%1").arg(binds[i].action), cbinds[i].strbind).toString();
    for(int i = 0; i < MAX_ACHIEVEMENTS; i++)
        if(achievements[i][0][0])
            AchievementProgress[i] = teamfile.value(QString("Achievements/%1").arg(achievements[i][0]), 0).toUInt();
        else
            break;
    return true;
}

bool HWTeam::FileExists()
{
    QFile f(cfgdir->absolutePath() + "/Teams/" + TeamName + ".hwt");
    return f.exists();
}

bool HWTeam::DeleteFile()
{
    if(m_isNetTeam)
        return false;
    QFile cfgfile(cfgdir->absolutePath() + "/Teams/" + TeamName + ".hwt");
    cfgfile.remove();
    return true;
}

bool HWTeam::SaveToFile()
{
    if (OldTeamName != TeamName)
    {
        QFile cfgfile(cfgdir->absolutePath() + "/Teams/" + OldTeamName + ".hwt");
        cfgfile.remove();
        OldTeamName = TeamName;
    }
    QSettings teamfile(cfgdir->absolutePath() + "/Teams/" + TeamName + ".hwt", QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    teamfile.setValue("Team/Name", TeamName);
    teamfile.setValue("Team/Grave", Grave);
    teamfile.setValue("Team/Fort", Fort);
    teamfile.setValue("Team/Voicepack", Voicepack);
    teamfile.setValue("Team/Flag", Flag);
    teamfile.setValue("Team/Difficulty", difficulty);
    teamfile.setValue("Team/Rounds", Rounds);
    teamfile.setValue("Team/Wins", Wins);
    teamfile.setValue("Team/CampaignProgress", CampaignProgress);
    for(int i = 0; i < 8; i++)
    {
        QString hh = QString("Hedgehog%1/").arg(i);
        teamfile.setValue(hh + "Name", Hedgehogs[i].Name);
        teamfile.setValue(hh + "Hat", Hedgehogs[i].Hat);
        teamfile.setValue(hh + "Rounds", Hedgehogs[i].Rounds);
        teamfile.setValue(hh + "Kills", Hedgehogs[i].Kills);
        teamfile.setValue(hh + "Deaths", Hedgehogs[i].Deaths);
        teamfile.setValue(hh + "Suicides", Hedgehogs[i].Suicides);
    }
    for(int i = 0; i < BINDS_NUMBER; i++)
        teamfile.setValue(QString("Binds/%1").arg(binds[i].action), binds[i].strbind);
    for(int i = 0; i < MAX_ACHIEVEMENTS; i++)
        if(achievements[i][0][0])
            teamfile.setValue(QString("Achievements/%1").arg(achievements[i][0]), AchievementProgress[i]);
        else
            break;
    return true;
}

void HWTeam::SetToPage(HWForm * hwform)
{
    hwform->ui.pageEditTeam->TeamNameEdit->setText(TeamName);
    hwform->ui.pageEditTeam->CBTeamLvl->setCurrentIndex(difficulty);
    for(int i = 0; i < 8; i++)
    {
         hwform->ui.pageEditTeam->HHNameEdit[i]->setText(Hedgehogs[i].Name);
         if (Hedgehogs[i].Hat.startsWith("Reserved"))
            hwform->ui.pageEditTeam->HHHats[i]->setCurrentIndex(hwform->ui.pageEditTeam->HHHats[i]->findData("Reserved "+Hedgehogs[i].Hat.remove(0,40), Qt::DisplayRole));
         else
            hwform->ui.pageEditTeam->HHHats[i]->setCurrentIndex(hwform->ui.pageEditTeam->HHHats[i]->findData(Hedgehogs[i].Hat, Qt::DisplayRole));
    }
    hwform->ui.pageEditTeam->CBGrave->setCurrentIndex(hwform->ui.pageEditTeam->CBGrave->findText(Grave));
    hwform->ui.pageEditTeam->CBFlag->setCurrentIndex(hwform->ui.pageEditTeam->CBFlag->findData(Flag));

    hwform->ui.pageEditTeam->CBFort->setCurrentIndex(hwform->ui.pageEditTeam->CBFort->findText(Fort));
    hwform->ui.pageEditTeam->CBVoicepack->setCurrentIndex(hwform->ui.pageEditTeam->CBVoicepack->findText(Voicepack));
    //hwform->ui.pageEditTeam->CBFort_activated(Fort);

    for(int i = 0; i < BINDS_NUMBER; i++)
    {
        hwform->ui.pageEditTeam->CBBind[i]->setCurrentIndex(hwform->ui.pageEditTeam->CBBind[i]->findData(binds[i].strbind));
    }
}

void HWTeam::GetFromPage(HWForm * hwform)
{
    TeamName  = hwform->ui.pageEditTeam->TeamNameEdit->text();
    difficulty = hwform->ui.pageEditTeam->CBTeamLvl->currentIndex();
    for(int i = 0; i < 8; i++)
    {
        Hedgehogs[i].Name = hwform->ui.pageEditTeam->HHNameEdit[i]->text();
        if (hwform->ui.pageEditTeam->HHHats[i]->currentText().startsWith("Reserved"))
            Hedgehogs[i].Hat = "Reserved"+playerHash+hwform->ui.pageEditTeam->HHHats[i]->currentText().remove(0,9);
        else
            Hedgehogs[i].Hat = hwform->ui.pageEditTeam->HHHats[i]->currentText();
    }

    Grave = hwform->ui.pageEditTeam->CBGrave->currentText();
    Fort = hwform->ui.pageEditTeam->CBFort->currentText();
    Voicepack = hwform->ui.pageEditTeam->CBVoicepack->currentText();
    Flag = hwform->ui.pageEditTeam->CBFlag->itemData(hwform->ui.pageEditTeam->CBFlag->currentIndex()).toString();
    for(int i = 0; i < BINDS_NUMBER; i++)
    {
        binds[i].strbind = hwform->ui.pageEditTeam->CBBind[i]->itemData(hwform->ui.pageEditTeam->CBBind[i]->currentIndex()).toString();
    }
}

QStringList HWTeam::TeamGameConfig(quint32 InitHealth) const
{
    QStringList sl;
    if (m_isNetTeam)
    {
        sl.push_back(QString("eaddteam %3 %1 %2").arg(teamColor.rgb() & 0xffffff).arg(TeamName).arg(QString(QCryptographicHash::hash(Owner.toLatin1(), QCryptographicHash::Md5).toHex())));
        sl.push_back("erdriven");
    }
    else sl.push_back(QString("eaddteam %3 %1 %2").arg(teamColor.rgb() & 0xffffff).arg(TeamName).arg(playerHash));

    sl.push_back(QString("egrave " + Grave));
    sl.push_back(QString("efort " + Fort));
    sl.push_back(QString("evoicepack " + Voicepack));
    sl.push_back(QString("eflag " + Flag));

    if (!m_isNetTeam)
        for(int i = 0; i < BINDS_NUMBER; i++)
            if(!binds[i].strbind.isEmpty())
                sl.push_back(QString("ebind " + binds[i].strbind + " " + binds[i].action));

    for (int t = 0; t < numHedgehogs; t++)
    {
      sl.push_back(QString("eaddhh %1 %2 %3")
               .arg(QString::number(difficulty),
                QString::number(InitHealth),
                Hedgehogs[t].Name));
      sl.push_back(QString("ehat %1")
               .arg(Hedgehogs[t].Hat));
    }
    return sl;
}

bool HWTeam::isNetTeam() const
{
  return m_isNetTeam;
}


bool HWTeam::operator==(const HWTeam& t1) const {
  return TeamName==t1.TeamName;
}

bool HWTeam::operator<(const HWTeam& t1) const {
  return TeamName<t1.TeamName; // if names are equal - test if it is net team
}


