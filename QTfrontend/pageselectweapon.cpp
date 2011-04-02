/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QGridLayout>
#include <QPushButton>
#include <QComboBox>

#include "pages.h"
#include "hwconsts.h"
#include "selectWeapon.h"

PageSelectWeapon::PageSelectWeapon(QWidget* parent) :
  AbstractPage(parent)
{
    QGridLayout * pageLayout = new QGridLayout(this);

    pWeapons = new SelWeaponWidget(cAmmoNumber, this);
    pageLayout->addWidget(pWeapons, 0, 0, 1, 5);

    BtnBack = addButton(":/res/Exit.png", pageLayout, 1, 0, 2, 1, true);
    BtnDefault = addButton(tr("Default"), pageLayout, 1, 3);
    BtnNew = addButton(tr("New"), pageLayout, 1, 2);
    BtnCopy = addButton(tr("Copy"), pageLayout, 2, 2);
    BtnDelete = addButton(tr("Delete"), pageLayout, 2, 3);
    BtnSave = addButton(":/res/Save.png", pageLayout, 1, 4, 2, 1, true);
    BtnSave->setStyleSheet("QPushButton{margin: 24px 0px 0px 0px;}");
    BtnBack->setFixedHeight(BtnSave->height());
    BtnBack->setStyleSheet("QPushButton{margin-top: 31px;}");

    selectWeaponSet = new QComboBox(this);
    pageLayout->addWidget(selectWeaponSet, 1, 1, 2, 1);

    connect(BtnDefault, SIGNAL(clicked()), pWeapons, SLOT(setDefault()));
    connect(BtnSave, SIGNAL(clicked()), pWeapons, SLOT(save()));
    connect(BtnNew, SIGNAL(clicked()), pWeapons, SLOT(newWeaponsName()));
    connect(BtnCopy, SIGNAL(clicked()), pWeapons, SLOT(copy()));
    connect(selectWeaponSet, SIGNAL(currentIndexChanged(const QString&)), pWeapons, SLOT(setWeaponsName(const QString&)));
}
