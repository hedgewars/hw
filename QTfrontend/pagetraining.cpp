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

#include "pagetraining.h"
#include "hwconsts.h"

PageTraining::PageTraining(QWidget* parent) : AbstractPage(parent)
{
    QGridLayout * pageLayout = new QGridLayout(this);
    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 2);
    pageLayout->setColumnStretch(2, 1);
    pageLayout->setRowStretch(0, 1);
    pageLayout->setRowStretch(2, 1);

    CBSelect = new QComboBox(this);

    QDir tmpdir;
    tmpdir.cd(cfgdir->absolutePath());
    tmpdir.cd("Data/Missions/Training");
    tmpdir.setFilter(QDir::Files);
    QStringList userlist = tmpdir.entryList(QStringList("*.lua")).replaceInStrings(QRegExp("^(.*)\\.lua"), "\\1");
    CBSelect->addItems(userlist);

    tmpdir.cd(datadir->absolutePath());
    tmpdir.cd("Missions/Training");
    tmpdir.setFilter(QDir::Files);
    QStringList tmplist = tmpdir.entryList(QStringList("*.lua")).replaceInStrings(QRegExp("^(.*)\\.lua"), "\\1");
    QStringList datalist;
    for (QStringList::Iterator it = tmplist.begin(); it != tmplist.end(); ++it)
        if (!userlist.contains(*it,Qt::CaseInsensitive)) datalist.append(*it);
    CBSelect->addItems(datalist);

    for(int i = 0; i < CBSelect->count(); i++)
    {
        CBSelect->setItemData(i, CBSelect->itemText(i));
        CBSelect->setItemText(i, CBSelect->itemText(i).replace("_", " "));
    }

    pageLayout->addWidget(CBSelect, 1, 1);
    
    BtnStartTrain = new QPushButton(this);
    BtnStartTrain->setFont(*font14);
    BtnStartTrain->setText(QPushButton::tr("Go!"));
    pageLayout->addWidget(BtnStartTrain, 1, 2);


    BtnBack = addButton(":/res/Exit.png", pageLayout, 3, 0, true);
    connect(BtnBack, SIGNAL(clicked()), this, SIGNAL(goBack()));
}
