/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2009 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QFile>
#include <QTextStream>
#include <QMessageBox>
#include <QPushButton>
#include <QListWidget>
#include <QStackedLayout>
#include <QLineEdit>
#include <QLabel>
#include <QRadioButton>
#include <QSpinBox>
#include <QCloseEvent>
#include <QCheckBox>
#include <QTextBrowser>
#include <QAction>
#include <QTimer>
#include <QScrollBar>

#include "hwform.h"
#include "game.h"
#include "team.h"
#include "teamselect.h"
#include "selectWeapon.h"
#include "gameuiconfig.h"
#include "pages.h"
#include "hwconsts.h"
#include "newnetclient.h"
#include "gamecfgwidget.h"
#include "netserverslist.h"
#include "netudpserver.h"
#include "chatwidget.h"
#include "playrecordpage.h"
#include "input_ip.h"

HWForm::HWForm(QWidget *parent)
  : QMainWindow(parent), pnetserver(0), pRegisterServer(0), editedTeam(0), hwnet(0)
{
	ui.setupUi(this);

	CustomizePalettes();

	ui.pageOptions->CBResolution->addItems(sdli.getResolutions());

	config = new GameUIConfig(this, cfgdir->absolutePath() + "/hedgewars.ini");

	UpdateTeamsLists();
	UpdateWeapons();

	connect(config, SIGNAL(frontendFullscreen(bool)), this, SLOT(onFrontendFullscreen(bool)));
	onFrontendFullscreen(config->isFrontendFullscreen());

	connect(ui.pageMain->BtnSinglePlayer,	SIGNAL(clicked()),	this, SLOT(GoToSinglePlayer()));
	connect(ui.pageMain->BtnSetup,	SIGNAL(clicked()),	this, SLOT(GoToSetup()));
	connect(ui.pageMain->BtnNet,	SIGNAL(clicked()),	this, SLOT(GoToNet()));
	connect(ui.pageMain->BtnInfo,	SIGNAL(clicked()),	this, SLOT(GoToInfo()));
	connect(ui.pageMain->BtnExit, SIGNAL(pressed()), this, SLOT(btnExitPressed()));
	connect(ui.pageMain->BtnExit, SIGNAL(clicked()), this, SLOT(btnExitClicked()));

	connect(ui.pageEditTeam->BtnTeamSave,	SIGNAL(clicked()),	this, SLOT(TeamSave()));
	connect(ui.pageEditTeam->BtnTeamDiscard,	SIGNAL(clicked()),	this, SLOT(TeamDiscard()));

	connect(ui.pageMultiplayer->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageMultiplayer->BtnStartMPGame,	SIGNAL(clicked()),	this, SLOT(StartMPGame()));
	connect(ui.pageMultiplayer->teamsSelect, SIGNAL(setEnabledGameStart(bool)),
		ui.pageMultiplayer->BtnStartMPGame, SLOT(setEnabled(bool)));
	connect(ui.pageMultiplayer->teamsSelect, SIGNAL(SetupClicked()), this, SLOT(IntermediateSetup()));

	connect(ui.pagePlayDemo->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pagePlayDemo->BtnPlayDemo,	SIGNAL(clicked()),	this, SLOT(PlayDemo()));
	connect(ui.pagePlayDemo->DemosList,	SIGNAL(doubleClicked (const QModelIndex &)),	this, SLOT(PlayDemo()));

	connect(ui.pageOptions->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageOptions->BtnNewTeam,	SIGNAL(clicked()),	this, SLOT(NewTeam()));
	connect(ui.pageOptions->BtnEditTeam,	SIGNAL(clicked()),	this, SLOT(EditTeam()));
	connect(ui.pageOptions->BtnSaveOptions,	SIGNAL(clicked()),	config, SLOT(SaveOptions()));
	connect(ui.pageOptions->BtnSaveOptions,	SIGNAL(clicked()),	this, SLOT(GoBack()));

	connect(ui.pageOptions->WeaponEdit, SIGNAL(clicked()), this, SLOT(GoToSelectWeapon()));
	connect(ui.pageOptions->WeaponsButt, SIGNAL(clicked()), this, SLOT(GoToSelectNewWeapon()));
	connect(ui.pageSelectWeapon->pWeapons, SIGNAL(weaponsChanged()), this, SLOT(UpdateWeapons()));

	connect(ui.pageNet->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));
	connect(ui.pageNet->BtnSpecifyServer, SIGNAL(clicked()), this, SLOT(NetConnect()));
	connect(ui.pageNet->BtnOfficialServer, SIGNAL(clicked()), this, SLOT(NetConnectOfficialServer()));
	connect(ui.pageNet->BtnNetSvrStart, SIGNAL(clicked()), this, SLOT(GoToNetServer()));
	connect(ui.pageNet, SIGNAL(connectClicked(const QString &, quint16)), this, SLOT(NetConnectServer(const QString &, quint16)));
	
	connect(ui.pageNetServer->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageNetServer->BtnStart,	SIGNAL(clicked()),	this, SLOT(NetStartServer()));

	connect(ui.pageNetGame->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(setEnabledGameStart(bool)),
		ui.pageNetGame->BtnGo, SLOT(setEnabled(bool)));
	connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(SetupClicked()), this, SLOT(IntermediateSetup()));

	connect(ui.pageRoomsList->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));

	connect(ui.pageInfo->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));

	connect(ui.pageGameStats->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));

	connect(ui.pageSinglePlayer->BtnSimpleGamePage,	SIGNAL(clicked()),	this, SLOT(SimpleGame()));
	connect(ui.pageSinglePlayer->BtnTrainPage,	SIGNAL(clicked()),	this, SLOT(GoToTraining()));
	connect(ui.pageSinglePlayer->BtnMultiplayer,	SIGNAL(clicked()),	this, SLOT(GoToMultiplayer()));
	connect(ui.pageSinglePlayer->BtnLoad,	SIGNAL(clicked()),	this, SLOT(GoToSaves()));
	connect(ui.pageSinglePlayer->BtnDemos,	SIGNAL(clicked()),	this, SLOT(GoToDemos()));
	connect(ui.pageSinglePlayer->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));

	connect(ui.pageTraining->BtnStartTrain,	SIGNAL(clicked()),	this, SLOT(StartTraining()));
	connect(ui.pageTraining->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));

	connect(ui.pageSelectWeapon->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageSelectWeapon->BtnDefault,	SIGNAL(clicked()),	ui.pageSelectWeapon->pWeapons, SLOT(setDefault()));
	connect(ui.pageSelectWeapon->BtnSave,	SIGNAL(clicked()),	ui.pageSelectWeapon->pWeapons, SLOT(save()));

	connect(ui.pageSelectWeapon->BtnDelete,	SIGNAL(clicked()),	
		ui.pageSelectWeapon->pWeapons, SLOT(deleteWeaponsName())); // executed first
	connect(ui.pageSelectWeapon->pWeapons,	SIGNAL(weaponsDeleted()),
		this, SLOT(UpdateWeapons())); // executed second
	connect(ui.pageSelectWeapon->pWeapons,	SIGNAL(weaponsDeleted()),
		this, SLOT(GoBack())); // executed third

	GoToPage(ID_PAGE_MAIN);
}

void HWForm::onFrontendFullscreen(bool value)
{
  if (value)
    setWindowState(windowState() | Qt::WindowFullScreen);
  else {
    setWindowState(windowState() & !Qt::WindowFullScreen);
  }
}

void HWForm::CustomizePalettes()
{
	QList<QScrollBar *> allSBars = findChildren<QScrollBar *>();
	QPalette pal = palette();
	pal.setColor(QPalette::WindowText, QColor(0xff, 0xcc, 0x00));
	pal.setColor(QPalette::Button, QColor(0x00, 0x35, 0x1d));
	pal.setColor(QPalette::Base, QColor(0x00, 0x35, 0x1d));
	pal.setColor(QPalette::Window, QColor(0x00, 0x00, 0x00));

	for (int i = 0; i < allSBars.size(); ++i)
		allSBars.at(i)->setPalette(pal);
}

void HWForm::UpdateWeapons()
{
	QVector<QComboBox*> combos;
	combos.push_back(ui.pageOptions->WeaponsName);
	combos.push_back(ui.pageMultiplayer->gameCFG->WeaponsName);
	combos.push_back(ui.pageNetGame->pGameCFG->WeaponsName);

	QStringList names = ui.pageSelectWeapon->pWeapons->getWeaponNames();

	for(QVector<QComboBox*>::iterator it = combos.begin(); it != combos.end(); ++it) {
		(*it)->clear();

		for(int i = 0; i < names.size(); ++i)
			(*it)->addItem(names[i], ui.pageSelectWeapon->pWeapons->getWeaponsString(names[i]));
		
		int pos = (*it)->findText("Default");
		if (pos != -1) {
			(*it)->setCurrentIndex(pos);
		}
	}
}

void HWForm::UpdateTeamsLists(const QStringList* editable_teams)
{
	QStringList teamslist;
	if(editable_teams) {
	  teamslist =* editable_teams;
	} else {
	  teamslist = config->GetTeamsList();
	}

	if(teamslist.empty()) {
		HWTeam defaultTeam("DefaultTeam");
		defaultTeam.SaveToFile();
		teamslist.push_back("DefaultTeam");
	}

	ui.pageOptions->CBTeamName->clear();
	ui.pageOptions->CBTeamName->addItems(teamslist);
}

void HWForm::GoToMain()
{
	GoToPage(ID_PAGE_MAIN);
}

void HWForm::GoToSinglePlayer()
{
	GoToPage(ID_PAGE_SINGLEPLAYER);
}

void HWForm::GoToTraining()
{
	GoToPage(ID_PAGE_TRAINING);
}

void HWForm::GoToSetup()
{
	GoToPage(ID_PAGE_SETUP);
}

void HWForm::GoToSelectNewWeapon()
{
	ui.pageSelectWeapon->pWeapons->setWeaponsName(tr("new"));
	GoToPage(ID_PAGE_SELECTWEAPON);
}

void HWForm::GoToSelectWeapon()
{
	ui.pageSelectWeapon->pWeapons->setWeaponsName(ui.pageOptions->WeaponsName->currentText());
	GoToPage(ID_PAGE_SELECTWEAPON);
}

void HWForm::GoToInfo()
{
	GoToPage(ID_PAGE_INFO);
}

void HWForm::GoToMultiplayer()
{
	GoToPage(ID_PAGE_MULTIPLAYER);
}

void HWForm::GoToSaves()
{
	ui.pagePlayDemo->FillFromDir(PagePlayDemo::RT_Save);

	GoToPage(ID_PAGE_DEMOS);
}

void HWForm::GoToDemos()
{
	ui.pagePlayDemo->FillFromDir(PagePlayDemo::RT_Demo);

	GoToPage(ID_PAGE_DEMOS);
}

void HWForm::GoToNet()
{
	ui.pageNet->updateServersList();

	GoToPage(ID_PAGE_NET);
}

void HWForm::GoToNetServer()
{
	GoToPage(ID_PAGE_NETSERVER);
}

void HWForm::OnPageShown(quint8 id, quint8 lastid)
{
	if (id == ID_PAGE_MULTIPLAYER || id == ID_PAGE_NETGAME) {
		QStringList tmNames = config->GetTeamsList();
		TeamSelWidget* curTeamSelWidget;
		
		if(id == ID_PAGE_MULTIPLAYER) {
		  curTeamSelWidget = ui.pageMultiplayer->teamsSelect;
		} else {
		  curTeamSelWidget = ui.pageNetGame->pNetTeamsWidget;
		}
		
		QList<HWTeam> teamsList;
		for(QStringList::iterator it = tmNames.begin(); it != tmNames.end(); it++) {
		  HWTeam team(*it);
		  team.LoadFromFile();
		  teamsList.push_back(team);
		}
		
		if(lastid == ID_PAGE_SETUP) { // _TEAM
		  if (editedTeam) {
		    curTeamSelWidget->addTeam(*editedTeam);
		  }
		} else if(lastid != ID_PAGE_GAMESTATS && lastid != ID_PAGE_INGAME) {
		  curTeamSelWidget->resetPlayingTeams(teamsList);
		}
	}
}

void HWForm::GoToPage(quint8 id)
{
	quint8 lastid = ui.Pages->currentIndex();
	PagesStack.push(ui.Pages->currentIndex());
	OnPageShown(id, lastid);
	ui.Pages->setCurrentIndex(id);
}

void HWForm::GoBack()
{
	quint8 id = PagesStack.isEmpty() ? ID_PAGE_MAIN : PagesStack.pop();
	quint8 curid = ui.Pages->currentIndex();
	ui.Pages->setCurrentIndex(id);
	OnPageShown(id, curid);
	
	if (id == ID_PAGE_ROOMSLIST || id == ID_PAGE_NETSERVER) {
		GoBack();
	}
	if (id == ID_PAGE_NET) {
		if(hwnet || pnetserver) NetDisconnect();
	}
}

void HWForm::btnExitPressed()
{
	eggTimer.start();
}

void HWForm::btnExitClicked()
{
	if (eggTimer.elapsed() < 3000)
		close();
	else
	{
		QPushButton * btn = findChild<QPushButton *>("imageButt");
		if (btn)
		{
			btn->setIcon(QIcon(":/res/bonus.png"));
		}
	}
}

void HWForm::IntermediateSetup()
{
	quint8 id=ui.Pages->currentIndex();
	TeamSelWidget* curTeamSelWidget;
	
	if(id == ID_PAGE_MULTIPLAYER) {
		curTeamSelWidget = ui.pageMultiplayer->teamsSelect;
	} else {
		curTeamSelWidget = ui.pageNetGame->pNetTeamsWidget;
	}
	
	QList<HWTeam> teams = curTeamSelWidget->getDontPlayingTeams();
	QStringList tmnames;
	for(QList<HWTeam>::iterator it = teams.begin(); it != teams.end(); ++it) {
		tmnames += it->TeamName;
	}
	UpdateTeamsLists(&tmnames); // FIXME: still need more work if teamname is updated while configuring

	GoToPage(ID_PAGE_SETUP);
}

void HWForm::NewTeam()
{
	editedTeam = new HWTeam("unnamed");
	editedTeam->SetToPage(this);
	GoToPage(ID_PAGE_SETUP_TEAM);
}

void HWForm::EditTeam()
{
	editedTeam = new HWTeam(ui.pageOptions->CBTeamName->currentText());
	editedTeam->LoadFromFile();
	editedTeam->SetToPage(this);
	GoToPage(ID_PAGE_SETUP_TEAM);
}

void HWForm::TeamSave()
{
	editedTeam->GetFromPage(this);
	editedTeam->SaveToFile();
	delete editedTeam;
	editedTeam=0;
	UpdateTeamsLists();
	GoBack();
}

void HWForm::TeamDiscard()
{
	delete editedTeam;
	editedTeam=0;
	GoBack();
}

void HWForm::SimpleGame()
{
	CreateGame(0, 0, *cDefaultAmmoStore);
	game->StartQuick();
}

void HWForm::PlayDemo()
{
	QListWidgetItem * curritem = ui.pagePlayDemo->DemosList->currentItem();
	if (!curritem)
	{
		QMessageBox::critical(this,
				tr("Error"),
				tr("Please, select record from the list above"),
				tr("OK"));
		return ;
	}
	CreateGame(0, 0, 0);
	game->PlayDemo(curritem->data(Qt::UserRole).toString());
}

void HWForm::NetConnectServer(const QString & host, quint16 port)
{
	_NetConnect(host, port, ui.pageOptions->editNetNick->text());
}

void HWForm::NetConnectOfficialServer()
{
	NetConnectServer("netserver.hedgewars.org", 46631);
}

void HWForm::_NetConnect(const QString & hostName, quint16 port, const QString & nick)
{
	if(hwnet) {
		hwnet->Disconnect();
		delete hwnet;
		hwnet=0;
	}
	
	ui.pageNetGame->pChatWidget->clear();
	ui.pageRoomsList->chatWidget->clear();
	
	hwnet = new HWNewNet(config, ui.pageNetGame->pGameCFG, ui.pageNetGame->pNetTeamsWidget);

	connect(hwnet, SIGNAL(showMessage(const QString &)), this, SLOT(ShowErrorMessage(const QString &)), Qt::QueuedConnection);

	connect(hwnet, SIGNAL(AskForRunGame()), this, SLOT(CreateNetGame()));
	connect(hwnet, SIGNAL(Connected()), this, SLOT(NetConnected()));
	connect(hwnet, SIGNAL(EnteredGame()), this, SLOT(NetGameEnter()));
	connect(hwnet, SIGNAL(AddNetTeam(const HWTeam&)), this, SLOT(AddNetTeam(const HWTeam&)));

	connect(hwnet, SIGNAL(roomsList(const QStringList&)),
		ui.pageRoomsList, SLOT(setRoomsList(const QStringList&)));
	connect(hwnet, SIGNAL(serverMessage(const QString&)),
		ui.pageRoomsList->serverMessage, SLOT(setText(const QString&)));
	
	connect(ui.pageRoomsList, SIGNAL(askForCreateRoom(const QString &)),
		hwnet, SLOT(CreateRoom(const QString&)));
	connect(ui.pageRoomsList, SIGNAL(askForJoinRoom(const QString &)),
		hwnet, SLOT(JoinRoom(const QString&)));
	connect(ui.pageRoomsList, SIGNAL(askForCreateRoom(const QString &)),
		this, SLOT(NetGameMaster()));
	connect(ui.pageRoomsList, SIGNAL(askForJoinRoom(const QString &)),
		this, SLOT(NetGameSlave()));
	connect(ui.pageRoomsList, SIGNAL(askForRoomList()),
		hwnet, SLOT(askRoomsList()));

	connect(hwnet, SIGNAL(chatStringFromNet(const QString&)),
		ui.pageNetGame->pChatWidget, SLOT(onChatString(const QString&)));
	connect(hwnet, SIGNAL(setReadyStatus(const QString &, bool)),
		ui.pageNetGame->pChatWidget, SLOT(setReadyStatus(const QString &, bool)));
	connect(hwnet, SIGNAL(chatStringFromMe(const QString&)),
		ui.pageNetGame->pChatWidget, SLOT(onChatString(const QString&)));
	connect(ui.pageNetGame->pChatWidget, SIGNAL(chatLine(const QString&)),
		hwnet, SLOT(chatLineToNet(const QString&)));
	connect(ui.pageNetGame->BtnGo, SIGNAL(clicked()), hwnet, SLOT(ToggleReady()));

	connect(ui.pageNetGame->pChatWidget, SIGNAL(kick(const QString&)),
		hwnet, SLOT(kickPlayer(const QString&)));
	connect(ui.pageNetGame->pChatWidget, SIGNAL(info(const QString&)),
		hwnet, SLOT(infoPlayer(const QString&)));
	connect(ui.pageRoomsList->chatWidget, SIGNAL(info(const QString&)),
		hwnet, SLOT(infoPlayer(const QString&)));

	connect(ui.pageRoomsList->chatWidget, SIGNAL(chatLine(const QString&)),
		hwnet, SLOT(chatLineToLobby(const QString&)));
	connect(hwnet, SIGNAL(chatStringLobby(const QString&)),
		ui.pageRoomsList->chatWidget, SLOT(onChatString(const QString&)));
	connect(hwnet, SIGNAL(chatStringFromMeLobby(const QString&)),
		ui.pageRoomsList->chatWidget, SLOT(onChatString(const QString&)));

	connect(hwnet, SIGNAL(nickAdded(const QString&)),
		ui.pageNetGame->pChatWidget, SLOT(nickAdded(const QString&)));
	connect(hwnet, SIGNAL(nickRemoved(const QString&)),
		ui.pageNetGame->pChatWidget, SLOT(nickRemoved(const QString&)));
	connect(hwnet, SIGNAL(nickAddedLobby(const QString&)),
		ui.pageRoomsList->chatWidget, SLOT(nickAdded(const QString&)));
	connect(hwnet, SIGNAL(nickRemovedLobby(const QString&)),
		ui.pageRoomsList->chatWidget, SLOT(nickRemoved(const QString&)));

	connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(hhogsNumChanged(const HWTeam&)),
		hwnet, SLOT(onHedgehogsNumChanged(const HWTeam&)));
	connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(teamColorChanged(const HWTeam&)),
		hwnet, SLOT(onTeamColorChanged(const HWTeam&)));
	connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(teamWillPlay(HWTeam)), hwnet, SLOT(AddTeam(HWTeam)));
	connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(acceptRequested(HWTeam)), hwnet, SLOT(AddTeam(HWTeam)));
	connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(teamNotPlaying(const HWTeam&)), hwnet, SLOT(RemoveTeam(const HWTeam&)));

	connect(ui.pageNetGame->pGameCFG, SIGNAL(seedChanged(const QString &)), hwnet, SLOT(onSeedChanged(const QString &)));
	connect(ui.pageNetGame->pGameCFG, SIGNAL(mapChanged(const QString &)), hwnet, SLOT(onMapChanged(const QString &)));
	connect(ui.pageNetGame->pGameCFG, SIGNAL(themeChanged(const QString &)), hwnet, SLOT(onThemeChanged(const QString &)));
	connect(ui.pageNetGame->pGameCFG, SIGNAL(initHealthChanged(int)), hwnet, SLOT(onInitHealthChanged(int)));
	connect(ui.pageNetGame->pGameCFG, SIGNAL(turnTimeChanged(int)), hwnet, SLOT(onTurnTimeChanged(int)));
	connect(ui.pageNetGame->pGameCFG, SIGNAL(fortsModeChanged(bool)), hwnet, SLOT(onFortsModeChanged(bool)));
	connect(ui.pageNetGame->pGameCFG, SIGNAL(teamsDivideChanged(bool)), hwnet, SLOT(onTeamsDivideChanged(bool)));
	connect(ui.pageNetGame->pGameCFG, SIGNAL(solidChanged(bool)), hwnet, SLOT(onSolidChanged(bool)));
	connect(ui.pageNetGame->pGameCFG, SIGNAL(newWeaponScheme(const QString &, const QString &)),
			hwnet, SLOT(onWeaponsNameChanged(const QString &, const QString &)));

	connect(hwnet, SIGNAL(Disconnected()), this, SLOT(ForcedDisconnect()));
	connect(hwnet, SIGNAL(seedChanged(const QString &)), ui.pageNetGame->pGameCFG, SLOT(setSeed(const QString &)));
	connect(hwnet, SIGNAL(mapChanged(const QString &)), ui.pageNetGame->pGameCFG, SLOT(setMap(const QString &)));
	connect(hwnet, SIGNAL(themeChanged(const QString &)), ui.pageNetGame->pGameCFG, SLOT(setTheme(const QString &)));
	connect(hwnet, SIGNAL(initHealthChanged(int)), ui.pageNetGame->pGameCFG, SLOT(setInitHealth(int)));
	connect(hwnet, SIGNAL(turnTimeChanged(int)), ui.pageNetGame->pGameCFG, SLOT(setTurnTime(int)));
	connect(hwnet, SIGNAL(fortsModeChanged(bool)), ui.pageNetGame->pGameCFG, SLOT(setFortsMode(bool)));
	connect(hwnet, SIGNAL(teamsDivideChanged(bool)), ui.pageNetGame->pGameCFG, SLOT(setTeamsDivide(bool)));
	connect(hwnet, SIGNAL(solidChanged(bool)), ui.pageNetGame->pGameCFG, SLOT(setSolid(bool)));
	connect(hwnet, SIGNAL(hhnumChanged(const HWTeam&)),
		ui.pageNetGame->pNetTeamsWidget, SLOT(changeHHNum(const HWTeam&)));
	connect(hwnet, SIGNAL(teamColorChanged(const HWTeam&)),
		ui.pageNetGame->pNetTeamsWidget, SLOT(changeTeamColor(const HWTeam&)));
	connect(hwnet, SIGNAL(ammoChanged(const QString&, const QString&)), ui.pageNetGame->pGameCFG, SLOT(setNetAmmo(const QString&, const QString&)));

	hwnet->Connect(hostName, port, nick);
}

void HWForm::NetConnect()
{
	HWHostPortDialog * hpd = new HWHostPortDialog(this);
	hpd->leHost->setText(*netHost);
	hpd->sbPort->setValue(netPort);

	if (hpd->exec() == QDialog::Accepted)
	{
		config->SaveOptions();
		delete netHost;
		netHost = new QString(hpd->leHost->text());
		netPort = hpd->sbPort->value();
		NetConnectServer(*netHost, netPort);
	}
}

void HWForm::NetStartServer()
{
	config->SaveOptions();

	pnetserver = new HWNetServer;
	if(!pnetserver->StartServer(ui.pageNetServer->sbPort->value()))
	{
		QMessageBox::critical(0, tr("Error"),
				tr("Unable to start the server"));
		delete pnetserver;
		pnetserver = 0;
		return;
	}

	QTimer::singleShot(250, this, SLOT(AsyncNetServerStart()));

	pRegisterServer = new HWNetUdpServer(0,
			ui.pageNetServer->leServerDescr->text(),
			ui.pageNetServer->sbPort->value());
}

void HWForm::AsyncNetServerStart()
{
	NetConnectServer("localhost", pnetserver->getRunningPort());
}

void HWForm::NetDisconnect()
{
	if(hwnet) {
		hwnet->Disconnect();
		delete hwnet;
		hwnet = 0;
	}
	if(pnetserver) {
		if (pRegisterServer)
		{
			pRegisterServer->unregister();
			pRegisterServer = 0;
		}

		pnetserver->StopServer();
		delete pnetserver;
		pnetserver = 0;
	}
}

void HWForm::ForcedDisconnect()
{
	if(pnetserver) return; // we have server - let it care of all things
	if (hwnet) {
		hwnet->deleteLater();
		hwnet = 0;
		QMessageBox::warning(this, QMessageBox::tr("Network"),
				QMessageBox::tr("Connection to server is lost"));
	}
	GoBack();
}

void HWForm::NetConnected()
{
	GoToPage(ID_PAGE_ROOMSLIST);
}

void HWForm::NetGameEnter()
{
	GoToPage(ID_PAGE_NETGAME);
}

void HWForm::AddNetTeam(const HWTeam& team)
{
	ui.pageNetGame->pNetTeamsWidget->addTeam(team);
}

void HWForm::StartMPGame()
{
	QString ammo;
	ammo = ui.pageMultiplayer->gameCFG->WeaponsName->itemData(
		ui.pageMultiplayer->gameCFG->WeaponsName->currentIndex()
		).toString();

	CreateGame(ui.pageMultiplayer->gameCFG, ui.pageMultiplayer->teamsSelect, ammo);

	game->StartLocal();
}

void HWForm::GameStateChanged(GameState gameState)
{
	switch(gameState) {
		case gsStarted: {
			Music(false);
			GoToPage(ID_PAGE_INGAME);
			ui.pageGameStats->labelGameStats->setText("");
			if (pRegisterServer)
			{
				pRegisterServer->unregister();
				pRegisterServer = 0;
			}
			break;
		}
		case gsFinished: {
			GoBack();
			Music(ui.pageOptions->CBEnableMusic->isChecked());
			GoToPage(ID_PAGE_GAMESTATS);
			if (hwnet) hwnet->gameFinished();
			break;
		}
		default: {
			quint8 id = ui.Pages->currentIndex();
			if (id == ID_PAGE_INGAME) {
				GoBack();
				Music(ui.pageOptions->CBEnableMusic->isChecked());
				if (hwnet) hwnet->gameFinished();
			}
		};
	}
}

void HWForm::AddStatText(const QString & msg)
{
	ui.pageGameStats->labelGameStats->setText(
		ui.pageGameStats->labelGameStats->text() + msg);
}

void HWForm::GameStats(char type, const QString & info)
{
	switch(type) {
		case 'r' : {
			AddStatText(QString("<h1 align=\"center\">%1</h1>").arg(info));
			break;
		}
		case 'D' : {
			int i = info.indexOf(' ');
			QString message = QLabel::tr("<p>The best shot award was won by <b>%1</b> with <b>%2</b> pts.</p>")
					.arg(info.mid(i + 1), info.left(i));
			AddStatText(message);
			break;
		}
		case 'k' : {
			int i = info.indexOf(' ');
			QString message = QLabel::tr("<p>The best shot award was won by <b>%1</b> with <b>%2</b> kills.</p>")
					.arg(info.mid(i + 1), info.left(i));
			AddStatText(message);
			break;
		}
		case 'K' : {
			QString message = QLabel::tr("<p>A total of <b>%1</b> Hedgehog(s) were killed during this round.</p>").arg(info);
			AddStatText(message);
			break;
		}
	}
}

void HWForm::CreateGame(GameCFGWidget * gamecfg, TeamSelWidget* pTeamSelWidget, QString ammo)
{
	game = new HWGame(config, gamecfg, ammo, pTeamSelWidget);
	connect(game, SIGNAL(GameStateChanged(GameState)), this, SLOT(GameStateChanged(GameState)));
	connect(game, SIGNAL(GameStats(char, const QString &)), this, SLOT(GameStats(char, const QString &)));
	connect(game, SIGNAL(ErrorMessage(const QString &)), this, SLOT(ShowErrorMessage(const QString &)), Qt::QueuedConnection);
	connect(game, SIGNAL(HaveRecord(bool, const QByteArray &)), this, SLOT(GetRecord(bool, const QByteArray &)));
}

void HWForm::ShowErrorMessage(const QString & msg)
{
	QMessageBox::warning(this,
			"Hedgewars",
			msg);
}

void HWForm::GetRecord(bool isDemo, const QByteArray & record)
{
	QString filename;
	QByteArray demo = record;
	QString recordFileName =
			config->appendDateTimeToRecordName() ?
				QDateTime::currentDateTime().toString(Qt::ISODate) :
				"LastRound";

	if (isDemo)
	{
		demo.replace(QByteArray("\x02TL"), QByteArray("\x02TD"));
		demo.replace(QByteArray("\x02TN"), QByteArray("\x02TD"));
		demo.replace(QByteArray("\x02TS"), QByteArray("\x02TD"));
		filename = cfgdir->absolutePath() + "/Demos/" + recordFileName + ".hwd_" + *cProtoVer;
	} else
	{
		demo.replace(QByteArray("\x02TL"), QByteArray("\x02TS"));
		demo.replace(QByteArray("\x02TN"), QByteArray("\x02TS"));
		filename = cfgdir->absolutePath() + "/Saves/" + recordFileName + ".hws_" + *cProtoVer;
	}


	QFile demofile(filename);
	if (!demofile.open(QIODevice::WriteOnly))
	{
		ShowErrorMessage(tr("Cannot save record to file %1").arg(filename));
		return ;
	}
	demofile.write(demo.constData(), demo.size());
	demofile.close();
}

void HWForm::StartTraining()
{
	CreateGame(0, 0, 0);

	game->StartTraining();
}

void HWForm::CreateNetGame()
{
	QString ammo;
	ammo = ui.pageNetGame->pGameCFG->WeaponsName->itemData(
			ui.pageNetGame->pGameCFG->WeaponsName->currentIndex()
			).toString();

	CreateGame(ui.pageNetGame->pGameCFG, ui.pageNetGame->pNetTeamsWidget, ammo);

	connect(game, SIGNAL(SendNet(const QByteArray &)), hwnet, SLOT(SendNet(const QByteArray &)));
	connect(game, SIGNAL(SendChat(const QString &)), hwnet, SLOT(chatLineToNet(const QString &)));
	connect(hwnet, SIGNAL(FromNet(const QByteArray &)), game, SLOT(FromNet(const QByteArray &)));
	connect(hwnet, SIGNAL(chatStringFromNet(const QString &)), game, SLOT(FromNetChat(const QString &)));

	game->StartNet();
}

void HWForm::closeEvent(QCloseEvent *event)
{
	config->SaveOptions();
	event->accept();
}

void HWForm::Music(bool checked)
{
	if (checked)
		sdli.StartMusic();
	else
		sdli.StopMusic();
}

void HWForm::NetGameMaster()
{
	ui.pageNetGame->BtnMaster->setVisible(true);
	ui.pageNetGame->restrictJoins->setChecked(false);
	ui.pageNetGame->restrictTeamAdds->setChecked(false);
	
	if (hwnet)
	{
		connect(ui.pageNetGame->startGame, SIGNAL(triggered()), hwnet, SLOT(startGame()));
		connect(ui.pageNetGame->restrictJoins, SIGNAL(triggered()), hwnet, SLOT(toggleRestrictJoins()));
		connect(ui.pageNetGame->restrictTeamAdds, SIGNAL(triggered()), hwnet, SLOT(toggleRestrictTeamAdds()));
	}
}

void HWForm::NetGameSlave()
{
	ui.pageNetGame->BtnMaster->setVisible(false);
}
