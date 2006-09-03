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
	HWGame * game;
	HWTeam * tmpTeam;
	HWNet * hwnet;
	GameUIConfig * config;
};

#define ID_PAGE_SINGLEPLAYER 0
#define ID_PAGE_SETUP_TEAM 1
#define ID_PAGE_SETUP 2
#define ID_PAGE_MULTIPLAYER 3
#define ID_PAGE_DEMOS 4
#define ID_PAGE_NET 5
#define ID_PAGE_NETCHAT 6
#define ID_PAGE_NETCFG 7
#define ID_PAGE_MAIN 8

#endif
