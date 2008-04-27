/*
 * Hedgewars, a worms-like game
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

#ifndef _SELECT_WEAPON_INCLUDED
#define _SELECT_WEAPON_INCLUDED

#include <QWidget>
#include <map>

class QGridLayout;
class WeaponItem;
class QLineEdit;
class QSettings;

class SelWeaponItem : public QWidget
{
  Q_OBJECT

public:
  SelWeaponItem(int iconNum, int wNum, QWidget* parent=0);

  unsigned char getItemsNum() const;
  void setItemsNum(const unsigned char num);

 private:
  WeaponItem* item;
};

class SelWeaponWidget : public QWidget
{
  Q_OBJECT
  
 public:
  SelWeaponWidget(int numItems, QWidget* parent=0);
  QString getWeaponsString() const; // deprecated?
  QString getWeaponsString(const QString& name) const;
  QStringList getWeaponNames() const;

 public slots:
  void setDefault();
  void setWeapons(const QString& ammo);
  void setWeaponsName(const QString& name, bool editMode);
  void deleteWeaponsName();
  void save();

 signals:
  void weaponsChanged();
  void weaponsDeleted();

 private:
  QString currentState;
  QString curWeaponsName;

  QLineEdit* m_name;

  QSettings* wconf;

  const int m_numItems;
  int operator [] (unsigned int weaponIndex) const;
  
  typedef std::map<int, SelWeaponItem*> twi;
  twi weaponItems;
  QGridLayout* pLayout;
};

#endif // _SELECT_WEAPON_INCLUDED
