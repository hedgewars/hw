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
 
#include "selectWeapon.h"
#include "weaponItem.h"
#include "hwconsts.h"

#include <QPushButton>
#include <QGridLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QBitmap>
#include <QLineEdit>
#include <QSettings>
#include <QMessageBox>

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

  item=new WeaponItem(QImage(":/res/ammopic.png"), this);
  item->setItemsNum(wNum);
  item->setInfinityState(true);
  hbLayout->addWidget(item);

  hbLayout->setStretchFactor(lbl, 1);
  hbLayout->setStretchFactor(item, 99);
  hbLayout->setAlignment(lbl, Qt::AlignLeft | Qt::AlignVCenter);
  hbLayout->setAlignment(item, Qt::AlignLeft | Qt::AlignVCenter);
}

void SelWeaponItem::setItemsNum(const unsigned char num)
{
  item->setItemsNum(num);
}

unsigned char SelWeaponItem::getItemsNum() const
{
  return item->getItemsNum();
}

SelWeaponWidget::SelWeaponWidget(int numItems, QWidget* parent) :
  m_numItems(numItems),
  QWidget(parent)
{
  wconf = new QSettings(cfgdir->absolutePath() + "/weapons.ini", QSettings::IniFormat, this);
  if (wconf->allKeys().empty()) {
    wconf->setValue("Default", cDefaultAmmoStore->mid(10));
  }

  currentState=cDefaultAmmoStore->mid(10);

  pLayout=new QGridLayout(this);
  pLayout->setSpacing(1);
  pLayout->setMargin(1);

  int j=-1;
  int i=0, k=0;
  for(; i<m_numItems; ++i) {
    if(i==6) continue;
    if (k%4==0) ++j;
    weaponItems[i]=new SelWeaponItem(i, currentState[i].digitValue(), this);
    pLayout->addWidget(weaponItems[i], j, k%4);
    ++k;
  }

  //pLayout->setRowStretch(5, 100);
  m_name = new QLineEdit(this);
  pLayout->addWidget(m_name, i, 0, 1, 5);
}

void SelWeaponWidget::setWeapons(const QString& ammo)
{
  for(int i=0; i<m_numItems; ++i) {
    twi::iterator it=weaponItems.find(i);
    if (it==weaponItems.end()) continue;
    it->second->setItemsNum(ammo[i].digitValue());
  }
  update();
}

void SelWeaponWidget::setDefault()
{
  setWeapons(cDefaultAmmoStore->mid(10));
}

void SelWeaponWidget::save()
{
  if (m_name->text()=="Default") {
    QMessageBox impossible(QMessageBox::Warning, QMessageBox::tr("Weapons"), QMessageBox::tr("Can not edit default weapon set"));
    impossible.exec();
    return;
  }
  if (m_name->text()=="") return;
  currentState="";
  for(int i=0; i<m_numItems; ++i) {
    twi::const_iterator it=weaponItems.find(i);
    int num = it==weaponItems.end() ? 9 : (*this)[i];
    currentState = QString("%1%2").arg(currentState).arg(num);
  }
  if (curWeaponsName!="") {
    // remove old entry
    wconf->remove(curWeaponsName);
  }
  wconf->setValue(m_name->text(), currentState);
  emit weaponsChanged();
}

int SelWeaponWidget::operator [] (unsigned int weaponIndex) const
{
  twi::const_iterator it=weaponItems.find(weaponIndex);
  return it==weaponItems.end() ? 9 : it->second->getItemsNum();
}

QString SelWeaponWidget::getWeaponsString() const
{
  return currentState;
}

QString SelWeaponWidget::getWeaponsString(const QString& name) const
{
  return wconf->value(name).toString();
}

void SelWeaponWidget::deleteWeaponsName()
{
  if (curWeaponsName=="") return;

  if (curWeaponsName=="Default") {
    QMessageBox impossible(QMessageBox::Warning, QMessageBox::tr("Weapons"), QMessageBox::tr("Can not delete default weapon set"));
    impossible.exec();
    return;
  }

  QMessageBox reallyDelete(QMessageBox::Question, QMessageBox::tr("Weapons"), QMessageBox::tr("Really delete this weapon set?"),
			   QMessageBox::Ok | QMessageBox::Cancel);
  
  if (reallyDelete.exec()==QMessageBox::Ok) {
    wconf->remove(curWeaponsName);
    emit weaponsDeleted();
  }
}

void SelWeaponWidget::setWeaponsName(const QString& name, bool editMode)
{
  if(name!="" && wconf->contains(name)) {
    setWeapons(wconf->value(name).toString());
  }

  if(editMode) curWeaponsName=name;
  else curWeaponsName="";

  m_name->setText(name);
}

QStringList SelWeaponWidget::getWeaponNames() const
{
  return wconf->allKeys();
}
