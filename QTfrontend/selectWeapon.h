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

#ifndef _SELECT_WEAPON_INCLUDED
#define _SELECT_WEAPON_INCLUDED

#include <QWidget>
#include <map>

class QGridLayout;
class WeaponItem;

class SelWeaponItem : public QWidget
{
  Q_OBJECT

public:
  SelWeaponItem(int iconNum, int wNum, QWidget* parent=0);

  unsigned char getItemsNum() const;

 private:
  WeaponItem* item;
};

class SelWeaponWidget : public QWidget
{
  Q_OBJECT
  
 public:
  SelWeaponWidget(QWidget* parent=0);
  int operator [] (unsigned int weaponIndex) const;
  QString getWeaponsString() const;

 private:
  std::map<int, SelWeaponItem*> weaponItems;
  QGridLayout* pLayout;
};

#endif // _SELECT_WEAPON_INCLUDED
