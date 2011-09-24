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

#include "pageinfo.h"
#include "about.h"

PageInfo::PageInfo(QWidget* parent) : AbstractPage(parent)
{
    QGridLayout * pageLayout = new QGridLayout(this);
    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 1);
    pageLayout->setColumnStretch(2, 1);

    BtnSnapshots = addButton(":/res/Star.png", pageLayout, 1, 2, true);

    about = new About(this);
    pageLayout->addWidget(about, 0, 0, 1, 3);


    BtnBack = addButton(":/res/Exit.png", pageLayout, 1, 0, true);
    connect(BtnBack, SIGNAL(clicked()), this, SIGNAL(goBack()));
}
