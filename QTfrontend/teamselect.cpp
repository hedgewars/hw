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
  if(team.isNetTeam()) {
    framePlaying->addTeam(team, true);
    curPlayingTeams.push_back(team);
    connect(framePlaying->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
		     this, SLOT(netTeamStatusChanged(const HWTeam&)));
  } else {
    frameDontPlaying->addTeam(team, false);
    curDontPlayingTeams.push_back(team);
    QObject::connect(frameDontPlaying->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
		     this, SLOT(changeTeamStatus(HWTeam)));
  }
}

void TeamSelWidget::hhNumChanged(const HWTeam& team)
{
  QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);
  itPlay->numHedgehogs=team.numHedgehogs;
  emit hhogsNumChanged(team);
}

void TeamSelWidget::changeHHNum(const HWTeam& team)
{
  QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);
  itPlay->numHedgehogs=team.numHedgehogs;

  framePlaying->setHHNum(team);
}

void TeamSelWidget::removeNetTeam(const HWTeam& team)
{
  for(;;) {
    QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);
    if(itPlay==curPlayingTeams.end()) break;
    if(itPlay->isNetTeam()) {
      QObject::disconnect(framePlaying->getTeamWidget(*itPlay), SIGNAL(teamStatusChanged(HWTeam)));
      framePlaying->removeTeam(team);
      curPlayingTeams.erase(itPlay);
      break;
    }
  }
}

void TeamSelWidget::netTeamStatusChanged(const HWTeam& team)
{
  QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);
  
}

//void TeamSelWidget::removeTeam(__attribute__ ((unused)) HWTeam team)
//{
  //curDontPlayingTeams.erase(std::find(curDontPlayingTeams.begin(), curDontPlayingTeams.end(), team));
//}

void TeamSelWidget::changeTeamStatus(HWTeam team)
{
  QList<HWTeam>::iterator itDontPlay=std::find(curDontPlayingTeams.begin(), curDontPlayingTeams.end(), team);
  QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);

  bool willBePlaying=itDontPlay!=curDontPlayingTeams.end();

  if(!willBePlaying) {
    // playing team => dont playing
    curDontPlayingTeams.push_back(*itPlay);
    emit teamNotPlaying(*itPlay);
    curPlayingTeams.erase(itPlay);
  } else {
    // return if max playing teams reached
    if(framePlaying->isFullTeams()) return;
    // dont playing team => playing
    curPlayingTeams.push_back(*itDontPlay);
    emit teamWillPlay(*itDontPlay);
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
  if(willBePlaying) connect(framePlaying->getTeamWidget(team), SIGNAL(hhNmChanged(const HWTeam&)), 
			    this, SLOT(hhNumChanged(const HWTeam&)));

  QSize szh=pAddTeams->sizeHint();
  QSize szh1=pRemoveTeams->sizeHint();
  if(szh.isValid() && szh1.isValid()) {
    pAddTeams->resize(pAddTeams->size().width(), szh.height());
    pRemoveTeams->resize(pRemoveTeams->size().width(), szh1.height());
  }
}

void TeamSelWidget::addScrArea(FrameTeams* pfteams, QColor color, int maxHeight)
{
  VertScrArea* area=new VertScrArea(color);
  area->setWidget(pfteams);
  mainLayout.addWidget(area, 30);
  if (maxHeight > 0)
  	area->setMaximumHeight(maxHeight);
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
  addScrArea(framePlaying, p.color(QPalette::Window).light(105), 200);
  addScrArea(frameDontPlaying, p.color(QPalette::Window).dark(105), 0);
  newTeam = new QPushButton(this);
  newTeam->setText(QPushButton::tr("New team"));
  connect(newTeam, SIGNAL(clicked()), this, SLOT(newTeamClicked()));
  mainLayout.addWidget(newTeam);
}

void TeamSelWidget::resetPlayingTeams(const QList<HWTeam>& teamslist)
{
  QList<HWTeam>::iterator it;
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

QList<HWTeam> TeamSelWidget::getPlayingTeams() const
{
  return curPlayingTeams;
}

void TeamSelWidget::newTeamClicked()
{
	emit NewTeam();
}
