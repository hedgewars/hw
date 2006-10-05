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

#ifndef _HWMAP_CONTAINER_INCLUDED
#define _HWMAP_CONTAINER_INCLUDED

#include "hwmap.h"

#include <QWidget>
#include <QVBoxLayout>

class QPushButton;

class HWMapContainer : public QWidget
{
  Q_OBJECT
    
 public:
  HWMapContainer(QWidget * parent=0);
  QString getCurrentSeed() const;

 public slots:
  void changeImage();

 private slots:
  void setImage(const QImage newImage);

 protected:
  virtual void resizeEvent ( QResizeEvent * event );

 private:
  QVBoxLayout mainLayout;
  QPushButton* imageButt;
  HWMap* pMap;
  QString m_seed;
};

#endif // _HWMAP_CONTAINER_INCLUDED
