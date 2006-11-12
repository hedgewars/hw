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

#include "teamselhelper.h"
#include "hwconsts.h"

#include <QPixmap>
#include <QPainter>
#include <QStyleFactory>

#include "frameTeam.h"

void TeamLabel::teamButtonClicked()
{
  emit teamActivated(text());
}

TeamShowWidget::TeamShowWidget(HWTeam team, bool isPlaying, QWidget * parent) :
  QWidget(parent), mainLayout(this), m_team(team), m_isPlaying(isPlaying), phhoger(0), colorButt(0)
{
  mainLayout.setSpacing(1);
  mainLayout.setMargin(2);
  this->setMaximumHeight(35);
  //QPixmap* px=new QPixmap(QPixmap(datadir->absolutePath() + "/Forts/" + m_team.Fort + "L.png").scaled(40, 40));
  QIcon* difficultyIcon=new QIcon(QString(":/res/botlevels/%1.png").arg(m_team.difficulty));

  QPalette newPalette = palette();
  newPalette.setColor(QPalette::Button, palette().color(backgroundRole()));

  // team fort
  QPushButton* butt=new QPushButton(*difficultyIcon, "", this); // *px
  butt->setFlat(true);
  butt->setGeometry(0, 0, 30, 30);
  butt->setMaximumWidth(30);
  butt->setPalette(newPalette);
  mainLayout.addWidget(butt);
  butt->setIconSize(butt->size());

  // team name
  QPushButton* bText=new QPushButton(team.TeamName, this);
  bText->setPalette(newPalette);
  bText->setFlat(true);
  mainLayout.addWidget(bText);

  if(m_isPlaying) {
    // team color
    colorButt=new QPushButton(this);
    colorButt->setMaximumWidth(30);
    colorButt->setGeometry(0, 0, 30, 30);
    changeTeamColor();
    connect(colorButt, SIGNAL(clicked()), this, SLOT(changeTeamColor()));
    mainLayout.addWidget(colorButt);

    // hedgehogs num
    phhoger=new CHedgehogerWidget(this);
    mainLayout.addWidget(phhoger);
  }

  QObject::connect(butt, SIGNAL(clicked()), this, SLOT(activateTeam()));
  QObject::connect(bText, SIGNAL(clicked()), this, SLOT(activateTeam()));
}

void TeamShowWidget::activateTeam()
{
  emit teamStatusChanged(m_team);
}

HWTeamTempParams TeamShowWidget::getTeamParams() const
{
  if(!phhoger) throw;
  HWTeamTempParams params;
  params.numHedgehogs=phhoger->getHedgehogsNum();
  params.teamColor=colorButt->palette().color(QPalette::Button);
  return params;
}

void TeamShowWidget::changeTeamColor()
{
  FrameTeams* pOurFrameTeams=dynamic_cast<FrameTeams*>(parentWidget());
  if(++pOurFrameTeams->currentColor==pOurFrameTeams->availableColors.end()) {
    pOurFrameTeams->currentColor=pOurFrameTeams->availableColors.begin();
  }
  
  QPalette newPalette = palette();
  newPalette.setColor(QPalette::Button, QColor(*pOurFrameTeams->currentColor));
  //colorButt->setStyleSheet(QString("background-color : ")+pOurFrameTeams->currentColor->name());
  colorButt->setStyle(QStyleFactory::create("plastique"));
  colorButt->setPalette(newPalette);
}
