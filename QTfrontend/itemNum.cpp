/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Ulyanov Igor <iulyanov@gmail.com>
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

#include "itemNum.h"
#include "hwform.h"

#include <QMouseEvent>
#include <QPainter>

ItemNum::ItemNum(const QImage& im, QWidget * parent, unsigned char min, unsigned char max) :
  QFrame(parent), m_im(im), infinityState(false), nonInteractive(false), minItems(min), maxItems(max),
  numItems(min+2 >= max ? min : min+2)
{
    if(frontendEffects) setAttribute(Qt::WA_PaintOnScreen, true);
}

ItemNum::~ItemNum()
{
}

void ItemNum::mousePressEvent ( QMouseEvent * event )
{
  if(nonInteractive) return;
  if(event->button()==Qt::LeftButton) {
    event->accept();
    if((infinityState && numItems <= maxItems) || (!infinityState && numItems < maxItems)) {
      incItems();
    } else {
      numItems = minItems+1;
      // appears there's an emit in there
      decItems();
    }
  } else if (event->button()==Qt::RightButton) {
    event->accept();
    if(numItems > minItems) {
      decItems();
    } else {
      numItems = maxItems+(infinityState?0:-1);
      incItems();
    }
  } else {
    event->ignore();
    return;
  }
  repaint();
}

QSize ItemNum::sizeHint () const
{
  return QSize((maxItems+1)*12, 32);
}

void ItemNum::paintEvent(QPaintEvent* event)
{
  QPainter painter(this);

  if (numItems==maxItems+1) {
    QRect target(0, 0, 100, 32);
    painter.drawImage(target, QImage(":/res/infinity.png"));
  } else {
    for(int i=0; i<numItems; i++) {
      QRect target(11 * i, i % 2, 25, 35);
      painter.drawImage(target, m_im);
    }
  }
}

unsigned char ItemNum::getItemsNum() const
{
  return numItems;
}

void ItemNum::setItemsNum(const unsigned char num)
{
  numItems=num;
}

void ItemNum::setInfinityState(bool value)
{
  infinityState=value;
}
