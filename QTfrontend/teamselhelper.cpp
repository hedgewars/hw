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
#include <QPushButton>
#include <QPainter>

void TeamLabel::teamButtonClicked()
{
  emit teamActivated(text());
}

TeamShowWidget::TeamShowWidget(HWTeam team, bool isPlaying, QWidget * parent) :
  QWidget(parent), mainLayout(this), m_team(team), m_isPlaying(isPlaying), phhoger(0)
{
  mainLayout.setSpacing(1);
  mainLayout.setMargin(2);
  this->setMaximumHeight(35);
  QPixmap* px=new QPixmap(QPixmap(datadir->absolutePath() + "/Forts/" + m_team.Fort + "L.png").scaled(40, 40));

  QPalette newPalette = palette();
  newPalette.setColor(QPalette::Button, palette().color(backgroundRole()));

  QPushButton* butt=new QPushButton(*px, "", this);
  butt->setFlat(true);
  butt->setGeometry(0, 0, 30, 30);
  butt->setMaximumWidth(30);
  butt->setPalette(newPalette);
  mainLayout.addWidget(butt);
  butt->setIconSize(butt->size());

  QPushButton* bText=new QPushButton(team.TeamName, this);
  bText->setPalette(newPalette);
  bText->setFlat(true);
  mainLayout.addWidget(bText);

  if(m_isPlaying) {
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

unsigned char TeamShowWidget::getHedgehogsNum() const
{
  return phhoger ? phhoger->getHedgehogsNum() : 0;
}
