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
#include "hwconsts.h"

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

SelWeaponItem::SelWeaponItem(int iconNum, int wNum, QWidget* parent) :
  QWidget(parent)
{
  QHBoxLayout* hbLayout = new QHBoxLayout(this);
  hbLayout->setSpacing(1);
  hbLayout->setMargin(1);
  
  QLabel* lbl = new QLabel(this);
  lbl->setPixmap(QPixmap::fromImage(getAmmoImage(iconNum)));
  lbl->setMaximumWidth(30);
  lbl->setGeometry(0, 0, 30, 30);
  hbLayout->addWidget(lbl);

  item=new WeaponItem(QImage(":/res/hh25x25.png"), this);
  item->setItemsNum(wNum);
  item->setInfinityState(true);
  hbLayout->addWidget(item);

  hbLayout->setStretchFactor(lbl, 1);
  hbLayout->setStretchFactor(item, 99);
  hbLayout->setAlignment(lbl, Qt::AlignLeft | Qt::AlignVCenter);
  hbLayout->setAlignment(item, Qt::AlignLeft | Qt::AlignVCenter);
}

unsigned char SelWeaponItem::getItemsNum() const
{
  return item->getItemsNum();
}

SelWeaponWidget::SelWeaponWidget(QWidget* parent) :
QWidget(parent)
{
  pLayout=new QGridLayout(this);
  pLayout->setSpacing(1);
  pLayout->setMargin(1);

  int j=-1;
  for(int i=0, k=0; i<20; ++i) {
    if(i==6) continue;
    if (k%4==0) ++j;
    weaponItems[i]=new SelWeaponItem(i, cDefaultAmmoStore->at(10+i).digitValue(), this);
    pLayout->addWidget(weaponItems[i], j, k%4);
    ++k;
  }
}

int SelWeaponWidget::operator [] (unsigned int weaponIndex) const
{
  std::map<int, SelWeaponItem*>::const_iterator it=weaponItems.find(weaponIndex);
  return it==weaponItems.end() ? 9 : it->second->getItemsNum();
}

QString SelWeaponWidget::getWeaponsString() const
{
  QString ammo("eammstore ");
  for(int i=0; i<20; ++i) {
    ammo=QString("%1%2").arg(ammo).arg((*this)[i]);
  }
  return ammo;
}
