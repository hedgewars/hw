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
    QHBoxLayout * pageLayout = new QHBoxLayout();

    gameCFG = new GameCFGWidget(this);
    pageLayout->addWidget(gameCFG, 3, Qt::AlignTop);

    teamsSelect = new TeamSelWidget(this);
    pageLayout->addWidget(teamsSelect, 2, Qt::AlignTop);

    return pageLayout;
}

QLayout * PageMultiplayer::footerLayoutLeftDefinition()
{
    QHBoxLayout * bottomLeftLayout = new QHBoxLayout();

    btnSetup = addButton(":/res/Settings.png", bottomLeftLayout, 0, true);
    btnSetup->setWhatsThis(tr("Edit game preferences"));

    return bottomLeftLayout;
}

QLayout * PageMultiplayer::footerLayoutDefinition()
{
    QHBoxLayout * footerLayout = new QHBoxLayout();

    const QIcon& lp = QIcon(":/res/Start.png");
    QSize sz = lp.actualSize(QSize(65535, 65535));
    BtnStartMPGame = new QPushButton();
    BtnStartMPGame->setText(tr("Start"));
    BtnStartMPGame->setMinimumWidth(sz.width() + 60);
    BtnStartMPGame->setIcon(lp);
    BtnStartMPGame->setFixedHeight(50);
    BtnStartMPGame->setIconSize(sz);
    BtnStartMPGame->setFlat(true);
    BtnStartMPGame->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);

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
