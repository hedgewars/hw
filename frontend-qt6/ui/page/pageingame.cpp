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

#include <QHBoxLayout>
#include <QLabel>

#include "pageingame.h"

QLayout * PageInGame::bodyLayoutDefinition()
{
    QHBoxLayout * pageLayout = new QHBoxLayout();

    QLabel * label = new QLabel(this);
    label->setText(tr("In game..."));
    pageLayout->addWidget(label);

    setBackButtonVisible(false);

    return pageLayout;
}

PageInGame::PageInGame(QWidget * parent) :  AbstractPage(parent)
{
    initPage();
}
