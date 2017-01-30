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
#include <QHBoxLayout>
#include <QPushButton>
#include <QComboBox>
#include <QLabel>
#include <QLineEdit>
#include <QTabWidget>
#include <QGroupBox>
#include <QToolBox>
#include <QMessageBox>
#include <QStandardItemModel>
#include <QDebug>
#include "SquareLabel.h"
#include "HWApplication.h"
#include "keybinder.h"

#include "DataManager.h"
#include "hatbutton.h"

#include "pageeditteam.h"

QLayout * PageEditTeam::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();
    tbw = new QTabWidget();
    QWidget * page1 = new QWidget(this);
    binder = new KeyBinder(this, tr("Select an action to choose a custom key bind for this team"), tr("Use my default"), tr("Reset all binds"));
    connect(binder, SIGNAL(resetAllBinds()), this, SLOT(resetAllBinds()));
    tbw->addTab(page1, tr("General"));
    tbw->addTab(binder, tr("Custom Controls"));
    pageLayout->addWidget(tbw, 0, 0, 1, 3);

    QHBoxLayout * page1Layout = new QHBoxLayout(page1);
    page1Layout->setAlignment(Qt::AlignTop);

// ====== Page 1 ======
    QVBoxLayout * vbox1 = new QVBoxLayout();
    QVBoxLayout * vbox2 = new QVBoxLayout();
    page1Layout->addLayout(vbox1);
    page1Layout->addLayout(vbox2);

    GBoxHedgehogs = new QGroupBox(this);
    GBoxHedgehogs->setTitle(QGroupBox::tr("Team Members"));
    GBoxHedgehogs->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
    QGridLayout * GBHLayout = new QGridLayout(GBoxHedgehogs);


    GBHLayout->addWidget(new QLabel(tr("Hat")), 0, 0);
    GBHLayout->addWidget(new QLabel(tr("Name")), 0, 1);

    for(int i = 0; i < HEDGEHOGS_PER_TEAM; i++)
    {
        HHHats[i] = new HatButton(GBoxHedgehogs);
        GBHLayout->addWidget(HHHats[i], i + 1, 0);

        HHNameEdit[i] = new QLineEdit(GBoxHedgehogs);
        HHNameEdit[i]->setMaxLength(64);
        HHNameEdit[i]->setMinimumWidth(120);
        HHNameEdit[i]->setFixedHeight(36);
        HHNameEdit[i]->setWhatsThis(tr("This hedgehog's name"));
        HHNameEdit[i]->setStyleSheet("padding: 6px;");
        GBHLayout->addWidget(HHNameEdit[i], i + 1, 1);

        btnRandomHogName[i] = addButton(":/res/dice.png", GBHLayout, i + 1, 3, 1, 1, true);
        btnRandomHogName[i]->setFixedHeight(HHNameEdit[i]->height());
        btnRandomHogName[i]->setWhatsThis(tr("Randomize this hedgehog's name"));
    }

    btnRandomTeam = new QPushButton();
    btnRandomTeam->setText(tr("Random Team"));
    btnRandomTeam->setStyleSheet("padding: 6px 10px;");
    GBHLayout->addWidget(btnRandomTeam, 9, 0, 1, 4, Qt::AlignCenter);
    btnRandomTeam->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);

    vbox1->addWidget(GBoxHedgehogs);

    GBoxTeam = new QGroupBox(this);
    GBoxTeam->setTitle(QGroupBox::tr("Team Settings"));
    GBoxTeam->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
    QGridLayout * GBTLayout = new QGridLayout(GBoxTeam);
    QLabel * tmpLabel = new QLabel(GBoxTeam);
    tmpLabel->setText(QLabel::tr("Name"));
    GBTLayout->addWidget(tmpLabel, 0, 0);
    tmpLabel = new QLabel(GBoxTeam);
    tmpLabel->setText(QLabel::tr("Player"));
    GBTLayout->addWidget(tmpLabel, 1, 0);
    tmpLabel = new QLabel(GBoxTeam);
    tmpLabel->setText(QLabel::tr("Grave"));
    GBTLayout->addWidget(tmpLabel, 2, 0);
    tmpLabel = new QLabel(GBoxTeam);
    tmpLabel->setText(QLabel::tr("Flag"));
    GBTLayout->addWidget(tmpLabel, 3, 0);
    tmpLabel = new QLabel(GBoxTeam);
    tmpLabel->setText(QLabel::tr("Voice"));
    GBTLayout->addWidget(tmpLabel, 4, 0);

    TeamNameEdit = new QLineEdit(GBoxTeam);
    TeamNameEdit->setMaxLength(64);
    GBTLayout->addWidget(TeamNameEdit, 0, 1);
    vbox2->addWidget(GBoxTeam);

    CBTeamLvl = new QComboBox(GBoxTeam);
    CBTeamLvl->setIconSize(QSize(32, 32));
    CBTeamLvl->addItem(QIcon(":/res/botlevels/small0.png"), QComboBox::tr("Human"));
    for(int i = 5; i > 0; i--)
        CBTeamLvl->addItem(
            QIcon(QString(":/res/botlevels/small%1.png").arg(6 - i)),
            QComboBox::tr("Computer (Level %1)").arg(i)
        );
    CBTeamLvl->setFixedHeight(38);
    GBTLayout->addWidget(CBTeamLvl, 1, 1);

    CBGrave = new QComboBox(GBoxTeam);
    CBGrave->setMaxCount(65535);
    CBGrave->setMaxVisibleItems(20);
    CBGrave->setIconSize(QSize(32, 32));
    CBGrave->setFixedHeight(44);
    GBTLayout->addWidget(CBGrave, 2, 1);

    CBFlag = new QComboBox(GBoxTeam);
    CBFlag->setMaxCount(65535);
    CBFlag->setMaxVisibleItems(50);
    CBFlag->setIconSize(QSize(22, 15));
    GBTLayout->addWidget(CBFlag, 3, 1);

    QHBoxLayout * hbox = new QHBoxLayout();
    CBVoicepack = new QComboBox(GBoxTeam);
    CBVoicepack->setMaxVisibleItems(50);

    hbox->addWidget(CBVoicepack, 100);
    btnTestSound = addSoundlessButton(":/res/PlaySound.png", hbox, 1, true);
    btnTestSound->setWhatsThis(tr("Play a random example of this voice"));
    hbox->setStretchFactor(btnTestSound, 1);

    GBTLayout->addLayout(hbox, 4, 1);

    GBoxFort = new QGroupBox(this);
    GBoxFort->setTitle(QGroupBox::tr("Fort"));
    QGridLayout * GBFLayout = new QGridLayout(GBoxFort);
    CBFort = new QComboBox(GBoxFort);
    CBFort->setMaxVisibleItems(25);
    CBFort->setMaxCount(65535);
    GBFLayout->addWidget(CBFort, 0, 0);
    FortPreview = new SquareLabel(GBoxFort);
    FortPreview->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
    FortPreview->setMinimumSize(128, 128);
    FortPreview->setPixmap(QPixmap());
    // perhaps due to handling its own paintevents, SquareLabel doesn't play nice with the stars
    //FortPreview->setAttribute(Qt::WA_PaintOnScreen, true);
    GBFLayout->addWidget(FortPreview, 1, 0);
    vbox2->addWidget(GBoxFort);

    vbox1->addStretch();
    vbox2->addStretch();

    return pageLayout;
}

QLayout * PageEditTeam::footerLayoutDefinition()
{
    return NULL;
}

void PageEditTeam::connectSignals()
{
    connect(this, SIGNAL(pageLeave()), this, SLOT(saveTeam()));

    signalMapper1 = new QSignalMapper(this);
    signalMapper2 = new QSignalMapper(this);

    connect(signalMapper1, SIGNAL(mapped(int)), this, SLOT(fixHHname(int)));
    connect(signalMapper2, SIGNAL(mapped(int)), this, SLOT(setRandomName(int)));

    for(int i = 0; i < HEDGEHOGS_PER_TEAM; i++)
    {
        connect(HHNameEdit[i], SIGNAL(editingFinished()), signalMapper1, SLOT(map()));
        signalMapper1->setMapping(HHNameEdit[i], i);

        connect(btnRandomHogName[i], SIGNAL(clicked()), signalMapper2, SLOT(map()));
        signalMapper2->setMapping(btnRandomHogName[i], i);
    }

    connect(btnRandomTeam, SIGNAL(clicked()), this, SLOT(setRandomNames()));

    connect(btnTestSound, SIGNAL(clicked()), this, SLOT(testSound()));

    connect(CBFort, SIGNAL(currentIndexChanged(const QString &)), this, SLOT(CBFort_activated(const QString &)));
}

PageEditTeam::PageEditTeam(QWidget* parent) :
    AbstractPage(parent)
{
    initPage();

    m_playerHash = "0000000000000000000000000000000000000000";
    m_loaded = false;
}

void PageEditTeam::lazyLoad()
{
    if(m_loaded) return;
    m_loaded = true;
    qDebug("[LAZINESS] PageEditTeam::lazyLoad()");

    HatModel * hatsModel = DataManager::instance().hatModel();
    for(int i = 0; i < HEDGEHOGS_PER_TEAM; i++)
        HHHats[i]->setModel(hatsModel);


    QRegExp pngSuffix("\\.png$");
    DataManager & dataMgr = DataManager::instance();
    QStringList list;


    // voicepacks
    list = dataMgr.entryList("Sounds/voices",
                             QDir::AllDirs | QDir::NoDotAndDotDot);

    CBVoicepack->addItems(list);


    // forts
    list = dataMgr.entryList("Forts", QDir::Files, QStringList("*L.png"));
    list.replaceInStrings(QRegExp("L\\.png$"), "");
    CBFort->addItems(list);


    // graves
    list =
        dataMgr.entryList("Graphics/Graves", QDir::Files, QStringList("*.png"));

    foreach (QString file, list)
    {
        QPixmap pix("physfs://Graphics/Graves/" + file);
        if ((pix.height() > 32) || pix.width() > 32)
            pix = pix.copy(0, 0, 32, 32);
        QIcon icon(pix);

        QString grave = file.remove(pngSuffix);

        CBGrave->addItem(icon, grave);
    }

    // flags

    list =
        dataMgr.entryList("Graphics/Flags", QDir::Files, QStringList("*.png"));

    // skip cpu and hedgewars flags
    int idx = list.indexOf("cpu.png");
    if (idx >= 0)
        list.removeAt(idx);
    idx = list.indexOf("cpu_plain.png");
    if (idx >= 0)
        list.removeAt(idx);
    idx = list.indexOf("hedgewars.png");
    if (idx >= 0)
        list.removeAt(idx);

    // add the default flag
    QPixmap hwFlag("physfs://Graphics/Flags/hedgewars.png");
    CBFlag->addItem(QIcon(hwFlag.copy(0, 0, 22, 15)), "Hedgewars", "hedgewars");

    // add seperator after
    CBFlag->insertSeparator(1);

    int insertAt = 2; // insert country flags after Hedgewars flag and seperator

    // add all country flags
    foreach (const QString & file, list)
    {
        QIcon icon(QPixmap("physfs://Graphics/Flags/" + file));

        QString flag = QString(file).remove(pngSuffix);

        bool isCountryFlag = !file.startsWith("cm_");

        if (isCountryFlag)
        {
            CBFlag->insertItem(insertAt, icon, flag.replace("_", " "), flag);
            insertAt++;
        }
        else // append community flags at end
            CBFlag->addItem(icon, flag.replace("cm_", QComboBox::tr("Community") + ": "), flag);
    }

    // add separator between country flags and community flags
    CBFlag->insertSeparator(insertAt);
}

void PageEditTeam::fixHHname(int idx)
{
    HHNameEdit[idx]->setText(HHNameEdit[idx]->text().trimmed());

    if (HHNameEdit[idx]->text().isEmpty())
        HHNameEdit[idx]->setText(QLineEdit::tr("hedgehog %1").arg(idx+1));
}

void PageEditTeam::CBFort_activated(const QString & fortname)
{
    QPixmap pix("physfs://Forts/" + fortname + "L.png");
    FortPreview->setPixmap(pix);
}

void PageEditTeam::testSound()
{
    DataManager & dataMgr = DataManager::instance();

    QString voiceDir = QString("Sounds/voices/") + CBVoicepack->currentText();

    QStringList list = dataMgr.entryList(
                           voiceDir,
                           QDir::Files,
                           QStringList() <<
                           "Illgetyou.ogg" <<
                           "Incoming.ogg" <<
                           "Stupid.ogg" <<
                           "Coward.ogg" <<
                           "Firstblood.ogg"
                       );

    if (!list.isEmpty())
        SDLInteraction::instance().playSoundFile("/" + voiceDir + "/" +
                                    list[rand() % list.size()]);
}

void PageEditTeam::createTeam(const QString & name, const QString & playerHash)
{
    m_playerHash = playerHash;
    lazyLoad();

    HWTeam newTeam(name);
    loadTeam(newTeam);
}

void PageEditTeam::editTeam(const QString & name, const QString & playerHash)
{
    m_playerHash = playerHash;
    lazyLoad();

    HWTeam team(name);
    team.loadFromFile();
    loadTeam(team);
}

void PageEditTeam::deleteTeam(const QString & name)
{
    QMessageBox reallyDeleteMsg(this);
    reallyDeleteMsg.setIcon(QMessageBox::Question);
    reallyDeleteMsg.setWindowTitle(QMessageBox::tr("Teams - Are you sure?"));
    reallyDeleteMsg.setText(QMessageBox::tr("Do you really want to delete the team '%1'?").arg(name));
    reallyDeleteMsg.setWindowModality(Qt::WindowModal);
    reallyDeleteMsg.setStandardButtons(QMessageBox::Ok | QMessageBox::Cancel);

    if (reallyDeleteMsg.exec() == QMessageBox::Ok)
        HWTeam(name).deleteFile();
}

void PageEditTeam::setRandomNames()
{
    HWTeam team = data();
    HWNamegen::teamRandomNames(team, true);
    loadTeam(team);
}

void PageEditTeam::setRandomName(int hh_index)
{
    HWTeam team = data();
    HWNamegen::teamRandomName(team,hh_index);
    loadTeam(team);
}

void PageEditTeam::loadTeam(const HWTeam & team)
{
    tbw->setCurrentIndex(0);
    binder->resetInterface();

    TeamNameEdit->setText(team.name());
    CBTeamLvl->setCurrentIndex(team.difficulty());

    for(int i = 0; i < HEDGEHOGS_PER_TEAM; i++)
    {
        HWHog hh = team.hedgehog(i);

        HHNameEdit[i]->setText(hh.Name);

        if (hh.Hat.startsWith("Reserved"))
            hh.Hat = "Reserved "+hh.Hat.remove(0,40);

        HHHats[i]->setCurrentHat(hh.Hat);
    }

    CBGrave->setCurrentIndex(CBGrave->findText(team.grave()));
    CBFlag->setCurrentIndex(CBFlag->findData(team.flag()));

    CBFort->setCurrentIndex(CBFort->findText(team.fort()));
    CBVoicepack->setCurrentIndex(CBVoicepack->findText(team.voicepack()));

    QStandardItemModel * binds = DataManager::instance().bindsModel();
    for(int i = 0; i < BINDS_NUMBER; i++)
    {
        if (team.keyBind(i).isEmpty()) continue;

        QModelIndexList mdl = binds->match(binds->index(0, 0), Qt::UserRole + 1, team.keyBind(i), 1, Qt::MatchExactly);

        if(mdl.size() == 1)
            binder->setBindIndex(i, mdl[0].row());
        else
            qDebug() << "Binds: cannot find" << team.keyBind(i);
    }
}

HWTeam PageEditTeam::data()
{
    HWTeam team(TeamNameEdit->text());
    team.setDifficulty(CBTeamLvl->currentIndex());

    for(int i = 0; i < HEDGEHOGS_PER_TEAM; i++)
    {
        HWHog hh;
        hh.Name = HHNameEdit[i]->text();
        hh.Hat = HHHats[i]->currentHat();

        if (hh.Hat.startsWith("Reserved"))
            hh.Hat = "Reserved"+m_playerHash+hh.Hat.remove(0,9);

        team.setHedgehog(i,hh);
    }

    team.setGrave(CBGrave->currentText());
    team.setFort(CBFort->currentText());
    team.setVoicepack(CBVoicepack->currentText());
    team.setFlag(CBFlag->itemData(CBFlag->currentIndex()).toString());

    QStandardItemModel * binds = DataManager::instance().bindsModel();
    for(int i = 0; i < BINDS_NUMBER; i++)
    {
        team.bindKey(i, binds->index(binder->bindIndex(i), 0).data(Qt::UserRole + 1).toString());
    }

    return team;
}

void PageEditTeam::saveTeam()
{
    data().saveToFile();
}

// When the "Use default for all binds" is pressed...
void PageEditTeam::resetAllBinds()
{
    for (int i = 0; i < BINDS_NUMBER; i++)
        binder->setBindIndex(i, 0);
}
