/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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

	config = new GameUIConfig(this);

	QStringList teamslist = config->GetTeamsList();

	if(teamslist.empty()) {
		HWTeam defaultTeam("DefaultTeam");
		defaultTeam.SaveToFile();
		teamslist.push_back("DefaultTeam");
	}

	for (QStringList::Iterator it = teamslist.begin(); it != teamslist.end(); ++it )
	{
	  ui.pageMultiplayer->teamsSelect->addTeam(*it);
	  ui.pageOptions->CBTeamName->addItem(*it);
	}

	connect(ui.pageMain->BtnSinglePlayer,	SIGNAL(clicked()),	this, SLOT(GoToSinglePlayer()));
	connect(ui.pageMain->BtnSetup,	SIGNAL(clicked()),	this, SLOT(GoToSetup()));
	connect(ui.pageMain->BtnMultiplayer,	SIGNAL(clicked()),	this, SLOT(GoToMultiplayer()));
	connect(ui.pageMain->BtnDemos,	SIGNAL(clicked()),	this, SLOT(GoToDemos()));
	connect(ui.pageMain->BtnNet,	SIGNAL(clicked()),	this, SLOT(GoToNet()));
	connect(ui.pageMain->BtnExit, SIGNAL(clicked()), this, SLOT(close()));

	connect(ui.pageLocalGame->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoToMain()));
	connect(ui.pageLocalGame->BtnSimpleGame,	SIGNAL(clicked()),	this, SLOT(SimpleGame()));

	connect(ui.pageEditTeam->BtnTeamSave,	SIGNAL(clicked()),	this, SLOT(TeamSave()));
	connect(ui.pageEditTeam->BtnTeamDiscard,	SIGNAL(clicked()),	this, SLOT(TeamDiscard()));

	connect(ui.pageMultiplayer->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoToMain()));
	connect(ui.pageMultiplayer->BtnStartMPGame,	SIGNAL(clicked()),	this, SLOT(StartMPGame()));

	connect(ui.pagePlayDemo->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoToMain()));
	connect(ui.pagePlayDemo->BtnPlayDemo,	SIGNAL(clicked()),	this, SLOT(PlayDemo()));

	connect(ui.pageOptions->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoToMain()));
	connect(ui.pageOptions->BtnNewTeam,	SIGNAL(clicked()),	this, SLOT(NewTeam()));
	connect(ui.pageOptions->BtnEditTeam,	SIGNAL(clicked()),	this, SLOT(EditTeam()));
	connect(ui.pageOptions->BtnSaveOptions,	SIGNAL(clicked()),	config, SLOT(SaveOptions()));

	connect(ui.pageNet->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoToMain()));
	connect(ui.pageNet->BtnNetConnect,	SIGNAL(clicked()),	this, SLOT(NetConnect()));

	connect(ui.pageNetGame->BtnBack,	SIGNAL(clicked()),	this, SLOT(GoToNetChat()));
	connect(ui.pageNetGame->BtnAddTeam,	SIGNAL(clicked()),	this, SLOT(NetAddTeam()));
	connect(ui.pageNetGame->BtnGo,	SIGNAL(clicked()),	this, SLOT(NetStartGame()));

	connect(ui.pageNetChat->BtnDisconnect, SIGNAL(clicked()), this, SLOT(NetDisconnect()));
	connect(ui.pageNetChat->BtnJoin,	SIGNAL(clicked()),	this, SLOT(NetJoin()));
	connect(ui.pageNetChat->BtnCreate,	SIGNAL(clicked()),	this, SLOT(NetCreate()));

	ui.Pages->setCurrentIndex(ID_PAGE_MAIN);
}

void HWForm::GoToMain()
{
	ui.Pages->setCurrentIndex(ID_PAGE_MAIN);
}

void HWForm::GoToSinglePlayer()
{
	ui.Pages->setCurrentIndex(ID_PAGE_SINGLEPLAYER);
}

void HWForm::GoToSetup()
{
	ui.Pages->setCurrentIndex(ID_PAGE_SETUP);
}

void HWForm::GoToMultiplayer()
{
	ui.Pages->setCurrentIndex(ID_PAGE_MULTIPLAYER);
}

void HWForm::GoToDemos()
{
	QDir tmpdir;
	tmpdir.cd(datadir->absolutePath());
	tmpdir.cd("Demos");
	tmpdir.setFilter(QDir::Files);
	ui.pagePlayDemo->DemosList->clear();
	ui.pagePlayDemo->DemosList->addItems(tmpdir.entryList(QStringList("*.hwd_1")).replaceInStrings(QRegExp("^(.*).hwd_1"), "\\1"));
	ui.Pages->setCurrentIndex(ID_PAGE_DEMOS);
}

void HWForm::GoToNet()
{
	ui.Pages->setCurrentIndex(ID_PAGE_NET);
}

void HWForm::GoToNetChat()
{
	ui.Pages->setCurrentIndex(ID_PAGE_NETCHAT);
}

void HWForm::NewTeam()
{
	tmpTeam = new HWTeam("unnamed");

	ui.Pages->setCurrentIndex(ID_PAGE_SETUP_TEAM);
}

void HWForm::EditTeam()
{
	tmpTeam = new HWTeam(ui.pageOptions->CBTeamName->currentText());
	tmpTeam->LoadFromFile();
	tmpTeam->SetToPage(this);
	ui.Pages->setCurrentIndex(ID_PAGE_SETUP_TEAM);
}

void HWForm::TeamSave()
{
	tmpTeam->GetFromPage(this);
	tmpTeam->SaveToFile();
	delete tmpTeam;
	ui.Pages->setCurrentIndex(ID_PAGE_SETUP);
}

void HWForm::TeamDiscard()
{
	ui.Pages->setCurrentIndex(ID_PAGE_SETUP);
}

void HWForm::SimpleGame()
{
	game = new HWGame(config, ui.pageLocalGame->gameCFG);
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
	game = new HWGame(config, 0);
	game->PlayDemo(datadir->absolutePath() + "/Demos/" + curritem->text() + ".hwd_1");
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
	GoToNet();
}

void HWForm::AddGame(const QString & chan)
{
	ui.pageNetChat->ChannelsList->addItem(chan);
}

void HWForm::NetGameEnter()
{
	ui.Pages->setCurrentIndex(ID_PAGE_NETCFG);
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
	game = new HWGame(config, ui.pageMultiplayer->gameCFG);
	QStringList teamslist = config->GetTeamsList();
	for (QStringList::Iterator it = teamslist.begin(); it != teamslist.end(); ++it ) {
	  if(ui.pageMultiplayer->teamsSelect->isPlaying(*it)) {
	    game->AddTeam(*it, ui.pageMultiplayer->teamsSelect->numHedgedogs(*it));
	  }
	}
	game->StartLocal();
}
