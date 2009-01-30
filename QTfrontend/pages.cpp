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
#include <QSound>

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

PageMain::PageMain(QWidget* parent) : 
  AbstractPage(parent)
{
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

PageEditTeam::PageEditTeam(QWidget* parent) :
  AbstractPage(parent)
{
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
	QVBoxLayout * vbox3 = new QVBoxLayout();
	page1Layout->addLayout(vbox1);
	page1Layout->addLayout(vbox2);
	page1Layout->addLayout(vbox3);
	
	GBoxHedgehogs = new QGroupBox(this);
	GBoxHedgehogs->setTitle(QGroupBox::tr("Team Members"));
	GBoxHedgehogs->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
	QGridLayout * GBHLayout = new QGridLayout(GBoxHedgehogs);
	
	HatsModel * hatsModel = new HatsModel(GBoxHedgehogs);
	for(int i = 0; i < 8; i++)
	{
		HHNameEdit[i] = new QLineEdit(GBoxHedgehogs);
		HHNameEdit[i]->setMaxLength(64);
		HHNameEdit[i]->setMinimumWidth(120);
		GBHLayout->addWidget(HHNameEdit[i], i, 0);
		
		HHHats[i] = new QComboBox(GBoxHedgehogs);
		HHHats[i]->setModel(hatsModel);
		HHHats[i]->setIconSize(QSize(32, 37));
		//HHHats[i]->setSizeAdjustPolicy(QComboBox::AdjustToContents);
		//HHHats[i]->setModelColumn(1);
		//HHHats[i]->setMinimumWidth(132);
		GBHLayout->addWidget(HHHats[i], i, 1);
	}
	vbox1->addWidget(GBoxHedgehogs);


	GBoxTeam = new QGroupBox(this);
	GBoxTeam->setTitle(QGroupBox::tr("Team"));
	GBoxTeam->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
	QVBoxLayout * GBTLayout = new QVBoxLayout(GBoxTeam);
	TeamNameEdit = new QLineEdit(GBoxTeam);
	TeamNameEdit->setMaxLength(64);
	GBTLayout->addWidget(TeamNameEdit);
	vbox2->addWidget(GBoxTeam);
	
	CBTeamLvl = new QComboBox(GBoxTeam);
	CBTeamLvl->setIconSize(QSize(48, 48));
	CBTeamLvl->addItem(QIcon(":/res/botlevels/0.png"), QComboBox::tr("Human"));
	for(int i = 5; i > 0; i--)
		CBTeamLvl->addItem(
				QIcon(QString(":/res/botlevels/%1.png").arg(6 - i)),
				QString("%1 %2").arg(QComboBox::tr("Level")).arg(i)
				);
	GBTLayout->addWidget(CBTeamLvl);
	
	CBGrave = new QComboBox(GBoxTeam);
	CBGrave->setMaxCount(65535);
	CBGrave->setIconSize(QSize(32, 32));
	GBTLayout->addWidget(CBGrave);

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
		GBTLayout->addLayout(hbox);
	}

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
	vbox3->addWidget(GBoxFort);

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

	vbox1->addStretch();
	vbox2->addStretch();
//	vbox3->addStretch();

// ====== Page 2 ======
	GBoxBinds = new QGroupBox(this);
	GBoxBinds->setTitle(QGroupBox::tr("Key binds"));
	QGridLayout * GBBLayout = new QGridLayout(GBoxBinds);
	BindsBox = new QToolBox(GBoxBinds);
	BindsBox->setLineWidth(0);
	GBBLayout->addWidget(BindsBox);
	page_A = new QWidget(this);
	BindsBox->addItem(page_A, QToolBox::tr("Actions"));
	page_W = new QWidget(this);
	BindsBox->addItem(page_W, QToolBox::tr("Weapons"));
	page_WP = new QWidget(this);
	BindsBox->addItem(page_WP, QToolBox::tr("Weapon properties"));
	page_O = new QWidget(this);
	BindsBox->addItem(page_O, QToolBox::tr("Other"));
	page2Layout->addWidget(GBoxBinds, 0, 0);

	QStringList binds;
	for(int i = 0; strlen(sdlkeys[i][1]) > 0; i++)
	{
		binds << sdlkeys[i][1];
	}

	quint16 widind = 0, i = 0;
	while (i < BINDS_NUMBER) {
		quint16 num = 0;
		QWidget * curW = BindsBox->widget(widind);
		QGridLayout * pagelayout = new QGridLayout(curW);
		do {
			LBind[i] = new QLabel(curW);
			LBind[i]->setText(QApplication::translate("binds", cbinds[i].name));
			LBind[i]->setAlignment(Qt::AlignRight);
			pagelayout->addWidget(LBind[i], num, 0);
			CBBind[i] = new QComboBox(curW);
			CBBind[i]->addItems(binds);
			pagelayout->addWidget(CBBind[i], num, 1);
			num++;
		} while (!cbinds[i++].chwidget);
		pagelayout->addWidget(new QWidget(curW), num, 0, 1, 2);
		widind++;
	}
}

void PageEditTeam::CBFort_activated(const QString & fortname)
{
	QPixmap pix(datadir->absolutePath() + "/Forts/" + fortname + "L.png");
	FortPreview->setPixmap(pix);
}

void PageEditTeam::testSound()
{
	QDir tmpdir;
	tmpdir.cd(datadir->absolutePath());
	tmpdir.cd("Sounds/voices");
	tmpdir.cd(CBVoicepack->currentText());
	QStringList list = tmpdir.entryList(QStringList() << "*.wav", QDir::Files);
	if (list.size())
		QSound::play(tmpdir.absolutePath() + "/" + list[rand() % list.size()]);
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
	{
		teamsBox = new IconedGroupBox(this);
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
		
		QHBoxLayout * layout2 = new QHBoxLayout;
		GBTlayout->addLayout(layout2);
		
		labelNN = new QLabel(teamsBox);
		labelNN->setText(QLabel::tr("Net nick"));
		layout2->addWidget(labelNN);

		editNetNick = new QLineEdit(teamsBox);
		editNetNick->setMaxLength(20);
		editNetNick->setText(QLineEdit::tr("unnamed"));
		layout2->addWidget(editNetNick);
		
		gbTBLayout->addWidget(teamsBox, 0, 0);
	}

	{
		IconedGroupBox* groupWeapons = new IconedGroupBox(this);
		groupWeapons->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
		groupWeapons->setIcon(QIcon(":/res/weaponsicon.png"));
		//groupWeapons->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
		groupWeapons->setTitle(QGroupBox::tr("Weapons"));
		QGridLayout * WeaponsLayout = new QGridLayout(groupWeapons);

		WeaponsButt = addButton(tr("Weapons set"), WeaponsLayout, 1, 0);
		WeaponsName = new QComboBox(this);
		WeaponsLayout->addWidget(WeaponsName, 0, 0, 1, 2);
		WeaponEdit = addButton(tr("Edit"), WeaponsLayout, 1, 1);
		gbTBLayout->addWidget(groupWeapons, 1, 0);
	}

	{
		AGGroupBox = new IconedGroupBox(this);
		AGGroupBox->setIcon(QIcon(":/res/graphicsicon.png"));
		AGGroupBox->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
		AGGroupBox->setTitle(QGroupBox::tr("Audio/Graphic options"));

		QVBoxLayout * GBAlayout = new QVBoxLayout(AGGroupBox);
		QHBoxLayout * GBAreslayout = new QHBoxLayout(0);
		QLabel * resolution = new QLabel(AGGroupBox);
		resolution->setText(QLabel::tr("Resolution"));
		GBAreslayout->addWidget(resolution);

		CBResolution = new QComboBox(AGGroupBox);
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

		CBFrontendFullscreen = new QCheckBox(AGGroupBox);
		CBFrontendFullscreen->setText(QCheckBox::tr("Frontend fullscreen"));
		GBAlayout->addWidget(CBFrontendFullscreen);

		CBEnableSound = new QCheckBox(AGGroupBox);
		CBEnableSound->setText(QCheckBox::tr("Enable sound"));
		GBAlayout->addWidget(CBEnableSound);

		CBEnableMusic = new QCheckBox(AGGroupBox);
		CBEnableMusic->setText(QCheckBox::tr("Enable music"));
		GBAlayout->addWidget(CBEnableMusic);

		QHBoxLayout * GBAvollayout = new QHBoxLayout(0);
		QLabel * vol = new QLabel(AGGroupBox);
		vol->setText(QLabel::tr("Initial sound volume"));
		GBAvollayout->addWidget(vol);
		GBAlayout->addLayout(GBAvollayout);
		volumeBox = new QSpinBox(AGGroupBox);
		volumeBox->setRange(0, 100);
		volumeBox->setSingleStep(5);
		GBAvollayout->addWidget(volumeBox);
		

		CBShowFPS = new QCheckBox(AGGroupBox);
		CBShowFPS->setText(QCheckBox::tr("Show FPS"));
		GBAlayout->addWidget(CBShowFPS);

		CBAltDamage = new QCheckBox(AGGroupBox);
		CBAltDamage->setText(QCheckBox::tr("Alternative damage show"));
		GBAlayout->addWidget(CBAltDamage);

		CBNameWithDate = new QCheckBox(AGGroupBox);
		CBNameWithDate->setText(QCheckBox::tr("Append date and time to record file name"));
		GBAlayout->addWidget(CBNameWithDate);

		fpsedit = new FPSEdit(AGGroupBox);
		GBAfpslayout->addWidget(fpsedit);
		gbTBLayout->addWidget(AGGroupBox, 0, 1, 2, 1);
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

	BtnOfficialServer = new QPushButton(ConnGroupBox);
	BtnOfficialServer->setFont(*font14);
	BtnOfficialServer->setText(QPushButton::tr("Join official server"));
	GBClayout->addWidget(BtnOfficialServer, 3, 0, 1, 3);

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
		QMessageBox::information(this, tr("Error"), tr("Please, select server from the list above"));
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

PageNetGame::PageNetGame(QWidget* parent) : AbstractPage(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setSizeConstraint(QLayout::SetMinimumSize);
	//pageLayout->setSpacing(1);
	pageLayout->setColumnStretch(0, 50);
	pageLayout->setColumnStretch(1, 50);

	// chatwidget
	pChatWidget = new HWChatWidget(this);
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
	BtnGo->setFont(*font14);
	BtnGo->setToolTip(QPushButton::tr("Ready"));
	BtnGo->setIcon(QIcon(":/res/lightbulb_off.png"));
	BtnGo->setIconSize(QSize(25, 34));
	BtnGo->setMinimumWidth(50);
	BtnGo->setMinimumHeight(50);
	bottomLayout->addWidget(BtnGo, 2);


	BtnMaster = addButton(tr("Control"), bottomLayout, 3);
	QMenu * menu = new QMenu(BtnMaster);
	startGame = new QAction(QAction::tr("Start"), menu);
	restrictJoins = new QAction(QAction::tr("Restrict Joins"), menu);
	restrictJoins->setCheckable(true);
	restrictTeamAdds = new QAction(QAction::tr("Restrict Team Additions"), menu);
	restrictTeamAdds->setCheckable(true);
	menu->addAction(startGame);
	menu->addAction(restrictJoins);
	menu->addAction(restrictTeamAdds);
	
	BtnMaster->setMenu(menu);

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
}

PageInfo::PageInfo(QWidget* parent) : AbstractPage(parent)
{
	QFont * font14 = new QFont("MS Shell Dlg", 14);
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
	QFont * font14 = new QFont("MS Shell Dlg", 14);
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
	QFont * font14 = new QFont("MS Shell Dlg", 14);
	QGridLayout * pageLayout = new QGridLayout(this);
	pageLayout->setColumnStretch(0, 1);
	pageLayout->setColumnStretch(1, 2);
	pageLayout->setColumnStretch(2, 1);

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
	
	pWeapons = new SelWeaponWidget(cDefaultAmmoStore->size(), this);
	pageLayout->addWidget(pWeapons, 0, 0, 1, 4);

	BtnBack = addButton(":/res/Exit.png", pageLayout, 1, 0, true);
	BtnDefault = addButton(tr("Default"), pageLayout, 1, 1);
	BtnDelete = addButton(tr("Delete"), pageLayout, 1, 2);
	BtnSave = addButton(":/res/Save.png", pageLayout, 1, 3, true);
	BtnSave->setStyleSheet("QPushButton{margin: 12px 0px 12px 0px;}");	
}

PageInGame::PageInGame(QWidget* parent) :
  AbstractPage(parent)
{
	QLabel * label = new QLabel(this);
	label->setText("In game...");
}

PageRoomsList::PageRoomsList(QWidget* parent) :
  AbstractPage(parent)
{
	QGridLayout * pageLayout = new QGridLayout(this);

	roomName = new QLineEdit(this);
	roomName->setMaxLength(60);
	pageLayout->addWidget(roomName, 0, 0);
	
	roomsList = new QTableWidget(this);
	roomsList->setColumnCount(3);
	roomsList->setSelectionBehavior(QAbstractItemView::SelectRows);
	roomsList->verticalHeader()->setVisible(false);
	roomsList->horizontalHeader()->setResizeMode(QHeaderView::Interactive);
	roomsList->horizontalHeader()->setResizeMode(0, QHeaderView::Stretch);
	pageLayout->addWidget(roomsList, 1, 0, 3, 1);
	pageLayout->setRowStretch(2, 100);
	
	chatWidget = new HWChatWidget(this);
	pageLayout->addWidget(chatWidget, 4, 0, 1, 2);
	pageLayout->setRowStretch(4, 350);

	BtnBack = addButton(":/res/Exit.png", pageLayout, 5, 0, true);
	BtnCreate = addButton(tr("Create"), pageLayout, 0, 1);
	BtnJoin = addButton(tr("Join"), pageLayout, 1, 1);
	BtnRefresh = addButton(tr("Refresh"), pageLayout, 3, 1);

	connect(BtnCreate, SIGNAL(clicked()), this, SLOT(onCreateClick()));
	connect(BtnJoin, SIGNAL(clicked()), this, SLOT(onJoinClick()));
	connect(BtnRefresh, SIGNAL(clicked()), this, SLOT(onRefreshClick()));
	connect(roomsList, SIGNAL(doubleClicked (const QModelIndex &)), this, SLOT(onJoinClick()));
}


void PageRoomsList::setRoomsList(const QStringList & list)
{
	roomsList->clear();
	roomsList->setHorizontalHeaderLabels(
			QStringList() <<
			QTableWidget::tr("Room name") <<
			QTableWidget::tr("Players number") <<
			QTableWidget::tr("Round in progress")
			);
	
	if (list.size() % 3)
		return;

	roomsList->setRowCount(list.size() / 3);
	for(int i = 0; i < list.size(); i += 3)
		for(int t = 0; t < 3; t++)
		{
			QTableWidgetItem * item = new QTableWidgetItem(list[i + t]);
			item->setFlags(Qt::ItemIsSelectable);
			roomsList->setItem(i / 3, t, item);
		}
	//roomsList->resizeColumnsToContents();
}

void PageRoomsList::onCreateClick()
{
	if (roomName->text().size())
		emit askForCreateRoom(roomName->text());
	else
		QMessageBox::critical(this,
				tr("Error"),
				tr("Please, enter room name"),
				tr("OK"));
}

void PageRoomsList::onJoinClick()
{
	QTableWidgetItem * curritem = roomsList->item(roomsList->currentRow(), 0);
	if (!curritem)
	{
		QMessageBox::critical(this,
				tr("Error"),
				tr("Please, select room from the list"),
				tr("OK"));
		return ;
	}
	emit askForJoinRoom(curritem->data(Qt::DisplayRole).toString());
}

void PageRoomsList::onRefreshClick()
{
	emit askForRoomList();
}

