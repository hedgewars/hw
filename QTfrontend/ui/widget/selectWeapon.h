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

#ifndef _SELECT_WEAPON_INCLUDED
#define _SELECT_WEAPON_INCLUDED

#include <QFrame>
#include <QMap>
#include <QList>

class QGridLayout;
class WeaponItem;
class QLineEdit;
class QSettings;

class SelWeaponItem : public QWidget
{
        Q_OBJECT

    public:
        SelWeaponItem(bool allowInfinite, int iconNum, int wNum, QImage image, QImage imagegrey, QWidget* parent=0);

        unsigned char getItemsNum() const;
        void setItemsNum(const unsigned char num);
        void setEnabled(bool value);

    private:
        WeaponItem* item;
};

class SelWeaponWidget : public QFrame
{
        Q_OBJECT

    public:
        SelWeaponWidget(int numItems, QWidget* parent=0);
        QString getWeaponsString(const QString& name) const;
        QStringList getWeaponNames() const;
        void deletionDone();
        void init();

    public slots:
        void setDefault();
        void setWeapons(const QString& ammo);
        //sets the name of the current set
        void setWeaponsName(const QString& name);
        void switchWeapons(const QString& name);
        void deleteWeaponsName();
        void newWeaponsName();
        void save();
        void copy();

    signals:
        void weaponsDeleted(QString weaponsName);
        void weaponsAdded(QString weaponsName, QString ammo);
        void weaponsEdited(QString oldWeaponsName, QString newWeaponsName, QString ammo);

    private:
        //the name of the current weapon set
        QString curWeaponsName;
        //set to true while an entry is deleted. Used to avoid duplicate saving due to combobox change
        bool isDeleting;

        QLineEdit* m_name;

        //storage for all the weapons sets
        QMap<QString, QString>* wconf;

        const int m_numItems;
        int operator [] (unsigned int weaponIndex) const;

        typedef QList<SelWeaponItem*> ItemsList;
        typedef QMap<int, ItemsList> twi;
        twi weaponItems;
        //layout element for each tab:
        QGridLayout* p1Layout;
        QGridLayout* p2Layout;
        QGridLayout* p3Layout;
        QGridLayout* p4Layout;

        QString fixWeaponSet(const QString & s);
};

#endif // _SELECT_WEAPON_INCLUDED
