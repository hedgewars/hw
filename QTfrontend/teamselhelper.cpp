/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Ulyanov Igor <iulyanov@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
