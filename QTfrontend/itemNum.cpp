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
 
#include "itemNum.h"

#include <QMouseEvent>
#include <QPainter>

ItemNum::ItemNum(const QImage& im, QWidget * parent, unsigned char min, unsigned char max) :
  m_im(im), QWidget(parent), nonInteractive(false), minItems(min), maxItems(max), numItems(min)
{
}

ItemNum::~ItemNum()
{
}

void ItemNum::mousePressEvent ( QMouseEvent * event )
{
  if(nonInteractive) return;
  if(event->button()==Qt::LeftButton) {
    event->accept();
    if(numItems < maxItems) {
      incItems();
    }
  } else if (event->button()==Qt::RightButton) {
    event->accept();
    if(numItems > minItems) {
      decItems();
    }
  } else {
    event->ignore();
    return;
  }
  repaint();
}

void ItemNum::paintEvent(QPaintEvent* event)
{
  QPainter painter(this);

  for(int i=0; i<numItems; i++) {
    QRect target(11 * i, i % 2, 25, 25);
    painter.drawImage(target, m_im);
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
