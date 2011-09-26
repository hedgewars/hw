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

QLayout * PageTraining::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();

    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 2);
    pageLayout->setColumnStretch(2, 1);
    pageLayout->setRowStretch(0, 1);
    pageLayout->setRowStretch(2, 1);

    CBSelect = new QComboBox(this);

    pageLayout->addWidget(CBSelect, 1, 1);
    
    BtnStartTrain = new QPushButton(this);
    BtnStartTrain->setFont(*font14);
    BtnStartTrain->setText(QPushButton::tr("Go!"));
    pageLayout->addWidget(BtnStartTrain, 1, 2);

    return pageLayout;
}

void PageTraining::connectSignals()
{
    //TODO
}

PageTraining::PageTraining(QWidget* parent) : AbstractPage(parent)
{
    initPage();

    QDir tmpdir;
    tmpdir.cd(cfgdir->absolutePath());
    tmpdir.cd("Data/Missions/Training");
    QStringList userlist = scriptList(tmpdir);

    tmpdir.cd(datadir->absolutePath());
    tmpdir.cd("Missions/Training");
    QStringList defaultlist = scriptList(tmpdir);

    CBSelect->addItems(userlist);

    // add only default scripts that have names different from detected user scripts
    foreach (const QString & line, defaultlist)
    {
        if (!userlist.contains(line,Qt::CaseInsensitive)) CBSelect->addItem(line);
    }

    // replace underscores with spaces in the displayed that
    for(int i = 0; i < CBSelect->count(); i++)
    {
        QString text = CBSelect->itemText(i);
        CBSelect->setItemData(i, text);
        CBSelect->setItemText(i, text.replace("_", " "));
//        if (userlist.contains(text))
//            CBSelect->setItemText(i, text + " (" + AbstractPage::tr("custom") + ")");
    }
}

QStringList PageTraining::scriptList(const QDir & scriptDir) const
{
    QDir dir = scriptDir;
    dir.setFilter(QDir::Files);
    return dir.entryList(QStringList("*.lua")).replaceInStrings(QRegExp("^(.*)\\.lua"), "\\1");
}
