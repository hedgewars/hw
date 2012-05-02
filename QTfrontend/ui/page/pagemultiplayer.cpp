/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

/**
 * @file
 * @brief PageMultiplayer class implementation
 */

#include <QGridLayout>
#include <QHBoxLayout>
#include <QPushButton>

#include "pagemultiplayer.h"
#include "gamecfgwidget.h"
#include "teamselect.h"

QLayout * PageMultiplayer::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();

    gameCFG = new GameCFGWidget(this);
    pageLayout->addWidget(gameCFG, 0, 0, 1, 2);

    btnSetup = new QPushButton(this);
    btnSetup->setText(QPushButton::tr("Setup"));
    pageLayout->addWidget(btnSetup, 1, 0, 1, 2);

    pageLayout->setRowStretch(2, 1);

    teamsSelect = new TeamSelWidget(this);
    pageLayout->addWidget(teamsSelect, 0, 2, 3, 2);

    return pageLayout;
}

QLayout * PageMultiplayer::footerLayoutDefinition()
{
    QHBoxLayout * footerLayout = new QHBoxLayout();

    BtnStartMPGame = formattedButton(tr("Start"));
    BtnStartMPGame->setMinimumWidth(180);

    footerLayout->addStretch();
    footerLayout->addWidget(BtnStartMPGame);

    return footerLayout;
}

void PageMultiplayer::connectSignals()
{
    PageMultiplayer::connect(btnSetup, SIGNAL(clicked()), this, SIGNAL(SetupClicked()));
}

PageMultiplayer::PageMultiplayer(QWidget* parent) : AbstractPage(parent)
{
    initPage();
}
