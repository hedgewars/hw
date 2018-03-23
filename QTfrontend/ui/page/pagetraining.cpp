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

#include <QTextStream>
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


    // tab widget containing all lists
    tbw = new QTabWidget(this);
    pageLayout->addWidget(tbw, 1, 0, 1, 2); // span 2 columns
    // let's not make the tab widget use more space than needed
    tbw->setFixedWidth(400);
    pageLayout->setAlignment(tbw, Qt::AlignHCenter);
    
    tbw->setStyleSheet("QListWidget { border-style: none; padding-top: 6px; }");

    // training/challenge/scenario lists
    lstTrainings = new QListWidget(this);
    lstTrainings ->setWhatsThis(tr("Pick the training to play"));

    lstChallenges = new QListWidget(this);
    lstChallenges ->setWhatsThis(tr("Pick the challenge to play"));

    lstScenarios= new QListWidget(this);
    lstScenarios->setWhatsThis(tr("Pick the scenario to play"));

    tbw->addTab(lstTrainings, tr("Trainings"));
    tbw->addTab(lstChallenges, tr("Challenges"));
    tbw->addTab(lstScenarios, tr("Scenarios"));
    tbw->setCurrentWidget(lstTrainings);

    return pageLayout;
}

QLayout * PageTraining::footerLayoutDefinition()
{
    QBoxLayout * bottomLayout = new QVBoxLayout();

    const QIcon& lp = QIcon(":/res/Start.png");
    QSize sz = lp.actualSize(QSize(65535, 65535));
    btnStart = new QPushButton();
    btnStart->setStyleSheet("padding: 5px 10px");
    btnStart->setText(QPushButton::tr("Start"));
    btnStart->setWhatsThis(tr("Start fighting"));
    btnStart->setMinimumWidth(sz.width() + 60);
    btnStart->setIcon(lp);
    btnStart->setFixedHeight(50);
    btnStart->setIconSize(sz);
    btnStart->setFlat(true);
    btnStart->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);

    bottomLayout->addWidget(btnStart);

    bottomLayout->setAlignment(btnStart, Qt::AlignRight | Qt::AlignVCenter);

    return bottomLayout;
}


void PageTraining::connectSignals()
{
    connect(lstTrainings, SIGNAL(currentItemChanged(QListWidgetItem*, QListWidgetItem*)), this, SLOT(updateInfo()));
    connect(lstTrainings, SIGNAL(itemClicked(QListWidgetItem*)), this, SLOT(updateInfo()));
    connect(lstTrainings, SIGNAL(itemDoubleClicked(QListWidgetItem*)), this, SLOT(startSelected()));

    connect(lstChallenges, SIGNAL(currentItemChanged(QListWidgetItem*, QListWidgetItem*)), this, SLOT(updateInfo()));
    connect(lstChallenges, SIGNAL(itemClicked(QListWidgetItem*)), this, SLOT(updateInfo()));
    connect(lstChallenges, SIGNAL(itemDoubleClicked(QListWidgetItem*)), this, SLOT(startSelected()));

    connect(lstScenarios, SIGNAL(currentItemChanged(QListWidgetItem*, QListWidgetItem*)), this, SLOT(updateInfo()));
    connect(lstScenarios, SIGNAL(itemClicked(QListWidgetItem*)), this, SLOT(updateInfo()));
    connect(lstScenarios, SIGNAL(itemDoubleClicked(QListWidgetItem*)), this, SLOT(startSelected()));

    connect(tbw, SIGNAL(currentChanged(int)), this, SLOT(updateInfo()));

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

    QString loc = QLocale().name();

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

    QStringList m_list;
    QListWidget * m_widget;
    QString subFolder;

    for(int i=1; i<=3; i++) {
        switch(i) {
            case 1:
                subFolder = "Training";
                m_widget = lstTrainings;
                break;
            case 2:
                subFolder = "Challenge";
                m_widget = lstChallenges;
                break;
            case 3:
                subFolder = "Scenario";
                m_widget = lstScenarios;
                break;
        }
        // scripts to load
        // first, load scripts in order specified in order.cfg (if present)
        QFile orderFile(QString("physfs://Missions/%1/order.cfg").arg(subFolder));
        QStringList orderedMissions;
        if (orderFile.open(QFile::ReadOnly))
        {
            QString m_id;
            QTextStream input(&orderFile);
            while(true)
            {
                m_id = input.readLine();
                if(m_id.isNull() || m_id.isEmpty())
                {
                    break;
                }
                QListWidgetItem * item = new QListWidgetItem(m_id);
                QString name = item->text().replace("_", " ");
                name = m_info->value(m_id + ".name", name).toString();
                item->setText(name);
                item->setData(Qt::UserRole, m_id);
                m_widget->addItem(item);

                orderedMissions << m_id;
            }
        }

        // then, just load anything else in no particular order
        m_list = dataMgr.entryList(
                    "Missions/" + subFolder,
                    QDir::Files, QStringList("*.lua")).
               replaceInStrings(QRegExp("\\.lua$"), "");

        foreach (const QString & m_id, m_list)
        {
            // Disallow duplicates from order.cfg
            if (orderedMissions.contains(m_id))
            {
                continue;
            }

            QListWidgetItem * item = new QListWidgetItem(m_id);

            // fallback name: replace underscores in mission name with spaces
            QString name = item->text().replace("_", " ");

            // see if we can get a prettier/translated name
            name = m_info->value(m_id + ".name", name).toString();

            item->setText(name);

            // store original name in data
            item->setData(Qt::UserRole, m_id);

            m_widget->addItem(item);
        }
    }

    updateInfo();

    // pre-select first mission
    if (lstTrainings->count() > 0)
        lstTrainings->setCurrentRow(0);

    if (lstChallenges->count() > 0)
        lstChallenges->setCurrentRow(0);

    if (lstScenarios->count() > 0)
        lstScenarios->setCurrentRow(0);
}

QString PageTraining::getSubFolderOfSelected()
{
    QString subFolder;
    if (tbw->currentWidget() == lstTrainings) {
        subFolder = "Training";
    } else if (tbw->currentWidget() == lstChallenges) {
        subFolder = "Challenge";
    } else if (tbw->currentWidget() == lstScenarios) {
        subFolder = "Scenario";
    } else {
        subFolder = "Training";
    }
    return subFolder;
}

void PageTraining::startSelected()
{
    QListWidget *list;
    list = (QListWidget*) tbw->currentWidget();
    QListWidgetItem * curItem = list->currentItem();

    if (curItem != NULL)
        emit startMission(curItem->data(Qt::UserRole).toString(), getSubFolderOfSelected());
}


void PageTraining::updateInfo()
{
    if (tbw->currentWidget())
    {
        QString subFolder;
        QListWidget *list;
        subFolder = getSubFolderOfSelected();
        list = (QListWidget*) tbw->currentWidget();
        if (list->currentItem())
        {
            // TODO also use .pngs in userdata folder
            QString thumbFile =     "physfs://Graphics/Missions/" +
                                    subFolder + "/" +
                                    list->currentItem()->data(Qt::UserRole).toString() +
                                    "@2x.png";

            if (QFile::exists(thumbFile))
                btnPreview->setIcon(QIcon(thumbFile));
            else
                btnPreview->setIcon(QIcon(":/res/Trainings.png"));

            btnPreview->setWhatsThis(tr("Start fighting"));

            QString realName = list->currentItem()->data(
                                    Qt::UserRole).toString();

            QString caption = m_info->value(realName + ".name",
                                            list->currentItem()->text()).toString();

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
}
