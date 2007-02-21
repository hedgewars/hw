/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QtGui>
#include <QStringList>
#include <QProcess>
#include <QDir>
#include <QPixmap>
#include <QRegExp>
#include <QIcon>
#include <QFile>
#include <QTextStream>
#include <QMessageBox>

#include "hwform.h"
#include "game.h"
#include "team.h"
#include "teamselect.h"
#include "gameuiconfig.h"
#include "pages.h"
#include "hwconsts.h"
#include "newnetclient.h"
#include "gamecfgwidget.h"
#include "netudpserver.h"
#include "netudpwidget.h"
#include "chatwidget.h"

HWForm::HWForm(QWidget *parent)
  : QMainWindow(parent), pnetserver(0), pUdpServer(0)
{
	ui.setupUi(this);

	config = new GameUIConfig(this, cfgdir->absolutePath() + "/hedgewars.ini");

	UpdateTeamsLists();

	connect(ui.pageMain->BtnSinglePlayer,	SIGNAL(clicked()),	this, SLOT(GoToSinglePlayer()));
	connect(ui.pageMain->BtnSetup,	SIGNAL(clicked()),	this, SLOT(GoToSetup()));
	connect(ui.pageMain->BtnMultiplayer,	SIGNAL(clicked()),	this, SLOT(GoToMultiplayer()));
	connect(ui.pageMain->BtnDemos,	SIGNAL(clicked()),	this, SLOT(GoToDemos()));
	connect(ui.pageMain->BtnNet,	SIGNAL(clicked()),	this, SLOT(GoToNet()));
	connect(ui.pageMain->BtnInfo,	SIGNAL(clicked()),	this, SLOT(GoToInfo()));
	connect(ui.pageMain->BtnExit, SIGNAL(clicked()), this, SLOT(close()));

	connect(ui.pageLocalGame->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageLocalGame->BtnSimpleGame,	SIGNAL(clicked()),	this, SLOT(SimpleGame()));

	connect(ui.pageEditTeam->BtnTeamSave,	SIGNAL(clicked()),	this, SLOT(TeamSave()));
	connect(ui.pageEditTeam->BtnTeamDiscard,	SIGNAL(clicked()),	this, SLOT(TeamDiscard()));

	connect(ui.pageMultiplayer->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageMultiplayer->BtnStartMPGame,	SIGNAL(clicked()),	this, SLOT(StartMPGame()));

	connect(ui.pagePlayDemo->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pagePlayDemo->BtnPlayDemo,	SIGNAL(clicked()),	this, SLOT(PlayDemo()));
	connect(ui.pagePlayDemo->DemosList,	SIGNAL(doubleClicked (const QModelIndex &)),	this, SLOT(PlayDemo()));

	connect(ui.pageOptions->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageOptions->BtnNewTeam,	SIGNAL(clicked()),	this, SLOT(NewTeam()));
	connect(ui.pageOptions->BtnEditTeam,	SIGNAL(clicked()),	this, SLOT(EditTeam()));
	connect(ui.pageOptions->BtnSaveOptions,	SIGNAL(clicked()),	config, SLOT(SaveOptions()));
	connect(ui.pageOptions->BtnSaveOptions,	SIGNAL(clicked()),	this, SLOT(GoBack()));

	connect(ui.pageNet->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageNet->BtnNetConnect,	SIGNAL(clicked()),	this, SLOT(NetConnect()));
	connect(ui.pageNet->BtnNetSvrStart, SIGNAL(clicked()), this, SLOT(NetStartServer()));
	connect(ui.pageMain->BtnNet,	SIGNAL(clicked()), ui.pageNet->pUdpClient, SLOT(updateList()));
	connect(ui.pageNet->pUpdateUdpButt, SIGNAL(clicked()), ui.pageNet->pUdpClient, SLOT(updateList()));
	connect(ui.pageNet->pUdpClient->serversList,	SIGNAL(doubleClicked (const QModelIndex &)),	this, SLOT(NetConnectServer()));

	connect(ui.pageNetGame->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageNetGame->BtnGo,	SIGNAL(clicked()),	this, SLOT(NetStartGame()));

	connect(ui.pageInfo->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));

	connect(ui.pageGameStats->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));

	connect(ui.pageMultiplayer->teamsSelect, SIGNAL(NewTeam()), this, SLOT(NewTeam()));

	GoToPage(ID_PAGE_MAIN);
}

void HWForm::UpdateTeamsLists()
{
	QStringList teamslist = config->GetTeamsList();

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

void HWForm::GoToSetup()
{
	GoToPage(ID_PAGE_SETUP);
}

void HWForm::GoToInfo()
{
	GoToPage(ID_PAGE_INFO);
}

void HWForm::GoToMultiplayer()
{
	GoToPage(ID_PAGE_MULTIPLAYER);
}

void HWForm::GoToDemos()
{
	QDir tmpdir;
	tmpdir.cd(cfgdir->absolutePath());
	tmpdir.cd("Demos");
	tmpdir.setFilter(QDir::Files);
	ui.pagePlayDemo->DemosList->clear();
	ui.pagePlayDemo->DemosList->addItems(tmpdir.entryList(QStringList("*.hwd_" + cProtoVer))
			.replaceInStrings(QRegExp("^(.*).hwd_" + cProtoVer), "\\1"));
	GoToPage(ID_PAGE_DEMOS);
}

void HWForm::GoToNet()
{
	GoToPage(ID_PAGE_NET);
}

void HWForm::OnPageShown(quint8 id)
{
	if (id == ID_PAGE_MULTIPLAYER || id == ID_PAGE_NETCFG) {
		QStringList tmNames=config->GetTeamsList();
		TeamSelWidget* curTeamSelWidget;
		id == ID_PAGE_MULTIPLAYER ? curTeamSelWidget=ui.pageMultiplayer->teamsSelect :
		  curTeamSelWidget=ui.pageNetGame->pNetTeamsWidget;
		QList<HWTeam> teamsList;
		for(QStringList::iterator it=tmNames.begin(); it!=tmNames.end(); it++) {
		  HWTeam team(*it);
		  team.LoadFromFile();
		  teamsList.push_back(team);
		}
		curTeamSelWidget->resetPlayingTeams(teamsList);
	}
}

void HWForm::GoToPage(quint8 id)
{
	PagesStack.push(ui.Pages->currentIndex());
	OnPageShown(id);
	ui.Pages->setCurrentIndex(id);
}

void HWForm::GoBack()
{
	if (!PagesStack.isEmpty() && PagesStack.top() == ID_PAGE_NET) {
	  if(hwnet || pnetserver) NetDisconnect();
	}
	quint8 id = PagesStack.isEmpty() ? ID_PAGE_MAIN : PagesStack.pop();
	OnPageShown(id);
	ui.Pages->setCurrentIndex(id);
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
	UpdateTeamsLists();
	GoBack();
}

void HWForm::TeamDiscard()
{
	delete editedTeam;
	GoBack();
}

void HWForm::SimpleGame()
{
	CreateGame(ui.pageLocalGame->gameCFG, 0);
	game->StartQuick();
}

void HWForm::PlayDemo()
{
	QListWidgetItem * curritem = ui.pagePlayDemo->DemosList->currentItem();
	if (!curritem)
	{
		QMessageBox::critical(this,
				tr("Error"),
				tr("Please, select demo from the list above"),
				tr("OK"));
		return ;
	}
	CreateGame(0, 0);
	game->PlayDemo(cfgdir->absolutePath() + "/Demos/" + curritem->text() + ".hwd_" + cProtoVer);
}

void HWForm::NetConnectServer()
{
  QListWidgetItem * curritem = ui.pageNet->pUdpClient->serversList->currentItem();
  if (!curritem) {
    QMessageBox::critical(this,
			  tr("Error"),
			  tr("Please, select server from the list above"),
			  tr("OK"));
    return ;
  }
  _NetConnect(curritem->text(), 46631, ui.pageNet->editNetNick->text());
}

void HWForm::_NetConnect(const QString & hostName, quint16 port, const QString & nick)
{
	ui.pageNetGame->pChatWidget->clear();
	hwnet = new HWNewNet(config, ui.pageNetGame->pGameCFG, ui.pageNetGame->pNetTeamsWidget);
	connect(hwnet, SIGNAL(GameStateChanged(GameState)), this, SLOT(NetGameStateChanged(GameState)));
	connect(hwnet, SIGNAL(AddGame(const QString &)), this, SLOT(AddGame(const QString &)));
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
	config->SaveOptions();
}

void HWForm::NetConnect()
{
  _NetConnect(ui.pageNet->editIP->text(), 46631, ui.pageNet->editNetNick->text());
}

void HWForm::NetStartServer()
{
  pnetserver = new HWNetServer;
  pnetserver->StartServer();
  _NetConnect("localhost", pnetserver->getRunningPort(), ui.pageNet->editNetNick->text());
  pUdpServer = new HWNetUdpServer();
}

void HWForm::NetDisconnect()
{
  if(hwnet) {
    hwnet->Disconnect();
    delete hwnet;
    hwnet=0;
  }
  if(pnetserver) {
    pUdpServer->deleteLater();
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

void HWForm::NetGameStateChanged(GameState __attribute__((unused)) gameState)
{
  ui.pageNetGame->BtnGo->setText(QPushButton::tr("Go!"));
  ui.pageNetGame->BtnGo->setEnabled(true);
}

void HWForm::GameStateChanged(GameState gameState)
{
	switch(gameState) {
		case gsStarted: {
			ui.pageGameStats->labelGameStats->setText("");
			break;
		}
		case gsFinished: {
			GoToPage(ID_PAGE_GAMESTATS);
			break;
		}
		default: ;
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
	game = new HWGame(config, gamecfg, pTeamSelWidget);
	connect(game, SIGNAL(GameStateChanged(GameState)), this, SLOT(GameStateChanged(GameState)));
	connect(game, SIGNAL(GameStats(char, const QString &)), this, SLOT(GameStats(char, const QString &)));
	connect(game, SIGNAL(ErrorMessage(const QString &)), this, SLOT(ShowErrorMessage(const QString &)), Qt::QueuedConnection);
}

void HWForm::ShowErrorMessage(const QString & msg)
{
	QMessageBox::warning(this,
			"Hedgewars",
			msg);
}
