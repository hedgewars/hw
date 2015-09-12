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
#include <QPushButton>
#include <QComboBox>
#include <QLabel>

#include "pagecampaign.h"

QLayout * PageCampaign::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();
    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 2);
    pageLayout->setColumnStretch(2, 1);
    pageLayout->setRowStretch(0, 1);
    pageLayout->setRowStretch(3, 1);

    QGridLayout * infoLayout = new QGridLayout();
    infoLayout->setColumnStretch(0, 1);
    infoLayout->setColumnStretch(1, 1);
    infoLayout->setColumnStretch(2, 1);
    infoLayout->setColumnStretch(3, 1);
    infoLayout->setColumnStretch(4, 1);
    infoLayout->setRowStretch(0, 1);
    infoLayout->setRowStretch(1, 1);

    // set this as default image first time page is created, this will change in hwform.cpp
    btnPreview = formattedButton(":/res/campaign/A_Classic_Fairytale/first_blood.png", true);
    infoLayout->setAlignment(btnPreview, Qt::AlignHCenter | Qt::AlignVCenter);

    lbldescription = new QLabel(this);
    lbldescription->setAlignment(Qt::AlignHCenter| Qt::AlignTop);
    lbldescription->setWordWrap(true);

    lbltitle = new QLabel();
    lbltitle->setAlignment(Qt::AlignHCenter | Qt::AlignBottom);

    CBTeam = new QComboBox(this);
    CBMission = new QComboBox(this);
    CBCampaign = new QComboBox(this);

    infoLayout->addWidget(btnPreview,0,1,2,1);
    infoLayout->addWidget(lbltitle,0,2,1,2);
    infoLayout->addWidget(lbldescription,1,2,1,2);

    pageLayout->addLayout(infoLayout, 0, 0, 2, 3);
    pageLayout->addWidget(CBTeam, 2, 1);
    pageLayout->addWidget(CBCampaign, 3, 1);
    pageLayout->addWidget(CBMission, 4, 1);

    BtnStartCampaign = new QPushButton(this);
    BtnStartCampaign->setFont(*font14);
    BtnStartCampaign->setText(QPushButton::tr("Go!"));
    pageLayout->addWidget(BtnStartCampaign, 3, 2);

    return pageLayout;
}

PageCampaign::PageCampaign(QWidget* parent) : AbstractPage(parent)
{
    initPage();
}


