/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Andrey Korotaev <unC0Rr@gmail.com>
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
class SquareLabel;
class About;
class QSpinBox;

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
	QPushButton *BtnInfo;
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
	SquareLabel *FortPreview;
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
	QSpinBox* difficultyBox;
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
	QPushButton *BtnStartMPGame;
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
	QGroupBox *AGGroupBox;
	QComboBox *CBResolution;
	QCheckBox *CBEnableSound;
	QCheckBox *CBFullscreen;
	QPushButton *BtnSaveOptions;
};

class PageNet : public QWidget
{
	Q_OBJECT

public:
	PageNet(QWidget* parent = 0);

	QPushButton *BtnBack;
	QPushButton *BtnNetConnect;
	QGroupBox *NNGroupBox;
	QLabel *labelNN;
	QLineEdit *editNetNick;
	QLabel *labelIP;
	QLineEdit * editIP;
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

class PageInfo : public QWidget
{
	Q_OBJECT

public:
	PageInfo(QWidget* parent = 0);

	QPushButton *BtnBack;
	About *about;
};

#endif // PAGES_H
