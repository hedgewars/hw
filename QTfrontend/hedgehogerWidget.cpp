/*
 * Hedgewars, a worms-like game
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

#include "hedgehogerWidget.h"

#include <QMouseEvent>
#include <QPainter>

#include "frameTeam.h"

CHedgehogerWidget::CHedgehogerWidget(QWidget * parent) :
  QWidget(parent), nonInteractive(false)
{
  if(parent) {
    pOurFrameTeams=dynamic_cast<FrameTeams*>(parent->parentWidget());
  }
  if(pOurFrameTeams->overallHedgehogs+4>pOurFrameTeams->maxHedgehogsPerGame) {
    numHedgehogs=pOurFrameTeams->maxHedgehogsPerGame-pOurFrameTeams->overallHedgehogs;
  } else numHedgehogs=4;
  pOurFrameTeams->overallHedgehogs+=numHedgehogs;
}

CHedgehogerWidget::~CHedgehogerWidget()
{
  pOurFrameTeams->overallHedgehogs-=numHedgehogs;
}

void CHedgehogerWidget::setNonInteractive()
{
  nonInteractive=true;
}

void CHedgehogerWidget::mousePressEvent ( QMouseEvent * event )
{
  if(nonInteractive) return;
  if(event->button()==Qt::LeftButton) {
    event->accept();
    if(numHedgehogs < 8 && pOurFrameTeams->overallHedgehogs<18) {
      numHedgehogs++;
      pOurFrameTeams->overallHedgehogs++;
      emit hedgehogsNumChanged();
    }
  } else if (event->button()==Qt::RightButton) {
    event->accept();
    if(numHedgehogs > 1) {
      numHedgehogs--;
      pOurFrameTeams->overallHedgehogs--;
      emit hedgehogsNumChanged();
    }
  } else {
    event->ignore();
    return;
  }
  repaint();
}

void CHedgehogerWidget::setHHNum(unsigned int num)
{
  unsigned int diff=numHedgehogs-num;
  numHedgehogs=num;
  pOurFrameTeams->overallHedgehogs+=diff;
  repaint();
}

void CHedgehogerWidget::paintEvent(QPaintEvent* event)
{
  QImage image(":/res/hh25x25.png");

  QPainter painter(this);

  for(int i=0; i<numHedgehogs; i++) {
    QRect target(11 * i, i % 2, 25, 25);
    painter.drawImage(target, image);
  }
}

unsigned char CHedgehogerWidget::getHedgehogsNum() const
{
  return numHedgehogs;
}
