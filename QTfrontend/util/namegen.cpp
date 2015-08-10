/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2009 Martin Minarik <ttsmj@pokec.sk>
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

#include "hwform.h"
#include "DataManager.h"

#include "namegen.h"

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
        if ((i == 0) || (team.hedgehog(i).Hat != team.hedgehog(i-1).Hat))
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

    // find .txt to load the names from
    QFile file(QString("physfs://Names/%1.txt").arg(filename));

    if (file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        QTextStream in(&file);
        QString line;
        do
        {
            line = in.readLine();

            if(!line.isEmpty())
                list.append(line);
        } while (!line.isNull());
    }

    if (list.size() == 0)
        list.append(filename);

    return list;
}


QStringList HWNamegen::dictsForHat(const QString hatname)
{
    QStringList list;

    // find .cfg to load the dicts from
    QFile file(QString("physfs://Names/%1.cfg").arg(hatname));

    if (file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        QTextStream in(&file);
        QString line;
        do
        {
            line = in.readLine();

            if(!line.isEmpty())
                list.append(line);
        } while (!line.isNull());
    }

    if (list.size() == 0)
        list.append(QString("generic"));

    return list;
}

// loades types from ini files. returns true on success.
bool HWNamegen::loadTypes()
{
    typesAvailable = false;

    // find .ini to load the names from
    QFile * file = new QFile(QString("physfs://Names/types.ini"));


    if (file->exists() && file->open(QIODevice::ReadOnly | QIODevice::Text))
    {

        int counter = 0; //counter starts with 0 (teamnames mode)
        TypesTeamnames.append(QStringList());
        TypesHatnames.append(QStringList());

        QTextStream in(file);
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
    }

    // this QFile isn't needed any further
    delete file;

    return typesAvailable;
}



QString HWNamegen::getRandomGrave()
{
    QStringList Graves;

    //list all available Graves
    Graves.append(DataManager::instance().entryList(
                      "Graphics/Graves",
                      QDir::Files,
                      QStringList("*.png")
                  ).replaceInStrings(QRegExp("\\.png$"), "")
                 );

    if(Graves.size()==0)
    {
        // TODO do some serious error handling
        return "Error";
    }

    //pick a random grave
    return Graves[rand()%(Graves.size())];
}

QString HWNamegen::getRandomFort()
{
    QStringList Forts;

    //list all available Forts
    Forts.append(DataManager::instance().entryList(
                     "Forts",
                     QDir::Files,
                     QStringList("*L.png")
                 ).replaceInStrings(QRegExp("L\\.png$"), "")
                );

    if(Forts.size()==0)
    {
        // TODO do some serious error handling
        return "Error";
    }

    //pick a random fort
    return Forts[rand()%(Forts.size())];
}
