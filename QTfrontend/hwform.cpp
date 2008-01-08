/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005-2007 Andrey Korotaev <unC0Rr@gmail.com>
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
#include "netwwwserver.h"
#include "chatwidget.h"
#include "playrecordpage.h"
#include "input_ip.h"

HWForm::HWForm(QWidget *parent)
  : QMainWindow(parent), pnetserver(0), pRegisterServer(0), editedTeam(0), hwnet(0)
{
	ui.setupUi(this);
	config = new GameUIConfig(this, cfgdir->absolutePath() + "/hedgewars.ini");

	UpdateTeamsLists();

	connect(ui.pageMain->BtnSinglePlayer,	SIGNAL(clicked()),	this, SLOT(GoToSinglePlayer()));
	connect(ui.pageMain->BtnSetup,	SIGNAL(clicked()),	this, SLOT(GoToSetup()));
	connect(ui.pageMain->BtnMultiplayer,	SIGNAL(clicked()),	this, SLOT(GoToMultiplayer()));
	connect(ui.pageMain->BtnLoad,	SIGNAL(clicked()),	this, SLOT(GoToSaves()));
	connect(ui.pageMain->BtnDemos,	SIGNAL(clicked()),	this, SLOT(GoToDemos()));
	connect(ui.pageMain->BtnNet,	SIGNAL(clicked()),	this, SLOT(GoToNet()));
	connect(ui.pageMain->BtnInfo,	SIGNAL(clicked()),	this, SLOT(GoToInfo()));
	connect(ui.pageMain->BtnExit, SIGNAL(pressed()), this, SLOT(btnExitPressed()));
	connect(ui.pageMain->BtnExit, SIGNAL(clicked()), this, SLOT(btnExitClicked()));

	connect(ui.pageSimpleGame->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageSimpleGame->BtnSimpleGame,	SIGNAL(clicked()),	this, SLOT(SimpleGame()));

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
	connect(ui.pageOptions->WeaponEdit,	SIGNAL(clicked()),	this, SLOT(GoToSelectWeapon()));
	connect(ui.pageOptions->WeaponsButt,	SIGNAL(clicked()),	this, SLOT(GoToSelectNewWeapon()));

	connect(ui.pageNet->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageNet->BtnSpecifyServer,	SIGNAL(clicked()),	this, SLOT(NetConnect()));
	connect(ui.pageNet->BtnNetSvrStart,	SIGNAL(clicked()),	this, SLOT(GoToNetServer()));
	connect(ui.pageNet,	SIGNAL(connectClicked(const QString &, quint16)),	this, SLOT(NetConnectServer(const QString &, quint16)));
	
	connect(ui.pageNetServer->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageNetServer->BtnStart,	SIGNAL(clicked()),	this, SLOT(NetStartServer()));

	connect(ui.pageNetGame->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageNetGame->BtnGo,	SIGNAL(clicked()),	this, SLOT(NetStartGame()));
	connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(setEnabledGameStart(bool)),
		ui.pageNetGame->BtnGo, SLOT(setEnabled(bool)));
	connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(SetupClicked()), this, SLOT(IntermediateSetup()));

	connect(ui.pageInfo->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));

	connect(ui.pageGameStats->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));

	connect(ui.pageSinglePlayer->BtnSimpleGamePage,	SIGNAL(clicked()),	this, SLOT(GoToSimpleGame()));
	connect(ui.pageSinglePlayer->BtnTrainPage,	SIGNAL(clicked()),	this, SLOT(GoToTraining()));
	connect(ui.pageSinglePlayer->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));

	connect(ui.pageTraining->BtnStartTrain,	SIGNAL(clicked()),	this, SLOT(StartTraining()));
	connect(ui.pageTraining->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));

	connect(ui.pageSelectWeapon->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageSelectWeapon->BtnDefault,	SIGNAL(clicked()),	ui.pageSelectWeapon->pWeapons, SLOT(setDefault()));
	connect(ui.pageSelectWeapon->BtnSave,	SIGNAL(clicked()),	ui.pageSelectWeapon->pWeapons, SLOT(save()));

	GoToPage(ID_PAGE_MAIN);
}

void HWForm::UpdateTeamsLists(const QStringList* editable_teams)
{
	QStringList teamslist;
	if(editable_teams) {
	  teamslist=*editable_teams;
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

	// now updates weapons also
	ui.pageOptions->WeaponsName->clear();
	ui.pageOptions->WeaponsName->addItems(ui.pageSelectWeapon->pWeapons->getWeaponNames());
}

void HWForm::GoToMain()
{
	GoToPage(ID_PAGE_MAIN);
}

void HWForm::GoToSinglePlayer()
{
	GoToPage(ID_PAGE_SINGLEPLAYER);
}

void HWForm::GoToSimpleGame()
{
	GoToPage(ID_PAGE_SIMPLEGAME);
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
	ui.pageSelectWeapon->pWeapons->setWeaponsName("");
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
	if (id == ID_PAGE_MULTIPLAYER || id == ID_PAGE_NETCFG) {
		QStringList tmNames=config->GetTeamsList();
		TeamSelWidget* curTeamSelWidget;
		if(id == ID_PAGE_MULTIPLAYER) {
		  curTeamSelWidget=ui.pageMultiplayer->teamsSelect;
		} else {
		  curTeamSelWidget=ui.pageNetGame->pNetTeamsWidget;
		}
		QList<HWTeam> teamsList;
		for(QStringList::iterator it=tmNames.begin(); it!=tmNames.end(); it++) {
		  HWTeam team(*it);
		  team.LoadFromFile();
		  teamsList.push_back(team);
		}
		if(lastid==ID_PAGE_SETUP) { // _TEAM
		  if (editedTeam) {
		    curTeamSelWidget->addTeam(*editedTeam);
		  }
		} else {
		  curTeamSelWidget->resetPlayingTeams(teamsList);
		}
	}
}

void HWForm::GoToPage(quint8 id)
{
	quint8 lastid=ui.Pages->currentIndex();
	PagesStack.push(ui.Pages->currentIndex());
	OnPageShown(id, lastid);
	ui.Pages->setCurrentIndex(id);
}

void HWForm::GoBack()
{
	if (!PagesStack.isEmpty() && PagesStack.top() == ID_PAGE_NET) {
	  if(hwnet || pnetserver) NetDisconnect();
	}
	quint8 id = PagesStack.isEmpty() ? ID_PAGE_MAIN : PagesStack.pop();
	OnPageShown(id, ui.Pages->currentIndex());
	ui.Pages->setCurrentIndex(id);
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
    curTeamSelWidget=ui.pageMultiplayer->teamsSelect;
  } else {
    curTeamSelWidget=ui.pageNetGame->pNetTeamsWidget;
  }
  QList<HWTeam> teams=curTeamSelWidget->getDontPlayingTeams();
  QStringList tmnames;
  for(QList<HWTeam>::iterator it = teams.begin(); it != teams.end(); ++it) {
    tmnames+=it->TeamName;
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
	CreateGame(ui.pageSimpleGame->gameCFG, 0);
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
	CreateGame(0, 0);
	game->PlayDemo(curritem->data(Qt::UserRole).toString());
}

void HWForm::NetConnectServer(const QString & host, quint16 port)
{
  _NetConnect(host, port, ui.pageOptions->editNetNick->text());
}

void HWForm::_NetConnect(const QString & hostName, quint16 port, const QString & nick)
{
	if(hwnet) {
		hwnet->Disconnect();
		delete hwnet;
		hwnet=0;
	}
	ui.pageNetGame->pChatWidget->clear();
	hwnet = new HWNewNet(config, ui.pageNetGame->pGameCFG, ui.pageNetGame->pNetTeamsWidget);

	connect(hwnet, SIGNAL(AskForRunGame()), this, SLOT(CreateNetGame()));
	connect(hwnet, SIGNAL(EnteredGame()), this, SLOT(NetGameEnter()));
	connect(hwnet, SIGNAL(AddNetTeam(const HWTeam&)), this, SLOT(AddNetTeam(const HWTeam&)));

	connect(hwnet, SIGNAL(chatStringFromNet(const QStringList&)),
		ui.pageNetGame->pChatWidget, SLOT(onChatStringFromNet(const QStringList&)));
	connect(ui.pageNetGame->pChatWidget, SIGNAL(chatLine(const QString&)),
		hwnet, SLOT(chatLineToNet(const QString&)));
	connect(hwnet, SIGNAL(nickAdded(const QString&)),
		ui.pageNetGame->pChatWidget, SLOT(nickAdded(const QString&)));
	connect(hwnet, SIGNAL(nickRemoved(const QString&)),
		ui.pageNetGame->pChatWidget, SLOT(nickRemoved(const QString&)));

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
	connect(ui.pageNetGame->pGameCFG, SIGNAL(initHealthChanged(quint32)), hwnet, SLOT(onInitHealthChanged(quint32)));
	connect(ui.pageNetGame->pGameCFG, SIGNAL(turnTimeChanged(quint32)), hwnet, SLOT(onTurnTimeChanged(quint32)));
	connect(ui.pageNetGame->pGameCFG, SIGNAL(fortsModeChanged(bool)), hwnet, SLOT(onFortsModeChanged(bool)));

	connect(hwnet, SIGNAL(Disconnected()), this, SLOT(ForcedDisconnect()));
	connect(hwnet, SIGNAL(seedChanged(const QString &)), ui.pageNetGame->pGameCFG, SLOT(setSeed(const QString &)));
	connect(hwnet, SIGNAL(mapChanged(const QString &)), ui.pageNetGame->pGameCFG, SLOT(setMap(const QString &)));
	connect(hwnet, SIGNAL(themeChanged(const QString &)), ui.pageNetGame->pGameCFG, SLOT(setTheme(const QString &)));
	connect(hwnet, SIGNAL(initHealthChanged(quint32)), ui.pageNetGame->pGameCFG, SLOT(setInitHealth(quint32)));
	connect(hwnet, SIGNAL(turnTimeChanged(quint32)), ui.pageNetGame->pGameCFG, SLOT(setTurnTime(quint32)));
	connect(hwnet, SIGNAL(fortsModeChanged(bool)), ui.pageNetGame->pGameCFG, SLOT(setFortsMode(bool)));
	connect(hwnet, SIGNAL(hhnumChanged(const HWTeam&)),
		ui.pageNetGame->pNetTeamsWidget, SLOT(changeHHNum(const HWTeam&)));
	connect(hwnet, SIGNAL(teamColorChanged(const HWTeam&)),
		ui.pageNetGame->pNetTeamsWidget, SLOT(changeTeamColor(const HWTeam&)));

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
		_NetConnect(*netHost, netPort, ui.pageOptions->editNetNick->text());
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

	_NetConnect("localhost", pnetserver->getRunningPort(), ui.pageOptions->editNetNick->text());

	if (ui.pageNet->rbLocalGame->isChecked())
		pRegisterServer = new HWNetUdpServer(0, ui.pageNetServer->leServerDescr->text(), ui.pageNetServer->sbPort->value());
	else
		pRegisterServer = new HWNetWwwServer(0, ui.pageNetServer->leServerDescr->text(), ui.pageNetServer->sbPort->value());
}

void HWForm::NetDisconnect()
{
  if(hwnet) {
    hwnet->Disconnect();
    delete hwnet;
    hwnet=0;
  }
  if(pnetserver) {
    if (pRegisterServer)
    {
      pRegisterServer->unregister();
      pRegisterServer = 0;
    }

    pnetserver->StopServer();
    delete pnetserver;
    pnetserver=0;
  }
}

void HWForm::ForcedDisconnect()
{
  if(pnetserver) return; // we have server - let it care of all things
  if (hwnet) {
    hwnet->deleteLater();
    hwnet=0;
    QMessageBox::warning(this, QMessageBox::tr("Network"),
			 QMessageBox::tr("Connection to server is lost"));
  }
  GoBack();
}

void HWForm::NetGameEnter()
{
	GoToPage(ID_PAGE_NETCFG);
}

void HWForm::NetStartGame()
{
  ui.pageNetGame->BtnGo->setText(QPushButton::tr("Waiting"));
  ui.pageNetGame->BtnGo->setEnabled(false);
  hwnet->StartGame();
}

void HWForm::AddNetTeam(const HWTeam& team)
{
  ui.pageNetGame->pNetTeamsWidget->addTeam(team);
}

void HWForm::StartMPGame()
{
	CreateGame(ui.pageMultiplayer->gameCFG, ui.pageMultiplayer->teamsSelect);

	game->StartLocal();
}

void HWForm::GameStateChanged(GameState gameState)
{
	switch(gameState) {
		case gsStarted: {
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
			GoToPage(ID_PAGE_GAMESTATS);
			break;
		}
		default: {
			quint8 id = ui.Pages->currentIndex();
			if (id == ID_PAGE_INGAME) GoBack();
		};
	}

	if (hwnet)
	{
		ui.pageNetGame->BtnGo->setText(QPushButton::tr("Go!"));
		ui.pageNetGame->BtnGo->setEnabled(true);
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
		case 'K' : {
			QString message = QLabel::tr("<p>A total of <b>%1</b> Hedgehog(s) were killed during this round.</p>").arg(info);
			AddStatText(message);
			break;
		}
	}
}

void HWForm::CreateGame(GameCFGWidget * gamecfg, TeamSelWidget* pTeamSelWidget)
{
	game = new HWGame(config, gamecfg, ui.pageSelectWeapon->pWeapons->getWeaponsString(), pTeamSelWidget);
	connect(game, SIGNAL(GameStateChanged(GameState)), this, SLOT(GameStateChanged(GameState)));
	connect(game, SIGNAL(GameStats(char, const QString &)), this, SLOT(GameStats(char, const QString &)));
	connect(game, SIGNAL(ErrorMessage(const QString &)), this, SLOT(ShowErrorMessage(const QString &)), Qt::QueuedConnection);
	connect(game, SIGNAL(HaveRecord(bool, const QByteArray &)), this, SLOT(GetRecord(bool, const QByteArray &)));

	GoToPage(ID_PAGE_INGAME);
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
	if (isDemo)
	{
		demo.replace(QByteArray("\x02TL"), QByteArray("\x02TD"));
		demo.replace(QByteArray("\x02TN"), QByteArray("\x02TD"));
		filename = cfgdir->absolutePath() + "/Demos/LastRound.hwd_" + *cProtoVer;
	} else
	{
		demo.replace(QByteArray("\x02TL"), QByteArray("\x02TS"));
		demo.replace(QByteArray("\x02TN"), QByteArray("\x02TS"));
		filename = cfgdir->absolutePath() + "/Saves/LastRound.hws_" + *cProtoVer;
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
	CreateGame(0, 0);

	game->StartTraining();
}

void HWForm::CreateNetGame()
{
	CreateGame(ui.pageNetGame->pGameCFG, ui.pageNetGame->pNetTeamsWidget);

	connect(game, SIGNAL(SendNet(const QByteArray &)), hwnet, SLOT(SendNet(const QByteArray &)));
	connect(hwnet, SIGNAL(FromNet(const QByteArray &)), game, SLOT(FromNet(const QByteArray &)));

	game->StartNet();
}

void HWForm::closeEvent(QCloseEvent *event)
{
	config->SaveOptions();
	event->accept();
}
