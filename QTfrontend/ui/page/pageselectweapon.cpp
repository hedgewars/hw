/*
 * Hedgewars, a free turn based strategy game
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

#include <QGridLayout>
#include <QHBoxLayout>
#include <QPushButton>
#include <QComboBox>

#include "pageselectweapon.h"
#include "hwconsts.h"
#include "selectWeapon.h"

QLayout * PageSelectWeapon::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();

    pWeapons = new SelWeaponWidget(cAmmoNumber, this);
    pageLayout->addWidget(pWeapons);

    return pageLayout;
}

QLayout * PageSelectWeapon::footerLayoutDefinition()
{
    QGridLayout * bottomLayout = new QGridLayout();

    selectWeaponSet = new QComboBox(this);
    bottomLayout->addWidget(selectWeaponSet, 0, 0, 2, 1);

    // first row
    BtnNew = addButton(tr("New"), bottomLayout, 0, 1);
    BtnDefault = addButton(tr("Default"), bottomLayout, 0, 2);

    // second row
    BtnCopy = addButton(tr("Copy"), bottomLayout, 1, 1);
    BtnDelete = addButton(tr("Delete"), bottomLayout, 1, 2);

    bottomLayout->setColumnStretch(1,1);
    bottomLayout->setColumnStretch(2,1);

    return bottomLayout;
}

void PageSelectWeapon::connectSignals()
{
    connect(BtnDefault, SIGNAL(clicked()), pWeapons, SLOT(setDefault()));
    connect(this, SIGNAL(goBack()), pWeapons, SLOT(save()));
    connect(BtnNew, SIGNAL(clicked()), pWeapons, SLOT(newWeaponsName()));
    connect(BtnCopy, SIGNAL(clicked()), pWeapons, SLOT(copy()));
    connect(selectWeaponSet, SIGNAL(currentIndexChanged(const QString&)), pWeapons, SLOT(setWeaponsName(const QString&)));
}

PageSelectWeapon::PageSelectWeapon(QWidget* parent) :  AbstractPage(parent)
{
    initPage();
}
