/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QMessageBox>
#include <QPushButton>
#include <QListWidget>
#include <QStackedLayout>
#include <QLineEdit>
#include <QLabel>
#include <QRadioButton>
#include <QSpinBox>
#include <QCloseEvent>
#include <QCheckBox>
#include <QTextBrowser>
#include <QAction>
#include <QTimer>
#include <QScrollBar>
#include <QDataWidgetMapper>
#include <QTableView>
#include <QCryptographicHash>
#include <QSignalMapper>
#include <QShortcut>
#include <QDesktopServices>
#include <QInputDialog>
#include <QPropertyAnimation>
#include <QSettings>

#if (QT_VERSION >= 0x040600)
#include <QGraphicsEffect>
#include <QParallelAnimationGroup>
#endif

#include "hwform.h"
#include "game.h"
#include "team.h"
#include "campaign.h"
#include "teamselect.h"
#include "selectWeapon.h"
#include "gameuiconfig.h"
#include "pageinfo.h"
#include "pagetraining.h"
#include "pagesingleplayer.h"
#include "pageselectweapon.h"
#include "pageadmin.h"
#include "pagecampaign.h"
#include "pagescheme.h"
#include "pagenetgame.h"
#include "pageroomslist.h"
#include "pageconnecting.h"
#include "pageoptions.h"
#include "pageeditteam.h"
#include "pagemultiplayer.h"
#include "pagenet.h"
#include "pagemain.h"
#include "pagefeedback.h"
#include "pagenetserver.h"
#include "pagedrawmap.h"
#include "pagenettype.h"
#include "pagegamestats.h"
#include "pageplayrecord.h"
#include "pagedata.h"
#include "pagevideos.h"
#include "hwconsts.h"
#include "newnetclient.h"
#include "gamecfgwidget.h"
#include "netserverslist.h"
#include "netudpserver.h"
#include "chatwidget.h"
#include "input_ip.h"
#include "input_password.h"
#include "ammoSchemeModel.h"
#include "bgwidget.h"
#include "xfire.h"
#include "drawmapwidget.h"
#include "mouseoverfilter.h"
#include "roomslistmodel.h"
#include "recorder.h"
#include "playerslistmodel.h"

#include "DataManager.h"

#ifdef __APPLE__
#include "M3Panel.h"
#ifdef SPARKLE_ENABLED
#define SPARKLE_APPCAST_URL "http://www.hedgewars.org/download/appcast.xml"
#include "SparkleAutoUpdater.h"
#endif
#endif


// I started handing this down to each place it touches, but it was getting ridiculous
// and this one flag does not warrant a static class
bool frontendEffects = true;
QString playerHash;

GameUIConfig* HWForm::config = NULL;
QSettings* HWForm::gameSettings = NULL;

HWForm::HWForm(QWidget *parent, QString styleSheet)
    : QMainWindow(parent)
    , game(0)
    , pnetserver(0)
    , pRegisterServer(0)
    , editedTeam(0)
    , hwnet(0)
{
    // set music track
    SDLInteraction::instance().setMusicTrack(
        DataManager::instance().findFileForRead("Music/main_theme.ogg")
    );

#ifdef USE_XFIRE
    xfire_init();
#endif
    gameSettings = new QSettings(cfgdir->absolutePath() + "/hedgewars.ini", QSettings::IniFormat);
    frontendEffects = gameSettings->value("frontend/effects", true).toBool();
    playerHash = QString(QCryptographicHash::hash(gameSettings->value("net/nick","").toString().toUtf8(), QCryptographicHash::Md5).toHex());

    this->setStyleSheet(styleSheet);
    ui.setupUi(this);
    setMinimumSize(760, 580);
    //setFocusPolicy(Qt::StrongFocus);
    CustomizePalettes();

    ui.pageOptions->CBResolution->addItems(SDLInteraction::instance().getResolutions());

    config = new GameUIConfig(this, cfgdir->absolutePath() + "/hedgewars.ini");

    ui.pageVideos->init(config);

#ifdef __APPLE__
    panel = new M3Panel;

#ifdef SPARKLE_ENABLED
    AutoUpdater* updater;

    updater = new SparkleAutoUpdater(SPARKLE_APPCAST_URL);
    if (updater && config->isAutoUpdateEnabled())
        updater->checkForUpdates();
#endif

    QShortcut *hideFrontend = new QShortcut(QKeySequence("Ctrl+M"), this);
    connect (hideFrontend, SIGNAL(activated()), this, SLOT(showMinimized()));
#else
    // ctrl+q closes frontend for consistency
    QShortcut * closeFrontend = new QShortcut(QKeySequence("Ctrl+Q"), this);
    connect (closeFrontend, SIGNAL(activated()), this, SLOT(close()));
    QShortcut * updateData = new QShortcut(QKeySequence("F5"), this);
    connect (updateData, SIGNAL(activated()), &DataManager::instance(), SLOT(reload()));
#endif

    UpdateTeamsLists();
    InitCampaignPage();
    UpdateCampaignPage(0);
    UpdateWeapons();

    // connect all goBack signals
    int nPages = ui.Pages->count();

    for (int i = 0; i < nPages; i++)
        connect(ui.Pages->widget(i), SIGNAL(goBack()), this, SLOT(GoBack()));

    pageSwitchMapper = new QSignalMapper(this);
    connect(pageSwitchMapper, SIGNAL(mapped(int)), this, SLOT(GoToPage(int)));

    connect(config, SIGNAL(frontendFullscreen(bool)), this, SLOT(onFrontendFullscreen(bool)));
    onFrontendFullscreen(config->isFrontendFullscreen());

    connect(ui.pageMain->BtnSinglePlayer, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageMain->BtnSinglePlayer, ID_PAGE_SINGLEPLAYER);

    connect(ui.pageMain->BtnSetup, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageMain->BtnSetup, ID_PAGE_SETUP);

    connect(ui.pageMain->BtnFeedback, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageMain->BtnFeedback, ID_PAGE_FEEDBACK);

    connect(ui.pageMain->BtnNet, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageMain->BtnNet, ID_PAGE_NETTYPE);

    connect(ui.pageMain->BtnInfo, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageMain->BtnInfo, ID_PAGE_INFO);

    connect(ui.pageMain->BtnDataDownload, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageMain->BtnDataDownload, ID_PAGE_DATADOWNLOAD);

    connect(ui.pageNetGame, SIGNAL(DLCClicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageNetGame, ID_PAGE_DATADOWNLOAD);

#ifdef VIDEOREC
    connect(ui.pageMain->BtnVideos, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageMain->BtnVideos, ID_PAGE_VIDEOS);
#endif

    //connect(ui.pageMain->BtnExit, SIGNAL(pressed()), this, SLOT(btnExitPressed()));
    //connect(ui.pageMain->BtnExit, SIGNAL(clicked()), this, SLOT(btnExitClicked()));

    connect(ui.pageFeedback->BtnSend, SIGNAL(clicked()), this, SLOT(SendFeedback()));

    connect(ui.pageEditTeam, SIGNAL(goBack()), this, SLOT(AfterTeamEdit()));

    connect(ui.pageMultiplayer->BtnStartMPGame, SIGNAL(clicked()), this, SLOT(StartMPGame()));
    connect(ui.pageMultiplayer->teamsSelect, SIGNAL(setEnabledGameStart(bool)),
            ui.pageMultiplayer->BtnStartMPGame, SLOT(setEnabled(bool)));
    connect(ui.pageMultiplayer, SIGNAL(SetupClicked()), this, SLOT(IntermediateSetup()));
    connect(ui.pageMultiplayer->gameCFG, SIGNAL(goToSchemes(int)), this, SLOT(GoToScheme(int)));
    connect(ui.pageMultiplayer->gameCFG, SIGNAL(goToWeapons(int)), this, SLOT(GoToSelectWeaponSet(int)));
    connect(ui.pageMultiplayer->gameCFG, SIGNAL(goToDrawMap()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageMultiplayer->gameCFG, ID_PAGE_DRAWMAP);


    connect(ui.pagePlayDemo->BtnPlayDemo, SIGNAL(clicked()), this, SLOT(PlayDemo()));
    connect(ui.pagePlayDemo->DemosList, SIGNAL(doubleClicked (const QModelIndex &)), this, SLOT(PlayDemo()));

    connect(ui.pageOptions, SIGNAL(newTeamRequested()), this, SLOT(NewTeam()));
    connect(ui.pageOptions, SIGNAL(editTeamRequested(const QString&)), this, SLOT(EditTeam(const QString&)));
    connect(ui.pageOptions, SIGNAL(deleteTeamRequested(const QString&)), this, SLOT(DeleteTeam(const QString&)));
    connect(ui.pageOptions, SIGNAL(goBack()), config, SLOT(SaveOptions()));
    connect(ui.pageOptions->BtnAssociateFiles, SIGNAL(clicked()), this, SLOT(AssociateFiles()));

    connect(ui.pageOptions->WeaponEdit, SIGNAL(clicked()), this, SLOT(GoToSelectWeapon()));
    connect(ui.pageOptions->WeaponNew, SIGNAL(clicked()), this, SLOT(GoToSelectNewWeapon()));
    connect(ui.pageOptions->WeaponDelete, SIGNAL(clicked()), this, SLOT(DeleteWeaponSet()));
    connect(ui.pageOptions->SchemeEdit, SIGNAL(clicked()), this, SLOT(GoToEditScheme()));
    connect(ui.pageOptions->SchemeNew, SIGNAL(clicked()), this, SLOT(GoToNewScheme()));
    connect(ui.pageOptions->SchemeDelete, SIGNAL(clicked()), this, SLOT(DeleteScheme()));
    connect(ui.pageOptions->CBFrontendEffects, SIGNAL(toggled(bool)), this, SLOT(onFrontendEffects(bool)) );
    connect(ui.pageSelectWeapon->pWeapons, SIGNAL(weaponsChanged()), this, SLOT(UpdateWeapons()));

    connect(ui.pageNet->BtnSpecifyServer, SIGNAL(clicked()), this, SLOT(NetConnect()));
    connect(ui.pageNet->BtnNetSvrStart, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageNet->BtnNetSvrStart, ID_PAGE_NETSERVER);

    connect(ui.pageNet, SIGNAL(connectClicked(const QString &, quint16)), this, SLOT(NetConnectServer(const QString &, quint16)));

    connect(ui.pageNetServer->BtnStart, SIGNAL(clicked()), this, SLOT(NetStartServer()));

    connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(setEnabledGameStart(bool)),
            ui.pageNetGame->BtnStart, SLOT(setEnabled(bool)));
    connect(ui.pageNetGame, SIGNAL(SetupClicked()), this, SLOT(IntermediateSetup()));
    connect(ui.pageNetGame->pGameCFG, SIGNAL(goToSchemes(int)), this, SLOT(GoToScheme(int)));
    connect(ui.pageNetGame->pGameCFG, SIGNAL(goToWeapons(int)), this, SLOT(GoToSelectWeaponSet(int)));
    connect(ui.pageNetGame->pGameCFG, SIGNAL(goToDrawMap()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageNetGame->pGameCFG, ID_PAGE_DRAWMAP);

    connect(ui.pageRoomsList->BtnAdmin, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageRoomsList->BtnAdmin, ID_PAGE_ADMIN);

    connect(ui.pageInfo->BtnSnapshots, SIGNAL(clicked()), this, SLOT(OpenSnapshotFolder()));

    connect(ui.pageGameStats, SIGNAL(saveDemoRequested()), this, SLOT(saveDemoWithCustomName()));

    connect(ui.pageSinglePlayer->BtnSimpleGamePage, SIGNAL(clicked()), this, SLOT(SimpleGame()));
    connect(ui.pageSinglePlayer->BtnTrainPage, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageSinglePlayer->BtnTrainPage, ID_PAGE_TRAINING);

    connect(ui.pageSinglePlayer->BtnCampaignPage, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageSinglePlayer->BtnCampaignPage, ID_PAGE_CAMPAIGN);

    connect(ui.pageSinglePlayer->BtnMultiplayer, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageSinglePlayer->BtnMultiplayer, ID_PAGE_MULTIPLAYER);

    connect(ui.pageSinglePlayer->BtnLoad, SIGNAL(clicked()), this, SLOT(GoToSaves()));
    connect(ui.pageSinglePlayer->BtnDemos, SIGNAL(clicked()), this, SLOT(GoToDemos()));

    connect(ui.pageTraining, SIGNAL(startMission(const QString&)), this, SLOT(startTraining(const QString&)));

    connect(ui.pageCampaign->BtnStartCampaign, SIGNAL(clicked()), this, SLOT(StartCampaign()));
    connect(ui.pageCampaign->CBTeam, SIGNAL(currentIndexChanged(int)), this, SLOT(UpdateCampaignPage(int)));
    connect(ui.pageCampaign->CBCampaign, SIGNAL(currentIndexChanged(int)), this, SLOT(UpdateCampaignPage(int)));


    connect(ui.pageSelectWeapon->BtnDelete, SIGNAL(clicked()),
            ui.pageSelectWeapon->pWeapons, SLOT(deleteWeaponsName())); // executed first
    connect(ui.pageSelectWeapon->pWeapons, SIGNAL(weaponsDeleted()),
            this, SLOT(UpdateWeapons())); // executed second
    //connect(ui.pageSelectWeapon->pWeapons, SIGNAL(weaponsDeleted()),
    //    this, SLOT(GoBack())); // executed third


    connect(ui.pageNetType->BtnLAN, SIGNAL(clicked()), this, SLOT(GoToNet()));
    connect(ui.pageNetType->BtnOfficialServer, SIGNAL(clicked()), this, SLOT(NetConnectOfficialServer()));

    connect(ui.pageConnecting, SIGNAL(cancelConnection()), this, SLOT(GoBack()));

    connect(ui.pageVideos, SIGNAL(goBack()), config, SLOT(SaveVideosOptions()));

    ammoSchemeModel = new AmmoSchemeModel(this, cfgdir->absolutePath() + "/schemes.ini");
    ui.pageScheme->setModel(ammoSchemeModel);
    ui.pageMultiplayer->gameCFG->GameSchemes->setModel(ammoSchemeModel);
    ui.pageOptions->SchemesName->setModel(ammoSchemeModel);

    wBackground = new BGWidget(this);
    wBackground->setFixedSize(this->width(), this->height());
    wBackground->lower();
    wBackground->init();
    wBackground->enabled = config->isFrontendEffects();
    wBackground->startAnimation();

    //Install all eventFilters :

    MouseOverFilter *filter = new MouseOverFilter();
    filter->setUi(&ui);

    QList<QWidget *> widgets;

    for (int i=0; i < ui.Pages->count(); i++)
    {
        widgets = ui.Pages->widget(i)->findChildren<QWidget *>();

        for (int i=0; i < widgets.size(); i++)
        {
            widgets.at(i)->installEventFilter(filter);
        }
    }

    PagesStack.push(ID_PAGE_MAIN);
    GoBack();
}

#ifdef USE_XFIRE
void HWForm::updateXfire(void)
{
    if(hwnet && (hwnet->clientState() != HWNewNet::Disconnected))
    {
        xfire_setvalue(XFIRE_SERVER, !hwnet->getHost().compare("netserver.hedgewars.org:46631") ? "Official server" : hwnet->getHost().toAscii());
        switch(hwnet->clientState())
        {
            case HWNewNet::Connecting: // Connecting
            case HWNewNet::Connected:
                xfire_setvalue(XFIRE_STATUS, "Connecting");
                xfire_setvalue(XFIRE_NICKNAME, "-");
                xfire_setvalue(XFIRE_ROOM, "-");
            case HWNewNet::InLobby: // In lobby
                xfire_setvalue(XFIRE_STATUS, "Online");
                xfire_setvalue(XFIRE_NICKNAME, hwnet->getNick().toAscii());
                xfire_setvalue(XFIRE_ROOM, "In game lobby");
                break;
            case HWNewNet::InRoom: // In room
                xfire_setvalue(XFIRE_STATUS, "Online");
                xfire_setvalue(XFIRE_NICKNAME, hwnet->getNick().toAscii());
                xfire_setvalue(XFIRE_ROOM, (hwnet->getRoom() + " (waiting for players)").toAscii());
                break;
            case HWNewNet::InGame: // In game
                xfire_setvalue(XFIRE_STATUS, "Online");
                xfire_setvalue(XFIRE_NICKNAME, hwnet->getNick().toAscii());
                xfire_setvalue(XFIRE_ROOM, (hwnet->getRoom() + " (playing or spectating)").toAscii());
                break;
            default:
                break;
        }
    }
    else
    {
        xfire_setvalue(XFIRE_STATUS, "Offline");
        xfire_setvalue(XFIRE_NICKNAME, "-");
        xfire_setvalue(XFIRE_ROOM, "-");
        xfire_setvalue(XFIRE_SERVER, "-");
    }
    xfire_update();
}
#endif

void HWForm::onFrontendFullscreen(bool value)
{
    if (value)
        setWindowState(windowState() | Qt::WindowFullScreen);
    else
    {
        setWindowState(windowState() & static_cast<int>(!Qt::WindowFullScreen));
    }
}

void HWForm::onFrontendEffects(bool value)
{
    wBackground->enabled = value;
    if (value)
        wBackground->startAnimation();
    else
        wBackground->stopAnimation();
}

/*
void HWForm::keyReleaseEvent(QKeyEvent *event)
{
  if (event->key() == Qt::Key_Escape)
    this->GoBack();
}
*/

void HWForm::CustomizePalettes()
{
    QList<QScrollBar *> allSBars = findChildren<QScrollBar *>();
    QPalette pal = palette();
    pal.setColor(QPalette::WindowText, QColor(0xff, 0xcc, 0x00));
    pal.setColor(QPalette::Button, QColor(0x00, 0x35, 0x1d));
    pal.setColor(QPalette::Base, QColor(0x00, 0x35, 0x1d));
    pal.setColor(QPalette::Window, QColor(0x00, 0x00, 0x00));

    for (int i = 0; i < allSBars.size(); ++i)
        allSBars.at(i)->setPalette(pal);
}

void HWForm::UpdateWeapons()
{
    QVector<QComboBox*> combos;
    combos.push_back(ui.pageOptions->WeaponsName);
    combos.push_back(ui.pageMultiplayer->gameCFG->WeaponsName);
    combos.push_back(ui.pageNetGame->pGameCFG->WeaponsName);
    combos.push_back(ui.pageSelectWeapon->selectWeaponSet);

    QStringList names = ui.pageSelectWeapon->pWeapons->getWeaponNames();

    for(QVector<QComboBox*>::iterator it = combos.begin(); it != combos.end(); ++it)
    {
        (*it)->clear();

        for(int i = 0; i < names.size(); ++i)
            (*it)->addItem(names[i], ui.pageSelectWeapon->pWeapons->getWeaponsString(names[i]));

        int pos = (*it)->findText("Default");
        if (pos != -1)
        {
            (*it)->setCurrentIndex(pos);
        }
    }
}

void HWForm::UpdateTeamsLists(const QStringList* editable_teams)
{
    QStringList teamslist;
    if(editable_teams)
    {
        teamslist =* editable_teams;
    }
    else
    {
        teamslist = config->GetTeamsList();
    }

    if(teamslist.empty())
    {
        HWTeam defaultTeam(tr("DefaultTeam"));
        defaultTeam.saveToFile();
        teamslist.push_back(tr("DefaultTeam"));
    }

    ui.pageOptions->CBTeamName->clear();
    ui.pageOptions->CBTeamName->addItems(teamslist);
    ui.pageCampaign->CBTeam->clear();
    ui.pageCampaign->CBTeam->addItems(teamslist);
}

void HWForm::GoToSelectNewWeapon()
{
    ui.pageSelectWeapon->pWeapons->newWeaponsName();
    GoToPage(ID_PAGE_SELECTWEAPON);
}

void HWForm::GoToSelectWeapon()
{
    ui.pageSelectWeapon->selectWeaponSet->setCurrentIndex(ui.pageOptions->WeaponsName->currentIndex());
    GoToPage(ID_PAGE_SELECTWEAPON);
}

void HWForm::GoToSelectWeaponSet(int index)
{
    ui.pageSelectWeapon->selectWeaponSet->setCurrentIndex(index);
    GoToPage(ID_PAGE_SELECTWEAPON);
}

void HWForm::GoToSaves()
{
    ui.pagePlayDemo->FillFromDir(PagePlayDemo::RT_Save);

    GoToPage(ID_PAGE_DEMOS);
}

void HWForm::GoToDemos()
{
    ui.pagePlayDemo->FillFromDir(PagePlayDemo::RT_Demo);

    GoToPage(ID_PAGE_DEMOS);
}

void HWForm::GoToNet()
{
    ui.pageNet->updateServersList();

    GoToPage(ID_PAGE_NET);
}

void HWForm::GoToScheme(int index)
{
    ui.pageScheme->selectScheme->setCurrentIndex(index);
    GoToPage(ID_PAGE_SCHEME);
}

void HWForm::GoToNewScheme()
{
    ui.pageScheme->newRow();
    GoToPage(ID_PAGE_SCHEME);
}

void HWForm::GoToEditScheme()
{
    ui.pageScheme->selectScheme->setCurrentIndex(ui.pageOptions->SchemesName->currentIndex());
    GoToPage(ID_PAGE_SCHEME);
}

void HWForm::GoToVideos()
{
    GoToPage(ID_PAGE_VIDEOS);
}

void HWForm::OnPageShown(quint8 id, quint8 lastid)
{
#ifdef USE_XFIRE
    updateXfire();
#endif
    if (id == ID_PAGE_DATADOWNLOAD)
    {
        ui.pageDataDownload->fetchList();
    }
    if (id == ID_PAGE_DRAWMAP)
    {
        DrawMapScene * scene;
        if(lastid == ID_PAGE_MULTIPLAYER)
            scene = ui.pageMultiplayer->gameCFG->pMapContainer->getDrawMapScene();
        else
            scene = ui.pageNetGame->pGameCFG->pMapContainer->getDrawMapScene();

        ui.pageDrawMap->drawMapWidget->setScene(scene);
    }

    if (lastid == ID_PAGE_DRAWMAP)
    {
        if (id == ID_PAGE_MULTIPLAYER)
            ui.pageMultiplayer->gameCFG->pMapContainer->mapDrawingFinished();
        else
            ui.pageNetGame->pGameCFG->pMapContainer->mapDrawingFinished();
    }

    if (id == ID_PAGE_ROOMSLIST)
    {
        if (hwnet && game && game->gameState == gsStarted)   // abnormal exit - kick or room destruction - send kills.
        {
            game->netSuspend = true;
            ui.pageRoomsList->displayWarning(tr("Game aborted"));
            game->abort();
        }
    }

    if (id == ID_PAGE_MULTIPLAYER || id == ID_PAGE_NETGAME)
    {
        QStringList tmNames = config->GetTeamsList();
        TeamSelWidget* curTeamSelWidget;
        ui.pageOptions->setTeamOptionsEnabled(false);

        if (id == ID_PAGE_MULTIPLAYER)
        {
            curTeamSelWidget = ui.pageMultiplayer->teamsSelect;
        }
        else
        {
            curTeamSelWidget = ui.pageNetGame->pNetTeamsWidget;
        }

        QList<HWTeam> teamsList;
        for (QStringList::iterator it = tmNames.begin(); it != tmNames.end(); it++)
        {
            HWTeam team(*it);
            team.loadFromFile();
            teamsList.push_back(team);
        }

        if (lastid == ID_PAGE_SETUP || lastid == ID_PAGE_DRAWMAP)   // _TEAM
        {
            if (editedTeam)
            {
                curTeamSelWidget->addTeam(*editedTeam);
            }
        }
        else if (lastid != ID_PAGE_GAMESTATS
                 && lastid != ID_PAGE_INGAME
                 && lastid != ID_PAGE_SCHEME
                 && lastid != ID_PAGE_SELECTWEAPON)
        {
            curTeamSelWidget->resetPlayingTeams(teamsList);
        }
    }
    else if (id == ID_PAGE_GAMESTATS)
    {
        ui.pageGameStats->renderStats();
    }

    if (id == ID_PAGE_MAIN)
    {
        ui.pageOptions->setTeamOptionsEnabled(true);
    }

    if (id == ID_PAGE_SETUP)
    {
        config->reloadValues();
    }

    if (id == ID_PAGE_VIDEOS )
    {
        config->reloadVideosValues();
    }
}

void HWForm::GoToPage(int id)
{
    bool stopAnim = false;

    int lastid = ui.Pages->currentIndex();
    PagesStack.push(ui.Pages->currentIndex());

    OnPageShown(id, lastid);
    ui.Pages->setCurrentIndex(id);


   /* if (id == ID_PAGE_DRAWMAP || id == ID_PAGE_GAMESTATS)
        stopAnim = true;
	This were disabled due to broken flake animations.  I believe the more general problems w/ opacity that forced its disable makes blocking these
	unnecessary.
   */

#if (QT_VERSION >= 0x040600)
    if (!stopAnim)
    {
        /**Start animation :**/
        int coeff = 1;
#ifdef false
        coeff = 2;
        QGraphicsOpacityEffect *effectNew = new QGraphicsOpacityEffect(ui.Pages->widget(id));
        ui.Pages->widget(id)->setGraphicsEffect(effectNew);

        QGraphicsOpacityEffect *effectLast = new QGraphicsOpacityEffect(ui.Pages->widget(lastid));
        ui.Pages->widget(lastid)->setGraphicsEffect(effectLast);
#endif
        // no effects, means 0 effect duration :D
        int duration = config->isFrontendEffects() ? 500 : 0;

        //New page animation
        animationNewSlide = new QPropertyAnimation(ui.Pages->widget(id), "pos");
        animationNewSlide->setDuration(duration);
        animationNewSlide->setStartValue(QPoint(width()/coeff, 0));
        animationNewSlide->setEndValue(QPoint(0, 0));
        animationNewSlide->setEasingCurve(QEasingCurve::OutExpo);

#ifdef false
        animationNewOpacity = new QPropertyAnimation(effectNew, "opacity");
        animationNewOpacity->setDuration(duration);
        animationNewOpacity->setStartValue(0.01);
        animationNewOpacity->setEndValue(1);
        animationNewOpacity->setEasingCurve(QEasingCurve::OutExpo);
#endif

        //Last page animation
        ui.Pages->widget(lastid)->setHidden(false);

        animationOldSlide = new QPropertyAnimation(ui.Pages->widget(lastid), "pos");
        animationOldSlide->setDuration(duration);
        animationOldSlide->setStartValue(QPoint(0, 0));
        animationOldSlide->setEndValue(QPoint(-width()/coeff, 0));
        animationOldSlide->setEasingCurve(QEasingCurve::OutExpo);

#ifdef false
        animationOldOpacity = new QPropertyAnimation(effectLast, "opacity");
        animationOldOpacity->setDuration(duration);
        animationOldOpacity->setStartValue(1);
        animationOldOpacity->setEndValue(0.01);
        animationOldOpacity->setEasingCurve(QEasingCurve::OutExpo);
#endif

        QParallelAnimationGroup *group = new QParallelAnimationGroup;
        group->addAnimation(animationOldSlide);
        group->addAnimation(animationNewSlide);
#ifdef false
        group->addAnimation(animationOldOpacity);
        group->addAnimation(animationNewOpacity);
#endif
        group->start();

        connect(animationOldSlide, SIGNAL(finished()), ui.Pages->widget(lastid), SLOT(hide()));
    	/* this is for the situation when the animation below is interrupted by a new animation.  For some reason, finished is not being fired */ 	
    	for(int i=0;i<MAX_PAGE;i++) if (i!=id && i!=lastid) ui.Pages->widget(i)->hide();
    }
#endif
}

void HWForm::GoBack()
{
    bool stopAnim = false;
    int curid = ui.Pages->currentIndex();
    if (curid == ID_PAGE_MAIN)
    {
        if (!ui.pageVideos->tryQuit(this))
            return;
        stopAnim = true;
        exit();
    }

    int id = PagesStack.isEmpty() ? ID_PAGE_MAIN : PagesStack.pop();
    ui.Pages->setCurrentIndex(id);
    OnPageShown(id, curid);

    if (id == ID_PAGE_CONNECTING)
    {
        stopAnim = true;
        GoBack();
    }
    if (id == ID_PAGE_NETSERVER)
    {
        stopAnim = true;
        GoBack();
    }
    if ((!hwnet) && (id == ID_PAGE_ROOMSLIST))
    {
        stopAnim = true;
        GoBack();
    }
    /*if (curid == ID_PAGE_DRAWMAP)
        stopAnim = true; */

    if ((!hwnet) || (!hwnet->isInRoom()))
        if (id == ID_PAGE_NETGAME || id == ID_PAGE_NETGAME)
        {
            stopAnim = true;
            GoBack();
        }

    if (curid == ID_PAGE_ROOMSLIST || curid == ID_PAGE_CONNECTING) NetDisconnect();
    if (curid == ID_PAGE_NETGAME && hwnet && hwnet->isInRoom()) hwnet->partRoom();
    // need to work on this, can cause invalid state for admin quit trying to prevent bad state message on kick
    //if (curid == ID_PAGE_NETGAME && (!game || game->gameState != gsStarted)) hwnet->partRoom();

    if (curid == ID_PAGE_SCHEME)
        ammoSchemeModel->Save();

#if (QT_VERSION >= 0x040600)
    /**Start animation :**/
    if (curid != 0 && !stopAnim)
    {
        int coeff = 1;
#ifdef false
        coeff = 2;
        QGraphicsOpacityEffect *effectNew = new QGraphicsOpacityEffect(ui.Pages->widget(id));
        effectNew->setOpacity(1);
        ui.Pages->widget(id)->setGraphicsEffect(effectNew);

        QGraphicsOpacityEffect *effectLast = new QGraphicsOpacityEffect(ui.Pages->widget(curid));
        ui.Pages->widget(curid)->setGraphicsEffect(effectLast);
#endif
        // no effects, means 0 effect duration :D
        int duration = config->isFrontendEffects() ? 500 : 0;

        //Last page animation
        animationOldSlide = new QPropertyAnimation(ui.Pages->widget(id), "pos");
        animationOldSlide->setDuration(duration);
        animationOldSlide->setStartValue(QPoint(-width()/coeff, 0));
        animationOldSlide->setEndValue(QPoint(0, 0));
        animationOldSlide->setEasingCurve(QEasingCurve::OutExpo);

#ifdef false
        animationOldOpacity = new QPropertyAnimation(effectLast, "opacity");
        animationOldOpacity->setDuration(duration);
        animationOldOpacity->setStartValue(1);
        animationOldOpacity->setEndValue(0.01);
        animationOldOpacity->setEasingCurve(QEasingCurve::OutExpo);
#endif
        //New page animation
        ui.Pages->widget(curid)->setHidden(false);

        animationNewSlide = new QPropertyAnimation(ui.Pages->widget(curid), "pos");
        animationNewSlide->setDuration(duration);
        animationNewSlide->setStartValue(QPoint(0, 0));
        animationNewSlide->setEndValue(QPoint(width()/coeff, 0));
        animationNewSlide->setEasingCurve(QEasingCurve::OutExpo);

#ifdef false
        animationNewOpacity = new QPropertyAnimation(effectNew, "opacity");
        animationNewOpacity->setDuration(duration);
        animationNewOpacity->setStartValue(0.01);
        animationNewOpacity->setEndValue(1);
        animationNewOpacity->setEasingCurve(QEasingCurve::OutExpo);
#endif

        QParallelAnimationGroup *group = new QParallelAnimationGroup;
        group->addAnimation(animationOldSlide);
        group->addAnimation(animationNewSlide);
#ifdef false
        group->addAnimation(animationOldOpacity);
        group->addAnimation(animationNewOpacity);
#endif
        group->start();

        connect(animationNewSlide, SIGNAL(finished()), ui.Pages->widget(curid), SLOT(hide()));
    }
#endif
}

void HWForm::OpenSnapshotFolder()
{
    QString path = QDir::toNativeSeparators(cfgdir->absolutePath() + "/Screenshots");
    QDesktopServices::openUrl(QUrl("file:///" + path));
}

void HWForm::btnExitPressed()
{
    eggTimer.start();
}

void HWForm::exit()
{
//   if (eggTimer.elapsed() < 3000){
#ifdef __APPLE__
    panel->showInstallController();
#endif
    close();
// TODO reactivate egg
    /*    }
        else
        {
            QPushButton * btn = findChild<QPushButton *>("imageButt");
            if (btn)
            {
                btn->setIcon(QIcon(":/res/bonus.png"));
            }
        } */
}

void HWForm::IntermediateSetup()
{
    quint8 id=ui.Pages->currentIndex();
    TeamSelWidget* curTeamSelWidget;

    if(id == ID_PAGE_MULTIPLAYER)
    {
        curTeamSelWidget = ui.pageMultiplayer->teamsSelect;
    }
    else
    {
        curTeamSelWidget = ui.pageNetGame->pNetTeamsWidget;
    }

    QStringList tmnames;

    foreach(HWTeam team, curTeamSelWidget->getNotPlayingTeams())
    tmnames += team.name();

    //UpdateTeamsLists(&tmnames); // FIXME: still need more work if teamname is updated while configuring
    UpdateTeamsLists();

    GoToPage(ID_PAGE_SETUP);
}

void HWForm::NewTeam()
{
    ui.pageEditTeam->createTeam(QLineEdit::tr("unnamed"), playerHash);
    UpdateTeamsLists();
    GoToPage(ID_PAGE_SETUP_TEAM);
}

void HWForm::EditTeam(const QString & teamName)
{
    ui.pageEditTeam->editTeam(teamName, playerHash);
    GoToPage(ID_PAGE_SETUP_TEAM);
}

void HWForm::AfterTeamEdit()
{
    UpdateTeamsLists();
    //GoBack();
}


void HWForm::DeleteTeam(const QString & teamName)
{
    QMessageBox reallyDeleteMsg(this);
    reallyDeleteMsg.setIcon(QMessageBox::Question);
    reallyDeleteMsg.setWindowTitle(QMessageBox::tr("Teams - Are you sure?"));
    reallyDeleteMsg.setText(QMessageBox::tr("Do you really want to delete the team '%1'?").arg(teamName));
    reallyDeleteMsg.setWindowModality(Qt::WindowModal);
    reallyDeleteMsg.setStandardButtons(QMessageBox::Ok | QMessageBox::Cancel);

    if (reallyDeleteMsg.exec() == QMessageBox::Ok)
    {
        ui.pageEditTeam->deleteTeam(teamName);
        UpdateTeamsLists();
    }
}

void HWForm::DeleteScheme()
{
    ui.pageScheme->selectScheme->setCurrentIndex(ui.pageOptions->SchemesName->currentIndex());
    if (ui.pageOptions->SchemesName->currentIndex() < ammoSchemeModel->numberOfDefaultSchemes)
    {
        ShowErrorMessage(QMessageBox::tr("Cannot delete default scheme '%1'!").arg(ui.pageOptions->SchemesName->currentText()));
    }
    else
    {
        ui.pageScheme->deleteRow();
        ammoSchemeModel->Save();
    }
}

void HWForm::DeleteWeaponSet()
{
    ui.pageSelectWeapon->selectWeaponSet->setCurrentIndex(ui.pageOptions->WeaponsName->currentIndex());
    ui.pageSelectWeapon->pWeapons->deleteWeaponsName();
}

void HWForm::SimpleGame()
{
    CreateGame(0, 0, *cDefaultAmmoStore);
    game->StartQuick();
}

void HWForm::PlayDemo()
{
    QListWidgetItem * curritem = ui.pagePlayDemo->DemosList->currentItem();
    if (!curritem)
    {
        ShowErrorMessage(QMessageBox::tr("Please select a record from the list"));
        return;
    }
    CreateGame(0, 0, 0);
    game->PlayDemo(curritem->data(Qt::UserRole).toString(), ui.pagePlayDemo->isSave());
}

void HWForm::PlayDemoQuick(const QString & demofilename)
{
    if (game && game->gameState == gsStarted) return;
    GoBack(); //needed to cleanly disconnect from netgame
    GoToPage(ID_PAGE_MAIN);
    CreateGame(0, 0, 0);
    game->PlayDemo(demofilename, false);
}

void HWForm::NetConnectServer(const QString & host, quint16 port)
{
    _NetConnect(host, port, ui.pageOptions->editNetNick->text().trimmed());
}

void HWForm::NetConnectOfficialServer()
{
    NetConnectServer("netserver.hedgewars.org", 46631);
}

void HWForm::NetPassword(const QString & nick)
{
    int passLength = config->value("net/passwordlength", 0).toInt();
    QString hash = config->value("net/passwordhash", "").toString();

    // If the password is blank, ask the user to enter one in
    if (passLength == 0)
    {
        HWPasswordDialog * hpd = new HWPasswordDialog(this, tr("Your nickname %1 is\nregistered on Hedgewars.org\nPlease provide your password below\nor pick another nickname in game config:").arg(nick));
        hpd->cbSave->setChecked(config->value("net/savepassword", true).toBool());
        if (hpd->exec() != QDialog::Accepted)
        {
            ForcedDisconnect(tr("No password supplied."));
            delete hpd;
            return;
        }

        QString password = hpd->lePassword->text();
        hash = QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Md5).toHex();

        bool save = hpd->cbSave->isChecked();
        config->setValue("net/savepassword", save);
        if (save) // user wants to save password
        {
            config->setValue("net/passwordhash", hash);
            config->setValue("net/passwordlength", password.size());
            config->setNetPasswordLength(password.size());
        }

        delete hpd;
    }

    hwnet->SendPasswordHash(hash);
}

void HWForm::NetNickTaken(const QString & nick)
{
    bool ok = false;
    QString newNick = QInputDialog::getText(this, tr("Nickname"), tr("Some one already uses\n your nickname %1\non the server.\nPlease pick another nickname:").arg(nick), QLineEdit::Normal, nick, &ok);

    if (!ok || newNick.isEmpty())
    {
        ForcedDisconnect(tr("No nickname supplied."));
        return;
    }

    hwnet->NewNick(newNick);
    config->setValue("net/nick", newNick);
    config->updNetNick();

    ui.pageRoomsList->setUser(nick);
    ui.pageNetGame->setUser(nick);
}

void HWForm::NetAuthFailed()
{
    // Set the password blank if case the user tries to join and enter his password again
    config->setValue("net/passwordlength", 0);
    config->setNetPasswordLength(0);
}

void HWForm::NetTeamAccepted(const QString & team)
{
    ui.pageNetGame->pNetTeamsWidget->changeTeamStatus(team);
}

void HWForm::NetError(const QString & errmsg)
{
    switch (ui.Pages->currentIndex())
    {
        case ID_PAGE_INGAME:
            ShowErrorMessage(errmsg);
            // no break
        case ID_PAGE_NETGAME:
            ui.pageNetGame->displayError(errmsg);
            break;
        default:
            ui.pageRoomsList->displayError(errmsg);
    }
}

void HWForm::NetWarning(const QString & wrnmsg)
{
    if (ui.Pages->currentIndex() == ID_PAGE_NETGAME || ui.Pages->currentIndex() == ID_PAGE_INGAME)
        ui.pageNetGame->displayWarning(wrnmsg);
    else
        ui.pageRoomsList->displayWarning(wrnmsg);
}

void HWForm::_NetConnect(const QString & hostName, quint16 port, QString nick)
{
    if(hwnet)
    {
        hwnet->Disconnect();
        delete hwnet;
        hwnet=0;
    }

    hwnet = new HWNewNet();

    GoToPage(ID_PAGE_CONNECTING);

    connect(hwnet, SIGNAL(AskForRunGame()), this, SLOT(CreateNetGame()), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(connected()), this, SLOT(NetConnected()), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(Error(const QString&)), this, SLOT(NetError(const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(Warning(const QString&)), this, SLOT(NetWarning(const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(EnteredGame()), this, SLOT(NetGameEnter()), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(LeftRoom(const QString&)), this, SLOT(NetLeftRoom(const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(AddNetTeam(const HWTeam&)), this, SLOT(AddNetTeam(const HWTeam&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(RemoveNetTeam(const HWTeam&)), this, SLOT(RemoveNetTeam(const HWTeam&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(TeamAccepted(const QString&)), this, SLOT(NetTeamAccepted(const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(AskForPassword(const QString&)), this, SLOT(NetPassword(const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(NickTaken(const QString&)), this, SLOT(NetNickTaken(const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(AuthFailed()), this, SLOT(NetAuthFailed()), Qt::QueuedConnection);
    //connect(ui.pageNetGame->BtnBack, SIGNAL(clicked()), hwnet, SLOT(partRoom()));

    ui.pageRoomsList->chatWidget->setUsersModel(hwnet->lobbyPlayersModel());
    ui.pageNetGame->pChatWidget->setUsersModel(hwnet->roomPlayersModel());

// rooms list page stuff
    ui.pageRoomsList->setModel(hwnet->roomsListModel());
    connect(hwnet, SIGNAL(adminAccess(bool)),
            ui.pageRoomsList, SLOT(setAdmin(bool)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(adminAccess(bool)),
            ui.pageRoomsList->chatWidget, SLOT(adminAccess(bool)), Qt::QueuedConnection);

    connect(hwnet, SIGNAL(serverMessage(const QString&)),
            ui.pageRoomsList->chatWidget, SLOT(onServerMessage(const QString&)), Qt::QueuedConnection);

    connect(ui.pageRoomsList, SIGNAL(askForCreateRoom(const QString &)),
            hwnet, SLOT(CreateRoom(const QString&)));
    connect(ui.pageRoomsList, SIGNAL(askForJoinRoom(const QString &)),
            hwnet, SLOT(JoinRoom(const QString&)));
//  connect(ui.pageRoomsList, SIGNAL(askForCreateRoom(const QString &)),
//      this, SLOT(NetGameMaster()));
//  connect(ui.pageRoomsList, SIGNAL(askForJoinRoom(const QString &)),
//      this, SLOT(NetGameSlave()));
    connect(ui.pageRoomsList, SIGNAL(askForRoomList()),
            hwnet, SLOT(askRoomsList()));

// room status stuff
    connect(hwnet, SIGNAL(roomMaster(bool)),
            this, SLOT(NetGameChangeStatus(bool)), Qt::QueuedConnection);

// net page stuff
    connect(hwnet, SIGNAL(chatStringFromNet(const QString&)),
            ui.pageNetGame->pChatWidget, SLOT(onChatString(const QString&)), Qt::QueuedConnection);

    connect(hwnet, SIGNAL(chatStringFromMe(const QString&)),
            ui.pageNetGame->pChatWidget, SLOT(onChatString(const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(roomMaster(bool)),
            ui.pageNetGame->pChatWidget, SLOT(adminAccess(bool)), Qt::QueuedConnection);
    connect(ui.pageNetGame->pChatWidget, SIGNAL(chatLine(const QString&)),
            hwnet, SLOT(chatLineToNet(const QString&)));
    connect(ui.pageNetGame->BtnGo, SIGNAL(clicked()), hwnet, SLOT(ToggleReady()));
    connect(hwnet, SIGNAL(setMyReadyStatus(bool)),
            ui.pageNetGame, SLOT(setReadyStatus(bool)), Qt::QueuedConnection);

// chat widget actions
    connect(ui.pageNetGame->pChatWidget, SIGNAL(kick(const QString&)),
            hwnet, SLOT(kickPlayer(const QString&)));
    connect(ui.pageNetGame->pChatWidget, SIGNAL(ban(const QString&)),
            hwnet, SLOT(banPlayer(const QString&)));
    connect(ui.pageNetGame->pChatWidget, SIGNAL(info(const QString&)),
            hwnet, SLOT(infoPlayer(const QString&)));
    connect(ui.pageNetGame->pChatWidget, SIGNAL(follow(const QString&)),
            hwnet, SLOT(followPlayer(const QString&)));
    connect(ui.pageRoomsList->chatWidget, SIGNAL(kick(const QString&)),
            hwnet, SLOT(kickPlayer(const QString&)));
    connect(ui.pageRoomsList->chatWidget, SIGNAL(ban(const QString&)),
            hwnet, SLOT(banPlayer(const QString&)));
    connect(ui.pageRoomsList->chatWidget, SIGNAL(info(const QString&)),
            hwnet, SLOT(infoPlayer(const QString&)));
    connect(ui.pageRoomsList->chatWidget, SIGNAL(follow(const QString&)),
            hwnet, SLOT(followPlayer(const QString&)));

// chatting
    connect(ui.pageRoomsList->chatWidget, SIGNAL(chatLine(const QString&)),
            hwnet, SLOT(chatLineToLobby(const QString&)));
    connect(hwnet, SIGNAL(chatStringLobby(const QString&)),
            ui.pageRoomsList->chatWidget, SLOT(onChatString(const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(chatStringLobby(const QString&, const QString&)),
            ui.pageRoomsList->chatWidget, SLOT(onChatString(const QString&, const QString&)));
    connect(hwnet, SIGNAL(chatStringFromMeLobby(const QString&)),
            ui.pageRoomsList->chatWidget, SLOT(onChatString(const QString&)), Qt::QueuedConnection);

// nick list stuff
    connect(hwnet, SIGNAL(nickAdded(const QString&, bool)),
            ui.pageNetGame->pChatWidget, SLOT(nickAdded(const QString&, bool)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(nickRemoved(const QString&)),
            ui.pageNetGame->pChatWidget, SLOT(nickRemoved(const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(nickAddedLobby(const QString&, bool)),
            ui.pageRoomsList->chatWidget, SLOT(nickAdded(const QString&, bool)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(nickRemovedLobby(const QString&)),
            ui.pageRoomsList->chatWidget, SLOT(nickRemoved(const QString&)), Qt::QueuedConnection);

// teams selecting stuff
    connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(hhogsNumChanged(const HWTeam&)),
            hwnet, SLOT(onHedgehogsNumChanged(const HWTeam&)));
    connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(teamColorChanged(const HWTeam&)),
            hwnet, SLOT(onTeamColorChanged(const HWTeam&)));
    connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(teamWillPlay(HWTeam)), hwnet, SLOT(AddTeam(HWTeam)));
    connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(acceptRequested(HWTeam)), hwnet, SLOT(AddTeam(HWTeam)));
    connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(teamNotPlaying(const HWTeam&)), hwnet, SLOT(RemoveTeam(const HWTeam&)));
    connect(hwnet, SIGNAL(hhnumChanged(const HWTeam&)),
            ui.pageNetGame->pNetTeamsWidget, SLOT(changeHHNum(const HWTeam&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(teamColorChanged(const HWTeam&)),
            ui.pageNetGame->pNetTeamsWidget, SLOT(changeTeamColor(const HWTeam&)), Qt::QueuedConnection);

// admin stuff
    connect(hwnet, SIGNAL(serverMessageNew(const QString&)), ui.pageAdmin, SLOT(serverMessageNew(const QString &)));
    connect(hwnet, SIGNAL(serverMessageOld(const QString&)), ui.pageAdmin, SLOT(serverMessageOld(const QString &)));
    connect(hwnet, SIGNAL(latestProtocolVar(int)), ui.pageAdmin, SLOT(protocol(int)));
    connect(ui.pageAdmin, SIGNAL(setServerMessageNew(const QString&)), hwnet, SLOT(setServerMessageNew(const QString &)));
    connect(ui.pageAdmin, SIGNAL(setServerMessageOld(const QString&)), hwnet, SLOT(setServerMessageOld(const QString &)));
    connect(ui.pageAdmin, SIGNAL(setProtocol(int)), hwnet, SLOT(setLatestProtocolVar(int)));
    connect(ui.pageAdmin, SIGNAL(askServerVars()), hwnet, SLOT(askServerVars()));
    connect(ui.pageAdmin, SIGNAL(clearAccountsCache()), hwnet, SLOT(clearAccountsCache()));

// disconnect
    connect(hwnet, SIGNAL(disconnected(const QString&)), this, SLOT(ForcedDisconnect(const QString&)), Qt::QueuedConnection);

// config stuff
    connect(hwnet, SIGNAL(paramChanged(const QString &, const QStringList &)), ui.pageNetGame->pGameCFG, SLOT(setParam(const QString &, const QStringList &)));
    connect(ui.pageNetGame->pGameCFG, SIGNAL(paramChanged(const QString &, const QStringList &)), hwnet, SLOT(onParamChanged(const QString &, const QStringList &)));
    connect(hwnet, SIGNAL(configAsked()), ui.pageNetGame->pGameCFG, SLOT(fullNetConfig()));

    while (nick.isEmpty())
    {
        nick = QInputDialog::getText(this,
                                     QObject::tr("Nickname"),
                                     QObject::tr("Please enter your nickname"),
                                     QLineEdit::Normal,
                                     QDir::home().dirName());
        config->setValue("net/nick",nick);
        config->updNetNick();
    }

    ui.pageRoomsList->setUser(nick);
    ui.pageNetGame->setUser(nick);

    hwnet->Connect(hostName, port, nick);
}

void HWForm::NetConnect()
{
    HWHostPortDialog * hpd = new HWHostPortDialog(this);
    hpd->leHost->setText(*netHost);
    hpd->sbPort->setValue(netPort);

    if (hpd->exec() == QDialog::Accepted)
    {
        config->SaveOptions();
        delete netHost;
        netHost = new QString(hpd->leHost->text());
        netPort = hpd->sbPort->value();
        NetConnectServer(*netHost, netPort);
    }
    delete hpd;
}

void HWForm::NetStartServer()
{
    config->SaveOptions();

    pnetserver = new HWNetServer;
    if (!pnetserver->StartServer(ui.pageNetServer->sbPort->value()))
    {
        ShowErrorMessage(QMessageBox::tr("Unable to start the server"));

        delete pnetserver;
        pnetserver = 0;
        return;
    }

    QTimer::singleShot(250, this, SLOT(AsyncNetServerStart()));

    pRegisterServer = new HWNetUdpServer(0,
                                         ui.pageNetServer->leServerDescr->text(),
                                         ui.pageNetServer->sbPort->value());
}

void HWForm::AsyncNetServerStart()
{
    NetConnectServer("localhost", pnetserver->getRunningPort());
}

void HWForm::NetDisconnect()
{
    if(pnetserver)
    {
        if (pRegisterServer)
        {
            pRegisterServer->unregister();
            pRegisterServer = 0;
        }

        pnetserver->StopServer();
        delete pnetserver;
        pnetserver = 0;
    }

    if(hwnet)
        hwnet->Disconnect();
}

void HWForm::ForcedDisconnect(const QString & reason)
{
    if (pnetserver)
        return; // we have server - let it care of all things
    if (hwnet)
    {
        QString errorStr = QMessageBox::tr("Connection to server is lost") + (reason.isEmpty()?"":("\n\n" + HWNewNet::tr("Quit reason: ") + '"' + reason +'"'));
        ShowErrorMessage(errorStr);
    }
    if (ui.Pages->currentIndex() != ID_PAGE_NET)
        GoBack();
}

void HWForm::NetConnected()
{
    GoToPage(ID_PAGE_ROOMSLIST);
}

void HWForm::NetGameEnter()
{
    ui.pageNetGame->pChatWidget->clear();
    GoToPage(ID_PAGE_NETGAME);
}

void HWForm::AddNetTeam(const HWTeam& team)
{
    ui.pageNetGame->pNetTeamsWidget->addTeam(team);
}

void HWForm::RemoveNetTeam(const HWTeam& team)
{
    ui.pageNetGame->pNetTeamsWidget->removeNetTeam(team);
}

void HWForm::StartMPGame()
{
    QString ammo;
    ammo = ui.pageMultiplayer->gameCFG->WeaponsName->itemData(
               ui.pageMultiplayer->gameCFG->WeaponsName->currentIndex()
           ).toString();

    CreateGame(ui.pageMultiplayer->gameCFG, ui.pageMultiplayer->teamsSelect, ammo);

    game->StartLocal();
}

void HWForm::GameStateChanged(GameState gameState)
{
    quint8 id = ui.Pages->currentIndex();
    switch(gameState)
    {
        case gsStarted:
        {
            Music(false);
            if (wBackground) wBackground->stopAnimation();
            if (!hwnet || (!hwnet->isRoomChief() || !hwnet->isInRoom())) GoToPage(ID_PAGE_INGAME);
            ui.pageGameStats->clear();
            if (pRegisterServer)
            {
                pRegisterServer->unregister();
                pRegisterServer = 0;
            }
            //setVisible(false);
            setFocusPolicy(Qt::NoFocus);
            break;
        }
        case gsFinished:
        {
            //setVisible(true);
            setFocusPolicy(Qt::StrongFocus);
            if (id == ID_PAGE_INGAME) GoBack();
            Music(ui.pageOptions->CBEnableFrontendMusic->isChecked());
            if (wBackground) wBackground->startAnimation();
            GoToPage(ID_PAGE_GAMESTATS);
            if (hwnet && (!game || !game->netSuspend)) hwnet->gameFinished(true);
            if (game) game->netSuspend = false;
            break;
        }
        default:
        {
            //setVisible(true);
            setFocusPolicy(Qt::StrongFocus);
            quint8 id = ui.Pages->currentIndex();
            if (id == ID_PAGE_INGAME ||
// was room chief and the game was aborted
                    (hwnet && hwnet->isRoomChief() && hwnet->isInRoom() &&
                     (gameState == gsInterrupted || gameState == gsStopped || gameState == gsDestroyed || gameState == gsHalted)))
            {
                if (id == ID_PAGE_INGAME) GoBack();
                Music(ui.pageOptions->CBEnableFrontendMusic->isChecked());
                if (wBackground) wBackground->startAnimation();
                if (hwnet) hwnet->gameFinished(false);
            }
            if (gameState == gsHalted) close();
        };
    }
}

void HWForm::CreateGame(GameCFGWidget * gamecfg, TeamSelWidget* pTeamSelWidget, QString ammo)
{
    game = new HWGame(config, gamecfg, ammo, pTeamSelWidget);
    connect(game, SIGNAL(CampStateChanged(int)), this, SLOT(UpdateCampaignPageProgress(int)));
    connect(game, SIGNAL(GameStateChanged(GameState)), this, SLOT(GameStateChanged(GameState)));
    connect(game, SIGNAL(GameStats(char, const QString &)), ui.pageGameStats, SLOT(GameStats(char, const QString &)));
    connect(game, SIGNAL(ErrorMessage(const QString &)), this, SLOT(ShowErrorMessage(const QString &)), Qt::QueuedConnection);
    connect(game, SIGNAL(HaveRecord(RecordType, const QByteArray &)), this, SLOT(GetRecord(RecordType, const QByteArray &)));
    m_lastDemo = QByteArray();
}

void HWForm::ShowErrorMessage(const QString & msg)
{
    QMessageBox msgMsg(this);
    msgMsg.setIcon(QMessageBox::Warning);
    msgMsg.setWindowTitle(QMessageBox::tr("Hedgewars - Error"));
    msgMsg.setText(msg);
    msgMsg.setWindowModality(Qt::WindowModal);
    msgMsg.exec();
}

void HWForm::GetRecord(RecordType type, const QByteArray & record)
{
    if (type != rtNeither)
    {
        QString filename;
        QByteArray demo = record;
        QString recordFileName =
            config->appendDateTimeToRecordName() ?
            QDateTime::currentDateTime().toString("yyyy-MM-dd_hh-mm") :
            "LastRound";

        QStringList versionParts = cVersionString->split('-');
        if ( (versionParts.size() == 2) && (!versionParts[1].isEmpty()) && (versionParts[1].contains(':')) )
            recordFileName = recordFileName + "_" + versionParts[1].replace(':','-');

        if (type == rtDemo)
        {
            demo.replace(QByteArray("\x02TL"), QByteArray("\x02TD"));
            demo.replace(QByteArray("\x02TN"), QByteArray("\x02TD"));
            demo.replace(QByteArray("\x02TS"), QByteArray("\x02TD"));
            filename = cfgdir->absolutePath() + "/Demos/" + recordFileName + "." + *cProtoVer + ".hwd";
            m_lastDemo = demo;
        }
        else
        {
            demo.replace(QByteArray("\x02TL"), QByteArray("\x02TS"));
            demo.replace(QByteArray("\x02TN"), QByteArray("\x02TS"));
            filename = cfgdir->absolutePath() + "/Saves/" + recordFileName + "." + *cProtoVer + ".hws";
        }

        QFile demofile(filename);
        if (!demofile.open(QIODevice::WriteOnly))
            ShowErrorMessage(tr("Cannot save record to file %1").arg(filename));
        else
        {
            demofile.write(demo);
            demofile.close();
        }
    }

    ui.pageVideos->startEncoding(record);
}

void HWForm::startTraining(const QString & scriptName)
{
    CreateGame(0, 0, 0);

    game->StartTraining(scriptName);
}

void HWForm::StartCampaign()
{
    CreateGame(0, 0, 0);

    QComboBox *combo = ui.pageCampaign->CBMission;
    QString camp = ui.pageCampaign->CBCampaign->currentText();
    unsigned int mNum = combo->count() - combo->currentIndex();
    QString miss = getCampaignScript(camp, mNum);
    QString campTeam = ui.pageCampaign->CBTeam->currentText();

    game->StartCampaign(camp, miss, campTeam);
}

void HWForm::CreateNetGame()
{
    QString ammo;
    ammo = ui.pageNetGame->pGameCFG->WeaponsName->itemData(
               ui.pageNetGame->pGameCFG->WeaponsName->currentIndex()
           ).toString();

    CreateGame(ui.pageNetGame->pGameCFG, ui.pageNetGame->pNetTeamsWidget, ammo);

    connect(game, SIGNAL(SendNet(const QByteArray &)), hwnet, SLOT(SendNet(const QByteArray &)));
    connect(game, SIGNAL(SendChat(const QString &)), hwnet, SLOT(chatLineToNet(const QString &)));
    connect(game, SIGNAL(SendTeamMessage(const QString &)), hwnet, SLOT(SendTeamMessage(const QString &)));
    connect(hwnet, SIGNAL(FromNet(const QByteArray &)), game, SLOT(FromNet(const QByteArray &)));
    connect(hwnet, SIGNAL(chatStringFromNet(const QString &)), game, SLOT(FromNetChat(const QString &)));

    game->StartNet();
}

void HWForm::closeEvent(QCloseEvent *event)
{
#ifdef USE_XFIRE
    xfire_free();
#endif
    config->SaveOptions();
    config->SaveVideosOptions();
    event->accept();
}

void HWForm::Music(bool checked)
{
    if (checked)
        SDLInteraction::instance().startMusic();
    else
        SDLInteraction::instance().stopMusic();
}

void HWForm::NetGameChangeStatus(bool isMaster)
{
    ui.pageNetGame->pGameCFG->setEnabled(isMaster);
    ui.pageNetGame->pNetTeamsWidget->setInteractivity(isMaster);

    if (isMaster)
        NetGameMaster();
    else
        NetGameSlave();
}

void HWForm::NetGameMaster()
{
    ui.pageNetGame->setMasterMode(true);
    ui.pageNetGame->restrictJoins->setChecked(false);
    ui.pageNetGame->restrictTeamAdds->setChecked(false);
    ui.pageNetGame->pGameCFG->GameSchemes->setModel(ammoSchemeModel);
    ui.pageNetGame->pGameCFG->setEnabled(true);
    ui.pageNetGame->pNetTeamsWidget->setInteractivity(true);

    if (hwnet)
    {
        // disconnect connections first to ensure their inexistance and not to connect twice
        ui.pageNetGame->BtnStart->disconnect(hwnet);
        ui.pageNetGame->BtnUpdate->disconnect(hwnet);
        ui.pageNetGame->restrictJoins->disconnect(hwnet);
        ui.pageNetGame->restrictTeamAdds->disconnect(hwnet);
        ui.pageNetGame->disconnect(hwnet, SLOT(updateRoomName(const QString&)));

        ui.pageNetGame->setRoomName(hwnet->getRoom());

        connect(ui.pageNetGame->BtnStart, SIGNAL(clicked()), hwnet, SLOT(startGame()));
        connect(ui.pageNetGame, SIGNAL(askForUpdateRoomName(const QString &)), hwnet, SLOT(updateRoomName(const QString &)));
        connect(ui.pageNetGame->restrictJoins, SIGNAL(triggered()), hwnet, SLOT(toggleRestrictJoins()));
        connect(ui.pageNetGame->restrictTeamAdds, SIGNAL(triggered()), hwnet, SLOT(toggleRestrictTeamAdds()));
        connect(ui.pageNetGame->pGameCFG->GameSchemes->model(),
                SIGNAL(dataChanged(const QModelIndex &, const QModelIndex &)),
                ui.pageNetGame->pGameCFG,
                SLOT(resendSchemeData())
               );
    }
}

void HWForm::NetGameSlave()
{
    ui.pageNetGame->pGameCFG->setEnabled(false);
    ui.pageNetGame->pNetTeamsWidget->setInteractivity(false);

    if (hwnet)
    {
        NetAmmoSchemeModel * netAmmo = new NetAmmoSchemeModel(hwnet);
        connect(hwnet, SIGNAL(netSchemeConfig(QStringList &)), netAmmo, SLOT(setNetSchemeConfig(QStringList &)));
        ui.pageNetGame->pGameCFG->GameSchemes->setModel(netAmmo);

        ui.pageNetGame->pGameCFG->GameSchemes->view()->disconnect(hwnet);
        connect(hwnet, SIGNAL(netSchemeConfig(QStringList &)),
                this, SLOT(selectFirstNetScheme()));
    }

    ui.pageNetGame->setMasterMode(false);
}

void HWForm::selectFirstNetScheme()
{
    ui.pageNetGame->pGameCFG->GameSchemes->setCurrentIndex(0);
}

void HWForm::NetLeftRoom(const QString & reason)
{
    if (ui.Pages->currentIndex() == ID_PAGE_NETGAME || ui.Pages->currentIndex() == ID_PAGE_INGAME)
    {
        GoBack();
        if (!reason.isEmpty())
            ui.pageRoomsList->displayNotice(reason);
    }
    else
        qWarning("Left room while not in room");
}

void HWForm::resizeEvent(QResizeEvent * event)
{
    int w = event->size().width();
    int h = event->size().height();
    if (wBackground)
    {
        wBackground->setFixedSize(w, h);
        wBackground->move(0, 0);
    }
}

void HWForm::InitCampaignPage()
{
    ui.pageCampaign->CBCampaign->clear();
    HWTeam team(ui.pageCampaign->CBTeam->currentText());

    QStringList entries = DataManager::instance().entryList(
                                  "Missions/Campaign",
                                  QDir::Dirs,
                                  QStringList("[^\\.]*")
                              );

    unsigned int n = entries.count();
    for(unsigned int i = 0; i < n; i++)
    {
        ui.pageCampaign->CBCampaign->addItem(QString(entries[i]), QString(entries[i]));
    }
}


void HWForm::UpdateCampaignPage(int index)
{
    Q_UNUSED(index);

    HWTeam team(ui.pageCampaign->CBTeam->currentText());
    ui.pageCampaign->CBMission->clear();

    QString campaignName = ui.pageCampaign->CBCampaign->currentText();
    QStringList missionEntries = getCampMissionList(campaignName);
    QString tName = team.name();
    unsigned int n = missionEntries.count();
    unsigned int m = getCampProgress(tName, campaignName);

    for (unsigned int i = qMin(m + 1, n); i > 0; i--)
    {
        ui.pageCampaign->CBMission->addItem(QString("Mission %1: ").arg(i) + QString(missionEntries[i-1]), QString(missionEntries[i-1]));
    }
}

void HWForm::UpdateCampaignPageProgress(int index)
{
    Q_UNUSED(index);

    int missionIndex = ui.pageCampaign->CBMission->currentIndex();
    UpdateCampaignPage(0);
    ui.pageCampaign->CBMission->setCurrentIndex(missionIndex);
}

// used for --set-everything [screen width] [screen height] [color dept] [volume] [enable music] [enable sounds] [language file] [full screen] [show FPS] [alternate damage] [timer value] [reduced quality]
QString HWForm::getDemoArguments()
{
    QRect resolution = config->vid_Resolution();
    return QString(QString::number(resolution.width()) + " "
                   + QString::number(resolution.height()) + " "
                   + QString::number(config->bitDepth()) + " " // bpp
                   + QString::number(config->volume()) + " " // sound volume
                   + (config->isMusicEnabled() ? "1" : "0") + " "
                   + (config->isSoundEnabled() ? "1" : "0") + " "
                   + config->language() + ".txt "
                   + (config->vid_Fullscreen() ? "1" : "0") + " "
                   + (config->isShowFPSEnabled() ? "1" : "0") + " "
                   + (config->isAltDamageEnabled() ? "1" : "0") + " "
                   + QString::number(config->timerInterval()) + " "
                   + QString::number(config->translateQuality()));
}

void HWForm::AssociateFiles()
{
    bool success = true;
    QString arguments = getDemoArguments();
#ifdef _WIN32
    QSettings registry_hkcr("HKEY_CLASSES_ROOT", QSettings::NativeFormat);
    registry_hkcr.setValue(".hwd/Default", "Hedgewars.Demo");
    registry_hkcr.setValue(".hws/Default", "Hedgewars.Save");
    registry_hkcr.setValue("Hedgewars.Demo/Default", tr("Hedgewars Demo File", "File Types"));
    registry_hkcr.setValue("Hedgewars.Save/Default", tr("Hedgewars Save File", "File Types"));
    registry_hkcr.setValue("Hedgewars.Demo/DefaultIcon/Default", "\"" + bindir->absolutePath().replace("/", "\\") + "\\hwdfile.ico\",0");
    registry_hkcr.setValue("Hedgewars.Save/DefaultIcon/Default", "\"" + bindir->absolutePath().replace("/", "\\") + "\\hwsfile.ico\",0");
    registry_hkcr.setValue("Hedgewars.Demo/Shell/Open/Command/Default", "\"" + bindir->absolutePath().replace("/", "\\") + "\\hwengine.exe\" \"" + cfgdir->absolutePath().replace("/","\\") + "\" \"" + datadir->absolutePath().replace("/", "\\") + "\" \"%1\" --set-everything "+arguments);
    registry_hkcr.setValue("Hedgewars.Save/Shell/Open/Command/Default", "\"" + bindir->absolutePath().replace("/", "\\") + "\\hwengine.exe\" \"" + cfgdir->absolutePath().replace("/","\\") + "\" \"" + datadir->absolutePath().replace("/", "\\") + "\" \"%1\" --set-everything "+arguments);
#elif defined __APPLE__
    // only useful when other apps have taken precedence over our file extensions and you want to reset it
    system("defaults write com.apple.LaunchServices LSHandlers -array-add '<dict><key>LSHandlerContentTag</key><string>hwd</string><key>LSHandlerContentTagClass</key><string>public.filename-extension</string><key>LSHandlerRoleAll</key><string>org.hedgewars.desktop</string></dict>'");
    system("defaults write com.apple.LaunchServices LSHandlers -array-add '<dict><key>LSHandlerContentTag</key><string>hws</string><key>LSHandlerContentTagClass</key><string>public.filename-extension</string><key>LSHandlerRoleAll</key><string>org.hedgewars.desktop</string></dict>'");
    system("/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -kill -domain local -domain system -domain user");
#else
    // this is a little silly due to all the system commands below anyway - just use mkdir -p ?  Does have the advantage of the alert I guess
    if (success) success = checkForDir(QDir::home().absolutePath() + "/.local");
    if (success) success = checkForDir(QDir::home().absolutePath() + "/.local/share");
    if (success) success = checkForDir(QDir::home().absolutePath() + "/.local/share/mime");
    if (success) success = checkForDir(QDir::home().absolutePath() + "/.local/share/mime/packages");
    if (success) success = checkForDir(QDir::home().absolutePath() + "/.local");
    if (success) success = checkForDir(QDir::home().absolutePath() + "/.local/share");
    if (success) success = checkForDir(QDir::home().absolutePath() + "/.local/share/applications");
    if (success) success = system(("cp "+datadir->absolutePath()+"/misc/hedgewars-mimeinfo.xml "+QDir::home().absolutePath()+"/.local/share/mime/packages").toLocal8Bit().constData())==0;
    if (success) success = system(("cp "+datadir->absolutePath()+"/misc/hwengine.desktop "+QDir::home().absolutePath()+"/.local/share/applications").toLocal8Bit().constData())==0;
    if (success) success = system(("update-mime-database "+QDir::home().absolutePath()+"/.local/share/mime").toLocal8Bit().constData())==0;
    if (success) success = system("xdg-mime default hwengine.desktop application/x-hedgewars-demo")==0;
    if (success) success = system("xdg-mime default hwengine.desktop application/x-hedgewars-save")==0;
    // hack to add user's settings to hwengine. might be better at this point to read in the file, append it, and write it out to its new home.  This assumes no spaces in the data dir path
    if (success) success = system(("sed -i 's/^\\(Exec=.*\\) \\([^ ]* %f\\)/\\1 "+cfgdir->absolutePath().replace(" ","\\\\ ").replace("/","\\/")+" \\2 --set-everything "+arguments+"/' "+QDir::home().absolutePath()+"/.local/share/applications/hwengine.desktop").toLocal8Bit().constData())==0;
#endif
    if (success)
    {
        QMessageBox infoMsg(this);
        infoMsg.setIcon(QMessageBox::Information);
        infoMsg.setWindowTitle(QMessageBox::tr("Hedgewars - Success"));
        infoMsg.setText(QMessageBox::tr("All file associations have been set"));
        infoMsg.setWindowModality(Qt::WindowModal);
        infoMsg.exec();
    }
    else
        ShowErrorMessage(QMessageBox::tr("File association failed."));
}

void HWForm::saveDemoWithCustomName()
{
    if(!m_lastDemo.isEmpty())
    {
        QString fileName;
        bool ok = false;
        do
        {
            fileName = QInputDialog::getText(this, tr("Demo name"), tr("Demo name:"));

            if(!fileName.isEmpty())
            {
                QString filePath = cfgdir->absolutePath() + "/Demos/" + fileName + "." + *cProtoVer + ".hwd";
                QFile demofile(filePath);
                ok = demofile.open(QIODevice::WriteOnly);
                if (!ok)
                    ShowErrorMessage(tr("Cannot save record to file %1").arg(filePath));
                else
                {
                    ok = -1 != demofile.write(m_lastDemo);
                    demofile.close();
                }
            }
        }
        while(!fileName.isEmpty() && !ok);
    }
}

void HWForm::SendFeedback()
{
    //Create Xml representation of google code issue first
    if (!CreateIssueXml())
    {
        ShowErrorMessage(QMessageBox::tr("Please fill out all fields"));
        return;
    }

    //Google login using fake account (feedback.hedgewars@gmail.com)
    nam = new QNetworkAccessManager(this);
    connect(nam, SIGNAL(finished(QNetworkReply*)),
            this, SLOT(finishedSlot(QNetworkReply*)));

    QUrl url(QString("https://www.google.com/accounts/ClientLogin?"
                     "accountType=GOOGLE&Email=feedback.hedgewars@gmail.com&Passwd=hwfeedback&service=code&source=HedgewarsFoundation-Hedgewars-")
                    + (cVersionString?(*cVersionString):QString("")));
    nam->get(QNetworkRequest(url));

}

bool HWForm::CreateIssueXml()
{
    QString summary = ui.pageFeedback->summary->text();
    QString description = ui.pageFeedback->description->toPlainText();

    //Check if all necessary information is entered
    if (summary.isEmpty() || description.isEmpty())
        return false;

    issueXml =
        "<?xml version='1.0' encoding='UTF-8'?>"
        "<entry xmlns='http://www.w3.org/2005/Atom' xmlns:issues='http://code.google.com/p/hedgewars/issues/list'>"
        "<title>";
    issueXml.append(summary);
    issueXml.append("</title><content type='html'>");
    issueXml.append(description);
    issueXml.append("</content><author><name>feedback.hedgewars</name></author></entry>");

    return true;
}

void HWForm::finishedSlot(QNetworkReply* reply)
{
    if (reply && reply->error() == QNetworkReply::NoError)
    {
        QByteArray array = reply->readAll();
        QString str(array);

        if (authToken.length() != 0)
        {

            QMessageBox infoMsg(this);
            infoMsg.setIcon(QMessageBox::Information);
            infoMsg.setWindowTitle(QMessageBox::tr("Hedgewars - Success"));
            infoMsg.setText(QMessageBox::tr("Successfully posted the issue on hedgewars.googlecode.com"));
            infoMsg.setWindowModality(Qt::WindowModal);
            infoMsg.exec();

            ui.pageFeedback->summary->clear();
            ui.pageFeedback->description->clear();
            authToken = "";
            return;
        }

        if (!getAuthToken(str))
        {
            ShowErrorMessage(QMessageBox::tr("Error during authentication at google.com"));
            return;
        }

        QByteArray body(issueXml.toUtf8());
        QNetworkRequest header(QUrl("https://code.google.com/feeds/issues/p/hedgewars/issues/full"));
        header.setRawHeader("Content-Length", QString::number(issueXml.length()).toAscii());
        header.setRawHeader("Content-Type", "application/atom+xml");
        header.setRawHeader("Authorization", QString("GoogleLogin auth=%1").arg(authToken).toUtf8());
        nam->post(header, body);

    }
    else if (authToken.length() == 0)
        ShowErrorMessage(QMessageBox::tr("Error during authentication at google.com"));
    else
    {
        ShowErrorMessage(QMessageBox::tr("Error reporting the issue, please try again later (or visit hedgewars.googlecode.come directly)"));
        authToken = "";
    }

}

bool HWForm::getAuthToken(QString str)
{
    QRegExp ex("Auth=(.+)");

    if (-1 == ex.indexIn(str))
        return false;

    authToken = ex.cap(1);
    authToken.remove(QChar('\n'));

    return true;
}



