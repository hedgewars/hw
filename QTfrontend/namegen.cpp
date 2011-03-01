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
#include <QApplication>
#include <QStringList>
#include <QLineEdit>
#include "namegen.h"
#include "hwform.h"
#include "hwconsts.h"


HWNamegen::HWNamegen() :
    TypesAvliable(false)
{

    TypesLoad();
}

HWNamegen::~HWNamegen()
{
}



void HWNamegen::TeamRandomName(HWTeam*& team, const int &i)
{
    RandomNameByHat(team,i);
}

void HWNamegen::TeamRandomNames(HWTeam*& team, const bool changeteamname)
{
    if ((TypesHatnames.size() > 0) && TypesAvliable){

        int kind = (rand()%(TypesHatnames.size()));

        if (changeteamname){
            if (TypesTeamnames[kind].size() > 0){
                team->TeamName = TypesTeamnames[kind][rand()%(TypesTeamnames[kind].size())];
            }
            team->Grave = "Simple"; // Todo: make it semi-random
            team->Fort = "Island"; // Todo: make it semi-random
            team->Voicepack = "Default";
        }

        for(int i = 0; i < 8; i++)
        {
            if ((TypesHatnames[kind].size()) > 0){
                team->Hedgehogs[i].Hat = TypesHatnames[kind][rand()%(TypesHatnames[kind].size())];
            }
            RandomNameByHat(team,i);
        }

    }

}


void HWNamegen::RandomNameByHat(HWTeam*& team, const int &i)
{
    QStringList Dictionaries;
    HatCfgLoad(team->Hedgehogs[i].Hat,Dictionaries);

    QStringList Dictionary;
    DictLoad(Dictionaries[rand()%(Dictionaries.size())],Dictionary);

    team->Hedgehogs[i].Name = Dictionary[rand()%(Dictionary.size())];
}

void HWNamegen::DictLoad(const QString filename, QStringList &list)
{
     list.clear();

     QFile file(QString("%1/Names/%2.txt").arg(datadir->absolutePath()).arg(filename));
     if (file.open(QIODevice::ReadOnly | QIODevice::Text))
     {

         QTextStream in(&file);
         while (!in.atEnd()) {
             QString line = in.readLine();
             if(line != QString(""))
                 {list.append(line);}
         }
     }

     if (list.size()==0)
         list.append(filename);

}


void HWNamegen::HatCfgLoad(const QString hatname, QStringList &list)
{
     list.clear();

     QFile file(QString("%1/Names/%2.cfg").arg(datadir->absolutePath()).arg(hatname));
     if (file.open(QIODevice::ReadOnly | QIODevice::Text))
     {

         QTextStream in(&file);
         while (!in.atEnd()) {
             QString line = in.readLine();
             if(line != QString(""))
                 {list.append(line);}
         }
     }

     if (list.size()==0)
         list.append(QString("generic"));

}


void HWNamegen::TypesLoad()
{

     QFile file(QString("%1/Names/types.ini").arg(datadir->absolutePath()));
     if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
         {TypesAvliable = FALSE; return;}

     int counter = 0; //counter starts with 0 (teamnames mode)
     TypesTeamnames.append(QStringList());
     TypesHatnames.append(QStringList());

     QTextStream in(&file);
     while (!in.atEnd()) {
         QString line = in.readLine();
         if (line == QString("#####")){
             counter++; //toggle mode (teamnames || hats)
             if ((counter%2) == 0){
                 TypesTeamnames.append(QStringList());
                 TypesHatnames.append(QStringList());
             }
         } else if ((line == QString("*****")) || (line == QString("*END*"))){
             TypesAvliable = TRUE; return; // bye bye
         } else {
             if ((counter%2) == 0){ // even => teamnames mode
                 TypesTeamnames[(counter/2)].append(line);
             } else { // odd => hats mode
                 TypesHatnames[((counter-1)/2)].append(line);
             }
         }
//         Types.append(line);
     }
         TypesAvliable = TRUE;
     return;
}


