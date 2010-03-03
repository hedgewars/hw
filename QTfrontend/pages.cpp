/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Andrey Korotaev <unC0Rr@gmail.com>
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
#include <QGroupBox>
#include <QComboBox>
#include <QCheckBox>
#include <QLabel>
#include <QToolBox>
#include <QLineEdit>
#include <QListWidget>
#include <QApplication>
#include <QSpinBox>
#include <QTextEdit>
#include <QRadioButton>
#include <QTableView>
#include <QMessageBox>
#include <QHeaderView>
#include <QTabWidget>
#include <QTextBrowser>
#include <QTableWidget>
#include <QAction>
#include <QMenu>
#include <QDataWidgetMapper>


#include "pages.h"
#include "sdlkeys.h"
#include "hwconsts.h"
#include "gamecfgwidget.h"
#include "teamselect.h"
#include "gamecfgwidget.h"
#include "SquareLabel.h"
#include "mapContainer.h"
#include "about.h"
#include "fpsedit.h"
#include "netserverslist.h"
#include "netudpwidget.h"
#include "chatwidget.h"
#include "playrecordpage.h"
#include "selectWeapon.h"
#include "igbox.h"
#include "hats.h"
#include "misc.h"
#include "togglebutton.h"
#include "hwform.h"
#include "SDLs.h"

PageMain::PageMain(QWidget* parent) :
  AbstractPage(parent)
{
    if(frontendEffects) setAttribute(Qt::WA_NoSystemBackground, true);
	QGridLayout * pageLayout = new QGridLayout(this);
	//pageLayout->setColumnStretch(0, 1);
	//pageLayout->setColumnStretch(1, 2);
	//pageLayout->setColumnStretch(2, 1);

	//QPushButton* btnLogo = addButton(":/res/HedgewarsTitle.png", pageLayout, 0, 0, 1, 4, true);
	//pageLayout->setAlignment(btnLogo, Qt::AlignHCenter);
	pageLayout->setRowStretch(0, 1);
	pageLayout->setRowStretch(1, 1);
	pageLayout->setRowStretch(2, 0);
	pageLayout->setRowStretch(3, 1);
	pageLayout->setRowStretch(4, 1);

	BtnSinglePlayer = addButton(":/res/LocalPlay.png", pageLayout, 2, 0, 1, 2, true);
	BtnSinglePlayer->setToolTip(tr("Local Game (Play a game on a single computer)"));
	pageLayout->setAlignment(BtnSinglePlayer, Qt::AlignHCenter);

	BtnNet = addButton(":/res/NetworkPlay.png", pageLayout, 2, 2, 1, 2, true);
	BtnNet->setToolTip(tr("Network Game (Play a game across a network)"));
	pageLayout->setAlignment(BtnNet, Qt::AlignHCenter);

	BtnSetup = addButton(":/res/Settings.png", pageLayout, 4, 3, true);

	//BtnInfo = addButton(":/res/About.png", pageLayout, 3, 1, 1, 2, true);
	BtnInfo = addButton(":/res/HedgewarsTitle.png", pageLayout, 0, 0, 1, 4, true);
	BtnInfo->setStyleSheet("border: transparent;background: transparent;");
	pageLayout->setAlignment(BtnInfo, Qt::AlignHCenter);
	//pageLayout->setAlignment(BtnInfo, Qt::AlignHCenter);

	BtnExit = addButton(":/res/Exit.png", pageLayout, 4, 0, 1, 1, true);
}

PageEditTeam::PageEditTeam(QWidget* parent, SDLInteraction * sdli) :
  AbstractPage(parent)
{
    mySdli = sdli;
	QGridLayout * pageLayout = new QGridLayout(this);
	QTabWidget * tbw = new QTabWidget(this);
	QWidget * page1 = new QWidget(this);
	QWidget * page2 = new QWidget(this);
	tbw->addTab(page1, tr("General"));
	tbw->addTab(page2, tr("Advanced"));
	pageLayout->addWidget(tbw, 0, 0, 1, 3);
	BtnTeamDiscard = addButton(":/res/Exit.png", pageLayout, 1, 0, true);
	BtnTeamSave = addButton(":/res/Save.png", pageLayout, 1, 2, true);;
	BtnTeamSave->setStyleSheet("QPushButton{margin: 12px 0px 12px 0px;}");

	QHBoxLayout * page1Layout = new QHBoxLayout(page1);
	page1Layout->setAlignment(Qt::AlignTop);
	QGridLayout * page2Layout = new QGridLayout(page2);

// ====== Page 1 ======
	QVBoxLayout * vbox1 = new QVBoxLayout();
	QVBoxLayout * vbox2 = new QVBoxLayout();
	page1Layout->addLayout(vbox1);
	page1Layout->addLayout(vbox2);

	GBoxHedgehogs = new QGroupBox(this);
	GBoxHedgehogs->setTitle(QGroupBox::tr("Team Members"));
	GBoxHedgehogs->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
	QGridLayout * GBHLayout = new QGridLayout(GBoxHedgehogs);

	signalMapper = new QSignalMapper(this);

	HatsModel * hatsModel = new HatsModel(GBoxHedgehogs);
	for(int i = 0; i < 8; i++)
	{
		HHHats[i] = new QComboBox(GBoxHedgehogs);
		HHHats[i]->setModel(hatsModel);
		HHHats[i]->setIconSize(QSize(32, 37));
		//HHHats[i]->setSizeAdjustPolicy(QComboBox::AdjustToContents);
		//HHHats[i]->setModelColumn(1);
		//HHHats[i]->setMinimumWidth(132);
		GBHLayout->addWidget(HHHats[i], i, 0);

		HHNameEdit[i] = new QLineEdit(GBoxHedgehogs);
		HHNameEdit[i]->setMaxLength(64);
		HHNameEdit[i]->setMinimumWidth(120);
		GBHLayout->addWidget(HHNameEdit[i], i, 1);

		randButton[i] = addButton(":/res/dice.png", GBHLayout, i, 3, true);

		connect(randButton[i], SIGNAL(clicked()), signalMapper, SLOT(map()));
         	signalMapper->setMapping(randButton[i], i);

	}

	randTeamButton = addButton(QPushButton::tr("Random Team"), GBHLayout, 9, false);

	vbox1->addWidget(GBoxHedgehogs);


	GBoxTeam = new QGroupBox(this);
	GBoxTeam->setTitle(QGroupBox::tr("Team Settings"));
	GBoxTeam->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
	QGridLayout * GBTLayout = new QGridLayout(GBoxTeam);
	QLabel * tmpLabel = new QLabel(GBoxTeam);
	tmpLabel->setText(QLabel::tr("Name"));
	GBTLayout->addWidget(tmpLabel, 0, 0);
	tmpLabel = new QLabel(GBoxTeam);
	tmpLabel->setText(QLabel::tr("Type"));
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
	CBTeamLvl->setIconSize(QSize(48, 48));
	CBTeamLvl->addItem(QIcon(":/res/botlevels/0.png"), QComboBox::tr("Human"));
	for(int i = 5; i > 0; i--)
		CBTeamLvl->addItem(
				QIcon(QString(":/res/botlevels/%1.png").arg(6 - i)),
				QString("%1 %2").arg(QComboBox::tr("Level")).arg(i)
				);
	GBTLayout->addWidget(CBTeamLvl, 1, 1);

	CBGrave = new QComboBox(GBoxTeam);
	CBGrave->setMaxCount(65535);
	CBGrave->setIconSize(QSize(32, 32));
	GBTLayout->addWidget(CBGrave, 2, 1);

	CBFlag = new QComboBox(GBoxTeam);
	CBFlag->setMaxCount(65535);
	CBFlag->setIconSize(QSize(22, 15));
	GBTLayout->addWidget(CBFlag, 3, 1);

	{
		QHBoxLayout * hbox = new QHBoxLayout();
		CBVoicepack = new QComboBox(GBoxTeam);
		{
			QDir tmpdir;
			tmpdir.cd(datadir->absolutePath());
			tmpdir.cd("Sounds/voices");
			QStringList list = tmpdir.entryList(QDir::AllDirs | QDir::NoDotAndDotDot, QDir::Name);
			CBVoicepack->addItems(list);
		}
		hbox->addWidget(CBVoicepack, 100);
		BtnTestSound = addButton(":/res/PlaySound.png", hbox, 1, true);
		hbox->setStretchFactor(BtnTestSound, 1);
		connect(BtnTestSound, SIGNAL(clicked()), this, SLOT(testSound()));
		GBTLayout->addLayout(hbox, 4, 1);
	}

	GBoxFort = new QGroupBox(this);
	GBoxFort->setTitle(QGroupBox::tr("Fort"));
	QGridLayout * GBFLayout = new QGridLayout(GBoxFort);
	CBFort = new QComboBox(GBoxFort);
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

	QDir tmpdir;
	tmpdir.cd(datadir->absolutePath());
	tmpdir.cd("Forts");
	tmpdir.setFilter(QDir::Files);

	connect(CBFort, SIGNAL(currentIndexChanged(const QString &)), this, SLOT(CBFort_activated(const QString &)));
	CBFort->addItems(tmpdir.entryList(QStringList("*L.png")).replaceInStrings(QRegExp("^(.*)L\\.png"), "\\1"));

	tmpdir.cd("../Graphics/Graves");
	QStringList list = tmpdir.entryList(QStringList("*.png"));
	for (QStringList::Iterator it = list.begin(); it != list.end(); ++it )
	{
		QPixmap pix(datadir->absolutePath() + "/Graphics/Graves/" + *it);
		QIcon icon(pix.copy(0, 0, 32, 32));
		CBGrave->addItem(icon, (*it).replace(QRegExp("^(.*)\\.png"), "\\1"));
	}

	tmpdir.cd(datadir->absolutePath());
	tmpdir.cd("Graphics/Flags");
	list = tmpdir.entryList(QStringList("*.png"));
	for (QStringList::Iterator it = list.begin(); it != list.end(); ++it )
	{
		QPixmap pix(datadir->absolutePath() + "/Graphics/Flags/" + *it);
		QIcon icon(pix.copy(0, 0, 22, 15));
		if(it->compare("cpu.png")) // skip cpu flag
			CBFlag->addItem(icon, (*it).replace(QRegExp("^(.*)\\.png"), "\\1"));
	}

	vbox1->addStretch();
	vbox2->addStretch();

// ====== Page 2 ======
	GBoxBinds = new QGroupBox(this);
	GBoxBinds->setTitle(QGroupBox::tr("Key binds"));
	QGridLayout * GBBLayout = new QGridLayout(GBoxBinds);
	BindsBox = new QToolBox(GBoxBinds);
	BindsBox->setLineWidth(0);
	GBBLayout->addWidget(BindsBox);
	page2Layout->addWidget(GBoxBinds, 0, 0);

	quint16 i = 0;
	quint16 num = 0;
	QWidget * curW = NULL;
	QGridLayout * pagelayout = NULL;
	QLabel* l = NULL;
	while (i < BINDS_NUMBER) {
		if(cbinds[i].category != NULL)
		{
			if(curW != NULL)
			{
				l = new QLabel(curW);
				l->setText("");
				pagelayout->addWidget(l, num++, 0, 1, 2);
			}
			curW = new QWidget(this);
			BindsBox->addItem(curW, QApplication::translate("binds (categories)", cbinds[i].category));
			pagelayout = new QGridLayout(curW);
			num = 0;
		}
		if(cbinds[i].description != NULL)
		{
			l = new QLabel(curW);
			l->setText((num > 0 ? QString("\n") : QString("")) + QApplication::translate("binds (descriptions)", cbinds[i].description));
			pagelayout->addWidget(l, num++, 0, 1, 2);
		}

		l = new QLabel(curW);
		l->setText(QApplication::translate("binds", cbinds[i].name));
		l->setAlignment(Qt::AlignRight);
		pagelayout->addWidget(l, num, 0);
		CBBind[i] = new QComboBox(curW);
		for(int j = 0; sdlkeys[j][1][0] != '\0'; j++)
			CBBind[i]->addItem(QApplication::translate("binds (keys)", sdlkeys[j][1]).contains(": ") ? QApplication::translate("binds (keys)", sdlkeys[j][1]) : QApplication::translate("binds (keys)", "Keyboard") + QString(": ") + QApplication::translate("binds (keys)", sdlkeys[j][1]), sdlkeys[j][0]);
		pagelayout->addWidget(CBBind[i++], num++, 1);
	}
}

void PageEditTeam::CBFort_activated(const QString & fortname)
{
	QPixmap pix(datadir->absolutePath() + "/Forts/" + fortname + "L.png");
	FortPreview->setPixmap(pix);
}

void PageEditTeam::testSound()
{
	Mix_Chunk *sound;
	QDir tmpdir;
	mySdli->SDLMusicInit();
	
	tmpdir.cd(datadir->absolutePath());
	tmpdir.cd("Sounds/voices");
	tmpdir.cd(CBVoicepack->currentText());
	QStringList list = tmpdir.entryList(QStringList() << "Illgetyou.ogg" << "Incoming.ogg" << "Stupid.ogg" << "Coward.ogg" << "Firstblood.ogg", QDir::Files);
	if (list.size()) {
		sound = Mix_LoadWAV(QString(tmpdir.absolutePath() + "/" + list[rand() % list.size()]).toLocal8Bit().constData());
		Mix_PlayChannel(-1, sound, 0);
	}
}

PageMultiplayer::PageMultiplayer(QWidget* parent) :
  AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);

	BtnBack = addButton(":/res/Exit.png", pageLayout, 2, 0, true);

	gameCFG = new GameCFGWidget(this);
	pageLayout->addWidget(gameCFG, 0, 0, 1, 2);

	pageLayout->setRowStretch(1, 1);

	teamsSelect = new TeamSelWidget(this);
	pageLayout->addWidget(teamsSelect, 0, 2, 2, 2);

	BtnStartMPGame = addButton(tr("Start"), pageLayout, 2, 3);
}

PageOptions::PageOptions(QWidget* parent) :
  AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setColumnStretch(0, 100);
	pageLayout->setColumnStretch(1, 100);
	pageLayout->setColumnStretch(2, 100);
	pageLayout->setRowStretch(0, 0);
	pageLayout->setRowStretch(1, 100);
	pageLayout->setRowStretch(2, 0);
	pageLayout->setContentsMargins(7, 7, 7, 0);
	pageLayout->setSpacing(0);


	QGroupBox * gbTwoBoxes = new QGroupBox(this);
	pageLayout->addWidget(gbTwoBoxes, 0, 0, 1, 3);
	QGridLayout * gbTBLayout = new QGridLayout(gbTwoBoxes);
	gbTBLayout->setMargin(0);
	gbTBLayout->setSpacing(0);
	gbTBLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
        {
            teamsBox = new IconedGroupBox(this);
            //teamsBox->setContentTopPadding(0);
            //teamsBox->setAttribute(Qt::WA_PaintOnScreen, true);
            teamsBox->setIcon(QIcon(":/res/teamicon.png"));
            teamsBox->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
            teamsBox->setTitle(QGroupBox::tr("Teams"));

            QVBoxLayout * GBTlayout = new QVBoxLayout(teamsBox);

            CBTeamName = new QComboBox(teamsBox);
            GBTlayout->addWidget(CBTeamName);

            QHBoxLayout * layout1 = new QHBoxLayout;
            GBTlayout->addLayout(layout1);
            BtnNewTeam = addButton(tr("New team"), layout1, 0);
            BtnEditTeam = addButton(tr("Edit team"), layout1, 1);
            layout1->setStretchFactor(BtnNewTeam, 100);
            layout1->setStretchFactor(BtnEditTeam, 100);

            gbTBLayout->addWidget(teamsBox, 0, 0);
        }

        {
            IconedGroupBox* groupWeapons = new IconedGroupBox(this);
            //groupWeapons->setContentTopPadding(0);
            groupWeapons->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
            groupWeapons->setIcon(QIcon(":/res/weaponsicon.png"));
            //groupWeapons->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
            groupWeapons->setTitle(QGroupBox::tr("Weapons"));
            QGridLayout * WeaponsLayout = new QGridLayout(groupWeapons);

            WeaponsButt = addButton(tr("Weapons set"), WeaponsLayout, 1, 0);
            WeaponsName = new QComboBox(this);
            WeaponsLayout->addWidget(WeaponsName, 0, 0, 1, 2);
            WeaponEdit = addButton(tr("Edit"), WeaponsLayout, 1, 1);

            WeaponTooltip = new QCheckBox(this);
            WeaponTooltip->setText(QCheckBox::tr("Show ammo menu tooltips"));
            WeaponsLayout->addWidget(WeaponTooltip, 2, 0, 1, 2);

            gbTBLayout->addWidget(groupWeapons, 1, 0);
        }

        {
            IconedGroupBox* groupMisc = new IconedGroupBox(this);
            //groupMisc->setContentTopPadding(0);
            groupMisc->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
            groupMisc->setIcon(QIcon(":/res/miscicon.png"));
            //groupMisc->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
            groupMisc->setTitle(QGroupBox::tr("Misc"));
            QGridLayout * MiscLayout = new QGridLayout(groupMisc);

            labelNN = new QLabel(groupMisc);
            labelNN->setText(QLabel::tr("Net nick"));
            MiscLayout->addWidget(labelNN, 0, 0);

            editNetNick = new QLineEdit(groupMisc);
            editNetNick->setMaxLength(20);
            editNetNick->setText(QLineEdit::tr("unnamed"));
            MiscLayout->addWidget(editNetNick, 0, 1);

            QLabel *labelLanguage = new QLabel(groupMisc);
            labelLanguage->setText(QLabel::tr("Locale") + " *");
            MiscLayout->addWidget(labelLanguage, 1, 0);

            CBLanguage = new QComboBox(groupMisc);
            QDir tmpdir;
            tmpdir.cd(datadir->absolutePath());
            tmpdir.cd("Locale");
            tmpdir.setFilter(QDir::Files);
            QStringList locs = tmpdir.entryList(QStringList("hedgewars_*.qm"));
			CBLanguage->addItem(QComboBox::tr("(System default)"), QString(""));
            for(int i = 0; i < locs.count(); i++)
            {
                QLocale loc(locs[i].replace(QRegExp("hedgewars_(.*)\\.qm"), "\\1"));
                CBLanguage->addItem(QLocale::languageToString(loc.language()) + " (" + QLocale::countryToString(loc.country()) + ")", loc.name());
            }

            MiscLayout->addWidget(CBLanguage, 1, 1);

            CBAltDamage = new QCheckBox(groupMisc);
            CBAltDamage->setText(QCheckBox::tr("Alternative damage show"));
            MiscLayout->addWidget(CBAltDamage, 2, 0, 1, 2);

            CBNameWithDate = new QCheckBox(groupMisc);
            CBNameWithDate->setText(QCheckBox::tr("Append date and time to record file name"));
            MiscLayout->addWidget(CBNameWithDate, 3, 0, 1, 2);

#ifdef SPARKLE_ENABLED
            CBAutoUpdate = new QCheckBox(groupMisc);
            CBAutoUpdate->setText(QCheckBox::tr("Check for updates at startup"));
            MiscLayout->addWidget(CBAutoUpdate, 4, 0, 1, 2);
#endif

            gbTBLayout->addWidget(groupMisc, 2, 0);
        }

        {
            AGGroupBox = new IconedGroupBox(this);
            //AGGroupBox->setContentTopPadding(0);
            AGGroupBox->setIcon(QIcon(":/res/graphicsicon.png"));
            AGGroupBox->setSizePolicy(QSizePolicy::MinimumExpanding, QSizePolicy::Fixed);
            AGGroupBox->setTitle(QGroupBox::tr("Audio/Graphic options"));

            QVBoxLayout * GBAlayout = new QVBoxLayout(AGGroupBox);
            QHBoxLayout * GBAreslayout = new QHBoxLayout(0);

            CBFrontendFullscreen = new QCheckBox(AGGroupBox);
            CBFrontendFullscreen->setText(QCheckBox::tr("Frontend fullscreen"));
            GBAlayout->addWidget(CBFrontendFullscreen);

            CBFrontendEffects = new QCheckBox(AGGroupBox);
            CBFrontendEffects->setText(QCheckBox::tr("Frontend effects") + " *");
            GBAlayout->addWidget(CBFrontendEffects);

            CBEnableFrontendSound = new QCheckBox(AGGroupBox);
            CBEnableFrontendSound->setText(QCheckBox::tr("Enable frontend sounds"));
            GBAlayout->addWidget(CBEnableFrontendSound);

            CBEnableFrontendMusic = new QCheckBox(AGGroupBox);
            CBEnableFrontendMusic->setText(QCheckBox::tr("Enable frontend music"));
            GBAlayout->addWidget(CBEnableFrontendMusic);

            QFrame * hr = new QFrame(AGGroupBox);
            hr->setFrameStyle(QFrame::HLine);
            hr->setLineWidth(3);
            hr->setFixedHeight(12);
            GBAlayout->addWidget(hr);

            QLabel * resolution = new QLabel(AGGroupBox);
            resolution->setText(QLabel::tr("Resolution"));
            GBAreslayout->addWidget(resolution);

            CBResolution = new QComboBox(AGGroupBox);
            GBAreslayout->addWidget(CBResolution);
            GBAlayout->addLayout(GBAreslayout);

            CBFullscreen = new QCheckBox(AGGroupBox);
            CBFullscreen->setText(QCheckBox::tr("Fullscreen"));
            GBAlayout->addWidget(CBFullscreen);

            CBReduceQuality = new QCheckBox(AGGroupBox);
            CBReduceQuality->setText(QCheckBox::tr("Reduced quality"));
            GBAlayout->addWidget(CBReduceQuality);

            hr = new QFrame(AGGroupBox);
            hr->setFrameStyle(QFrame::HLine);
            hr->setLineWidth(3);
            hr->setFixedHeight(12);
            GBAlayout->addWidget(hr);

            QHBoxLayout * GBAvollayout = new QHBoxLayout(0);
            QLabel * vol = new QLabel(AGGroupBox);
            vol->setText(QLabel::tr("Initial sound volume"));
            GBAvollayout->addWidget(vol);
            GBAlayout->addLayout(GBAvollayout);
            volumeBox = new QSpinBox(AGGroupBox);
            volumeBox->setRange(0, 100);
            volumeBox->setSingleStep(5);
            GBAvollayout->addWidget(volumeBox);

            CBEnableSound = new QCheckBox(AGGroupBox);
            CBEnableSound->setText(QCheckBox::tr("Enable sound"));
            GBAlayout->addWidget(CBEnableSound);

            CBEnableMusic = new QCheckBox(AGGroupBox);
            CBEnableMusic->setText(QCheckBox::tr("Enable music"));
            GBAlayout->addWidget(CBEnableMusic);

            hr = new QFrame(AGGroupBox);
            hr->setFrameStyle(QFrame::HLine);
            hr->setLineWidth(3);
            hr->setFixedHeight(12);
            GBAlayout->addWidget(hr);

            QHBoxLayout * GBAfpslayout = new QHBoxLayout(0);
            QLabel * maxfps = new QLabel(AGGroupBox);
            maxfps->setText(QLabel::tr("FPS limit"));
            GBAfpslayout->addWidget(maxfps);
            GBAlayout->addLayout(GBAfpslayout);
            fpsedit = new FPSEdit(AGGroupBox);
            GBAfpslayout->addWidget(fpsedit);

            CBShowFPS = new QCheckBox(AGGroupBox);
            CBShowFPS->setText(QCheckBox::tr("Show FPS"));
            GBAlayout->addWidget(CBShowFPS);

            hr = new QFrame(AGGroupBox);
            hr->setFrameStyle(QFrame::HLine);
            hr->setLineWidth(3);
            hr->setFixedHeight(12);
            GBAlayout->addWidget(hr);

	            QLabel *restartNote = new QLabel(this);
            restartNote->setText(QString("* ") + QLabel::tr("Restart game to apply"));
            GBAlayout->addWidget(restartNote);

            gbTBLayout->addWidget(AGGroupBox, 0, 1, 3, 1);
        }

	BtnSaveOptions = addButton(":/res/Save.png", pageLayout, 2, 2, true);
	BtnSaveOptions->setStyleSheet("QPushButton{margin: 12px 0px 12px 0px;}");

	BtnBack = addButton(":/res/Exit.png", pageLayout, 2, 0, true);
}

PageNet::PageNet(QWidget* parent) : AbstractPage(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 1);
	pageLayout->setColumnStretch(2, 1);

	BtnNetSvrStart = new QPushButton(this);
	BtnNetSvrStart->setFont(*font14);
	BtnNetSvrStart->setText(QPushButton::tr("Start server"));
	BtnNetSvrStart->setVisible(haveServer);
	pageLayout->addWidget(BtnNetSvrStart, 4, 2);

	BtnBack = addButton(":/res/Exit.png", pageLayout, 4, 0, true);

	ConnGroupBox = new QGroupBox(this);
	ConnGroupBox->setTitle(QGroupBox::tr("Net game"));
	pageLayout->addWidget(ConnGroupBox, 2, 0, 1, 3);
	GBClayout = new QGridLayout(ConnGroupBox);
	GBClayout->setColumnStretch(0, 1);
	GBClayout->setColumnStretch(1, 1);
	GBClayout->setColumnStretch(2, 1);

	BtnNetConnect = new QPushButton(ConnGroupBox);
	BtnNetConnect->setFont(*font14);
	BtnNetConnect->setText(QPushButton::tr("Connect"));
	GBClayout->addWidget(BtnNetConnect, 2, 2);

	tvServersList = new QTableView(ConnGroupBox);
	tvServersList->setSelectionBehavior(QAbstractItemView::SelectRows);
	GBClayout->addWidget(tvServersList, 1, 0, 1, 3);

	BtnUpdateSList = new QPushButton(ConnGroupBox);
	BtnUpdateSList->setFont(*font14);
	BtnUpdateSList->setText(QPushButton::tr("Update"));
	GBClayout->addWidget(BtnUpdateSList, 2, 0);

	BtnSpecifyServer = new QPushButton(ConnGroupBox);
	BtnSpecifyServer->setFont(*font14);
	BtnSpecifyServer->setText(QPushButton::tr("Specify"));
	GBClayout->addWidget(BtnSpecifyServer, 2, 1);

	connect(BtnNetConnect, SIGNAL(clicked()), this, SLOT(slotConnect()));
}

void PageNet::updateServersList()
{
	tvServersList->setModel(new HWNetUdpModel(tvServersList));

	tvServersList->horizontalHeader()->setResizeMode(0, QHeaderView::Stretch);

	static_cast<HWNetServersModel *>(tvServersList->model())->updateList();

	connect(BtnUpdateSList, SIGNAL(clicked()), static_cast<HWNetServersModel *>(tvServersList->model()), SLOT(updateList()));
	connect(tvServersList, SIGNAL(doubleClicked(const QModelIndex &)), this, SLOT(slotConnect()));
}

void PageNet::slotConnect()
{
	HWNetServersModel * model = static_cast<HWNetServersModel *>(tvServersList->model());
	QModelIndex mi = tvServersList->currentIndex();
	if(!mi.isValid())
	{
		QMessageBox::information(this, tr("Error"), tr("Please select server from the list above"));
		return;
	}
	QString host = model->index(mi.row(), 1).data().toString();
	quint16 port = model->index(mi.row(), 2).data().toUInt();

	emit connectClicked(host, port);
}

PageNetServer::PageNetServer(QWidget* parent) : AbstractPage(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 1);
	pageLayout->setColumnStretch(2, 1);

	pageLayout->setRowStretch(0, 1);
	pageLayout->setRowStretch(1, 0);

	BtnBack =addButton(":/res/Exit.png", pageLayout, 1, 0, true);

	BtnStart = new QPushButton(this);
	BtnStart->setFont(*font14);
	BtnStart->setText(QPushButton::tr("Start"));
	pageLayout->addWidget(BtnStart, 1, 2);

	QWidget * wg = new QWidget(this);
	pageLayout->addWidget(wg, 0, 0, 1, 3);

	QGridLayout * wgLayout = new QGridLayout(wg);
	wgLayout->setColumnStretch(0, 1);
	wgLayout->setColumnStretch(1, 3);
	wgLayout->setColumnStretch(2, 1);

	wgLayout->setRowStretch(0, 0);
	wgLayout->setRowStretch(1, 1);

	QGroupBox * gb = new QGroupBox(wg);
	wgLayout->addWidget(gb, 0, 1);

	QGridLayout * gbLayout = new QGridLayout(gb);

	labelSD = new QLabel(gb);
	labelSD->setText(QLabel::tr("Server name:"));
	gbLayout->addWidget(labelSD, 0, 0);

	leServerDescr = new QLineEdit(gb);
	gbLayout->addWidget(leServerDescr, 0, 1);

	labelPort = new QLabel(gb);
	labelPort->setText(QLabel::tr("Server port:"));
	gbLayout->addWidget(labelPort, 1, 0);

	sbPort = new QSpinBox(gb);
	sbPort->setMinimum(0);
	sbPort->setMaximum(65535);
	gbLayout->addWidget(sbPort, 1, 1);

	BtnDefault = new QPushButton(gb);
	BtnDefault->setText(QPushButton::tr("default"));
	gbLayout->addWidget(BtnDefault, 1, 2);

	connect(BtnDefault, SIGNAL(clicked()), this, SLOT(setDefaultPort()));
}

void PageNetServer::setDefaultPort()
{
	sbPort->setValue(46631);
}

PageNetGame::PageNetGame(QWidget* parent, QSettings * gameSettings, SDLInteraction * sdli) : AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setSizeConstraint(QLayout::SetMinimumSize);
	//pageLayout->setSpacing(1);
	pageLayout->setColumnStretch(0, 50);
	pageLayout->setColumnStretch(1, 50);

	// chatwidget
	pChatWidget = new HWChatWidget(this, gameSettings, sdli, true);
	pChatWidget->setShowReady(true); // show status bulbs by default
	pageLayout->addWidget(pChatWidget, 1, 0, 1, 2);
	pageLayout->setRowStretch(1, 100);

	pGameCFG = new GameCFGWidget(this);
	pageLayout->addWidget(pGameCFG, 0, 0);

	pNetTeamsWidget = new TeamSelWidget(this);
	pNetTeamsWidget->setAcceptOuter(true);
	pageLayout->addWidget(pNetTeamsWidget, 0, 1);


	QHBoxLayout * bottomLayout = new QHBoxLayout;
	pageLayout->addLayout(bottomLayout, 3, 0, 1, 2);

	BtnBack = addButton(":/res/Exit.png", bottomLayout, 0, true);

	BtnGo = new QPushButton(this);
	BtnGo->setToolTip(QPushButton::tr("Ready"));
	BtnGo->setIcon(QIcon(":/res/lightbulb_off.png"));
	BtnGo->setIconSize(QSize(25, 34));
	BtnGo->setMinimumWidth(50);
	BtnGo->setMinimumHeight(50);
	bottomLayout->addWidget(BtnGo, 4);


	BtnMaster = addButton(tr("Control"), bottomLayout, 2);
	QMenu * menu = new QMenu(BtnMaster);
	restrictJoins = new QAction(QAction::tr("Restrict Joins"), menu);
	restrictJoins->setCheckable(true);
	restrictTeamAdds = new QAction(QAction::tr("Restrict Team Additions"), menu);
	restrictTeamAdds->setCheckable(true);
	//menu->addAction(startGame);
	menu->addAction(restrictJoins);
	menu->addAction(restrictTeamAdds);

	BtnMaster->setMenu(menu);

	BtnStart = addButton(QAction::tr("Start"), bottomLayout, 3);

	bottomLayout->insertStretch(1, 100);
}

void PageNetGame::setReadyStatus(bool isReady)
{
	if(isReady)
		BtnGo->setIcon(QIcon(":/res/lightbulb_on.png"));
	else
		BtnGo->setIcon(QIcon(":/res/lightbulb_off.png"));
}

void PageNetGame::setMasterMode(bool isMaster)
{
	BtnMaster->setVisible(isMaster);
	BtnStart->setVisible(isMaster);
}

PageInfo::PageInfo(QWidget* parent) : AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 1);
	pageLayout->setColumnStretch(2, 1);

	BtnBack = addButton(":/res/Exit.png", pageLayout, 1, 0, true);

	about = new About(this);
	pageLayout->addWidget(about, 0, 0, 1, 3);
}

PageSinglePlayer::PageSinglePlayer(QWidget* parent) : AbstractPage(parent)
{
	QVBoxLayout * vLayout = new QVBoxLayout(this);
	QHBoxLayout * topLine = new QHBoxLayout();
	QHBoxLayout * middleLine = new QHBoxLayout();
	QHBoxLayout * bottomLine = new QHBoxLayout();
	vLayout->addStretch();
	vLayout->addLayout(topLine);
	vLayout->addSpacing(30);
	vLayout->addLayout(middleLine);
	vLayout->addStretch();
	vLayout->addLayout(bottomLine);

	topLine->addStretch();
	BtnSimpleGamePage = addButton(":/res/SimpleGame.png", topLine, 0, true);
	BtnSimpleGamePage->setToolTip(tr("Simple Game (a quick game against the computer, settings are chosen for you)"));
	topLine->addSpacing(60);
	BtnMultiplayer = addButton(":/res/Multiplayer.png", topLine, 1, true);
	BtnMultiplayer->setToolTip(tr("Multiplayer (play a hotseat game against your friends, or AI teams)"));
	topLine->addStretch();


	BtnTrainPage = addButton(":/res/Trainings.png", middleLine, 0, true);
	BtnTrainPage->setToolTip(tr("Training Mode (Practice your skills in a range of training missions). IN DEVELOPMENT"));

	BtnBack = addButton(":/res/Exit.png", bottomLine, 0, true);
	bottomLine->addStretch();

	BtnDemos = addButton(":/res/Record.png", bottomLine, 1, true);
	BtnDemos->setToolTip(tr("Demos (Watch recorded demos)"));
	BtnLoad = addButton(":/res/Save.png", bottomLine, 2, true);
	BtnLoad->setStyleSheet("QPushButton{margin: 12px 0px 12px 0px;}");
	BtnLoad->setToolTip(tr("Load (Load a previously saved game)"));
}

PageTraining::PageTraining(QWidget* parent) : AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 2);
	pageLayout->setColumnStretch(2, 1);

	CBSelect = new QComboBox(this);

	QDir tmpdir;
	tmpdir.cd(datadir->absolutePath());
	tmpdir.cd("Missions");
	tmpdir.setFilter(QDir::Files);
	CBSelect->addItems(tmpdir.entryList(QStringList("*.hwt")).replaceInStrings(QRegExp("^(.*)\\.hwt"), "\\1"));

	pageLayout->addWidget(CBSelect, 1, 1);
	
	BtnStartTrain = new QPushButton(this);
	BtnStartTrain->setFont(*font14);
	BtnStartTrain->setText(QPushButton::tr("Go!"));
	pageLayout->addWidget(BtnStartTrain, 1, 2);

	BtnBack = addButton(":/res/Exit.png", pageLayout, 1, 0, true);
}

PageSelectWeapon::PageSelectWeapon(QWidget* parent) :
  AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);

	pWeapons = new SelWeaponWidget(cAmmoNumber, this);
	pageLayout->addWidget(pWeapons, 0, 0, 1, 4);

	BtnBack = addButton(":/res/Exit.png", pageLayout, 1, 0, true);
	BtnDefault = addButton(tr("Default"), pageLayout, 1, 1);
	BtnDelete = addButton(tr("Delete"), pageLayout, 1, 2);
	BtnSave = addButton(":/res/Save.png", pageLayout, 1, 3, true);
	BtnSave->setStyleSheet("QPushButton{margin: 12px 0px 12px 0px;}");

	connect(BtnDefault, SIGNAL(clicked()), pWeapons, SLOT(setDefault()));
	connect(BtnSave, SIGNAL(clicked()), pWeapons, SLOT(save()));
}

PageInGame::PageInGame(QWidget* parent) :
  AbstractPage(parent)
{
	QLabel * label = new QLabel(this);
	label->setText("In game...");
}

PageRoomsList::PageRoomsList(QWidget* parent, QSettings * gameSettings, SDLInteraction * sdli) :
  AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);

	QHBoxLayout * newRoomLayout = new QHBoxLayout();
	QLabel * roomNameLabel = new QLabel(this);
	roomNameLabel->setText(tr("Room Name:"));
	roomName = new QLineEdit(this);
	roomName->setMaxLength(60);
	newRoomLayout->addWidget(roomNameLabel);
	newRoomLayout->addWidget(roomName);
	pageLayout->addLayout(newRoomLayout, 0, 0);

	roomsList = new QTableWidget(this);
	roomsList->setSelectionBehavior(QAbstractItemView::SelectRows);
	roomsList->verticalHeader()->setVisible(false);
	roomsList->horizontalHeader()->setResizeMode(QHeaderView::Interactive);
	roomsList->setAlternatingRowColors(true);
	pageLayout->addWidget(roomsList, 1, 0, 3, 1);
	pageLayout->setRowStretch(2, 100);

	chatWidget = new HWChatWidget(this, gameSettings, sdli, false);
	pageLayout->addWidget(chatWidget, 4, 0, 1, 2);
	pageLayout->setRowStretch(4, 350);

	BtnCreate = addButton(tr("Create"), pageLayout, 0, 1);
	BtnJoin = addButton(tr("Join"), pageLayout, 1, 1);
	BtnRefresh = addButton(tr("Refresh"), pageLayout, 3, 1);

	BtnBack = addButton(":/res/Exit.png", pageLayout, 5, 0, true);
	BtnAdmin = addButton(tr("Admin features"), pageLayout, 5, 1);

	connect(BtnCreate, SIGNAL(clicked()), this, SLOT(onCreateClick()));
	connect(BtnJoin, SIGNAL(clicked()), this, SLOT(onJoinClick()));
	connect(BtnRefresh, SIGNAL(clicked()), this, SLOT(onRefreshClick()));
	connect(roomsList, SIGNAL(doubleClicked (const QModelIndex &)), this, SLOT(onJoinClick()));
}

void PageRoomsList::setAdmin(bool flag)
{
	BtnAdmin->setVisible(flag);
}

void PageRoomsList::setRoomsList(const QStringList & list)
{
	roomsList->clear();
	roomsList->setColumnCount(7);
	roomsList->setHorizontalHeaderLabels(
			QStringList() <<
			QTableWidget::tr("Room Name") <<
			QTableWidget::tr("C") <<
			QTableWidget::tr("T") <<
			QTableWidget::tr("Owner") <<
			QTableWidget::tr("Map") <<
			QTableWidget::tr("Rules") <<
			QTableWidget::tr("Weapons")
			);

	// set minimum sizes
//	roomsList->horizontalHeader()->resizeSection(0, 200);
//	roomsList->horizontalHeader()->resizeSection(1, 50);
//	roomsList->horizontalHeader()->resizeSection(2, 50);
//	roomsList->horizontalHeader()->resizeSection(3, 100);
//	roomsList->horizontalHeader()->resizeSection(4, 100);
//	roomsList->horizontalHeader()->resizeSection(5, 100);
//	roomsList->horizontalHeader()->resizeSection(6, 100);

	// set resize modes
//	roomsList->horizontalHeader()->setResizeMode(QHeaderView::Interactive);

	if (list.size() % 8)
		return;

	roomsList->setRowCount(list.size() / 8);
	for(int i = 0, r = 0; i < list.size(); i += 8, r++)
	{
		QTableWidgetItem * item;
		item = new QTableWidgetItem(list[i + 1]); // room name
		item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
		
		// pick appropriate room icon and tooltip (game in progress yes/no; later maybe locked rooms etc.)
		if(list[i].compare("True"))
		{
			item->setIcon(QIcon(":/res/iconTime.png"));// game is in lobby
			item->setToolTip(tr("This game is in lobby.\nYou may join and start playing once the game starts."));
		}
		else
		{
			item->setIcon(QIcon(":/res/iconDamage.png"));// game has started
			item->setToolTip(tr("This game is in progress.\nYou may join and spectate now but you'll have to wait for the game to end to start playing."));
		}

		roomsList->setItem(r, 0, item);

		item = new QTableWidgetItem(list[i + 2]); // number of clients
		item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
		item->setTextAlignment(Qt::AlignCenter);
		item->setToolTip(tr("There are %1 clients connected to this room.", "", list[i + 2].toInt()).arg(list[i + 2]));
		roomsList->setItem(r, 1, item);

		item = new QTableWidgetItem(list[i + 3]); // number of teams
		item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
		item->setTextAlignment(Qt::AlignCenter);
		item->setToolTip(tr("There are %1 teams participating in this room.", "", list[i + 3].toInt()).arg(list[i + 3]));
		roomsList->setItem(r, 2, item);

		item = new QTableWidgetItem(list[i + 4].left(15)); // name of host
		item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
		item->setToolTip(tr("%1 is the host. He may adjust settings and start the game.").arg(list[i + 4]));
		roomsList->setItem(r, 3, item);

		if(list[i + 5].compare("+rnd+"))
		{
			item = new QTableWidgetItem(list[i + 5]); // selected map
			
			// check to see if we've got this map
			// not perfect but a start
			if(!mapList->contains(list[i + 5]))
				item->setForeground(QBrush(QColor(255, 0, 0)));
		}
		else
			item = new QTableWidgetItem(tr("Random Map")); // selected map (is randomized)
		
		item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
		item->setToolTip(tr("Games may be played on precreated or randomized maps."));
		roomsList->setItem(r, 4, item);

		item = new QTableWidgetItem(list[i + 6].left(20)); // selected game scheme
		item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
		item->setToolTip(tr("The Game Scheme defines general options and preferences like Round Time, Sudden Death or Vampirism."));
		roomsList->setItem(r, 5, item);

		item = new QTableWidgetItem(list[i + 7].left(20)); // selected weapon scheme
		item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
		item->setToolTip(tr("The Weapon Scheme defines available weapons and their ammunition count."));
		roomsList->setItem(r, 6, item);

	}
   roomsList->horizontalHeader()->setResizeMode(0, QHeaderView::Stretch);
   roomsList->horizontalHeader()->setResizeMode(1, QHeaderView::ResizeToContents);
   roomsList->horizontalHeader()->setResizeMode(2, QHeaderView::ResizeToContents);
   roomsList->horizontalHeader()->setResizeMode(3, QHeaderView::ResizeToContents);
   roomsList->horizontalHeader()->setResizeMode(4, QHeaderView::ResizeToContents);
   roomsList->horizontalHeader()->setResizeMode(5, QHeaderView::ResizeToContents);
   roomsList->horizontalHeader()->setResizeMode(6, QHeaderView::ResizeToContents);

//	roomsList->resizeColumnsToContents();
}

void PageRoomsList::onCreateClick()
{
	if (roomName->text().size())
		emit askForCreateRoom(roomName->text());
	else
		QMessageBox::critical(this,
				tr("Error"),
				tr("Please enter room name"),
				tr("OK"));
}

void PageRoomsList::onJoinClick()
{
	QTableWidgetItem * curritem = roomsList->item(roomsList->currentRow(), 0);
	if (!curritem)
	{
		QMessageBox::critical(this,
				tr("Error"),
				tr("Please select room from the list"),
				tr("OK"));
		return ;
	}
	emit askForJoinRoom(curritem->data(Qt::DisplayRole).toString());
}

void PageRoomsList::onRefreshClick()
{
	emit askForRoomList();
}


PageConnecting::PageConnecting(QWidget* parent) :
	AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);

	QLabel * lblConnecting = new QLabel(this);
	lblConnecting->setText(tr("Connecting..."));
	pageLayout->addWidget(lblConnecting);
}

PageScheme::PageScheme(QWidget* parent) :
	AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);
	QGroupBox * gb = new QGroupBox(this);

	QGridLayout * gl = new QGridLayout();
	gb->setLayout(gl);
	QSizePolicy sp;
	sp.setVerticalPolicy(QSizePolicy::MinimumExpanding);
	sp.setHorizontalPolicy(QSizePolicy::Expanding);

	pageLayout->addWidget(gb, 1,0,13,4);

	gbGameModes = new QGroupBox(QGroupBox::tr("Game Modifiers"), gb);
	gbBasicSettings = new QGroupBox(QGroupBox::tr("Basic Settings"), gb);

	gbGameModes->setStyleSheet(".QGroupBox {"
			"background-color: #130f2c; background-image:url();"
			"}");
	gbBasicSettings->setStyleSheet(".QGroupBox {"
			"background-color: #130f2c; background-image:url();"
			"}");

	gbGameModes->setSizePolicy(sp);
	gbBasicSettings->setSizePolicy(sp);
	gl->addWidget(gbGameModes,0,0,1,3,Qt::AlignTop);
	gl->addWidget(gbBasicSettings,0,3,1,3,Qt::AlignTop);

	QGridLayout * glGMLayout = new QGridLayout(gbGameModes);
	QGridLayout * glBSLayout = new QGridLayout(gbBasicSettings);
	gbGameModes->setLayout(glGMLayout);
	gbBasicSettings->setLayout(glBSLayout);
	// Left

	TBW_mode_Forts = new ToggleButtonWidget(gbGameModes, ":/res/btnForts.png");
	TBW_mode_Forts->setText(ToggleButtonWidget::tr("Fort Mode"));
    TBW_mode_Forts->setToolTip(tr("Defend your fort and destroy the opponents, two team colours max!"));
	glGMLayout->addWidget(TBW_mode_Forts,0,0,1,1);

	TBW_teamsDivide = new ToggleButtonWidget(gbGameModes, ":/res/btnTeamsDivide.png");
	TBW_teamsDivide->setText(ToggleButtonWidget::tr("Divide Teams"));
    TBW_teamsDivide->setToolTip(tr("Teams will start on opposite sides of the terrain, two team colours max!"));
	glGMLayout->addWidget(TBW_teamsDivide,0,1,1,1);

	TBW_solid = new ToggleButtonWidget(gbGameModes, ":/res/btnSolid.png");
	TBW_solid->setText(ToggleButtonWidget::tr("Solid Land"));
    TBW_solid->setToolTip(tr("Land can not be destroyed!"));
	glGMLayout->addWidget(TBW_solid,0,2,1,1);

	TBW_border = new ToggleButtonWidget(gbGameModes, ":/res/btnBorder.png");
	TBW_border->setText(ToggleButtonWidget::tr("Add Border"));
    TBW_border->setToolTip(tr("Add an indestructable border around the terrain"));
	glGMLayout->addWidget(TBW_border,0,3,1,1);

	TBW_lowGravity = new ToggleButtonWidget(gbGameModes, ":/res/btnLowGravity.png");
	TBW_lowGravity->setText(ToggleButtonWidget::tr("Low Gravity"));
    TBW_lowGravity->setToolTip(tr("Lower gravity"));
	glGMLayout->addWidget(TBW_lowGravity,1,0,1,1);

	TBW_laserSight = new ToggleButtonWidget(gbGameModes, ":/res/btnLaserSight.png");
	TBW_laserSight->setText(ToggleButtonWidget::tr("Laser Sight"));
    TBW_laserSight->setToolTip(tr("Assisted aiming with laser sight"));
	glGMLayout->addWidget(TBW_laserSight,1,1,1,1);

	TBW_invulnerable = new ToggleButtonWidget(gbGameModes, ":/res/btnInvulnerable.png");
	TBW_invulnerable->setText(ToggleButtonWidget::tr("Invulnerable"));
    TBW_invulnerable->setToolTip(tr("All hogs have a personal forcefield"));
	glGMLayout->addWidget(TBW_invulnerable,1,2,1,1);

	TBW_mines = new ToggleButtonWidget(gbGameModes, ":/res/btnMines.png");
	TBW_mines->setText(ToggleButtonWidget::tr("Add Mines"));
    TBW_mines->setToolTip(tr("Enable random mines"));
	glGMLayout->addWidget(TBW_mines,1,3,1,1);

	TBW_vampiric = new ToggleButtonWidget(gbGameModes, ":/res/btnVampiric.png");
	TBW_vampiric->setText(ToggleButtonWidget::tr("Vampirism"));
    TBW_vampiric->setToolTip(tr("Gain 80% of the damage you do back in health"));
	glGMLayout->addWidget(TBW_vampiric,2,0,1,1);

	TBW_karma = new ToggleButtonWidget(gbGameModes, ":/res/btnKarma.png");
	TBW_karma->setText(ToggleButtonWidget::tr("Karma"));
    TBW_karma->setToolTip(tr("Share your opponents pain, share their damage"));
	glGMLayout->addWidget(TBW_karma,2,1,1,1);

	TBW_artillery = new ToggleButtonWidget(gbGameModes, ":/res/btnArtillery.png");
	TBW_artillery->setText(ToggleButtonWidget::tr("Artillery"));
    TBW_artillery->setToolTip(tr("Your hogs are unable to move, put your artillery skills to the test"));
	glGMLayout->addWidget(TBW_artillery,2,2,1,1);

	TBW_randomorder = new ToggleButtonWidget(gbGameModes, ":/res/btnRandomOrder.png");
	TBW_randomorder->setText(ToggleButtonWidget::tr("Random Order"));
    TBW_randomorder->setToolTip(tr("Order of play is random instead of in room order."));
	glGMLayout->addWidget(TBW_randomorder,2,3,1,1);

	TBW_king = new ToggleButtonWidget(gbGameModes, ":/res/btnKing.png");
	TBW_king->setText(ToggleButtonWidget::tr("King"));
    TBW_king->setToolTip(tr("Play with a King. If he dies, your side dies."));
	glGMLayout->addWidget(TBW_king,3,0,1,1);

	TBW_placehog = new ToggleButtonWidget(gbGameModes, ":/res/btnPlaceHog.png");
	TBW_placehog->setText(ToggleButtonWidget::tr("Place Hedgehogs"));
    TBW_placehog->setToolTip(tr("Take turns placing your hedgehogs before the start of play."));
	glGMLayout->addWidget(TBW_placehog,3,1,1,1);

	TBW_sharedammo = new ToggleButtonWidget(gbGameModes, ":/res/btnSharedAmmo.png");
	TBW_sharedammo->setText(ToggleButtonWidget::tr("Clan Shares Ammo"));
    TBW_sharedammo->setToolTip(tr("Ammo is shared between all teams that share a colour."));
	glGMLayout->addWidget(TBW_sharedammo,3,2,1,1);

	TBW_disablegirders = new ToggleButtonWidget(gbGameModes, ":/res/btnDisableGirders.png");
	TBW_disablegirders->setText(ToggleButtonWidget::tr("Disable Girders"));
    TBW_disablegirders->setToolTip(tr("Disable girders when generating random maps."));
	glGMLayout->addWidget(TBW_disablegirders,3,3,1,1);
	
	// Right
	QLabel * l;

	l = new QLabel(gbBasicSettings);
	l->setText(QLabel::tr("Damage Modifier"));
	l->setWordWrap(true);
	glBSLayout->addWidget(l,0,0,1,1);
	l = new QLabel(gbBasicSettings);
	l->setFixedSize(32,32);
	l->setPixmap(QPixmap(":/res/iconDamage.png"));
	glBSLayout->addWidget(l,0,1,1,1);

	SB_DamageModifier = new QSpinBox(gbBasicSettings);
	SB_DamageModifier->setRange(10, 300);
	SB_DamageModifier->setValue(100);
	SB_DamageModifier->setSingleStep(25);
	glBSLayout->addWidget(SB_DamageModifier,0,2,1,1);

	l = new QLabel(gbBasicSettings);
	l->setText(QLabel::tr("Turn Time"));
	l->setWordWrap(true);
	glBSLayout->addWidget(l,1,0,1,1);
	l = new QLabel(gbBasicSettings);
	l->setFixedSize(32,32);
	l->setPixmap(QPixmap(":/res/iconTime.png"));
	glBSLayout->addWidget(l,1,1,1,1);

	SB_TurnTime = new QSpinBox(gbBasicSettings);
	SB_TurnTime->setRange(1, 99);
	SB_TurnTime->setValue(45);
	SB_TurnTime->setSingleStep(15);
	glBSLayout->addWidget(SB_TurnTime,1,2,1,1);

	l = new QLabel(gbBasicSettings);
	l->setText(QLabel::tr("Initial Health"));
	l->setWordWrap(true);
	glBSLayout->addWidget(l,2,0,1,1);
	l = new QLabel(gbBasicSettings);
	l->setFixedSize(32,32);
	l->setPixmap(QPixmap(":/res/iconHealth.png"));
	glBSLayout->addWidget(l,2,1,1,1);

	SB_InitHealth = new QSpinBox(gbBasicSettings);
	SB_InitHealth->setRange(50, 200);
	SB_InitHealth->setValue(100);
	SB_InitHealth->setSingleStep(25);
	glBSLayout->addWidget(SB_InitHealth,2,2,1,1);

	l = new QLabel(gbBasicSettings);
	l->setText(QLabel::tr("Sudden Death Timeout"));
	l->setWordWrap(true);
	glBSLayout->addWidget(l,3,0,1,1);
	l = new QLabel(gbBasicSettings);
	l->setFixedSize(32,32);
	l->setPixmap(QPixmap(":/res/iconSuddenDeath.png"));
	glBSLayout->addWidget(l,3,1,1,1);

	SB_SuddenDeath = new QSpinBox(gbBasicSettings);
	SB_SuddenDeath->setRange(0, 50);
	SB_SuddenDeath->setValue(15);
	SB_SuddenDeath->setSingleStep(3);
	glBSLayout->addWidget(SB_SuddenDeath,3,2,1,1);

	l = new QLabel(gbBasicSettings);
	l->setText(QLabel::tr("Crate Drops"));
	l->setWordWrap(true);
	glBSLayout->addWidget(l,4,0,1,1);
	l = new QLabel(gbBasicSettings);
	l->setFixedSize(32,32);
	l->setPixmap(QPixmap(":/res/iconBox.png"));
	glBSLayout->addWidget(l,4,1,1,1);

	SB_CaseProb = new FreqSpinBox(gbBasicSettings);
	SB_CaseProb->setRange(0, 9);
	SB_CaseProb->setValue(5);
	glBSLayout->addWidget(SB_CaseProb,4,2,1,1);

	l = new QLabel(gbBasicSettings);
	l->setText(QLabel::tr("Mines Time"));
	l->setWordWrap(true);
	glBSLayout->addWidget(l,5,0,1,1);
	l = new QLabel(gbBasicSettings);
	l->setFixedSize(32,32);
	l->setPixmap(QPixmap(":/res/iconTime.png")); // TODO: icon
	glBSLayout->addWidget(l,5,1,1,1);
	SB_MinesTime = new QSpinBox(gbBasicSettings);
	SB_MinesTime->setRange(-1, 3);
	SB_MinesTime->setValue(3);
	SB_MinesTime->setSingleStep(1);
	SB_MinesTime->setSpecialValueText(tr("Random"));
	SB_MinesTime->setSuffix(" "+ tr("Seconds"));
	glBSLayout->addWidget(SB_MinesTime,5,2,1,1);

	l = new QLabel(gbBasicSettings);
	l->setText(QLabel::tr("Mines"));
	l->setWordWrap(true);
	glBSLayout->addWidget(l,6,0,1,1);
	l = new QLabel(gbBasicSettings);
	l->setFixedSize(32,32);
	l->setPixmap(QPixmap(":/res/iconMine.png")); // TODO: icon
	glBSLayout->addWidget(l,6,1,1,1);
	SB_Mines = new QSpinBox(gbBasicSettings);
	SB_Mines->setRange(1, 80);
	SB_Mines->setValue(1);
	SB_Mines->setSingleStep(5);
	glBSLayout->addWidget(SB_Mines,6,2,1,1);

	l = new QLabel(gbBasicSettings);
	l->setText(QLabel::tr("% Dud Mines"));
	l->setWordWrap(true);
	glBSLayout->addWidget(l,7,0,1,1);
	l = new QLabel(gbBasicSettings);
	l->setFixedSize(32,32);
	l->setPixmap(QPixmap(":/res/iconMine.png"));
	glBSLayout->addWidget(l,7,1,1,1);
	SB_MineDuds = new QSpinBox(gbBasicSettings);
	SB_MineDuds->setRange(0, 100);
	SB_MineDuds->setValue(0);
	SB_MineDuds->setSingleStep(5);
	glBSLayout->addWidget(SB_MineDuds,7,2,1,1);


	l = new QLabel(gbBasicSettings);
	l->setText(QLabel::tr("Explosives"));
	l->setWordWrap(true);
	glBSLayout->addWidget(l,8,0,1,1);
	l = new QLabel(gbBasicSettings);
	l->setFixedSize(32,32);
	l->setPixmap(QPixmap(":/res/iconDamage.png"));
	glBSLayout->addWidget(l,8,1,1,1);
	SB_Explosives = new QSpinBox(gbBasicSettings);
	SB_Explosives->setRange(0, 40);
	SB_Explosives->setValue(0);
	SB_Explosives->setSingleStep(1);
	glBSLayout->addWidget(SB_Explosives,8,2,1,1);


	l = new QLabel(gbBasicSettings);
	l->setText(QLabel::tr("Scheme Name:"));

	LE_name = new QLineEdit(this);

	gl->addWidget(LE_name,14,1,1,5);
	gl->addWidget(l,14,0,1,1);

	mapper = new QDataWidgetMapper(this);

	BtnBack = addButton(":/res/Exit.png", pageLayout, 15, 0, true);
	BtnNew = addButton(tr("New"), pageLayout, 15, 2);
	BtnDelete = addButton(tr("Delete"), pageLayout, 15, 3);

	selectScheme = new QComboBox(this);
	pageLayout->addWidget(selectScheme, 15, 1);

	connect(BtnNew, SIGNAL(clicked()), this, SLOT(newRow()));
	connect(BtnDelete, SIGNAL(clicked()), this, SLOT(deleteRow()));
	connect(selectScheme, SIGNAL(currentIndexChanged(int)), mapper, SLOT(setCurrentIndex(int)));
	connect(selectScheme, SIGNAL(currentIndexChanged(int)), this, SLOT(schemeSelected(int)));
}

void PageScheme::setModel(QAbstractItemModel * model)
{
	mapper->setModel(model);
	selectScheme->setModel(model);

	mapper->addMapping(LE_name, 0);
	mapper->addMapping(TBW_mode_Forts->button(), 1);
	mapper->addMapping(TBW_teamsDivide->button(), 2);
	mapper->addMapping(TBW_solid->button(), 3);
	mapper->addMapping(TBW_border->button(), 4);
	mapper->addMapping(TBW_lowGravity->button(), 5);
	mapper->addMapping(TBW_laserSight->button(), 6);
	mapper->addMapping(TBW_invulnerable->button(), 7);
	mapper->addMapping(TBW_mines->button(), 8);
	mapper->addMapping(TBW_vampiric->button(), 9);
	mapper->addMapping(TBW_karma->button(), 10);
	mapper->addMapping(TBW_artillery->button(), 11);
	mapper->addMapping(TBW_randomorder->button(), 12);
	mapper->addMapping(TBW_king->button(), 13);
	mapper->addMapping(TBW_placehog->button(), 14);
	mapper->addMapping(TBW_sharedammo->button(), 15);
	mapper->addMapping(TBW_disablegirders->button(), 16);
	mapper->addMapping(SB_DamageModifier, 17);
	mapper->addMapping(SB_TurnTime, 18);
	mapper->addMapping(SB_InitHealth, 19);
	mapper->addMapping(SB_SuddenDeath, 20);
	mapper->addMapping(SB_CaseProb, 21);
	mapper->addMapping(SB_MinesTime, 22);
	mapper->addMapping(SB_Mines, 23);
	mapper->addMapping(SB_MineDuds, 24);
	mapper->addMapping(SB_Explosives, 25);

	mapper->toFirst();
}

void PageScheme::newRow()
{
	QAbstractItemModel * model = mapper->model();
	model->insertRow(model->rowCount());
	selectScheme->setCurrentIndex(model->rowCount() - 1);
}

void PageScheme::deleteRow()
{
	QAbstractItemModel * model = mapper->model();
	model->removeRow(selectScheme->currentIndex());
}

void PageScheme::schemeSelected(int n)
{
	gbGameModes->setEnabled(n >= 5); // FIXME: derive number from model
	gbBasicSettings->setEnabled(n >= 5);
	LE_name->setEnabled(n >= 5);
}

/////////////////////////////////////////////////

PageAdmin::PageAdmin(QWidget* parent) :
	AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);

	QLabel * lblSM = new QLabel(this);
	lblSM->setText(tr("Server message:"));
	pageLayout->addWidget(lblSM, 0, 0);

	leServerMessage = new QLineEdit(this);
	pageLayout->addWidget(leServerMessage, 0, 1);

	pbSetSM = addButton(tr("Set message"), pageLayout, 0, 2);
	pbClearAccountsCache = addButton(tr("Clear Accounts Cache"), pageLayout, 1, 0);

	BtnBack = addButton(":/res/Exit.png", pageLayout, 2, 0, true);

	connect(pbSetSM, SIGNAL(clicked()), this, SLOT(smChanged()));
}

void PageAdmin::smChanged()
{
	emit setServerMessage(leServerMessage->text());
}

void PageAdmin::serverMessage(const QString & str)
{
	leServerMessage->setText(str);
}

/////////////////////////////////////////////////

PageNetType::PageNetType(QWidget* parent) : AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setRowStretch(0, 10);
	pageLayout->setRowStretch(3, 10);

	pageLayout->setColumnStretch(1, 10);
	pageLayout->setColumnStretch(2, 20);
	pageLayout->setColumnStretch(3, 10);

	BtnLAN = addButton(tr("LAN game"), pageLayout, 1, 2);
	BtnOfficialServer = addButton(tr("Official server"), pageLayout, 2, 2);

	// hack: temporary deactivated - requires server modifications that aren't backward compatible (yet)
	//BtnOfficialServer->setEnabled(false);

	BtnBack = addButton(":/res/Exit.png", pageLayout, 4, 0, true);
}
