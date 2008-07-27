/*
 * Hedgewars, a free turn based strategy game
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
#include <QRadioButton>
#include <QTableView>
#include <QMessageBox>
#include <QHeaderView>

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
#include "netwwwwidget.h"
#include "chatwidget.h"
#include "SDLs.h"
#include "playrecordpage.h"
#include "selectWeapon.h"

PageMain::PageMain(QWidget* parent) : 
  AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setMargin(25);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 2);
	pageLayout->setColumnStretch(2, 1);

	BtnSinglePlayer = addButton(tr("Single Player"), pageLayout, 0, 1);
	BtnSinglePlayer->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);

	BtnMultiplayer = addButton(tr("Multiplayer"), pageLayout, 1, 1);
	BtnMultiplayer->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);

	BtnNet = addButton(tr("Net game"), pageLayout, 2, 1);
	BtnNet->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);

	BtnLoad = addButton(tr("Saved games"), pageLayout, 3, 1);
	BtnLoad->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);

	BtnDemos = addButton(tr("Demos"), pageLayout, 4, 1);
	BtnDemos->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);

	BtnSetup = addButton(tr("Setup"), pageLayout, 5, 1);
	BtnSetup->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);

	BtnInfo = addButton(tr("About"), pageLayout, 6, 1);
	BtnInfo->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);

	BtnExit = addButton(tr("Exit"), pageLayout, 7, 1);
	BtnExit->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
}

PageEditTeam::PageEditTeam(QWidget* parent) :
  AbstractPage(parent)
{
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

	BtnTeamDiscard = addButton(tr("Discard"), pageLayout, 4, 0);

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

	BtnTeamSave = addButton(tr("Save"), pageLayout, 4, 2, 1, 2);

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

PageMultiplayer::PageMultiplayer(QWidget* parent) : 
  AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);

	BtnBack = addButton(tr("Back"), pageLayout, 1, 0);

	gameCFG = new GameCFGWidget(this);
	pageLayout->addWidget(gameCFG, 0, 0, 1, 2);

	teamsSelect = new TeamSelWidget(this);
	pageLayout->addWidget(teamsSelect, 0, 2, 1, 2);

	BtnStartMPGame = addButton(tr("Start"), pageLayout, 1, 3);
}

PageOptions::PageOptions(QWidget* parent) : 
  AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setColumnStretch(0, 100);
	pageLayout->setColumnStretch(1, 100);
	pageLayout->setColumnStretch(2, 100);
	pageLayout->setRowStretch(0, 0);
	pageLayout->setRowStretch(1, 0);
	pageLayout->setRowStretch(2, 0);
	pageLayout->setRowStretch(3, 100);
	pageLayout->setRowStretch(4, 0);

	groupBox = new QGroupBox(this);
	groupBox->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
	groupBox->setTitle(QGroupBox::tr("Teams"));
	pageLayout->addWidget(groupBox, 0, 0, 1, 3);

	QGridLayout * GBTlayout = new QGridLayout(groupBox);

	BtnNewTeam = addButton(tr("New team"), GBTlayout, 0, 0);

	CBTeamName = new QComboBox(groupBox);
	GBTlayout->addWidget(CBTeamName, 0, 1);

	BtnEditTeam = addButton(tr("Edit team"), GBTlayout, 0, 2);

	AGGroupBox = new QGroupBox(this);
	AGGroupBox->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
	AGGroupBox->setTitle(QGroupBox::tr("Audio/Graphic options"));
	pageLayout->addWidget(AGGroupBox, 2, 1);

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

	CBEnableMusic = new	QCheckBox(AGGroupBox);
	CBEnableMusic->setText(QCheckBox::tr("Enable music"));
	GBAlayout->addWidget(CBEnableMusic);

	CBShowFPS = new QCheckBox(AGGroupBox);
	CBShowFPS->setText(QCheckBox::tr("Show FPS"));
	GBAlayout->addWidget(CBShowFPS);

	CBAltDamage = new QCheckBox(AGGroupBox);
	CBAltDamage->setText(QCheckBox::tr("Alternative damage show"));
	GBAlayout->addWidget(CBAltDamage);

	fpsedit = new FPSEdit(AGGroupBox);
	GBAfpslayout->addWidget(fpsedit);

	BtnSaveOptions = addButton(tr("Save"), pageLayout, 4, 2);

	BtnBack = addButton(tr("Back"), pageLayout, 4, 0);

	QGroupBox* groupWeapons = new QGroupBox(this);
	groupWeapons->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
	groupWeapons->setTitle(QGroupBox::tr("Weapons"));
	pageLayout->addWidget(groupWeapons, 1, 0, 1, 3);
	QGridLayout * WeaponsLayout = new QGridLayout(groupWeapons);

	WeaponsButt = addButton(tr("Weapons set"), WeaponsLayout, 0, 0);
	WeaponsName = new QComboBox(this);
	WeaponsLayout->addWidget(WeaponsName, 0, 1);
	WeaponEdit = addButton(tr("Edit"), WeaponsLayout, 0, 2);

	NNGroupBox = new QGroupBox(this);
	NNGroupBox->setSizePolicy(QSizePolicy::MinimumExpanding, QSizePolicy::Fixed);
	NNGroupBox->setTitle(QGroupBox::tr("Net options"));
	pageLayout->addWidget(NNGroupBox, 2, 2);

	QGridLayout * GBNlayout = new QGridLayout(NNGroupBox);
	labelNN = new QLabel(NNGroupBox);
	labelNN->setText(QLabel::tr("Net nick"));
	GBNlayout->addWidget(labelNN, 0, 0);

	editNetNick = new QLineEdit(NNGroupBox);
	editNetNick->setMaxLength(20);
	editNetNick->setText(QLineEdit::tr("unnamed"));
	GBNlayout->addWidget(editNetNick, 0, 1);
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

	QGroupBox * NetTypeGroupBox = new QGroupBox(this);
	NetTypeGroupBox->setSizePolicy(QSizePolicy::MinimumExpanding, QSizePolicy::Fixed);
	NetTypeGroupBox->setTitle(QGroupBox::tr("Servers list"));
	pageLayout->addWidget(NetTypeGroupBox, 0, 1);

	QVBoxLayout * GBTlayout = new QVBoxLayout(NetTypeGroupBox);
	rbLocalGame = new QRadioButton(NetTypeGroupBox);
	rbLocalGame->setText(tr("Local"));
	rbLocalGame->setChecked(true);
	GBTlayout->addWidget(rbLocalGame);
	rbInternetGame = new QRadioButton(NetTypeGroupBox);
	rbInternetGame->setText(tr("Internet"));
	GBTlayout->addWidget(rbInternetGame);

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

	BtnBack = new QPushButton(this);
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
	pageLayout->addWidget(BtnBack, 3, 0);

	connect(rbLocalGame, SIGNAL(toggled(bool)), this, SLOT(updateServersList()));
	connect(BtnNetConnect, SIGNAL(clicked()), this, SLOT(slotConnect()));
}

void PageNet::updateServersList()
{
	if (rbLocalGame->isChecked())
		tvServersList->setModel(new HWNetUdpModel(tvServersList));
	else
		tvServersList->setModel(new HWNetWwwModel(tvServersList));

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
		QMessageBox::information(this, tr("Error"), tr("Please, select server from the list above"));
		return;
	}
	QString host = model->index(mi.row(), 1).data().toString();
	quint16 port = model->index(mi.row(), 2).data().toUInt();

	emit connectClicked(host, port);
}

PageNetServer::PageNetServer(QWidget* parent) : QWidget(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 1);
	pageLayout->setColumnStretch(2, 1);

	pageLayout->setRowStretch(0, 1);
	pageLayout->setRowStretch(1, 0);

	BtnBack = new QPushButton(this);
	BtnBack->setFont(*font14);
	BtnBack->setText(QPushButton::tr("Back"));
	pageLayout->addWidget(BtnBack, 1, 0);

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

	BtnGo = new QPushButton(this);
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

PageSelectWeapon::PageSelectWeapon(QWidget* parent) :
  AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setMargin(25);
	
	pWeapons=new SelWeaponWidget(cDefaultAmmoStore->size() - 10, this);
	pageLayout->addWidget(pWeapons, 0, 0, 1, 4);

	BtnBack = addButton(tr("Back"), pageLayout, 1, 0);
	BtnDefault = addButton(tr("Default"), pageLayout, 1, 1);
	BtnDelete = addButton(tr("Delete"), pageLayout, 1, 2);
	BtnSave = addButton(tr("Save"), pageLayout, 1, 3);
}

PageInGame::PageInGame(QWidget* parent) : 
  AbstractPage(parent)
{
	QLabel * label = new QLabel(this);
	label->setText("In game...");
}
