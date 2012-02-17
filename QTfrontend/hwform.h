/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2012 Andrey Korotaev <unC0Rr@gmail.com>
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
        static QSettings * gameSettings; // Same file GameUIConfig points to but without the baggage.  Needs sync() calls if you want to get GameUIConfig changes though
        void updateXfire();
        void PlayDemoQuick(const QString & demofilename);
        void exit();
        void setButtonDescription(QString desc);
        void backDescription();

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
        void startTraining(const QString&);
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
        void NetNickTaken(const QString & nick);
        void NetAuthFailed();
        void NetTeamAccepted(const QString& team);
        void AddNetTeam(const HWTeam& team);
        void RemoveNetTeam(const HWTeam& team);
        void StartMPGame();
        void GameStateChanged(GameState gameState);
        void ForcedDisconnect(const QString & reason);
        void ShowErrorMessage(const QString &);
        void GetRecord(bool isDemo, const QByteArray & record);
        void CreateNetGame();
        void UpdateWeapons();
        void onFrontendFullscreen(bool value);
        void onFrontendEffects(bool value);
        void Music(bool checked);
        void UpdateCampaignPage(int index);
        //Starts the transmission process for the feedback
        void SendFeedback();
        //Make a xml representation of the issue to be created
        bool CreateIssueXml();
        //Called the first time when receiving authorization token from google,
        //second time when receiving the response after posting the issue
        void finishedSlot(QNetworkReply* reply);
        //Filter the auth token from the reply from google
        bool getAuthToken(QString str);

        void NetGameChangeStatus(bool isMaster);
        void NetGameMaster();
        void NetGameSlave();

        void AsyncNetServerStart();
        void NetLeftRoom(const QString & reason);
        void selectFirstNetScheme();

        void saveDemoWithCustomName();

    private:
        void _NetConnect(const QString & hostName, quint16 port, QString nick);
        void UpdateTeamsLists(const QStringList* editable_teams=0);
        void CreateGame(GameCFGWidget * gamecfg, TeamSelWidget* pTeamSelWidget, QString ammo);
        void closeEvent(QCloseEvent *event);
        void CustomizePalettes();
        void resizeEvent(QResizeEvent * event);
        //void keyReleaseEvent(QKeyEvent *event);

        enum PageIDs
        {
            ID_PAGE_SETUP_TEAM      =  0,
            ID_PAGE_SETUP           =  1,
            ID_PAGE_MULTIPLAYER     =  2,
            ID_PAGE_DEMOS           =  3,
            ID_PAGE_NET             =  4,
            ID_PAGE_NETGAME         =  5,
            ID_PAGE_INFO            =  6,
            ID_PAGE_MAIN            =  7,
            ID_PAGE_GAMESTATS       =  8,
            ID_PAGE_SINGLEPLAYER    =  9,
            ID_PAGE_TRAINING        = 10,
            ID_PAGE_SELECTWEAPON    = 11,
            ID_PAGE_NETSERVER       = 12,
            ID_PAGE_INGAME          = 13,
            ID_PAGE_ROOMSLIST       = 14,
            ID_PAGE_CONNECTING      = 15,
            ID_PAGE_SCHEME          = 16,
            ID_PAGE_ADMIN           = 17,
            ID_PAGE_NETTYPE         = 18,
            ID_PAGE_CAMPAIGN        = 19,
            ID_PAGE_DRAWMAP         = 20,
            ID_PAGE_DATADOWNLOAD    = 21,
            ID_PAGE_FEEDBACK        = 22
        };
        QPointer<HWGame> game;
        QPointer<HWNetServer> pnetserver;
        QPointer<HWNetRegisterServer> pRegisterServer;
        QPointer<HWTeam> editedTeam;
        QPointer<HWNewNet> hwnet;
        HWNamegen * namegen;
        AmmoSchemeModel * ammoSchemeModel;
        QStack<int> PagesStack;
        QTime eggTimer;
        BGWidget * wBackground;
        QSignalMapper * pageSwitchMapper;
        QByteArray m_lastDemo;
        QNetworkAccessManager * nam;
        QString issueXml;
        QString authToken;

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
