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
#include <QLabel>
#include <QListWidget>
#include <QListWidgetItem>
#include <QPushButton>

#include "pagetraining.h"
#include "hwconsts.h"

QLayout * PageTraining::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();

// left column

    // declare start button, caption and description
    btnStart = formattedButton(":/res/Trainings.png", true);
    btnStart->setToolTip(QPushButton::tr("Go!"));
    lblCaption = new QLabel(this);
    lblDescription = new QLabel(this);
    lblDescription->setWordWrap(true);

    // add start button, caption and description to 3 different rows
    pageLayout->addWidget(btnStart, 0, 0);
    pageLayout->addWidget(lblCaption, 1, 0);
    pageLayout->addWidget(lblDescription, 2, 0);

    // make first and last row stretch vertically
    pageLayout->setRowStretch(0, 1);
    pageLayout->setRowStretch(1, 0);
    pageLayout->setRowStretch(2, 1);

    // make both columns equal width
    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 1);

    // center widgets within their grid cells
    pageLayout->setAlignment(btnStart, Qt::AlignHCenter | Qt::AlignVCenter);
    pageLayout->setAlignment(lblCaption, Qt::AlignHCenter | Qt::AlignVCenter);
    pageLayout->setAlignment(lblDescription, Qt::AlignHCenter | Qt::AlignVCenter);

// right column

    lstMissions = new QListWidget(this);
    pageLayout->addWidget(lstMissions, 0, 1, 3, 1); // spans over 3 rows

    return pageLayout;
}


void PageTraining::connectSignals()
{
    connect(lstMissions, SIGNAL(itemSelectionChanged()), this, SLOT(updateInfo()));
    connect(lstMissions, SIGNAL(itemDoubleClicked(QListWidgetItem *)), this, SLOT(startSelected()));
    connect(btnStart, SIGNAL(clicked()), this, SLOT(startSelected()));
}


PageTraining::PageTraining(QWidget* parent) : AbstractPage(parent)
{
    initPage();

    QDir tmpdir;
    tmpdir.cd(cfgdir->absolutePath());
    tmpdir.cd("Data/Missions/Training");
    QStringList missionList = scriptList(tmpdir);
    missionList.sort();
    missionList.replaceInStrings(QRegExp("$")," *");

    tmpdir.cd(datadir->absolutePath());
    tmpdir.cd("Missions/Training");
    QStringList defaultList = scriptList(tmpdir);
    defaultList.sort();

    missionList << defaultList;

    // add only default scripts that have names different from detected user scripts
    foreach (const QString & mission, missionList)
    {
        QListWidgetItem * item = new QListWidgetItem(mission);

        // replace underscores in mission name with spaces
        item->setText(item->text().replace("_", " "));

        // store original name in data
        item->setData(Qt::UserRole, mission);

        lstMissions->addItem(item);
    }

    updateInfo();
}

QStringList PageTraining::scriptList(const QDir & scriptDir) const
{
    QDir dir = scriptDir;
    dir.setFilter(QDir::Files);
    return dir.entryList(QStringList("*.lua")).replaceInStrings(QRegExp("^(.*)\\.lua"), "\\1");
}


void PageTraining::startSelected()
{
    emit startMission(lstMissions->currentItem()->data(Qt::UserRole).toString());
}


void PageTraining::updateInfo()
{
    if (lstMissions->currentItem())
    {
        QString thumbFile = datadir->absolutePath() + "/Graphics/Missions/Training/" + lstMissions->currentItem()->data(Qt::UserRole).toString() + ".png";
        if (QFile::exists(thumbFile))
            btnStart->setIcon(QIcon(thumbFile));
        else
            btnStart->setIcon(QIcon(":/res/Trainings.png"));

        lblCaption->setText(lstMissions->currentItem()->text());
        // TODO load mission description from file
        lblDescription->setText("< Imagine\nMission\nDescription\nhere >\n\nThank you.");
    }
    else
    {
        btnStart->setIcon(QIcon(":/res/Trainings.png"));
        lblCaption->setText(tr("Select a mission on the right -->"));
        // TODO better text and tr()
        lblDescription->setText("Welcome to the Training screen.\n\n\n...\nWHAT?\nIt's not finished yet...");
    }
}
