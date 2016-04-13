/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifndef HWFORM_H
#define HWFORM_H

#include <QMainWindow>
#include <QStack>
#include <QTime>
#include <QPointer>
#include <QPropertyAnimation>
#include <QUrl>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QNetworkAccessManager>

#include "netserver.h"
#include "game.h"
#include "ui_hwform.h"
#include "SDLInteraction.h"
#include "bgwidget.h"
#include "campaign.h"

#ifdef __APPLE__
#include "InstallController.h"
#endif

class HWGame;
class HWTeam;
class HWNamegen;
class HWNewNet;
class GameUIConfig;
class HWNetRegisterServer;
class QCloseEvent;
class AmmoSchemeModel;
class QSettings;
class QSignalMapper;

extern bool frontendEffects;
extern QString playerHash;

class HWForm : public QMainWindow
{
        Q_OBJECT

    public:
        HWForm(QWidget *parent = 0, QString styleSheet = "");
        Ui_HWForm ui;
        static GameUIConfig * config;
        void exit();
        void setButtonDescription(QString desc);
        void backDescription();
        void GoToVideos();

        void NetConnectQuick(const QString & host, quint16 port);
        void PlayDemoQuick(const QString & demofilename);

    private slots:
        void GoToSaves();
        void GoToDemos();
        void GoToNet();
        void GoToSelectWeapon();
        void GoToSelectWeaponSet(int index);
        void GoToSelectNewWeapon();
        void GoToScheme(int index);
        void GoToEditScheme();
        void GoToNewScheme();
        void GoToPage(int id);
        void GoBack();
        void OpenSnapshotFolder();
        QString getDemoArguments();
        void AssociateFiles();
        void btnExitPressed();
        void IntermediateSetup();
        void NewTeam();
        void EditTeam(const QString & teamName);
        void AfterTeamEdit();
        void DeleteTeam(const QString & teamName);
        void DeleteScheme();
        void DeleteWeaponSet();
        void SimpleGame();
        void PlayDemo();
        void startTraining(const QString&, const QString&);
        void StartCampaign();
        void NetConnect();
        void NetConnectServer(const QString & host, quint16 port);
        void NetConnectOfficialServer();
        void NetStartServer();
        void NetDisconnect();
        void NetConnected();
        void NetError(const QString & errmsg);
        void NetWarning(const QString & wrnmsg);
        void NetGameEnter();
        void NetPassword(const QString & nick);
        void NetNickRegistered(const QString & nick);
        void NetNickNotRegistered(const QString & nick);
        void NetNickTaken(const QString & nick);
        void NetAuthFailed();
        void askRoomPassword();
        bool RetryDialog(const QString & title, const QString & label);
        void NetTeamAccepted(const QString& team);
        void AddNetTeam(const HWTeam& team);
        void RemoveNetTeam(const HWTeam& team);
        void StartMPGame();
        void GameStateChanged(GameState gameState);
        void ForcedDisconnect(const QString & reason);
        void ShowFatalErrorMessage(const QString &);
        void GetRecord(RecordType type, const QByteArray & record);
        void CreateNetGame();
        void UpdateWeapons();
        void onFrontendFullscreen(bool value);
        void onFrontendEffects(bool value);
        void Music(bool checked);
        void UpdateCampaignPage(int index);
        void UpdateCampaignPageTeam(int index);
        void UpdateCampaignPageProgress(int index);
        void UpdateCampaignPageMission(int index);
        void InitCampaignPage();
        void showFeedbackDialog();
        void showFeedbackDialogNetChecked();

        void NetGameChangeStatus(bool isMaster);
        void NetGameMaster();
        void NetGameSlave();

        void AsyncNetServerStart();
        void NetLeftRoom(const QString & reason);
        void selectFirstNetScheme();

        void saveDemoWithCustomName();
        void openRegistrationPage();

        void startGame();
        void restartGame();

        void FromNetProxySlot(const QByteArray &);

    private:
        void _NetConnect(const QString & hostName, quint16 port, QString nick);
        int  AskForNickAndPwd(void);
        void UpdateTeamsLists();
        void CreateGame(GameCFGWidget * gamecfg, TeamSelWidget* pTeamSelWidget, QString ammo);
        void closeEvent(QCloseEvent *event);
        void CustomizePalettes();
        void resizeEvent(QResizeEvent * event);
        QString stringifyPageId(quint32 id);
        //void keyReleaseEvent(QKeyEvent *event);

        enum PageIDs
        {
            ID_PAGE_SETUP_TEAM     ,
            ID_PAGE_SETUP          ,
            ID_PAGE_MULTIPLAYER    ,
            ID_PAGE_DEMOS          ,
            ID_PAGE_NET            ,
            ID_PAGE_NETGAME        ,
            ID_PAGE_INFO           ,
            ID_PAGE_MAIN           ,
            ID_PAGE_GAMESTATS      ,
            ID_PAGE_SINGLEPLAYER   ,
            ID_PAGE_TRAINING       ,
            ID_PAGE_SELECTWEAPON   ,
            ID_PAGE_NETSERVER      ,
            ID_PAGE_INGAME         ,
            ID_PAGE_ROOMSLIST      ,
            ID_PAGE_CONNECTING     ,
            ID_PAGE_SCHEME         ,
            ID_PAGE_ADMIN          ,
            ID_PAGE_CAMPAIGN       ,
            ID_PAGE_DRAWMAP        ,
            ID_PAGE_DATADOWNLOAD   ,
            ID_PAGE_VIDEOS         ,
            MAX_PAGE
        };
        QPointer<HWGame> game;
        QPointer<HWNetServer> pnetserver;
        QPointer<HWNetRegisterServer> pRegisterServer;
        QPointer<HWTeam> editedTeam;
        QPointer<HWNewNet> hwnet;
        HWNamegen * namegen;
        AmmoSchemeModel * ammoSchemeModel;
        QStack<int> PagesStack;
        QString previousCampaignName;
        QString previousTeamName;
        QList<MissionInfo> campaignMissionInfo;
        QTime eggTimer;
        BGWidget * wBackground;
        QSignalMapper * pageSwitchMapper;
        QByteArray m_lastDemo;

        QPropertyAnimation *animationNewSlide;
        QPropertyAnimation *animationOldSlide;
        QPropertyAnimation *animationNewOpacity;
        QPropertyAnimation *animationOldOpacity;

#ifdef __APPLE__
        InstallController * panel;
#endif

        void OnPageShown(quint8 id, quint8 lastid=0);
};

#endif
