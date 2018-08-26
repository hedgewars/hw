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

#include <QFile>
#include <QTextStream>
#include <QStringList>
#include <QLineEdit>
#include <QCryptographicHash>
#include <QSettings>
#include <QStandardItemModel>
#include <QDebug>

#include "team.h"
#include "hwform.h"
#include "DataManager.h"
#include "gameuiconfig.h"

HWTeam::HWTeam(const QString & teamname) :
    QObject(0)
    , m_difficulty(0)
    , m_numHedgehogs(4)
    , m_isNetTeam(false)
{
    m_name = teamname;
    OldTeamName = m_name;
    for (int i = 0; i < HEDGEHOGS_PER_TEAM; i++)
    {
        m_hedgehogs.append(HWHog());
        m_hedgehogs[i].Name = (QLineEdit::tr("Hedgehog %1").arg(i+1));
        m_hedgehogs[i].Hat = "NoHat";
    }
    m_grave = "Statue";
    m_fort = "Plane";
    m_voicepack = "Default";
    m_flag = "hedgewars";
    for(int i = 0; i < BINDS_NUMBER; i++)
    {
        m_binds.append(BindAction());
        m_binds[i].action = cbinds[i].action;
        m_binds[i].strbind = QString();
    }
    m_color = 0;
}

HWTeam::HWTeam(const QStringList& strLst) :
    QObject(0)
    , m_numHedgehogs(4)
    , m_isNetTeam(true)
{
    // net teams are configured from QStringList
    if(strLst.size() != 23) throw HWTeamConstructException();
    m_name = strLst[0];
    m_grave = strLst[1];
    m_fort = strLst[2];
    m_voicepack = strLst[3];
    m_flag = strLst[4];
    m_owner = strLst[5];
    m_difficulty = strLst[6].toUInt();
    for(int i = 0; i < HEDGEHOGS_PER_TEAM; i++)
    {
        m_hedgehogs.append(HWHog());
        m_hedgehogs[i].Name=strLst[i * 2 + 7];
        m_hedgehogs[i].Hat=strLst[i * 2 + 8];
// Somehow claymore managed an empty hat.  Until we figure out how, this should avoid a repeat
// Checking net teams is probably pointless, but can't hurt.
        if (m_hedgehogs[i].Hat.isEmpty()) m_hedgehogs[i].Hat = "NoHat";
    }
    m_color = 0;
}

HWTeam::HWTeam() :
    QObject(0)
    , m_difficulty(0)
    , m_numHedgehogs(4)
    , m_isNetTeam(false)
{
    m_name = QString("Team");
    for (int i = 0; i < HEDGEHOGS_PER_TEAM; i++)
    {
        m_hedgehogs.append(HWHog());
        m_hedgehogs[i].Name.sprintf("hedgehog %d", i);
        m_hedgehogs[i].Hat = "NoHat";
    }

    m_grave = QString("Simple"); // default
    m_fort = QString("Island"); // default
    m_voicepack = "Default";
    m_flag = "hedgewars";

    for(int i = 0; i < BINDS_NUMBER; i++)
    {
        m_binds.append(BindAction());
        m_binds[i].action = cbinds[i].action;
        m_binds[i].strbind = QString();
    }
    m_color = 0;
}

HWTeam::HWTeam(const HWTeam & other) :
    QObject(0)
    , OldTeamName(other.OldTeamName)
    , m_name(other.m_name)
    , m_grave(other.m_grave)
    , m_fort(other.m_fort)
    , m_flag(other.m_flag)
    , m_voicepack(other.m_voicepack)
    , m_hedgehogs(other.m_hedgehogs)
    , m_difficulty(other.m_difficulty)
    , m_binds(other.m_binds)
    , m_numHedgehogs(other.m_numHedgehogs)
    , m_color(other.m_color)
    , m_isNetTeam(other.m_isNetTeam)
    , m_owner(other.m_owner)
//      , AchievementProgress(other.AchievementProgress)
{

}

HWTeam & HWTeam::operator = (const HWTeam & other)
{
    if(this != &other)
    {
        OldTeamName = other.OldTeamName;
        m_name = other.m_name;
        m_grave = other.m_grave;
        m_fort = other.m_fort;
        m_flag = other.m_flag;
        m_voicepack = other.m_voicepack;
        m_hedgehogs = other.m_hedgehogs;
        m_difficulty = other.m_difficulty;
        m_binds = other.m_binds;
        m_numHedgehogs = other.m_numHedgehogs;
        m_color = other.m_color;
        m_isNetTeam = other.m_isNetTeam;
        m_owner = other.m_owner;
        m_color = other.m_color;
    }

    return *this;
}

bool HWTeam::loadFromFile()
{
    QSettings teamfile(QString(cfgdir->absolutePath() + "/Teams/%1.hwt").arg(DataManager::safeFileName(m_name)), QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    m_name = teamfile.value("Team/Name", m_name).toString();
    m_grave = teamfile.value("Team/Grave", "Statue").toString();
    m_fort = teamfile.value("Team/Fort", "Plane").toString();
    m_voicepack = teamfile.value("Team/Voicepack", "Default").toString();
    m_flag = teamfile.value("Team/Flag", "hedgewars").toString();
    m_difficulty = teamfile.value("Team/Difficulty", 0).toInt();
    for(int i = 0; i < HEDGEHOGS_PER_TEAM; i++)
    {
        QString hh = QString("Hedgehog%1/").arg(i);
        m_hedgehogs[i].Name = teamfile.value(hh + "Name", QString("Hedgehog %1").arg(i+1)).toString();
        m_hedgehogs[i].Hat = teamfile.value(hh + "Hat", "NoHat").toString();
    }
    for(int i = 0; i < BINDS_NUMBER; i++)
        m_binds[i].strbind = teamfile.value(QString("Binds/%1").arg(m_binds[i].action), QString()).toString();
    for(int i = 0; i < MAX_ACHIEVEMENTS; i++)
        if(achievements[i][0][0])
            AchievementProgress[i] = teamfile.value(QString("Achievements/%1").arg(achievements[i][0]), 0).toUInt();
        else
            break;
    return true;
}

bool HWTeam::fileExists()
{
    QFile f(QString(cfgdir->absolutePath() + "/Teams/%1.hwt").arg(DataManager::safeFileName(m_name)));
    return f.exists();
}

// Returns true if the team name has been changed but a file with the same team name already exists.
// So if this team would be saved, another team file would be overwritten, which is generally not
// desired.
bool HWTeam::wouldOverwriteOtherFile()
{
    return (m_name != OldTeamName) && fileExists();
}

bool HWTeam::deleteFile()
{
    if(m_isNetTeam)
        return false;
    QFile cfgfile(QString(cfgdir->absolutePath() + "/Teams/%1.hwt").arg(DataManager::safeFileName(m_name)));
    cfgfile.remove();
    return true;
}

bool HWTeam::saveToFile()
{
    if (OldTeamName != m_name)
    {
        QFile cfgfile(QString(cfgdir->absolutePath() + "/Teams/%1.hwt").arg(DataManager::safeFileName(OldTeamName)));
        cfgfile.remove();
        OldTeamName = m_name;
    }

    QString fileName = QString(cfgdir->absolutePath() + "/Teams/%1.hwt").arg(DataManager::safeFileName(m_name));
    DataManager::ensureFileExists(fileName);
    QSettings teamfile(fileName, QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    teamfile.setValue("Team/Name", m_name);
    teamfile.setValue("Team/Grave", m_grave);
    teamfile.setValue("Team/Fort", m_fort);
    teamfile.setValue("Team/Voicepack", m_voicepack);
    teamfile.setValue("Team/Flag", m_flag);
    teamfile.setValue("Team/Difficulty", m_difficulty);

    for(int i = 0; i < HEDGEHOGS_PER_TEAM; i++)
    {
        QString hh = QString("Hedgehog%1/").arg(i);
        teamfile.setValue(hh + "Name", m_hedgehogs[i].Name);
        teamfile.setValue(hh + "Hat", m_hedgehogs[i].Hat);
    }
    for(int i = 0; i < BINDS_NUMBER; i++)
        teamfile.setValue(QString("Binds/%1").arg(m_binds[i].action), m_binds[i].strbind);
    for(int i = 0; i < MAX_ACHIEVEMENTS; i++)
        if(achievements[i][0][0])
            teamfile.setValue(QString("Achievements/%1").arg(achievements[i][0]), AchievementProgress[i]);
        else
            break;

    return true;
}

QStringList HWTeam::teamGameConfig(quint32 InitHealth) const
{
    QStringList sl;
    if (m_isNetTeam)
    {
        sl.push_back(QString("eaddteam %3 %1 %2").arg(qcolor().rgb() & 0xffffff).arg(m_name).arg(QString(QCryptographicHash::hash(m_owner.toUtf8(), QCryptographicHash::Md5).toHex())));
        sl.push_back("erdriven");
    }
    else sl.push_back(QString("eaddteam %3 %1 %2").arg(qcolor().rgb() & 0xffffff).arg(m_name).arg(playerHash));

    sl.push_back(QString("egrave " + m_grave));
    sl.push_back(QString("efort " + m_fort));
    sl.push_back(QString("evoicepack " + m_voicepack));
    sl.push_back(QString("eflag " + m_flag));

    if(!m_owner.isEmpty())
        sl.push_back(QString("eowner ") + m_owner);

    for (int t = 0; t < m_numHedgehogs; t++)
    {
        sl.push_back(QString("eaddhh %1 %2 %3")
                     .arg(QString::number(m_difficulty),
                          QString::number(InitHealth),
                          m_hedgehogs[t].Name));
        sl.push_back(QString("ehat %1")
                     .arg(m_hedgehogs[t].Hat));
    }
    return sl;
}


void HWTeam::setNetTeam(bool isNetTeam)
{
    m_isNetTeam = isNetTeam;
}

bool HWTeam::isNetTeam() const
{
    return m_isNetTeam;
}


bool HWTeam::operator==(const HWTeam& t1) const
{
    return m_name==t1.m_name;
}

bool HWTeam::operator<(const HWTeam& t1) const
{
    return m_name<t1.m_name; // if names are equal - test if it is net team
}


//// Methods for member inspection+modification ////


// name
QString HWTeam::name() const
{
    return m_name;
}
void HWTeam::setName(const QString & name)
{
    m_name = name;
}

// single hedgehog
const HWHog & HWTeam::hedgehog(unsigned int idx) const
{
    return m_hedgehogs[idx];
}
void HWTeam::setHedgehog(unsigned int idx, HWHog hh)
{
    m_hedgehogs[idx] = hh;
}

// owner
QString HWTeam::owner() const
{
    return m_owner;
}



// difficulty
unsigned int HWTeam::difficulty() const
{
    return m_difficulty;
}
void HWTeam::setDifficulty(unsigned int level)
{
    m_difficulty = level;
}

// color
int HWTeam::color() const
{
    return m_color;
}

QColor HWTeam::qcolor() const
{
    return DataManager::instance().colorsModel()->item(m_color)->data().value<QColor>();
}

void HWTeam::setColor(int color)
{
    m_color = color % DataManager::instance().colorsModel()->rowCount();
}


// binds
QString HWTeam::keyBind(unsigned int idx) const
{
    return m_binds[idx].strbind;
}
void HWTeam::bindKey(unsigned int idx, const QString & key)
{
    m_binds[idx].strbind = key;
}

// flag
void    HWTeam::setFlag(const QString & flag)
{
    m_flag = flag;
}
QString HWTeam::flag() const
{
    return m_flag;
}

// fort
void    HWTeam::setFort(const QString & fort)
{
    m_fort = fort;
}
QString HWTeam::fort() const
{
    return m_fort;
}

// grave
void HWTeam::setGrave(const QString & grave)
{
    m_grave = grave;
}
QString HWTeam::grave() const
{
    return m_grave;
}

// voicepack - getter/setter
void HWTeam::setVoicepack(const QString & voicepack)
{
    m_voicepack = voicepack;
}
QString HWTeam::voicepack() const
{
    return m_voicepack;
}

// amount of hedgehogs
unsigned char HWTeam::numHedgehogs() const
{
    return m_numHedgehogs;
}
void HWTeam::setNumHedgehogs(unsigned char num)
{
    m_numHedgehogs = num;
}

