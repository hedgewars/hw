/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006, 2007 Andrey Korotaev <unC0Rr@gmail.com>
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
#include "netudpwidget.h"
#include "chatwidget.h"
#include "SDLs.h"
#include "playrecordpage.h"
#include "selectWeapon.h"

PageMain::PageMain(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setMargin(25);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 2);
	pageLayout->setColumnStretch(2, 1);

	BtnSinglePlayer = new QPushButton(this);
	BtnSinglePlayer->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	BtnSinglePlayer->setFont(*font14);
	BtnSinglePlayer->setText(QPushButton::tr("Single Player"));
	pageLayout->addWidget(BtnSinglePlayer, 0, 1);

	BtnMultiplayer = new QPushButton(this);
	BtnMultiplayer->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	BtnMultiplayer->setFont(*font14);
	BtnMultiplayer->setText(QPushButton::tr("Multiplayer"));
	pageLayout->addWidget(BtnMultiplayer, 1, 1);

	BtnNet = new QPushButton(this);
	BtnNet->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	BtnNet->setFont(*font14);
	BtnNet->setText(QPushButton::tr("Net game"));
	pageLayout->addWidget(BtnNet, 2, 1);

	BtnLoad = new QPushButton(this);
	BtnLoad->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	BtnLoad->setFont(*font14);
	BtnLoad->setText(QPushButton::tr("Load"));
	pageLayout->addWidget(BtnLoad, 3, 1);

	BtnDemos = new QPushButton(this);
	BtnDemos->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	BtnDemos->setFont(*font14);
	BtnDemos->setText(QPushButton::tr("Demos"));
	pageLayout->addWidget(BtnDemos, 4, 1);

	BtnSetup = new QPushButton(this);
	BtnSetup->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	BtnSetup->setFont(*font14);
	BtnSetup->setText(QPushButton::tr("Setup"));
	pageLayout->addWidget(BtnSetup, 5, 1);

	BtnInfo = new QPushButton(this);
	BtnInfo->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	BtnInfo->setFont(*font14);
	BtnInfo->setText(QPushButton::tr("About"));
	pageLayout->addWidget(BtnInfo, 6, 1);

	BtnExit = new QPushButton(parent);
	BtnExit->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	BtnExit->setFont(*font14);
	BtnExit->setText(QPushButton::tr("Exit"));
	pageLayout->addWidget(BtnExit, 7, 1);
}

PageSimpleGame::PageSimpleGame(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QVBoxLayout * pageLayout = new QVBoxLayout(this);
	QHBoxLayout * topLayout = new QHBoxLayout();
	QHBoxLayout * bottomLayout = new QHBoxLayout();
	pageLayout->addLayout(topLayout, 100);
	pageLayout->addLayout(bottomLayout, 0);

	BtnBack = new QPushButton(this);
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
	bottomLayout->addWidget(BtnBack, 100);
	bottomLayout->addStretch(100);
	BtnSimpleGame = new QPushButton(this);
	BtnSimpleGame->setFont(*font14);
	BtnSimpleGame->setText(QPushButton::tr("Simple Game"));
	bottomLayout->addWidget(BtnSimpleGame, 100);

	gameCFG = new GameCFGWidget(this);
	topLayout->addStretch(100);
	topLayout->addWidget(gameCFG);
	topLayout->addStretch(100);
}

PageEditTeam::PageEditTeam(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnMinimumWidth(0, 150);
	pageLayout->setColumnStretch(1, 100);
	pageLayout->setColumnMinimumWidth(1, 210);
	pageLayout->setColumnStretch(2, 75);
	pageLayout->setColumnMinimumWidth(2, 110);
	pageLayout->setColumnStretch(3, 75);
	pageLayout->setColumnMinimumWidth(3, 110);

	GBoxTeam = new QGroupBox(this);
	GBoxTeam->setTitle(QGroupBox::tr("Team"));
	GBoxTeam->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
	QGridLayout * GBTLayout = new QGridLayout(GBoxTeam);
	TeamNameEdit = new QLineEdit(GBoxTeam);
	TeamNameEdit->setMaxLength(15);
	GBTLayout->addWidget(TeamNameEdit, 0, 0, 1, 0);

	pageLayout->addWidget(GBoxTeam, 0, 0);

	GBoxHedgehogs = new QGroupBox(this);
	GBoxHedgehogs->setTitle(QGroupBox::tr("Team Members"));
	GBoxHedgehogs->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
	QGridLayout * GBHLayout = new QGridLayout(GBoxHedgehogs);
	for(int i = 0; i < 8; i++)
	{
		HHNameEdit[i] = new QLineEdit(GBoxHedgehogs);
		HHNameEdit[i]->setGeometry(QRect(10, 20 + i * 30, 141, 20));
		HHNameEdit[i]->setMaxLength(15);
		GBHLayout->addWidget(HHNameEdit[i]);
	}
	pageLayout->addWidget(GBoxHedgehogs, 1, 0, 2, 1);

	BtnTeamDiscard = new QPushButton(this);
	BtnTeamDiscard->setFont(*font14);
	BtnTeamDiscard->setText(QPushButton::tr("Discard"));
	pageLayout->addWidget(BtnTeamDiscard, 4, 0);

	GBoxBinds = new QGroupBox(this);
	GBoxBinds->setTitle(QGroupBox::tr("Key binds"));
	QGridLayout * GBBLayout = new QGridLayout(GBoxBinds);
	BindsBox = new QToolBox(GBoxBinds);
	BindsBox->setLineWidth(0);
	GBBLayout->addWidget(BindsBox);
	page_A = new QWidget();
	BindsBox->addItem(page_A, QToolBox::tr("Actions"));
	page_W = new QWidget();
	BindsBox->addItem(page_W, QToolBox::tr("Weapons"));
	page_WP = new QWidget();
	BindsBox->addItem(page_WP, QToolBox::tr("Weapon properties"));
	page_O = new QWidget();
	BindsBox->addItem(page_O, QToolBox::tr("Other"));
	pageLayout->addWidget(GBoxBinds, 0, 1, 5, 1);

	QStringList binds;
	for(int i = 0; strlen(sdlkeys[i][1]) > 0; i++)
	{
		binds << sdlkeys[i][1];
	}

	quint16 widind = 0, i = 0;
	while (i < BINDS_NUMBER) {
		quint16 num = 0;
		QGridLayout * pagelayout = new QGridLayout(BindsBox->widget(widind));
		do {
			LBind[i] = new QLabel(BindsBox->widget(widind));
			LBind[i]->setText(QApplication::translate("binds", cbinds[i].name));
			LBind[i]->setAlignment(Qt::AlignRight);
			pagelayout->addWidget(LBind[i], num, 0);
			CBBind[i] = new QComboBox(BindsBox->widget(widind));
			CBBind[i]->addItems(binds);
			pagelayout->addWidget(CBBind[i], num, 1);
			num++;
		} while (!cbinds[i++].chwidget);
		pagelayout->addWidget(new QWidget(BindsBox->widget(widind)), num, 0, 1, 2);
		widind++;
	}

	GBoxGrave = new QGroupBox(this);
	GBoxGrave->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
	GBoxGrave->setTitle(QGroupBox::tr("Grave"));
	QGridLayout * GBGLayout = new QGridLayout(GBoxGrave);
	CBGrave = new QComboBox(GBoxGrave);
	CBGrave->setMaxCount(65535);
	GBGLayout->addWidget(CBGrave, 0, 0, 1, 3);
	GravePreview = new QLabel(GBoxGrave);
	GravePreview->setScaledContents(false);
	pageLayout->addWidget(GBoxGrave, 0, 3, 2, 1);
	GBGLayout->addWidget(GravePreview, 1, 1);

	GBoxTeamLvl = new QGroupBox(this);
	GBoxTeamLvl->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
	GBoxTeamLvl->setTitle(QGroupBox::tr("Team level"));
	QGridLayout * GBTLLayout = new QGridLayout(GBoxTeamLvl);
	CBTeamLvl = new QComboBox(GBoxTeamLvl);
	CBTeamLvl->addItem(QComboBox::tr("Human"));
	CBTeamLvl->addItem(QComboBox::tr("Level 5"));
	CBTeamLvl->addItem(QComboBox::tr("Level 4"));
	CBTeamLvl->addItem(QComboBox::tr("Level 3"));
	CBTeamLvl->addItem(QComboBox::tr("Level 2"));
	CBTeamLvl->addItem(QComboBox::tr("Level 1"));
	CBTeamLvl->setMaxCount(6);
	GBTLLayout->addWidget(CBTeamLvl, 0, 0, 1, 3);
	LevelPict = new QLabel(GBoxTeamLvl);
	LevelPict->setScaledContents(false);
	LevelPict->setFixedSize(32, 32);
	pageLayout->addWidget(GBoxTeamLvl, 0, 2, 2, 1);
	GBTLLayout->addWidget(LevelPict, 1, 1);

	GBoxFort = new QGroupBox(this);
	GBoxFort->setTitle(QGroupBox::tr("Fort"));
	QGridLayout * GBFLayout = new QGridLayout(GBoxFort);
	CBFort = new QComboBox(GBoxFort);
	CBFort->setMaxCount(65535);
	GBFLayout->addWidget(CBFort, 0, 0);
	FortPreview = new SquareLabel(GBoxFort);
	FortPreview->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	FortPreview->setPixmap(QPixmap());
	GBFLayout->addWidget(FortPreview, 1, 0);
	pageLayout->addWidget(GBoxFort, 2, 2, 1, 2);

	BtnTeamSave = new QPushButton(this);
	BtnTeamSave->setFont(*font14);
	BtnTeamSave->setText(QPushButton::tr("Save"));
	pageLayout->addWidget(BtnTeamSave, 4, 2, 1, 2);

	QDir tmpdir;
	tmpdir.cd(datadir->absolutePath());
	tmpdir.cd("Forts");
	tmpdir.setFilter(QDir::Files);

	CBFort->addItems(tmpdir.entryList(QStringList("*L.png")).replaceInStrings(QRegExp("^(.*)L\\.png"), "\\1"));
	tmpdir.cd("../Graphics/Graves");
	QStringList list = tmpdir.entryList(QStringList("*.png"));
	for (QStringList::Iterator it = list.begin(); it != list.end(); ++it )
	{
		CBGrave->addItem((*it).replace(QRegExp("^(.*)\\.png"), "\\1"));
	}

	connect(CBGrave, SIGNAL(activated(const QString &)), this, SLOT(CBGrave_activated(const QString &)));
	connect(CBTeamLvl, SIGNAL(activated(int)), this, SLOT(CBTeamLvl_activated(int)));
	connect(CBFort, SIGNAL(activated(const QString &)), this, SLOT(CBFort_activated(const QString &)));
}

void PageEditTeam::CBGrave_activated(const QString & gravename)
{
	QPixmap pix(datadir->absolutePath() + "/Graphics/Graves/" + gravename + ".png");
	GravePreview->setPixmap(pix.copy(0, 0, 32, 32));
}

void PageEditTeam::CBFort_activated(const QString & fortname)
{
	QPixmap pix(datadir->absolutePath() + "/Forts/" + fortname + "L.png");
	FortPreview->setPixmap(pix);
}

void PageEditTeam::CBTeamLvl_activated(int id)
{
	QPixmap pix(QString(":/res/botlevels/%1.png").arg(id));
	LevelPict->setPixmap(pix);
}

PageMultiplayer::PageMultiplayer(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);

	BtnBack = new QPushButton(this);
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
	pageLayout->addWidget(BtnBack, 1, 0);

	gameCFG = new GameCFGWidget(this);
	pageLayout->addWidget(gameCFG, 0, 0, 1, 2);
	teamsSelect = new TeamSelWidget(this);
	pageLayout->addWidget(teamsSelect, 0, 2, 1, 2);

	BtnStartMPGame = new QPushButton(this);
	BtnStartMPGame->setFont(*font14);
	BtnStartMPGame->setText(QPushButton::tr("Start"));
	pageLayout->addWidget(BtnStartMPGame, 1, 3);
}

PageOptions::PageOptions(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setColumnStretch(0, 100);
	pageLayout->setColumnStretch(1, 100);
	pageLayout->setColumnStretch(2, 100);
	pageLayout->setRowStretch(0, 0);
	pageLayout->setRowStretch(1, 0);
	pageLayout->setRowStretch(2, 100);
	pageLayout->setRowStretch(3, 0);

	groupBox = new QGroupBox(this);
	groupBox->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
	groupBox->setTitle(QGroupBox::tr("Teams"));
	pageLayout->addWidget(groupBox, 0, 0, 1, 3);

	QGridLayout * GBTlayout = new QGridLayout(groupBox);
	BtnNewTeam = new QPushButton(groupBox);
	BtnNewTeam->setFont(*font14);
	BtnNewTeam->setText(QPushButton::tr("New team"));
	GBTlayout->addWidget(BtnNewTeam, 0, 0);

	CBTeamName = new QComboBox(groupBox);
	GBTlayout->addWidget(CBTeamName, 0, 1);

	BtnEditTeam	= new QPushButton(groupBox);
	BtnEditTeam->setFont(*font14);
	BtnEditTeam->setText(QPushButton::tr("Edit team"));
	GBTlayout->addWidget(BtnEditTeam, 0, 2);

	AGGroupBox = new QGroupBox(this);
	AGGroupBox->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
	AGGroupBox->setTitle(QGroupBox::tr("Audio/Graphic options"));
	pageLayout->addWidget(AGGroupBox, 1, 1);

	QVBoxLayout * GBAlayout = new QVBoxLayout(AGGroupBox);
	QHBoxLayout * GBAreslayout = new QHBoxLayout(0);
	QLabel * resolution = new QLabel(AGGroupBox);
	resolution->setText(QLabel::tr("Resolution"));
	GBAreslayout->addWidget(resolution);

	CBResolution = new QComboBox(AGGroupBox);
	SDLInteraction sdli;
	CBResolution->addItems(sdli.getResolutions());
	GBAreslayout->addWidget(CBResolution);
	GBAlayout->addLayout(GBAreslayout);

	QHBoxLayout * GBAfpslayout = new QHBoxLayout(0);
	QLabel * maxfps = new QLabel(AGGroupBox);
	maxfps->setText(QLabel::tr("FPS limit"));
	GBAfpslayout->addWidget(maxfps);
	GBAlayout->addLayout(GBAfpslayout);

	CBFullscreen = new QCheckBox(AGGroupBox);
	CBFullscreen->setText(QCheckBox::tr("Fullscreen"));
	GBAlayout->addWidget(CBFullscreen);

	CBEnableSound = new	QCheckBox(AGGroupBox);
	CBEnableSound->setText(QCheckBox::tr("Enable sound"));
	GBAlayout->addWidget(CBEnableSound);

	CBShowFPS = new QCheckBox(AGGroupBox);
	CBShowFPS->setText(QCheckBox::tr("Show FPS"));
	GBAlayout->addWidget(CBShowFPS);

	CBAltDamage = new QCheckBox(AGGroupBox);
	CBAltDamage->setText(QCheckBox::tr("Alternative damage show"));
	GBAlayout->addWidget(CBAltDamage);

	fpsedit = new FPSEdit(AGGroupBox);
	GBAfpslayout->addWidget(fpsedit);

	BtnSaveOptions = new QPushButton(this);
	BtnSaveOptions->setFont(*font14);
	BtnSaveOptions->setText(QPushButton::tr("Save"));
	pageLayout->addWidget(BtnSaveOptions, 4, 2);

	BtnBack = new QPushButton(this);
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
	pageLayout->addWidget(BtnBack, 4, 0);

	WeaponsButt = new QPushButton(this);
	WeaponsButt->setFont(*font14);
	WeaponsButt->setText(QPushButton::tr("Weapons scheme"));
	pageLayout->addWidget(WeaponsButt, 1, 0);

}

PageNet::PageNet(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 1);
	pageLayout->setColumnStretch(2, 1);

	BtnNetSvrStart = new QPushButton(this);
	BtnNetSvrStart->setFont(*font14);
	BtnNetSvrStart->setText(QPushButton::tr("Start server"));
	pageLayout->addWidget(BtnNetSvrStart, 3, 2);

	NNGroupBox = new QGroupBox(this);
	NNGroupBox->setSizePolicy(QSizePolicy::MinimumExpanding, QSizePolicy::Fixed);
	NNGroupBox->setTitle(QGroupBox::tr("Net options"));
	pageLayout->addWidget(NNGroupBox, 0, 0);

	QGridLayout * GBNlayout = new QGridLayout(NNGroupBox);
	labelNN = new QLabel(NNGroupBox);
	labelNN->setText(QLabel::tr("Net nick"));
	GBNlayout->addWidget(labelNN, 0, 0);

	editNetNick	= new QLineEdit(NNGroupBox);
	editNetNick->setMaxLength(20);
	editNetNick->setText(QLineEdit::tr("unnamed"));
	GBNlayout->addWidget(editNetNick, 0, 1);

	QGroupBox * ConnGroupBox = new QGroupBox(this);
	ConnGroupBox->setTitle(QGroupBox::tr("Net game"));
	pageLayout->addWidget(ConnGroupBox, 2, 0, 1, 3);
	QGridLayout * GBClayout = new QGridLayout(ConnGroupBox);
	GBClayout->setColumnStretch(0, 0);
	GBClayout->setColumnStretch(1, 1);
	GBClayout->setColumnStretch(2, 1);
	GBClayout->setRowStretch(0, 0);
	GBClayout->setRowStretch(1, 0);
	GBClayout->setRowStretch(2, 1);

	labelIP = new QLabel(ConnGroupBox);
	labelIP->setText(QLabel::tr("Server address"));
	GBClayout->addWidget(labelIP, 0, 0);

	editIP = new QLineEdit(ConnGroupBox);
	editIP->setMaxLength(50);
	GBClayout->addWidget(editIP, 0, 1);

	BtnNetConnect = new	QPushButton(ConnGroupBox);
	BtnNetConnect->setFont(*font14);
	BtnNetConnect->setText(QPushButton::tr("Connect"));
	GBClayout->addWidget(BtnNetConnect, 0, 2);

	pUdpClient=new HWNetUdpWidget(ConnGroupBox);
	GBClayout->addWidget(pUdpClient, 1, 0, 2, 2);

	pUpdateUdpButt = new QPushButton(ConnGroupBox);
	pUpdateUdpButt->setFont(*font14);
	pUpdateUdpButt->setText(QPushButton::tr("Update"));
	GBClayout->addWidget(pUpdateUdpButt, 1, 2);

	BtnBack = new QPushButton(this);
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
	pageLayout->addWidget(BtnBack, 3, 0);
}

PageNetGame::PageNetGame(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setSizeConstraint(QLayout::SetMinimumSize);
	//pageLayout->setSpacing(1);
	//pageLayout->setMargin(1);
	pageLayout->setColumnStretch(0, 50);
	pageLayout->setColumnStretch(1, 50);

	// chatwidget
	pChatWidget = new HWChatWidget(this);
	pageLayout->addWidget(pChatWidget, 1, 0);
	pageLayout->setRowStretch(1, 100);

	pGameCFG = new GameCFGWidget(this);
	pageLayout->addWidget(pGameCFG, 0, 0);

	pNetTeamsWidget = new TeamSelWidget(this);
	pNetTeamsWidget->setAcceptOuter(true);
	pageLayout->addWidget(pNetTeamsWidget, 0, 1, 2, 1);

	BtnBack = new QPushButton(this);
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
	pageLayout->addWidget(BtnBack, 2, 0);

	BtnGo	= new QPushButton(this);
	BtnGo->setFont(*font14);
	BtnGo->setText(QPushButton::tr("Go!"));
	BtnGo->setEnabled(false);
	pageLayout->addWidget(BtnGo, 2, 1);
}

PageInfo::PageInfo(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 1);
	pageLayout->setColumnStretch(2, 1);

	BtnBack = new QPushButton(this);
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
	pageLayout->addWidget(BtnBack, 1, 0);

	about = new About(this);
	pageLayout->addWidget(about, 0, 0, 1, 3);
}

PageGameStats::PageGameStats(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 1);
	pageLayout->setColumnStretch(2, 1);

	BtnBack = new QPushButton(this);
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
	pageLayout->addWidget(BtnBack, 1, 0);

	labelGameStats = new QLabel(this);
	labelGameStats->setTextFormat(Qt::RichText);
	pageLayout->addWidget(labelGameStats, 0, 0, 1, 3);
}

PageSinglePlayer::PageSinglePlayer(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setMargin(25);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 2);
	pageLayout->setColumnStretch(2, 1);
	pageLayout->setRowStretch(0, 1);
	pageLayout->setRowStretch(3, 1);

	BtnSimpleGamePage = new QPushButton(this);
	BtnSimpleGamePage->setFont(*font14);
	BtnSimpleGamePage->setText(QPushButton::tr("Simple Game"));
	pageLayout->addWidget(BtnSimpleGamePage, 1, 1);

	BtnTrainPage = new QPushButton(this);
	BtnTrainPage->setFont(*font14);
	BtnTrainPage->setText(QPushButton::tr("Training"));
	pageLayout->addWidget(BtnTrainPage, 2, 1);

	BtnBack = new QPushButton(this);
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
	pageLayout->addWidget(BtnBack, 4, 0);

}

PageTraining::PageTraining(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setMargin(25);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 2);
	pageLayout->setColumnStretch(2, 1);

	BtnStartTrain = new QPushButton(this);
	BtnStartTrain->setFont(*font14);
	BtnStartTrain->setText(QPushButton::tr("Go!"));
	pageLayout->addWidget(BtnStartTrain, 1, 2);

	BtnBack = new QPushButton(this);
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
	pageLayout->addWidget(BtnBack, 1, 0);
}

PageSelectWeapon::PageSelectWeapon(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setMargin(25);
	//pageLayout->setColumnStretch(0, 1);
	//pageLayout->setColumnStretch(1, 2);
	//pageLayout->setColumnStretch(2, 1);
        
        pWeapons=new SelWeaponWidget(this);
	pageLayout->addWidget(pWeapons, 0, 0);

	BtnBack = new QPushButton(this);
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
	pageLayout->addWidget(BtnBack, 1, 0);
}

