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
#include <QTabWidget>
#include <math.h>

QImage getAmmoImage(int num)
{
    static QImage ammo(":Ammos.png");
    int x = floor(num/(ammo.height()/32));
    int y = (num-((ammo.height()/32)*x))*32;
    x*=32;
    return ammo.copy(x, y, 32, 32);
}

SelWeaponItem::SelWeaponItem(bool allowInfinite, int iconNum, int wNum, QImage image, QWidget* parent) :
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

    item = new WeaponItem(image, this);
    item->setItemsNum(wNum);
    item->setInfinityState(allowInfinite);
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
  QFrame(parent),
  m_numItems(numItems)
{
    wconf = new QSettings(cfgdir->absolutePath() + "/weapons.ini", QSettings::IniFormat, this);

    for(int i = 0; i < cDefaultAmmos.size(); ++i)
        wconf->setValue(cDefaultAmmos[i].first, cDefaultAmmos[i].second);

    QStringList keys = wconf->allKeys();
    for(int i = 0; i < keys.size(); i++)
    {
        if (wconf->value(keys[i]).toString().size() != cDefaultAmmoStore->size())
            wconf->remove(keys[i]);
    }

    QString currentState = *cDefaultAmmoStore;

    QTabWidget * tbw = new QTabWidget(this);
    QWidget * page1 = new QWidget(this);
    p1Layout = new QGridLayout(page1);
    p1Layout->setSpacing(1);
    p1Layout->setMargin(1);
    QWidget * page2 = new QWidget(this);
    p2Layout = new QGridLayout(page2);
    p2Layout->setSpacing(1);
    p2Layout->setMargin(1);
    QWidget * page3 = new QWidget(this);
    p3Layout = new QGridLayout(page3);
    p3Layout->setSpacing(1);
    p3Layout->setMargin(1);
    QWidget * page4 = new QWidget(this);
    p4Layout = new QGridLayout(page4);
    p4Layout->setSpacing(1);
    p4Layout->setMargin(1);

    tbw->addTab(page1, tr("Weapon set"));
    tbw->addTab(page2, tr("Probabilities"));
    tbw->addTab(page4, tr("Ammo in boxes"));
    tbw->addTab(page3, tr("Delays"));

    QGridLayout * pageLayout = new QGridLayout(this);
    pageLayout->addWidget(tbw);


    int j = -1;
    int i = 0, k = 0;
    for(; i < m_numItems; ++i) {
        if (i == 6) continue;
        if (k % 4 == 0) ++j;
        SelWeaponItem * swi = new SelWeaponItem(true, i, currentState[i].digitValue(), QImage(":/res/ammopic.png"), this);
        weaponItems[i].append(swi);
        p1Layout->addWidget(swi, j, k % 4);

        SelWeaponItem * pwi = new SelWeaponItem(false, i, currentState[numItems + i].digitValue(), QImage(":/res/ammopicbox.png"), this);
        weaponItems[i].append(pwi);
        p2Layout->addWidget(pwi, j, k % 4);
        
        SelWeaponItem * dwi = new SelWeaponItem(false, i, currentState[numItems*2 + i].digitValue(), QImage(":/res/ammopicdelay.png"), this);
        weaponItems[i].append(dwi);
        p3Layout->addWidget(dwi, j, k % 4);
        
        SelWeaponItem * awi = new SelWeaponItem(false, i, currentState[numItems*3 + i].digitValue(), QImage(":/res/ammopic.png"), this);
        weaponItems[i].append(awi);
        p4Layout->addWidget(awi, j, k % 4);

        ++k;
    }

    //pLayout->setRowStretch(5, 100);
    m_name = new QLineEdit(this);
    pageLayout->addWidget(m_name, i, 0, 1, 5);
}

void SelWeaponWidget::setWeapons(const QString& ammo)
{
    for(int i = 0; i < m_numItems; ++i) {
        twi::iterator it = weaponItems.find(i);
        if (it == weaponItems.end()) continue;
        it.value()[0]->setItemsNum(ammo[i].digitValue());
        it.value()[1]->setItemsNum(ammo[m_numItems + i].digitValue());
        it.value()[2]->setItemsNum(ammo[m_numItems*2 + i].digitValue());
        it.value()[3]->setItemsNum(ammo[m_numItems*3 + i].digitValue());
    }
    update();
}

void SelWeaponWidget::setDefault()
{
    setWeapons(*cDefaultAmmoStore);
}

void SelWeaponWidget::save()
{
    for(int i = 0; i < cDefaultAmmos.size(); i++)
        if (!cDefaultAmmos[i].first.compare(m_name->text())) {
            QMessageBox::warning(0, QMessageBox::tr("Weapons"), QMessageBox::tr("Can not overwrite default weapon set '%1'!").arg(cDefaultAmmos[i].first));
            return;
        }

    if (m_name->text() == "") return;

    QString state1;
    QString state2;
    QString state3;
    QString state4;

    for(int i = 0; i < m_numItems; ++i) {
        twi::const_iterator it = weaponItems.find(i);
        int num = it == weaponItems.end() ? 9 : it.value()[0]->getItemsNum(); // 9 is for 'skip turn'
        state1.append(QString::number(num));
        int prob = it == weaponItems.end() ? 0 : it.value()[1]->getItemsNum();
        state2.append(QString::number(prob));
        int del = it == weaponItems.end() ? 0 : it.value()[2]->getItemsNum();
        state3.append(QString::number(del));
        int am = it == weaponItems.end() ? 0 : it.value()[3]->getItemsNum();
        state4.append(QString::number(am));
    }
    if (curWeaponsName != "") {
        // remove old entry
        wconf->remove(curWeaponsName);
    }
    wconf->setValue(m_name->text(), state1 + state2 + state3 + state4);
    emit weaponsChanged();
}

int SelWeaponWidget::operator [] (unsigned int weaponIndex) const
{
    twi::const_iterator it = weaponItems.find(weaponIndex);
    return it == weaponItems.end() ? 9 : it.value()[0]->getItemsNum();
}

QString SelWeaponWidget::getWeaponsString(const QString& name) const
{
    return wconf->value(name).toString();
}

void SelWeaponWidget::deleteWeaponsName()
{
    if (curWeaponsName == "") return;

    if (curWeaponsName == "Default") {
        QMessageBox impossible(QMessageBox::Warning, QMessageBox::tr("Weapons"), QMessageBox::tr("Can not delete default weapon set"));
        impossible.exec();
        return;
    }

    QMessageBox reallyDelete(QMessageBox::Question, QMessageBox::tr("Weapons"), QMessageBox::tr("Really delete this weapon set?"), QMessageBox::Ok | QMessageBox::Cancel);

    if (reallyDelete.exec() == QMessageBox::Ok) {
        wconf->remove(curWeaponsName);
        emit weaponsDeleted();
    }
}

void SelWeaponWidget::setWeaponsName(const QString& name)
{
    if(name != "" && wconf->contains(name)) {
        setWeapons(wconf->value(name).toString());
    }

    curWeaponsName = name;

    m_name->setText(name);
}

QStringList SelWeaponWidget::getWeaponNames() const
{
    return wconf->allKeys();
}
