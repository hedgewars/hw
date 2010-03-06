/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006, 2007 Ulyanov Igor <iulyanov@gmail.com>
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

#include <algorithm>

#include <QLabel>
#include <QPixmap>
#include <QPushButton>
#include <QFrame>
#include <QDebug>

#include "vertScrollArea.h"
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
    connect(framePlaying->getTeamWidget(team), SIGNAL(hhNmChanged(const HWTeam&)),
                this, SLOT(hhNumChanged(const HWTeam&)));
    dynamic_cast<TeamShowWidget*>(framePlaying->getTeamWidget(team))->hhNumChanged();
    connect(framePlaying->getTeamWidget(team), SIGNAL(teamColorChanged(const HWTeam&)),
                this, SLOT(proxyTeamColorChanged(const HWTeam&)));
  } else {
    frameDontPlaying->addTeam(team, false);
    curDontPlayingTeams.push_back(team);
    if(m_acceptOuter) {
      connect(frameDontPlaying->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
          this, SLOT(pre_changeTeamStatus(HWTeam)));
    } else {
      connect(frameDontPlaying->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
          this, SLOT(changeTeamStatus(HWTeam)));
    }
  }
  emit setEnabledGameStart(curPlayingTeams.size()>1);
}

void TeamSelWidget::setInteractivity(bool interactive)
{
    framePlaying->setInteractivity(interactive);
}

void TeamSelWidget::hhNumChanged(const HWTeam& team)
{
    QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);
    if(itPlay==curPlayingTeams.end())
    {
        qWarning() << QString("hhNumChanged: team '%1' not found").arg(team.TeamName);
        return;
    }
    itPlay->numHedgehogs=team.numHedgehogs;
    emit hhogsNumChanged(team);
}

void TeamSelWidget::proxyTeamColorChanged(const HWTeam& team)
{
    QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);
    if(itPlay==curPlayingTeams.end())
    {
        qWarning() << QString("proxyTeamColorChanged: team '%1' not found").arg(team.TeamName);
        return;
    }
    itPlay->teamColor=team.teamColor;
    emit teamColorChanged(team);
}

void TeamSelWidget::changeHHNum(const HWTeam& team)
{
  QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);
    if(itPlay==curPlayingTeams.end())
    {
        qWarning() << QString("changeHHNum: team '%1' not found").arg(team.TeamName);
        return;
    }
  itPlay->numHedgehogs=team.numHedgehogs;

  framePlaying->setHHNum(team);
}

void TeamSelWidget::changeTeamColor(const HWTeam& team)
{
    QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);
    if(itPlay==curPlayingTeams.end())
    {
        qWarning() << QString("changeTeamColor: team '%1' not found").arg(team.TeamName);
        return;
    }
    itPlay->teamColor=team.teamColor;

    framePlaying->setTeamColor(team);
}

void TeamSelWidget::removeNetTeam(const HWTeam& team)
{
    //qDebug() << QString("removeNetTeam: removing team '%1'").arg(team.TeamName);
    for(;;) {
        QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);
        if(itPlay==curPlayingTeams.end())
        {
            qWarning() << QString("removeNetTeam: team '%1' not found").arg(team.TeamName);
            break;
        }
        if(itPlay->isNetTeam()) {
            QObject::disconnect(framePlaying->getTeamWidget(*itPlay), SIGNAL(teamStatusChanged(HWTeam)));
            framePlaying->removeTeam(team);
            curPlayingTeams.erase(itPlay);
            break;
        }
    }
    emit setEnabledGameStart(curPlayingTeams.size()>1);
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
    team=*itDontPlay; // for net team info saving in framePlaying (we have only name with netID from network)
    itDontPlay->teamColor=framePlaying->getNextColor();
    curPlayingTeams.push_back(*itDontPlay);
    if(!m_acceptOuter) emit teamWillPlay(*itDontPlay);
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
  if(!team.isNetTeam() && m_acceptOuter && !willBePlaying) {
    connect(frameDontPlaying->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
        this, SLOT(pre_changeTeamStatus(HWTeam)));
  } else {
    connect(pAddTeams->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
        this, SLOT(changeTeamStatus(HWTeam)));
  }
  if(willBePlaying) {
    connect(framePlaying->getTeamWidget(team), SIGNAL(hhNmChanged(const HWTeam&)),
        this, SLOT(hhNumChanged(const HWTeam&)));
    dynamic_cast<TeamShowWidget*>(framePlaying->getTeamWidget(team))->hhNumChanged();
    connect(framePlaying->getTeamWidget(team), SIGNAL(teamColorChanged(const HWTeam&)),
        this, SLOT(proxyTeamColorChanged(const HWTeam&)));
    emit teamColorChanged(((TeamShowWidget*)framePlaying->getTeamWidget(team))->getTeam());
  }

  QSize szh=pAddTeams->sizeHint();
  QSize szh1=pRemoveTeams->sizeHint();
  if(szh.isValid() && szh1.isValid()) {
    pAddTeams->resize(pAddTeams->size().width(), szh.height());
    pRemoveTeams->resize(pRemoveTeams->size().width(), szh1.height());
  }

  emit setEnabledGameStart(curPlayingTeams.size()>1);
}

void TeamSelWidget::addScrArea(FrameTeams* pfteams, QColor color, int fixedHeight)
{
    VertScrArea* area = new VertScrArea(color);
    area->setWidget(pfteams);
    mainLayout.addWidget(area, 30);
    if (fixedHeight > 0)
    {
        area->setMinimumHeight(fixedHeight);
        area->setMaximumHeight(fixedHeight);
        area->setStyleSheet(
                "FrameTeams{"
                    "border: solid;"
                    "border-width: 1px;"
                    "border-radius: 16px;"
                    "border-color: #ffcc00;"
                    "}"
        );
    }
}

TeamSelWidget::TeamSelWidget(QWidget* parent) :
  QGroupBox(parent), mainLayout(this), m_acceptOuter(false)
{
    setTitle(QGroupBox::tr("Playing teams"));
    framePlaying = new FrameTeams();
    frameDontPlaying = new FrameTeams();

    QPalette p;
    p.setColor(QPalette::Window, QColor(0x00, 0x00, 0x00));
    addScrArea(framePlaying, p.color(QPalette::Window).light(105), 250);
    addScrArea(frameDontPlaying, p.color(QPalette::Window).dark(105), 0);
    QPushButton * btnSetup = new QPushButton(this);
    btnSetup->setText(QPushButton::tr("Setup"));
    connect(btnSetup, SIGNAL(clicked()), this, SIGNAL(SetupClicked()));
    mainLayout.addWidget(btnSetup);
}

void TeamSelWidget::setAcceptOuter(bool acceptOuter)
{
  m_acceptOuter=acceptOuter;
}

void TeamSelWidget::resetPlayingTeams(const QList<HWTeam>& teamslist)
{
  QList<HWTeam>::iterator it;
  //for(it=curPlayingTeams.begin(); it!=curPlayingTeams.end(); it++) {
  //framePlaying->removeTeam(*it);
  //}
  framePlaying->resetTeams();
  framePlaying->resetColors();
  curPlayingTeams.clear();
  //for(it=curDontPlayingTeams.begin(); it!=curDontPlayingTeams.end(); it++) {
  //frameDontPlaying->removeTeam(*it);
  //}
  frameDontPlaying->resetTeams();
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

QList<HWTeam> TeamSelWidget::getDontPlayingTeams() const
{
  return curDontPlayingTeams;
}

void TeamSelWidget::pre_changeTeamStatus(HWTeam team)
{
  team.teamColor=framePlaying->getNextColor();
  emit acceptRequested(team);
}
