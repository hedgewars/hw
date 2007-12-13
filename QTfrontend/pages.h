/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006, 2007 Andrey Korotaev <unC0Rr@gmail.com>
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
#include "mapContainer.h"

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
class FPSEdit;
class HWNetUdpWidget;
class QTextEdit;
class HWChatWidget;
class SelWeaponWidget;
class HWNetServersWidget;
class QRadioButton;

class PageMain : public QWidget
{
	Q_OBJECT

public:
	PageMain(QWidget* parent = 0);

	QPushButton *BtnSinglePlayer;
	QPushButton *BtnMultiplayer;
	QPushButton *BtnNet;
	QPushButton *BtnSetup;
	QPushButton *BtnLoad;
	QPushButton *BtnDemos;
	QPushButton *BtnInfo;
	QPushButton *BtnExit;
};

class PageSimpleGame : public QWidget
{
	Q_OBJECT

public:
	PageSimpleGame(QWidget* parent = 0);

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
	QGroupBox *GBoxTeamLvl;
	QComboBox *CBTeamLvl;
	QLabel *LevelPict;
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
	void CBTeamLvl_activated(int id);

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

class PageOptions : public QWidget
{
	Q_OBJECT

public:
	PageOptions(QWidget* parent = 0);

	QPushButton* WeaponsButt;
	QPushButton *BtnBack;
	QGroupBox *groupBox;
	QPushButton *BtnNewTeam;
	QPushButton *BtnEditTeam;
	QComboBox *CBTeamName;
	QGroupBox *AGGroupBox;
	QComboBox *CBResolution;
	QCheckBox *CBEnableSound;
	QCheckBox *CBFullscreen;
	QCheckBox *CBShowFPS;
	QCheckBox *CBAltDamage;
	FPSEdit *fpsedit;
	QPushButton *BtnSaveOptions;
	QGroupBox *NNGroupBox;
	QLabel *labelNN;
	QLineEdit *editNetNick;
};

class PageNet : public QWidget
{
	Q_OBJECT

public:
	PageNet(QWidget* parent = 0);

	QPushButton* BtnUpdateSList;
	HWNetServersWidget* netServersWidget;
	QPushButton * BtnBack;
	QPushButton * BtnNetConnect;
	QPushButton * BtnNetSvrStart;
	QPushButton * BtnSpecifyServer;
	QRadioButton * rbLocalGame;
	QRadioButton * rbInternetGame;

private:
	QGroupBox * ConnGroupBox;
	QGridLayout * GBClayout;

private slots:
	void slotConnect();

public slots:
	void updateServersList();

signals:
	void connectClicked();
};

class PageNetServer : public QWidget
{
	Q_OBJECT

public:
	PageNetServer(QWidget* parent = 0);

	QPushButton *BtnBack;
	QPushButton *BtnStart;
	QPushButton *BtnDefault;
	QLabel *labelSD;
	QLineEdit *leServerDescr;
	QLabel *labelPort;
	QSpinBox *sbPort;

private slots:
	void setDefaultPort();
};

class PageNetGame : public QWidget
{
	Q_OBJECT

public:
	PageNetGame(QWidget* parent = 0);

	QPushButton *BtnBack;
	QPushButton *BtnGo;

	HWChatWidget* pChatWidget;

	TeamSelWidget* pNetTeamsWidget;
	GameCFGWidget* pGameCFG;
};

class PageInfo : public QWidget
{
	Q_OBJECT

public:
	PageInfo(QWidget* parent = 0);

	QPushButton *BtnBack;
	About *about;
};

class PageGameStats : public QWidget
{
	Q_OBJECT

public:
	PageGameStats(QWidget* parent = 0);

	QPushButton *BtnBack;
	QLabel *labelGameStats;
};

class PageSinglePlayer : public QWidget
{
	Q_OBJECT

public:
	PageSinglePlayer(QWidget* parent = 0);

	QPushButton *BtnSimpleGamePage;
	QPushButton *BtnTrainPage;
	QPushButton *BtnBack;
	GameCFGWidget *gameCFG;
};

class PageTraining : public QWidget
{
	Q_OBJECT

public:
	PageTraining(QWidget* parent = 0);

	QPushButton *BtnStartTrain;
	QPushButton *BtnBack;
};

class PageSelectWeapon : public QWidget
{
	Q_OBJECT

public:
	PageSelectWeapon(QWidget* parent = 0);

	QPushButton *BtnBack;
        SelWeaponWidget* pWeapons;
};

#endif // PAGES_H
