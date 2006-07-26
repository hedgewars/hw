/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef PAGES_H
#define PAGES_H

#include <QWidget>

#include "binds.h"

class GameCFGWidget;
class QPushButton;
class QGroupBox;
class QComboBox;
class QLabel;
class QToolBox;
class QLineEdit;
class TeamSelWidget;
class DemosList;
class QListWidget;
class QCheckBox;

class PageMain : public QWidget
{
	Q_OBJECT

public:
	PageMain(QWidget* parent = 0);

	QPushButton *BtnSinglePlayer;
	QPushButton *BtnMultiplayer;
	QPushButton *BtnNet;
	QPushButton *BtnSetup;
	QPushButton *BtnDemos;
	QPushButton *BtnExit;
};

class PageLocalGame : public QWidget
{
	Q_OBJECT

public:
	PageLocalGame(QWidget* parent = 0);

	QPushButton *BtnSimpleGame;
	QPushButton *BtnBack;
	GameCFGWidget *gameCFG;
};

class PageEditTeam : public QWidget
{
	Q_OBJECT

public:
	PageEditTeam(QWidget* parent = 0);
	QGroupBox *GBoxHedgehogs;
	QGroupBox *GBoxTeam;
	QGroupBox *GBoxFort;
	QComboBox *CBFort;
	QLabel *FortPreview;
	QGroupBox *GBoxGrave;
	QComboBox *CBGrave;
	QLabel *GravePreview;
	QGroupBox *GBoxBinds;
	QToolBox *BindsBox;
	QWidget *page_A;
	QWidget *page_W;
	QWidget *page_WP;
	QWidget *page_O;
	QPushButton *BtnTeamDiscard;
	QPushButton *BtnTeamSave;
	QLineEdit * TeamNameEdit;
	QLineEdit * HHNameEdit[8];
	QComboBox * CBBind[BINDS_NUMBER];

public slots:
	void CBGrave_activated(const QString & gravename);
	void CBFort_activated(const QString & gravename);

private:
	QLabel * LBind[BINDS_NUMBER];
};

class PageMultiplayer : public QWidget
{
	Q_OBJECT

public:
	PageMultiplayer(QWidget* parent = 0);

	QPushButton *BtnBack;
	GameCFGWidget *gameCFG;
	TeamSelWidget *teamsSelect;
};

class PagePlayDemo : public QWidget
{
	Q_OBJECT

public:
	PagePlayDemo(QWidget* parent = 0);

	QPushButton *BtnBack;
	QPushButton *BtnPlayDemo;
	QListWidget *DemosList;
};

class PageOptions : public QWidget
{
	Q_OBJECT

public:
	PageOptions(QWidget* parent = 0);

	QPushButton *BtnBack;
	QGroupBox *groupBox;
	QPushButton *BtnNewTeam;
	QPushButton *BtnEditTeam;
	QComboBox *CBTeamName;
	QComboBox *CBResolution;
	QCheckBox *CBEnableSound;
	QCheckBox *CBFullscreen;
	QLabel *label;
	QLineEdit *editNetNick;
	QPushButton *BtnSaveOptions;
};

class PageNet : public QWidget
{
	Q_OBJECT

public:
	PageNet(QWidget* parent = 0);

	QPushButton *BtnBack;
	QPushButton *BtnNetConnect;
};

class PageNetChat : public QWidget
{
	Q_OBJECT

public:
	PageNetChat(QWidget* parent = 0);

	QPushButton *BtnDisconnect;
	QListWidget *ChannelsList;
	QPushButton *BtnJoin;
	QPushButton *BtnCreate;
};

class PageNetGame : public QWidget
{
	Q_OBJECT

public:
	PageNetGame(QWidget* parent = 0);

	QPushButton *BtnBack;
	QPushButton *BtnAddTeam;
	QPushButton *BtnGo;
	QListWidget *listNetTeams;
};

#endif // PAGES_H
