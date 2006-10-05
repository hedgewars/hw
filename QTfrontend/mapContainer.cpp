/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Igor Ulyanov <iulyanov@gmail.com>
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

#include "mapContainer.h"

#include <QPushButton>
#include <QBuffer>
#include <QUuid>
#include <QBitmap>
#include <QPainter>
#include <QLinearGradient>
#include <QColor>

HWMapContainer::HWMapContainer(QWidget * parent) :
  QWidget(parent), mainLayout(this)
{
  imageButt=new QPushButton(this);
  imageButt->setMaximumSize(256, 128);
  imageButt->setFlat(true);
  imageButt->setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum);
  mainLayout.addWidget(imageButt);
  connect(imageButt, SIGNAL(clicked()), this, SLOT(changeImage()));
  changeImage();
}

void HWMapContainer::setImage(const QImage newImage)
{
  QPixmap px(256, 128);
  QPixmap pxres(256, 128);
  QPainter p(&pxres);

  px.fill(Qt::yellow);
  QBitmap bm = QBitmap::fromImage(newImage);
  px.setMask(bm);

  QLinearGradient linearGrad(QPoint(128, 0), QPoint(128, 128));
  linearGrad.setColorAt(0, QColor(0, 0, 192));
  linearGrad.setColorAt(1, QColor(0, 0, 64));
  p.fillRect(QRect(0, 0, 256, 128), linearGrad);
  p.drawPixmap(QPoint(0, 0), px);


  imageButt->setIcon(pxres);
  imageButt->setIconSize(QSize(256, 128));
}

void HWMapContainer::changeImage()
{
  pMap=new HWMap();
  connect(pMap, SIGNAL(ImageReceived(const QImage)), this, SLOT(setImage(const QImage)));
  m_seed = QUuid::createUuid().toString();
  pMap->getImage(m_seed.toStdString());
}

QString HWMapContainer::getCurrentSeed() const
{
  return m_seed;
}

void HWMapContainer::resizeEvent ( QResizeEvent * event )
{
  //imageButt->setIconSize(imageButt->size());
}
