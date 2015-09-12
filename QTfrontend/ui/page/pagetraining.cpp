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
#include <QVBoxLayout>
#include <QLabel>
#include <QListWidget>
#include <QListWidgetItem>
#include <QPushButton>

#include <QFile>
#include <QLocale>
#include <QSettings>

#include "hwconsts.h"
#include "DataManager.h"

#include "pagetraining.h"

QLayout * PageTraining::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();

// left column

    // declare start button, caption and description
    btnPreview = formattedButton(":/res/Trainings.png", true);

    // make both rows equal height
    pageLayout->setRowStretch(0, 1);
    pageLayout->setRowStretch(1, 1);

    // add start button, caption and description to 3 different rows
    pageLayout->addWidget(btnPreview, 0, 0);

    // center preview
    pageLayout->setAlignment(btnPreview, Qt::AlignRight | Qt::AlignVCenter);


// right column

    // info area (caption on top, description below)
    QVBoxLayout * infoLayout = new QVBoxLayout();

    lblCaption = new QLabel();
    lblCaption->setMinimumWidth(360);
    lblCaption->setAlignment(Qt::AlignHCenter | Qt::AlignBottom);
    lblCaption->setWordWrap(true);
    lblDescription = new QLabel();
    lblDescription->setMinimumWidth(360);
    lblDescription->setAlignment(Qt::AlignHCenter | Qt::AlignTop);
    lblDescription->setWordWrap(true);

    infoLayout->addWidget(lblCaption);
    infoLayout->addWidget(lblDescription);

    pageLayout->addLayout(infoLayout, 0, 1);
    pageLayout->setAlignment(infoLayout, Qt::AlignLeft);


    // mission list
    lstMissions = new QListWidget(this);
    lstMissions->setWhatsThis(tr("Pick the mission or training to play"));
    pageLayout->addWidget(lstMissions, 1, 0, 1, 2); // span 2 columns

    // let's not make the list use more space than needed
    lstMissions->setFixedWidth(400);
    pageLayout->setAlignment(lstMissions, Qt::AlignHCenter);

    return pageLayout;
}

QLayout * PageTraining::footerLayoutDefinition()
{
    QBoxLayout * bottomLayout = new QVBoxLayout();

    btnStart = formattedButton(QPushButton::tr("Go!"));
    btnStart->setWhatsThis(tr("Start fighting"));
    btnStart->setFixedWidth(140);

    bottomLayout->addWidget(btnStart);

    bottomLayout->setAlignment(btnStart, Qt::AlignRight | Qt::AlignVCenter);

    return bottomLayout;
}


void PageTraining::connectSignals()
{
    connect(lstMissions, SIGNAL(currentItemChanged(QListWidgetItem*, QListWidgetItem*)), this, SLOT(updateInfo()));
    connect(lstMissions, SIGNAL(itemClicked(QListWidgetItem*)), this, SLOT(updateInfo()));
    connect(lstMissions, SIGNAL(itemDoubleClicked(QListWidgetItem*)), this, SLOT(startSelected()));
    connect(btnPreview, SIGNAL(clicked()), this, SLOT(startSelected()));
    connect(btnStart, SIGNAL(clicked()), this, SLOT(startSelected()));
}


PageTraining::PageTraining(QWidget* parent) : AbstractPage(parent)
{
    initPage();

    DataManager & dataMgr = DataManager::instance();

    // get locale
    QSettings settings(dataMgr.settingsFileName(),
                       QSettings::IniFormat);

    QString loc = settings.value("misc/locale", "").toString();
    if (loc.isEmpty())
        loc = QLocale::system().name();

    QString infoFile = QString("physfs://Locale/missions_" + loc + ".txt");

    // if file is non-existant try with language only
    if (!QFile::exists(infoFile))
        infoFile = QString("physfs://Locale/missions_" + loc.remove(QRegExp("_.*$")) + ".txt");

    // fallback if file for current locale is non-existant
    if (!QFile::exists(infoFile))
        infoFile = QString("physfs://Locale/missions_en.txt");


    // preload mission info for current locale
    m_info = new QSettings(infoFile, QSettings::IniFormat, this);
    m_info->setIniCodec("UTF-8");


    QStringList missionList = dataMgr.entryList(
                                  "Missions/Training",
                                  QDir::Files, QStringList("*.lua")).
                              replaceInStrings(QRegExp("\\.lua$"), "");

    // scripts to lost - TODO: model?
    foreach (const QString & mission, missionList)
    {
        QListWidgetItem * item = new QListWidgetItem(mission);

        // fallback name: replace underscores in mission name with spaces
        QString name = item->text().replace("_", " ");

        // see if we can get a prettier/translated name
        name = m_info->value(mission + ".name", name).toString();

        item->setText(name);

        // store original name in data
        item->setData(Qt::UserRole, mission);

        lstMissions->addItem(item);
    }

    updateInfo();

    // pre-select first mission
    if (lstMissions->count() > 0)
        lstMissions->setCurrentRow(0);
}


void PageTraining::startSelected()
{
    QListWidgetItem * curItem = lstMissions->currentItem();

    if (curItem != NULL)
        emit startMission(curItem->data(Qt::UserRole).toString());
}


void PageTraining::updateInfo()
{
    if (lstMissions->currentItem())
    {
        // TODO also use .pngs in userdata folder
        QString thumbFile =     "physfs://Graphics/Missions/Training/" +
                                lstMissions->currentItem()->data(Qt::UserRole).toString() +
                                "@2x.png";

        if (QFile::exists(thumbFile))
            btnPreview->setIcon(QIcon(thumbFile));
        else
            btnPreview->setIcon(QIcon(":/res/Trainings.png"));

        QString realName = lstMissions->currentItem()->data(
                               Qt::UserRole).toString();

        QString caption = m_info->value(realName + ".name",
                                        lstMissions->currentItem()->text()).toString();

        QString description = m_info->value(realName + ".desc",
                                            tr("No description available")).toString();

        lblCaption->setText("<h2>" + caption +"</h2>");
        lblDescription->setText(description);
    }
    else
    {
        btnPreview->setIcon(QIcon(":/res/Trainings.png"));
        lblCaption->setText(tr("Select a mission!"));
        // TODO better text and tr()
        lblDescription->setText("");
    }
}
