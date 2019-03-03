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
    pWeapons->init();
    pageLayout->addWidget(pWeapons);

    return pageLayout;
}

QLayout * PageSelectWeapon::footerLayoutDefinition()
{
    QGridLayout * bottomLayout = new QGridLayout();

    selectWeaponSet = new QComboBox(this);
    selectWeaponSet->setMaxVisibleItems(50);
    bottomLayout->addWidget(selectWeaponSet, 0, 0, 2, 1);

    // first row
    BtnNew = addButton(tr("New"), bottomLayout, 0, 1);
    BtnNew->setStyleSheet("padding: 3px;");
    BtnDefault = addButton(tr("Default"), bottomLayout, 0, 2);
    BtnDefault->setStyleSheet("padding: 3px;");

    // second row
    BtnCopy = addButton(tr("Copy"), bottomLayout, 1, 1);
    BtnCopy->setStyleSheet("padding: 3px;");
    BtnDelete = addButton(tr("Delete"), bottomLayout, 1, 2);
    BtnDelete->setStyleSheet("padding: 3px;");

    bottomLayout->setColumnStretch(1,1);
    bottomLayout->setColumnStretch(2,1);

    return bottomLayout;
}

void PageSelectWeapon::connectSignals()
{
    connect(selectWeaponSet, SIGNAL(currentIndexChanged(const QString&)), pWeapons, SLOT(switchWeapons(const QString&)));
    connect(BtnDefault, SIGNAL(clicked()), pWeapons, SLOT(setDefault()));
    connect(this, SIGNAL(goBack()), pWeapons, SLOT(save()));
    connect(BtnNew, SIGNAL(clicked()), pWeapons, SLOT(newWeaponsName()));
    connect(BtnCopy, SIGNAL(clicked()), pWeapons, SLOT(copy()));
    connect(BtnDelete, SIGNAL(clicked()), pWeapons, SLOT(deleteWeaponsName()));
}

PageSelectWeapon::PageSelectWeapon(QWidget* parent) :  AbstractPage(parent)
{
    initPage();
}
