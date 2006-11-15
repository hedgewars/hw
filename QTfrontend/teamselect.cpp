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

#include <QLabel>
#include <QPixmap>
#include <QPushButton>
#include <QFrame>

#include <vertScrollArea.h>
#include "teamselect.h"
#include "teamselhelper.h"
#include "frameTeam.h"

void TeamSelWidget::addTeam(HWTeam team)
{
  frameDontPlaying->addTeam(team, false);
  curDontPlayingTeams.push_back(team);
  QObject::connect(frameDontPlaying->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
		   this, SLOT(changeTeamStatus(HWTeam)));
}

//void TeamSelWidget::removeTeam(__attribute__ ((unused)) HWTeam team)
//{
  //curDontPlayingTeams.erase(std::find(curDontPlayingTeams.begin(), curDontPlayingTeams.end(), team));
//}

void TeamSelWidget::changeTeamStatus(HWTeam team)
{
  list<HWTeam>::iterator itDontPlay=std::find(curDontPlayingTeams.begin(), curDontPlayingTeams.end(), team);
  list<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);

  bool willBePlaying=itDontPlay!=curDontPlayingTeams.end();

  if(!willBePlaying) {
    // playing team => dont playing
    curDontPlayingTeams.push_back(*itPlay);
    curPlayingTeams.erase(itPlay);
  } else {
    // return if max playing teams reached
    if(framePlaying->isFullTeams()) return;
    // dont playing team => playing
    curPlayingTeams.push_back(*itDontPlay);
    curDontPlayingTeams.erase(itDontPlay);
  }

  FrameTeams* pRemoveTeams;
  FrameTeams* pAddTeams;
  if(!willBePlaying) {
    pRemoveTeams=framePlaying;
    pAddTeams=frameDontPlaying;
  } else {
    pRemoveTeams=frameDontPlaying;
    pAddTeams=framePlaying;
  }

  pAddTeams->addTeam(team, willBePlaying);
  pRemoveTeams->removeTeam(team);
  QObject::connect(pAddTeams->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
		   this, SLOT(changeTeamStatus(HWTeam)));

  QSize szh=pAddTeams->sizeHint();
  QSize szh1=pRemoveTeams->sizeHint();
  if(szh.isValid() && szh1.isValid()) {
    pAddTeams->resize(pAddTeams->size().width(), szh.height());
    pRemoveTeams->resize(pRemoveTeams->size().width(), szh1.height());
  }
}

void TeamSelWidget::addScrArea(FrameTeams* pfteams, QColor color)
{
  VertScrArea* area=new VertScrArea(color);
  area->setWidget(pfteams);
  mainLayout.addWidget(area, 30);
}

TeamSelWidget::TeamSelWidget(QWidget* parent) :
  QGroupBox(parent), mainLayout(this)
{
  setTitle(QGroupBox::tr("Playing teams"));
  framePlaying=new FrameTeams();
  frameDontPlaying=new FrameTeams();
//  addScrArea(framePlaying, QColor("DarkTurquoise"));
//  addScrArea(frameDontPlaying, QColor("LightGoldenrodYellow"));
  QPalette p;
  addScrArea(framePlaying, p.color(QPalette::Window).light(105));
  addScrArea(frameDontPlaying, p.color(QPalette::Window).dark(105));
}

void TeamSelWidget::resetPlayingTeams(const QList<HWTeam>& teamslist)
{
  list<HWTeam>::iterator it;
  for(it=curPlayingTeams.begin(); it!=curPlayingTeams.end(); it++) {
    framePlaying->removeTeam(*it);
  }
  framePlaying->resetColors();
  curPlayingTeams.clear();
  for(it=curDontPlayingTeams.begin(); it!=curDontPlayingTeams.end(); it++) {
    frameDontPlaying->removeTeam(*it);
  }
  curDontPlayingTeams.clear();

  for (QList<HWTeam>::ConstIterator it = teamslist.begin(); it != teamslist.end(); ++it ) {
    addTeam(*it);
  }
}

bool TeamSelWidget::isPlaying(HWTeam team) const
{
  return std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team)!=curPlayingTeams.end();
}

list<HWTeam> TeamSelWidget::getPlayingTeams() const
{
  return curPlayingTeams;
}

HWTeamTempParams TeamSelWidget::getTeamParams(HWTeam team) const
{
  const TeamShowWidget* tsw=dynamic_cast<TeamShowWidget*>(framePlaying->getTeamWidget(team));
  if(!tsw) throw;
  return tsw->getTeamParams();
}
