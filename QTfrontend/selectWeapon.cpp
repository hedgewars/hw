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
 
#include "selectWeapon.h"
#include "weaponItem.h"

#include <QPushButton>
#include <QGridLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QBitmap>

QImage getAmmoImage(int num)
{
  static QImage ammo(":Ammos.png");
  return ammo.copy(0, num*32, 32, 32);
}

SelWeaponItem::SelWeaponItem(int num, QWidget* parent) :
  QWidget(parent)
{
  QHBoxLayout* hbLayout = new QHBoxLayout(this);
  
  QLabel* lbl = new QLabel(this);
  lbl->setPixmap(QPixmap::fromImage(getAmmoImage(num)));
  lbl->setMaximumWidth(30);
  lbl->setGeometry(0, 0, 30, 30);
  hbLayout->addWidget(lbl);

  WeaponItem* item=new WeaponItem(QImage(":/res/M2Round2.jpg"), this);
  item->setInfinityState(true);
  hbLayout->addWidget(item);

  hbLayout->setStretchFactor(lbl, 1);
  hbLayout->setStretchFactor(item, 99);
  hbLayout->setAlignment(lbl, Qt::AlignLeft | Qt::AlignTop);
  //hbLayout->setAlignment(item, Qt::AlignTop);
}

SelWeaponWidget::SelWeaponWidget(QWidget* parent) :
QWidget(parent)
{
  pLayout=new QGridLayout(this);

  int j=-1;
  for(int i=0; i<19; ++i) {
    if (i%4==0) ++j;
    SelWeaponItem* swi = new SelWeaponItem(i, this);
    pLayout->addWidget(swi, j, i%4);
  }
}
