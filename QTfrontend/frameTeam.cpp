/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Ulyanov Igor <iulyanov@gmail.com>
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

#include "frameTeam.h"
#include "teamselhelper.h"

#include <QResizeEvent>
#include <QCoreApplication>

using namespace std;

FrameTeams::FrameTeams(QWidget* parent) :
  QWidget(parent), maxHedgehogsPerGame(18), overallHedgehogs(0), mainLayout(this)
{
  mainLayout.setSpacing(1);
}

void FrameTeams::addTeam(HWTeam team, bool willPlay)
{
  TeamShowWidget* pTeamShowWidget =new TeamShowWidget(team, willPlay, this);
//  int hght=teamToWidget.empty() ? 0 : teamToWidget.begin()->second->size().height();
  teamToWidget.insert(make_pair(team, pTeamShowWidget));
  mainLayout.addWidget(pTeamShowWidget);
  QResizeEvent* pevent=new QResizeEvent(parentWidget()->size(), parentWidget()->size());
  QCoreApplication::postEvent(parentWidget(), pevent);
}

void FrameTeams::removeTeam(HWTeam team)
{
  tmapTeamToWidget::iterator it=teamToWidget.find(team);
  mainLayout.removeWidget(it->second);
  delete it->second;
  teamToWidget.erase(team);
}

QWidget* FrameTeams::getTeamWidget(HWTeam team)
{
  tmapTeamToWidget::iterator it=teamToWidget.find(team);
  QWidget* ret = it!=teamToWidget.end() ? it->second : 0;
  return ret;
}

bool FrameTeams::isFullTeams() const
{
  return overallHedgehogs==maxHedgehogsPerGame;
}
