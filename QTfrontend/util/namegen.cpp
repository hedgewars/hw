/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2009 Martin Minarik <ttsmj@pokec.sk>
 * Copyright (c) 2009-2011 Andrey Korotaev <unC0Rr@gmail.com>
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
#include <QStringList>
#include <QLineEdit>
#include "namegen.h"
#include "hwform.h"
#include "hwconsts.h"


HWNamegen::HWNamegen() {}

QList<QStringList> HWNamegen::TypesTeamnames;
QList<QStringList> HWNamegen::TypesHatnames;
bool HWNamegen::typesAvailable = false;


void HWNamegen::teamRandomNames(HWTeam & team, const bool changeteamname)
{
    // load types if not already loaded
    if (!typesAvailable)
        if (!loadTypes())
            return; // abort if loading failed

    // abort if there are no hat types
    if (TypesHatnames.size() <= 0)
        return;

    // the hat will influence which names the hogs get
    int kind = (rand()%(TypesHatnames.size()));

    // pick team name based on hat
    if (changeteamname)
    {
        if (TypesTeamnames[kind].size() > 0)
            team.setName(TypesTeamnames[kind][rand()%(TypesTeamnames[kind].size())]);

        team.setGrave(getRandomGrave());
        team.setFort(getRandomFort());
        team.setVoicepack("Default");
    }

    QStringList dicts;
    QStringList dict;

    if ((TypesHatnames[kind].size()) <= 0)
    {
        dicts = dictsForHat(team.hedgehog(0).Hat);
        dict  = dictContents(dicts[rand()%(dicts.size())]);
    }

    for(int i = 0; i < HEDGEHOGS_PER_TEAM; i++)
    {
        if ((TypesHatnames[kind].size()) > 0)
        {
            HWHog hh = team.hedgehog(i);
            hh.Hat = TypesHatnames[kind][rand()%(TypesHatnames[kind].size())];
            team.setHedgehog(i,hh);
        }

        // there is a chance that this hog has the same hat as the previous one
        // let's reuse the hat-specific dict in this case
        if ((i == 0) or (team.hedgehog(i).Hat != team.hedgehog(i-1).Hat))
        {
            dicts = dictsForHat(team.hedgehog(i).Hat);
            dict  = dictContents(dicts[rand()%(dicts.size())]);
        }

        // give each hedgehog a random name
        HWNamegen::teamRandomName(team,i,dict);
    }

}

void HWNamegen::teamRandomName(HWTeam & team, const int HedgehogNumber)
{
    QStringList dicts = dictsForHat(team.hedgehog(HedgehogNumber).Hat);

    QStringList dict = dictContents(dicts[rand()%(dicts.size())]);

    teamRandomName(team, HedgehogNumber, dict);
}

void HWNamegen::teamRandomName(HWTeam & team, const int HedgehogNumber, const QStringList & dict)
{
    QStringList namesDict = dict;

    for(int i = 0; i < HEDGEHOGS_PER_TEAM; i++)
    {
        namesDict.removeOne(team.hedgehog(i).Name);
    }

    // if our dict doesn't have any new names we'll have to use duplicates
    if (namesDict.size() < 1)
        namesDict = dict;

    HWHog hh = team.hedgehog(HedgehogNumber);

    hh.Name = namesDict[rand()%(namesDict.size())];

    team.setHedgehog(HedgehogNumber, hh);
}

QStringList HWNamegen::dictContents(const QString filename)
{
    QStringList list;

    QFile file;

    // find .cfg to load the names from
    file.setFileName(QString("%1/Data/Names/%2.txt").arg(cfgdir->absolutePath()).arg(filename));
    if (!file.exists())
        file.setFileName(QString("%1/Names/%2.txt").arg(datadir->absolutePath()).arg(filename));

    if (file.open(QIODevice::ReadOnly | QIODevice::Text))
    {

        QTextStream in(&file);
        while (!in.atEnd())
        {
            QString line = in.readLine();
            if(!line.isEmpty())
                list.append(line);
        }
    }

    if (list.size() == 0)
         list.append(filename);

    return list;
}


QStringList HWNamegen::dictsForHat(const QString hatname)
{
    QStringList list;

    QFile file;

    // find .cfg to load the names from
    file.setFileName(QString("%1/Data/Names/%2.cfg").arg(cfgdir->absolutePath()).arg(hatname));
    if (!file.exists())
        file.setFileName(QString("%1/Names/%2.cfg").arg(datadir->absolutePath()).arg(hatname));


    if (file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        QTextStream in(&file);
        while (!in.atEnd())
        {
            QString line = in.readLine();
            if(!line.isEmpty())
                list.append(line);
        }
    }

    if (list.size() == 0)
         list.append(QString("generic"));

    return list;
}

// loades types from ini files. returns true on success.
bool HWNamegen::loadTypes()
{
    QFile file;

    // find .cfg to load the names from
    file.setFileName(QString("%1/Data/Names/types.ini").arg(cfgdir->absolutePath()));
    if (!file.exists())
        file.setFileName(QString("%1/Names/types.ini").arg(datadir->absolutePath()));


    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;

    int counter = 0; //counter starts with 0 (teamnames mode)
    TypesTeamnames.append(QStringList());
    TypesHatnames.append(QStringList());

    QTextStream in(&file);
    while (!in.atEnd())
    {
        QString line = in.readLine();
        if (line == QString("#####"))
        {
            counter++; //toggle mode (teamnames || hats)
            if ((counter%2) == 0)
            {
                TypesTeamnames.append(QStringList());
                TypesHatnames.append(QStringList());
            }
        }
        else if ((line == QString("*****")) || (line == QString("*END*")))
        {
            typesAvailable = true;
            return true; // bye bye
        }
        else
        {
            if ((counter%2) == 0)
            {
                // even => teamnames mode
                TypesTeamnames[(counter/2)].append(line);
            }
            else
            {
                // odd => hats mode
                TypesHatnames[((counter-1)/2)].append(line);
            }
        }
    }

    typesAvailable = true;
    return true;
}



QString HWNamegen::getRandomGrave()
{
    QStringList Graves;

    //list all available Graves
    QDir tmpdir;
    tmpdir.cd(cfgdir->absolutePath());
    tmpdir.cd("Data/Graphics/Graves");
    tmpdir.setFilter(QDir::Files);
    Graves.append(tmpdir.entryList(QStringList("*.png")).replaceInStrings(QRegExp("^(.*)\\.png"), "\\1"));

    tmpdir.cd(datadir->absolutePath());
    tmpdir.cd("Graphics/Graves");
    tmpdir.setFilter(QDir::Files);
    QStringList tmpList = tmpdir.entryList(QStringList("*.png")).replaceInStrings(QRegExp("^(.*)\\.png"), "\\1");
    for (QStringList::Iterator it = tmpList.begin(); it != tmpList.end(); ++it) 
        if (!Graves.contains(*it,Qt::CaseInsensitive)) Graves.append(*it);

    if(Graves.size()==0)
    {
        //do some serious error handling
        return "Error";
    }

    //pick a random grave
    return Graves[rand()%(Graves.size())];
}

QString HWNamegen::getRandomFort()
{
    QStringList Forts;

    //list all available Forts
    QDir tmpdir;
    tmpdir.cd(datadir->absolutePath());
    tmpdir.cd("Forts");
    tmpdir.setFilter(QDir::Files);
    Forts.append(tmpdir.entryList(QStringList("*L.png")).replaceInStrings(QRegExp("^(.*)L\\.png"), "\\1"));

    if(Forts.size()==0)
    {
        //do some serious error handling
        return "Error";
    }

    //pick a random fort
    return Forts[rand()%(Forts.size())];
}
