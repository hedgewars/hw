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

#include "hwform.h"
#include "game.h"
#include "team.h"
#include "netclient.h"
#include "teamselect.h"
#include "gameuiconfig.h"
#include "pages.h"
#include "hwconsts.h"

HWForm::HWForm(QWidget *parent)
	: QMainWindow(parent)
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

	connect(ui.pageNetGame->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoBack()));
	connect(ui.pageNetGame->BtnAddTeam,	SIGNAL(clicked()),	this, SLOT(NetAddTeam()));
	connect(ui.pageNetGame->BtnGo,	SIGNAL(clicked()),	this, SLOT(NetStartGame()));

	connect(ui.pageNetChat->BtnDisconnect, SIGNAL(clicked()), this, SLOT(NetDisconnect()));
	connect(ui.pageNetChat->BtnJoin,	SIGNAL(clicked()),	this, SLOT(NetJoin()));
	connect(ui.pageNetChat->BtnCreate,	SIGNAL(clicked()),	this, SLOT(NetCreate()));

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

void HWForm::GoToNetChat()
{
	GoToPage(ID_PAGE_NETCHAT);
}

void HWForm::OnPageShown(quint8 id)
{
	if (id == ID_PAGE_MULTIPLAYER) {
		QStringList tmNames=config->GetTeamsList();
		QList<HWTeam> teamsList;
		for(QStringList::iterator it=tmNames.begin(); it!=tmNames.end(); it++) {
		  HWTeam team(*it);
		  team.LoadFromFile();
		  teamsList.push_back(team);
		}
		ui.pageMultiplayer->teamsSelect->resetPlayingTeams(teamsList);
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
	CreateGame(ui.pageLocalGame->gameCFG);
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
	CreateGame(0);
	game->PlayDemo(cfgdir->absolutePath() + "/Demos/" + curritem->text() + ".hwd_" + cProtoVer);
}

void HWForm::NetConnect()
{
	hwnet = new HWNet(config);
	connect(hwnet, SIGNAL(Connected()), this, SLOT(GoToNetChat()));
	connect(hwnet, SIGNAL(AddGame(const QString &)), this, SLOT(AddGame(const QString &)));
	connect(hwnet, SIGNAL(EnteredGame()), this, SLOT(NetGameEnter()));
	connect(hwnet, SIGNAL(ChangeInTeams(const QStringList &)), this, SLOT(ChangeInNetTeams(const QStringList &)));
	hwnet->Connect(ui.pageNet->editIP->text(), 6667, ui.pageNet->editNetNick->text());
	config->SaveOptions();
}

void HWForm::NetDisconnect()
{
	hwnet->Disconnect();
	GoBack();
}

void HWForm::AddGame(const QString & chan)
{
	ui.pageNetChat->ChannelsList->addItem(chan);
}

void HWForm::NetGameEnter()
{
	GoToPage(ID_PAGE_NETCFG);
}

void HWForm::NetJoin()
{
	hwnet->JoinGame("#hw");
}

void HWForm::NetCreate()
{
	hwnet->JoinGame("#hw");
}

void HWForm::NetAddTeam()
{
	HWTeam team("DefaultTeam");
	team.LoadFromFile();
	hwnet->AddTeam(team);
}

void HWForm::NetStartGame()
{
	hwnet->StartGame();
}

void HWForm::ChangeInNetTeams(const QStringList & teams)
{
	ui.pageNetGame->listNetTeams->clear();
	ui.pageNetGame->listNetTeams->addItems(teams);
}

void HWForm::StartMPGame()
{
	CreateGame(ui.pageMultiplayer->gameCFG);

	list<HWTeam> teamslist=ui.pageMultiplayer->teamsSelect->getPlayingTeams();
	for (list<HWTeam>::const_iterator it = teamslist.begin(); it != teamslist.end(); ++it ) {
	  HWTeamTempParams params=ui.pageMultiplayer->teamsSelect->getTeamParams(it->TeamName);
	  game->AddTeam(it->TeamName, params);
	}
	game->StartLocal();
}

void HWForm::GameStateChanged(GameState gameState)
{
	if (gameState == gsStarted)
	{
		GoToPage(ID_PAGE_GAMESTATS);
		ui.pageGameStats->labelGameStats->setText("");
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

void HWForm::CreateGame(GameCFGWidget * gamecfg)
{
	game = new HWGame(config, gamecfg);
	connect(game, SIGNAL(GameStateChanged(GameState)), this, SLOT(GameStateChanged(GameState)));
	connect(game, SIGNAL(GameStats(char, const QString &)), this, SLOT(GameStats(char, const QString &)));
}
