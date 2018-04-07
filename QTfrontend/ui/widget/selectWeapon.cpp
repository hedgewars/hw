/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "selectWeapon.h"
#include "weaponItem.h"
#include "hwconsts.h"

#include <QDebug>
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
    int x = num/(ammo.height()/32);
    int y = (num-((ammo.height()/32)*x))*32;
    x*=32;
    return ammo.copy(x, y, 32, 32);
}

SelWeaponItem::SelWeaponItem(bool allowInfinite, int iconNum, int wNum, QImage image, QImage imagegrey, QWidget* parent) :
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

    item = new WeaponItem(image, imagegrey, this);
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

void SelWeaponItem::setEnabled(bool value)
{
    item->setEnabled(value);
}

SelWeaponWidget::SelWeaponWidget(int numItems, QWidget* parent) :
    QFrame(parent),
    m_numItems(numItems)
{
    wconf = new QMap<QString, QString>();
    for(int i = 0; i < cDefaultAmmos.size(); ++i)
    {
        wconf->insert(cDefaultAmmos[i].first, cDefaultAmmos[i].second);
    }

    if (!QDir(cfgdir->absolutePath() + "/Schemes").exists()) {
        QDir().mkdir(cfgdir->absolutePath() + "/Schemes");
    }
    if (!QDir(cfgdir->absolutePath() + "/Schemes/Ammo").exists()) {
        qDebug("No /Schemes/Ammo directory found. Trying to import weapon schemes from weapons.ini.");
        QDir().mkdir(cfgdir->absolutePath() + "/Schemes/Ammo");

        QSettings old_wconf(cfgdir->absolutePath() + "/weapons.ini", QSettings::IniFormat);

        QStringList defaultAmmos;
        for(int i = 0; i < cDefaultAmmos.size(); ++i)
        {
            defaultAmmos.append(cDefaultAmmos[i].first);
        }

        QStringList keys = old_wconf.allKeys();
        int imported = 0;
        for(int i = 0; i < keys.size(); i++)
        {
            if (!defaultAmmos.contains(keys[i])) {
                wconf->insert(keys[i], fixWeaponSet(old_wconf.value(keys[i]).toString()));
                QFile file(cfgdir->absolutePath() + "/Schemes/Ammo/" + keys[i] + ".hwa");
                if (file.open(QIODevice::WriteOnly)) {
                    QTextStream stream( &file );
                    stream << old_wconf.value(keys[i]).toString() << endl;
                    file.close();
                }
                imported++;
            }
        }
        qDebug("%d weapon scheme(s) imported.", imported);
    } else {
        QStringList schemes = QDir(cfgdir->absolutePath() + "/Schemes/Ammo").entryList();

        for(int i = 0; i < schemes.size(); i++)
        {
            if (schemes[i] == "." || schemes[i] == "..") continue;

            QFile file(cfgdir->absolutePath() + "/Schemes/Ammo/" + schemes[i]);
            QString config;
            if (file.open(QIODevice::ReadOnly)) {
                QTextStream stream( &file );
                stream >> config;
                file.close();
            }

            // Chop off file name suffix
            QString schemeName = schemes[i];
            if (schemeName.endsWith(".hwa", Qt::CaseInsensitive)) {
                schemeName.chop(4);
            }
            wconf->insert(schemeName, fixWeaponSet(config));
        }
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
    for(; i < m_numItems; ++i)
    {
        if (i == 6) continue;
        if (k % 4 == 0) ++j;
        SelWeaponItem * swi = new SelWeaponItem(true, i, currentState[i].digitValue(), QImage(":/res/ammopic.png"), QImage(":/res/ammopicgrey.png"), this);
        weaponItems[i].append(swi);
        p1Layout->addWidget(swi, j, k % 4);

        SelWeaponItem * pwi = new SelWeaponItem(false, i, currentState[numItems + i].digitValue(), QImage(":/res/ammopicbox.png"), QImage(":/res/ammopicboxgrey.png"), this);
        weaponItems[i].append(pwi);
        p2Layout->addWidget(pwi, j, k % 4);

        SelWeaponItem * dwi = new SelWeaponItem(false, i, currentState[numItems*2 + i].digitValue(), QImage(":/res/ammopicdelay.png"), QImage(":/res/ammopicdelaygrey.png"), this);
        weaponItems[i].append(dwi);
        p3Layout->addWidget(dwi, j, k % 4);

        SelWeaponItem * awi = new SelWeaponItem(false, i, currentState[numItems*3 + i].digitValue(), QImage(":/res/ammopic.png"), QImage(":/res/ammopicgrey.png"), this);
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
    bool enable = true;
    for(int i = 0; i < cDefaultAmmos.size(); i++)
    {
        if (!cDefaultAmmos[i].first.compare(m_name->text()))
        {
            enable = false;
            break;
        }
    }
    for(int i = 0; i < m_numItems; ++i)
    {
        twi::iterator it = weaponItems.find(i);
        if (it == weaponItems.end()) continue;
        it.value()[0]->setItemsNum(ammo[i].digitValue());
        it.value()[1]->setItemsNum(ammo[m_numItems + i].digitValue());
        it.value()[2]->setItemsNum(ammo[m_numItems*2 + i].digitValue());
        it.value()[3]->setItemsNum(ammo[m_numItems*3 + i].digitValue());
        it.value()[0]->setEnabled(enable);
        it.value()[1]->setEnabled(enable);
        it.value()[2]->setEnabled(enable);
        it.value()[3]->setEnabled(enable);
    }
    m_name->setEnabled(enable);
}

void SelWeaponWidget::setDefault()
{
    for(int i = 0; i < cDefaultAmmos.size(); i++)
    {
        if (!cDefaultAmmos[i].first.compare(m_name->text()))
        {
            return;
        }
    }
    setWeapons(*cDefaultAmmoStore);
}

//Save current weapons set.
void SelWeaponWidget::save()
{
    //The save() function is called by ANY change of the combo box.
    //If an entry is deleted, this code would just re-add the deleted
    //item. We use isDeleted to check if we are currently deleting to
    //prevent this.
    if (isDeleting)
        return;
    // TODO make this return if success or not, so that the page can react
    // properly and not goBack if saving failed
    if (m_name->text() == "")
        return;

    QString state1;
    QString state2;
    QString state3;
    QString state4;
    QString stateFull;

    for(int i = 0; i < m_numItems; ++i)
    {
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

    stateFull = state1 + state2 + state3 + state4;

    for(int i = 0; i < cDefaultAmmos.size(); i++)
    {
        // Don't allow same name as default weapon set, even case-insensitively.
        // This prevents some problems with saving/loading.
        if (cDefaultAmmos[i].first.toLower().compare(m_name->text().toLower()) == 0)
        {
            // don't show warning if no change
            if (cDefaultAmmos[i].second.compare(stateFull) == 0)
                return;

            m_name->setText(curWeaponsName);
            QMessageBox deniedMsg(this);
            deniedMsg.setIcon(QMessageBox::Warning);
            deniedMsg.setWindowTitle(QMessageBox::tr("Weapons - Warning"));
            deniedMsg.setText(QMessageBox::tr("Cannot overwrite default weapon set '%1'!").arg(cDefaultAmmos[i].first));
            deniedMsg.setWindowModality(Qt::WindowModal);
            deniedMsg.exec();
            return;
        }
    }

    if (curWeaponsName != "")
    {
        // remove old entry
        wconf->remove(curWeaponsName);
    }
    wconf->insert(m_name->text(), stateFull);
    QFile file(cfgdir->absolutePath() + "/Schemes/Ammo/" + m_name->text()+ ".hwa");
    if (file.open(QIODevice::WriteOnly)) {
        QTextStream stream( &file );
        stream << stateFull << endl;
        file.close();
    }
    emit weaponsEdited(curWeaponsName, m_name->text(), stateFull);
}

int SelWeaponWidget::operator [] (unsigned int weaponIndex) const
{
    twi::const_iterator it = weaponItems.find(weaponIndex);
    return it == weaponItems.end() ? 9 : it.value()[0]->getItemsNum();
}

QString SelWeaponWidget::getWeaponsString(const QString& name) const
{
    return wconf->find(name).value();
}

void SelWeaponWidget::deleteWeaponsName()
{
    QString delWeaponsName = curWeaponsName;
    if (delWeaponsName == "") return;

    for(int i = 0; i < cDefaultAmmos.size(); i++)
    {
        if (!cDefaultAmmos[i].first.compare(delWeaponsName))
        {
            QMessageBox deniedMsg(this);
            deniedMsg.setIcon(QMessageBox::Warning);
            deniedMsg.setWindowTitle(QMessageBox::tr("Weapons - Warning"));
            deniedMsg.setText(QMessageBox::tr("Cannot delete default weapon set '%1'!").arg(cDefaultAmmos[i].first));
            deniedMsg.setWindowModality(Qt::WindowModal);
            deniedMsg.exec();
            return;
        }
    }

    QMessageBox reallyDeleteMsg(this);
    reallyDeleteMsg.setIcon(QMessageBox::Question);
    reallyDeleteMsg.setWindowTitle(QMessageBox::tr("Weapons - Are you sure?"));
    reallyDeleteMsg.setText(QMessageBox::tr("Do you really want to delete the weapon set '%1'?").arg(delWeaponsName));
    reallyDeleteMsg.setWindowModality(Qt::WindowModal);
    reallyDeleteMsg.setStandardButtons(QMessageBox::Ok | QMessageBox::Cancel);

    if (reallyDeleteMsg.exec() == QMessageBox::Ok)
    {
        isDeleting = true;
        wconf->remove(delWeaponsName);
        QFile(cfgdir->absolutePath() + "/Schemes/Ammo/" + curWeaponsName + ".hwa").remove();
        emit weaponsDeleted(delWeaponsName);
    }
}

void SelWeaponWidget::newWeaponsName()
{
    save();
    QString newName = tr("New");
    if(wconf->contains(newName))
    {
        //name already used -> look for an appropriate name:
        int i=2;
        while(wconf->contains(newName = tr("New (%1)").arg(i++))) ;
    }
    setWeaponsName(newName);
    wconf->insert(newName, *cEmptyAmmoStore);
    emit weaponsAdded(newName, *cEmptyAmmoStore);
}

void SelWeaponWidget::setWeaponsName(const QString& name)
{
    m_name->setText(name);

    curWeaponsName = name;

    if(name != "" && wconf->contains(name))
    {
        setWeapons(wconf->find(name).value());
    }
    else
    {
        setWeapons(*cEmptyAmmoStore);
    }
}

void SelWeaponWidget::switchWeapons(const QString& name)
{
    // Rescue old weapons set, then select new one
    save();
    setWeaponsName(name);
}

QStringList SelWeaponWidget::getWeaponNames() const
{
    return wconf->keys();
}

void SelWeaponWidget::copy()
{
    save();
    if(wconf->contains(curWeaponsName))
    {
        QString ammo = getWeaponsString(curWeaponsName);
        QString newName = tr("Copy of %1").arg(curWeaponsName);
        if(wconf->contains(newName))
        {
            //name already used -> look for an appropriate name:
            int i=2;
            while(wconf->contains(newName = tr("Copy of %1 (%2)").arg(curWeaponsName).arg(i++)));
        }
        setWeaponsName(newName);
        setWeapons(ammo);
        wconf->insert(newName, ammo);
        emit weaponsAdded(newName, ammo);
    }
}

QString SelWeaponWidget::fixWeaponSet(const QString &s)
{
    int neededLength = cDefaultAmmoStore->size() / 4;
    int thisSetLength = s.size() / 4;

    QStringList sl;
    sl
            << s.left(thisSetLength)
            << s.mid(thisSetLength, thisSetLength)
            << s.mid(thisSetLength * 2, thisSetLength)
            << s.right(thisSetLength)
               ;

    for(int i = sl.length() - 1; i >= 0; --i)
    {
        sl[i] = sl[i].leftJustified(neededLength, '0', true);
    }

    return sl.join(QString());
}

void SelWeaponWidget::deletionDone()
{
    isDeleting = false;
}

void SelWeaponWidget::init()
{
    isDeleting = false;
}
