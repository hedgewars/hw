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
#include <QFileInfo>
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

void HWNamegen::teamRandomTeamName(HWTeam & team)
{
    QString newName = getRandomTeamName(-1);
    if(!newName.isNull())
        team.setName(newName);
}

void HWNamegen::teamRandomFlag(HWTeam & team, bool withDLC)
{
    team.setFlag(getRandomFlag(withDLC));
}

void HWNamegen::teamRandomVoice(HWTeam & team, bool withDLC)
{
    team.setVoicepack(getRandomVoice(withDLC));
}

void HWNamegen::teamRandomGrave(HWTeam & team, bool withDLC)
{
    team.setGrave(getRandomGrave(withDLC));
}

void HWNamegen::teamRandomFort(HWTeam & team, bool withDLC)
{
    team.setFort(getRandomFort(withDLC));
}

void HWNamegen::teamRandomEverything(HWTeam & team, const RandomTeamMode mode)
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
    if (mode == HWNamegen::rtmEverything)
    {        team.setName(getRandomTeamName(kind));
        team.setGrave(getRandomGrave());
        team.setFort(getRandomFort());
        team.setFlag(getRandomFlag());
        team.setVoicepack(getRandomVoice());
    }

    QStringList dicts;
    QStringList dict;

    if ((mode == HWNamegen::rtmHogNames || mode == HWNamegen::rtmEverything) && (TypesHatnames[kind].size()) <= 0)
    {
        dicts = dictsForHat(team.hedgehog(0).Hat);
        dict  = dictContents(dicts[rand()%(dicts.size())]);
    }

    for(int i = 0; i < HEDGEHOGS_PER_TEAM; i++)
    {
        if (mode == HWNamegen::rtmEverything && (TypesHatnames[kind].size()) > 0)
        {
            HWHog hh = team.hedgehog(i);
            hh.Hat = TypesHatnames[kind][rand()%(TypesHatnames[kind].size())];
            team.setHedgehog(i,hh);
        }
        else if (mode == HWNamegen::rtmHats)
        {
            HWNamegen::teamRandomHat(team,i);
        }

        // there is a chance that this hog has the same hat as the previous one
        // let's reuse the hat-specific dict in this case
        if ( (mode == HWNamegen::rtmHogNames || mode == HWNamegen::rtmEverything) && ((i == 0) || (team.hedgehog(i).Hat != team.hedgehog(i-1).Hat)))
        {
            dicts = dictsForHat(team.hedgehog(i).Hat);
            dict  = dictContents(dicts[rand()%(dicts.size())]);
        }

        // give each hedgehog a random name
        if (mode == HWNamegen::rtmHogNames || mode == HWNamegen::rtmEverything)
            HWNamegen::teamRandomHogName(team,i,dict);
    }

}

void HWNamegen::teamRandomHat(HWTeam & team, const int HedgehogNumber, bool withDLC)
{
    HWHog hh = team.hedgehog(HedgehogNumber);

    hh.Hat = getRandomHat(withDLC);

    team.setHedgehog(HedgehogNumber, hh);
}

void HWNamegen::teamRandomHat(HWTeam & team, const int HedgehogNumber, const QStringList & dict)
{
    HWHog hh = team.hedgehog(HedgehogNumber);

    hh.Name = dict[rand()%(dict.size())];

    team.setHedgehog(HedgehogNumber, hh);
}

void HWNamegen::teamRandomHogName(HWTeam & team, const int HedgehogNumber)
{
    QStringList dicts = dictsForHat(team.hedgehog(HedgehogNumber).Hat);

    QStringList dict = dictContents(dicts[rand()%(dicts.size())]);

    teamRandomHogName(team, HedgehogNumber, dict);
}

void HWNamegen::teamRandomHogName(HWTeam & team, const int HedgehogNumber, const QStringList & dict)
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

    // Find and check .cfg to load the dicts from
    QString path = QString("physfs://Names/%1.cfg").arg(hatname);
    QFileInfo check_file(path);

    // Note: The .cfg file is optional; a fallback mechanism is in place (see below)

    // Check if file exists to prevent PhysFS from complaining in console so much
    if (check_file.exists() && check_file.isFile())
    {
        QFile file(path);

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
    }

    // Use Data/Names/generic.cfg by default
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

/* Generates a random team name.
kind: Use to select a team name out of a group (types.ini).
Use a negative value if you don't care.
This function may return a null QString on error(this should never happen). */
QString HWNamegen::getRandomTeamName(int kind)
{
    // load types if not already loaded
    if (!typesAvailable)
        if (!loadTypes())
            return QString(); // abort if loading failed

    // abort if there are no hat types
    if (TypesHatnames.size() <= 0)
        return QString();

    if(kind < 0)
        kind = (rand()%(TypesHatnames.size()));

    if (TypesTeamnames[kind].size() > 0)
        return TypesTeamnames[kind][rand()%(TypesTeamnames[kind].size())];
    else
        return QString();
}

QString HWNamegen::getRandomHat(bool withDLC)
{
    QStringList Hats;

    // list all available hats
    Hats.append(DataManager::instance().entryList(
                      "Graphics/Hats",
                      QDir::Files,
                      QStringList("*.png"),
                      withDLC
                  ).replaceInStrings(QRegExp("\\.png$"), "")
                 );

    if(Hats.size()==0)
    {
        // TODO do some serious error handling
        return "Error";
    }

    // pick a random hat
    return Hats[rand()%(Hats.size())];
}

QString HWNamegen::getRandomGrave(bool withDLC)
{
    QStringList Graves;

    //list all available Graves
    Graves.append(DataManager::instance().entryList(
                      "Graphics/Graves",
                      QDir::Files,
                      QStringList("*.png"),
                      withDLC
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

QString HWNamegen::getRandomFlag(bool withDLC)
{
    QStringList Flags;

    //list all available flags
    Flags.append(DataManager::instance().entryList(
                      "Graphics/Flags",
                      QDir::Files,
                      QStringList("*.png"),
                      withDLC
                  ).replaceInStrings(QRegExp("\\.png$"), "")
                 );
    //remove internal flags
    Flags.removeAll("cpu");
    Flags.removeAll("cpu_plain");

    if(Flags.size()==0)
    {
        // TODO do some serious error handling
        return "Error";
    }

    //pick a random flag
    return Flags[rand()%(Flags.size())];
}

QString HWNamegen::getRandomFort(bool withDLC)
{
    QStringList Forts;

    //list all available Forts
    Forts.append(DataManager::instance().entryList(
                     "Forts",
                     QDir::Files,
                     QStringList("*L.png"),
                     withDLC
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

QString HWNamegen::getRandomVoice(bool withDLC)
{
    QStringList Voices;

    //list all available voices 
    Voices.append(DataManager::instance().entryList(
                     "Sounds/voices",
                     QDir::Dirs | QDir::NoDotAndDotDot,
                     QStringList("*"),
                     withDLC));

    if(Voices.size()==0)
    {
        // TODO do some serious error handling
        return "Error";
    }

    //pick a random voice
    return Voices[rand()%(Voices.size())];
}
