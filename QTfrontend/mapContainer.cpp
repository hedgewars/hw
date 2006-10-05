/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Igor Ulyanov <iulyanov@gmail.com>
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
