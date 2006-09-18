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

#include "hedgehogerWidget.h"

#include <QMouseEvent>
#include <QPainter>

#include "frameTeam.h"

CHedgehogerWidget::CHedgehogerWidget(QWidget * parent) :
  QWidget(parent)
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

void CHedgehogerWidget::mousePressEvent ( QMouseEvent * event )
{
  if(event->button()==Qt::LeftButton) {
    event->accept();
    if(numHedgehogs < 8 && pOurFrameTeams->overallHedgehogs<18) {
      numHedgehogs++;
      pOurFrameTeams->overallHedgehogs++;
    }
  } else if (event->button()==Qt::RightButton) {
    event->accept();
    if(numHedgehogs > 3) {
      numHedgehogs--;
      pOurFrameTeams->overallHedgehogs--;
    }
  } else {
    event->ignore();
    return;
  }
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

unsigned char CHedgehogerWidget::getHedgehogsNum()
{
  return numHedgehogs;
}
