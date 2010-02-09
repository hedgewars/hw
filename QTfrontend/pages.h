/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Andrey Korotaev <unC0Rr@gmail.com>
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
#include <QPushButton>
#include <QFont>
#include <QGridLayout>
#include <QSignalMapper>

#include "binds.h"
#include "hwform.h"
#include "mapContainer.h"
#include "togglebutton.h"

class QPushButton;
class QGroupBox;
class QComboBox;
class QLabel;
class QToolBox;
class QLineEdit;
class QListWidget;
class QCheckBox;
class QSpinBox;
class QTextEdit;
class QRadioButton;
class QTableView;
class QTextBrowser;
class QTableWidget;
class QAction;
class QDataWidgetMapper;
class QAbstractItemModel;
class QSettings;

class GameCFGWidget;
class TeamSelWidget;
class DemosList;
class SquareLabel;
class About;
class FPSEdit;
class HWChatWidget;
class SelWeaponWidget;
class IconedGroupBox;
class FreqSpinBox;

class AbstractPage : public QWidget
{
	Q_OBJECT

 public:

 protected:
  AbstractPage(QWidget* parent = 0) {
    font14 = new QFont("MS Shell Dlg", 14);
  }
  virtual ~AbstractPage() {};

  QPushButton* addButton(QString btname, QGridLayout* grid, int wy, int wx, bool iconed = false) {
    QPushButton* butt = new QPushButton(this);
    if (!iconed) {
      butt->setFont(*font14);
      butt->setText(btname);
      //butt->setStyleSheet("background-color: #0d0544");
    } else {
      const QIcon& lp=QIcon(btname);
      QSize sz = lp.actualSize(QSize(65535, 65535));
      butt->setIcon(lp);
      butt->setFixedSize(sz);
      butt->setIconSize(sz);
      butt->setFlat(true);
      butt->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
    }
    grid->addWidget(butt, wy, wx);
    return butt;
  };

  QPushButton* addButton(QString btname, QGridLayout* grid, int wy, int wx, int rowSpan, int columnSpan, bool iconed = false) {
    QPushButton* butt = new QPushButton(this);
    if (!iconed) {
      butt->setFont(*font14);
      butt->setText(btname);
    } else {
      const QIcon& lp=QIcon(btname);
      QSize sz = lp.actualSize(QSize(65535, 65535));
      butt->setIcon(lp);
      butt->setFixedSize(sz);
      butt->setIconSize(sz);
      butt->setFlat(true);
      butt->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
    }
    grid->addWidget(butt, wy, wx, rowSpan, columnSpan);
    return butt;
  };

  QPushButton* addButton(QString btname, QBoxLayout* box, int where, bool iconed = false) {
    QPushButton* butt = new QPushButton(this);
    if (!iconed) {
      butt->setFont(*font14);
      butt->setText(btname);
    } else {
      const QIcon& lp=QIcon(btname);
      QSize sz = lp.actualSize(QSize(65535, 65535));
      butt->setIcon(lp);
      butt->setFixedSize(sz);
      butt->setIconSize(sz);
      butt->setFlat(true);
      butt->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
    }
    box->addWidget(butt, where);
    return butt;
  };

  QFont * font14;
};

class PageMain : public AbstractPage
{
	Q_OBJECT

public:
	PageMain(QWidget* parent = 0);

	QPushButton *BtnSinglePlayer;
	QPushButton *BtnNet;
	QPushButton *BtnSetup;
	QPushButton *BtnInfo;
	QPushButton *BtnExit;
};

class PageEditTeam : public AbstractPage
{
	Q_OBJECT

public:
	PageEditTeam(QWidget* parent, SDLInteraction * sdli);
	QSignalMapper* signalMapper;
	QGroupBox *GBoxHedgehogs;
	QGroupBox *GBoxTeam;
	QGroupBox *GBoxFort;
	QComboBox *CBFort;
	SquareLabel *FortPreview;
	QComboBox *CBGrave;
	QComboBox *CBFlag;
	QComboBox *CBTeamLvl;
	QComboBox *CBVoicepack;
	QGroupBox *GBoxBinds;
	QToolBox *BindsBox;
	QPushButton *BtnTeamDiscard;
	QPushButton *BtnTeamSave;
	QPushButton * BtnTestSound;
	QLineEdit * TeamNameEdit;
	QLineEdit * HHNameEdit[8];
	QComboBox * HHHats[8];
	QPushButton * randButton[8];
	QComboBox * CBBind[BINDS_NUMBER];
	QPushButton * randTeamButton;

private:
    SDLInteraction * mySdli;

public slots:
	void CBFort_activated(const QString & gravename);

private slots:
	void testSound();
};

class PageMultiplayer : public AbstractPage
{
	Q_OBJECT

public:
	PageMultiplayer(QWidget* parent = 0);

	QPushButton *BtnBack;
	GameCFGWidget *gameCFG;
	TeamSelWidget *teamsSelect;
	QPushButton *BtnStartMPGame;
};

class PageOptions : public AbstractPage
{
	Q_OBJECT

public:
	PageOptions(QWidget* parent = 0);

	QPushButton *WeaponsButt;
	QPushButton *WeaponEdit;
	QComboBox *WeaponsName;
	QCheckBox *WeaponTooltip;

	QPushButton *BtnBack;
	IconedGroupBox *teamsBox;
	QPushButton *BtnNewTeam;
	QPushButton *BtnEditTeam;
	QComboBox *CBTeamName;
	IconedGroupBox *AGGroupBox;
	QComboBox *CBResolution;
	QCheckBox *CBEnableSound;
#ifdef _WIN32
	QCheckBox *CBHardwareSound;
#endif
	QCheckBox *CBEnableMusic;
	QCheckBox *CBFullscreen;
	QCheckBox *CBFrontendFullscreen;
	QCheckBox *CBShowFPS;
	QCheckBox *CBAltDamage;
	QCheckBox *CBNameWithDate;
#ifdef __APPLE__
    QCheckBox *CBAutoUpdate;
#endif

	FPSEdit *fpsedit;
	QPushButton *BtnSaveOptions;
	QLabel *labelNN;
	QSpinBox * volumeBox;
	QLineEdit *editNetNick;
	QCheckBox *CBReduceQuality;
	QCheckBox *CBFrontendEffects;
};

class PageNet : public AbstractPage
{
	Q_OBJECT

public:
	PageNet(QWidget* parent = 0);

	QPushButton* BtnUpdateSList;
	QTableView * tvServersList;
	QPushButton * BtnBack;
	QPushButton * BtnNetConnect;
	QPushButton * BtnNetSvrStart;
	QPushButton * BtnSpecifyServer;

private:
	QGroupBox * ConnGroupBox;
	QGridLayout * GBClayout;

private slots:
	void slotConnect();

public slots:
	void updateServersList();

signals:
	void connectClicked(const QString & host, quint16 port);
};

class PageNetServer : public AbstractPage
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

class PageNetGame : public AbstractPage
{
	Q_OBJECT

public:
	PageNetGame(QWidget* parent, QSettings * config, SDLInteraction * sdli);

	QPushButton *BtnBack;
	QPushButton *BtnGo;
	QPushButton *BtnMaster;
	QPushButton *BtnStart;

	QAction * restrictJoins;
	QAction * restrictTeamAdds;

	HWChatWidget* pChatWidget;

	TeamSelWidget* pNetTeamsWidget;
	GameCFGWidget* pGameCFG;

public slots:
	void setReadyStatus(bool isReady);
	void setMasterMode(bool isMaster);
};

class PageInfo : public AbstractPage
{
	Q_OBJECT

public:
	PageInfo(QWidget* parent = 0);

	QPushButton *BtnBack;
	About *about;
};

class PageSinglePlayer : public AbstractPage
{
	Q_OBJECT

public:
	PageSinglePlayer(QWidget* parent = 0);

	QPushButton *BtnSimpleGamePage;
	QPushButton *BtnTrainPage;
	QPushButton *BtnMultiplayer;
	QPushButton *BtnLoad;
	QPushButton *BtnDemos;
	QPushButton *BtnBack;
	GameCFGWidget *gameCFG;
};

class PageTraining : public AbstractPage
{
	Q_OBJECT

public:
	PageTraining(QWidget* parent = 0);

	QPushButton *BtnStartTrain;
	QPushButton *BtnBack;
	QComboBox   *CBSelect;
};

class PageSelectWeapon : public AbstractPage
{
	Q_OBJECT

public:
	PageSelectWeapon(QWidget* parent = 0);

	QPushButton *BtnSave;
	QPushButton *BtnDefault;
	QPushButton *BtnDelete;
	QPushButton *BtnBack;
	SelWeaponWidget* pWeapons;
};

class PageInGame : public AbstractPage
{
	Q_OBJECT

public:
	PageInGame(QWidget* parent = 0);
};

class PageRoomsList : public AbstractPage
{
	Q_OBJECT

public:
    PageRoomsList(QWidget* parent, QSettings * config, SDLInteraction * sdli);

	QLineEdit * roomName;
	QTableWidget * roomsList;
	QPushButton * BtnBack;
	QPushButton * BtnCreate;
	QPushButton * BtnJoin;
	QPushButton * BtnRefresh;
	QPushButton * BtnAdmin;
	HWChatWidget * chatWidget;

public slots:
	void setRoomsList(const QStringList & list);
	void setAdmin(bool);

private slots:
	void onCreateClick();
	void onJoinClick();
	void onRefreshClick();

signals:
	void askForCreateRoom(const QString &);
	void askForJoinRoom(const QString &);
	void askForRoomList();
};

class PageConnecting : public AbstractPage
{
	Q_OBJECT

public:
	PageConnecting(QWidget* parent = 0);
};

class PageScheme : public AbstractPage
{
	Q_OBJECT

public:
	PageScheme(QWidget* parent = 0);

	QPushButton * BtnBack;
	QPushButton * BtnNew;
	QPushButton * BtnDelete;
	QPushButton * BtnSave;

	void setModel(QAbstractItemModel * model);

private:
	QDataWidgetMapper * mapper;
	ToggleButtonWidget * TBW_mode_Forts;
	ToggleButtonWidget * TBW_teamsDivide;
	ToggleButtonWidget * TBW_solid;
	ToggleButtonWidget * TBW_border;
	ToggleButtonWidget * TBW_lowGravity;
	ToggleButtonWidget * TBW_laserSight;
	ToggleButtonWidget * TBW_invulnerable;
	ToggleButtonWidget * TBW_mines;
	ToggleButtonWidget * TBW_vampiric;
	ToggleButtonWidget * TBW_karma;
	ToggleButtonWidget * TBW_artillery;
	ToggleButtonWidget * TBW_randomorder;
	ToggleButtonWidget * TBW_king;
	ToggleButtonWidget * TBW_placehog;

	QSpinBox * SB_DamageModifier;
	QSpinBox * SB_TurnTime;
	QSpinBox * SB_InitHealth;
	QSpinBox * SB_SuddenDeath;
	FreqSpinBox * SB_CaseProb;
	QSpinBox * SB_MinesTime;
	QSpinBox * SB_Mines;
	QLineEdit * LE_name;
	QComboBox * selectScheme;

	QGroupBox * gbGameModes;
	QGroupBox * gbBasicSettings;

private slots:
	void newRow();
	void deleteRow();
	void schemeSelected(int);
};

class PageAdmin : public AbstractPage
{
	Q_OBJECT

public:
	PageAdmin(QWidget* parent = 0);

	QPushButton * BtnBack;
	QPushButton * pbClearAccountsCache;

private:
	QLineEdit * leServerMessage;
	QPushButton * pbSetSM;

private slots:
	void smChanged();

public slots:
	void serverMessage(const QString & str);

signals:
	void setServerMessage(const QString & str);
};


class PageNetType : public AbstractPage
{
	Q_OBJECT

public:
	PageNetType(QWidget* parent = 0);

	QPushButton * BtnBack;
	QPushButton * BtnLAN;
	QPushButton * BtnOfficialServer;
};

#endif // PAGES_H
