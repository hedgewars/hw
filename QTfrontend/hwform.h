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

#ifndef HWFORM_H
#define HWFORM_H

#include <QLabel>
#include <QLineEdit>
#include <QDir>

#include "ui_hwform.h"

class HWGame;
class HWTeam;
class HWNet;
class GameUIConfig;

class HWForm : public QMainWindow
{
	Q_OBJECT

public:
	HWForm(QWidget *parent = 0);
	Ui_HWForm ui;

private slots:
	void GoToMain();
	void GoToSinglePlayer();
	void GoToSetup();
	void GoToMultiplayer();
	void GoToDemos();
	void GoToNet();
	void GoToNetChat();
	void GoToInfo();
	void NewTeam();
	void EditTeam();
	void TeamSave();
	void TeamDiscard();
	void SimpleGame();
	void PlayDemo();
	void NetConnect();
	void NetDisconnect();
	void NetJoin();
	void NetCreate();
	void AddGame(const QString & chan);
	void NetAddTeam();
	void NetGameEnter();
	void NetStartGame();
	void ChangeInNetTeams(const QStringList & teams);
	void StartMPGame();

private:
	enum PageIDs {
		ID_PAGE_SINGLEPLAYER	= 0,
		ID_PAGE_SETUP_TEAM	= 1,
		ID_PAGE_SETUP	= 2,
		ID_PAGE_MULTIPLAYER	= 3,
		ID_PAGE_DEMOS	= 4,
		ID_PAGE_NET	= 5,
		ID_PAGE_NETCHAT	= 6,
		ID_PAGE_NETCFG	= 7,
		ID_PAGE_INFO	= 8,
		ID_PAGE_MAIN	= 9
		};
	HWGame * game;
	HWTeam * tmpTeam;
	HWNet * hwnet;
	GameUIConfig * config;
};

#endif
