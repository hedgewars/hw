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

#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QMessageBox>
#include <QPushButton>
#include <QSpinBox>
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
#include <QDesktopWidget>
#include <QApplication>
#include <QInputDialog>
#include <QPropertyAnimation>
#include <QSettings>
#include <QSortFilterProxyModel>
#include <QIcon>
#include <QImage>

#if (QT_VERSION >= 0x040600)
#include <QGraphicsEffect>
#include <QParallelAnimationGroup>
#endif

#include "hwform.h"
#include "game.h"
#include "team.h"
#include "mission.h"
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
#include "pagenetserver.h"
#include "pagedrawmap.h"
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
#include "gameSchemeModel.h"
#include "bgwidget.h"
#include "drawmapwidget.h"
#include "mouseoverfilter.h"
#include "roomslistmodel.h"
#include "recorder.h"
#include "playerslistmodel.h"
#include "feedbackdialog.h"

#include "MessageDialog.h"
#include "DataManager.h"
#include "AutoUpdater.h"

#ifdef Q_OS_WIN
#ifndef WINVER
#define WINVER 0x0500
#endif
#include <windows.h>
#else
#include <unistd.h>
#include <sys/types.h>
#endif

#ifdef Q_OS_MAC
#include <sys/sysctl.h>
#endif

#ifdef __APPLE__
#include "M3Panel.h"
#ifdef SPARKLE_ENABLED
#include "SparkleAutoUpdater.h"
#endif
#endif


// I started handing this down to each place it touches, but it was getting ridiculous
// and this one flag does not warrant a static class
bool frontendEffects = true;
QString playerHash;

QIcon finishedIcon;
QIcon notFinishedIcon;
GameUIConfig* HWForm::config = NULL;

HWForm::HWForm(QWidget *parent, QString styleSheet)
    : QMainWindow(parent)
    , game(0)
    , pnetserver(0)
    , pRegisterServer(0)
    , editedTeam(0)
    , hwnet(0)
{
    // set music track
    SDLInteraction::instance().setMusicTrack("/Music/main_theme.ogg");

    this->setStyleSheet(styleSheet);


    QIcon * hwIcon = new QIcon();
    hwIcon->addFile(":/res/hh_small.png");
    //hwIcon->addFile(":/res/hh25x25.png");
    // crop-workaround for the fact that hh25x25.png is actually 25x35
    QPixmap pm(":/res/hh25x25.png");
    hwIcon->addPixmap(pm.copy(0,(pm.height()-25)/2,25,25));
    hwIcon->addFile(":/res/teamicon.png");
    hwIcon->addFile(":/res/teamicon2.png");

    this->setWindowIcon(*hwIcon);
    ui.setupUi(this);
    setMinimumSize(760, 580);
    //setFocusPolicy(Qt::StrongFocus);
    CustomizePalettes();

    ui.pageOptions->CBResolution->addItems(SDLInteraction::instance().getResolutions());

    config = new GameUIConfig(this, DataManager::instance().settingsFileName());
    frontendEffects = config->value("frontend/effects", true).toBool();
    playerHash = QString(QCryptographicHash::hash(config->value("net/nick",tr("Guest")+QString("%1").arg(rand())).toString().toUtf8(), QCryptographicHash::Md5).toHex());

    // Icons for finished missions
    finishedIcon.addFile(":/res/missionFinished.png", QSize(), QIcon::Normal, QIcon::On);
    finishedIcon.addFile(":/res/missionFinishedSelected.png", QSize(), QIcon::Selected, QIcon::On);

    // A transparent icon, used to nicely align the unfinished missions with the finished ones
    QPixmap emptySpace = QPixmap(15, 15);
    emptySpace.fill(QColor(0, 0, 0, 0));
    notFinishedIcon = QIcon(emptySpace);

    ui.pageRoomsList->setSettings(config);
    ui.pageNetGame->setSettings(config);
    ui.pageNetGame->chatWidget->setSettings(config);
    ui.pageRoomsList->chatWidget->setSettings(config);
    ui.pageOptions->setConfig(config);
#ifdef VIDEOREC
    ui.pageVideos->init(config);
#endif

#if defined(__APPLE__) && defined(SPARKLE_ENABLED)
    if (config->isAutoUpdateEnabled())
    {
        AutoUpdater* updater = NULL;

        updater = new SparkleAutoUpdater();
        if (updater)
        {
            updater->checkForUpdates();
            delete updater;
        }
    }
#endif

#ifdef __APPLE__
    panel = new M3Panel;

    QShortcut *hideFrontend = new QShortcut(QKeySequence("Ctrl+M"), this);
    connect (hideFrontend, SIGNAL(activated()), this, SLOT(showMinimized()));
#else
    // ctrl+q closes frontend for consistency
    QShortcut * closeFrontend = new QShortcut(QKeySequence("Ctrl+Q"), this);
    connect (closeFrontend, SIGNAL(activated()), this, SLOT(close()));
    //QShortcut * updateData = new QShortcut(QKeySequence("F5"), this);
    //connect (updateData, SIGNAL(activated()), &DataManager::instance(), SLOT(reload()));
#endif

    previousCampaignName = "";
    previousTeamName = "";
    UpdateTeamsLists();
    InitCampaignPage();
    RestoreSingleplayerTeamSelection();
    UpdateCampaignPage(0);
    UpdateCampaignPageTeam(0);
    UpdateCampaignPageMission(0);
    UpdateWeapons();

    // connect all goBack signals
    int nPages = ui.Pages->count();

    for (int i = 0; i < nPages; i++)
        connect(ui.Pages->widget(i), SIGNAL(goBack()), this, SLOT(GoBack()));

    pageSwitchMapper = new QSignalMapper(this);
    connect(pageSwitchMapper, SIGNAL(mapped(int)), this, SLOT(GoToPage(int)));
    
    connect(ui.pageMain->BtnSinglePlayer, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageMain->BtnSinglePlayer, ID_PAGE_SINGLEPLAYER);

    connect(ui.pageMain->BtnSetup, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageMain->BtnSetup, ID_PAGE_SETUP);

    connect(ui.pageMain->BtnFeedback, SIGNAL(clicked()), this, SLOT(showFeedbackDialog()));

    connect(ui.pageMain->BtnInfo, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageMain->BtnInfo, ID_PAGE_INFO);

    connect(ui.pageMain->BtnDataDownload, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageMain->BtnDataDownload, ID_PAGE_DATADOWNLOAD);

    connect(ui.pageMain->BtnHelp, SIGNAL(clicked()), this, SLOT(GoToHelp()));

#ifdef VIDEOREC
    connect(ui.pageMain->BtnVideos, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageMain->BtnVideos, ID_PAGE_VIDEOS);
#endif

    //connect(ui.pageMain->BtnExit, SIGNAL(pressed()), this, SLOT(btnExitPressed()));
    //connect(ui.pageMain->BtnExit, SIGNAL(clicked()), this, SLOT(btnExitClicked()));

    connect(ui.pageEditTeam, SIGNAL(goBack()), this, SLOT(AfterTeamEdit()));

    connect(ui.pageMultiplayer->BtnStartMPGame, SIGNAL(clicked()), this, SLOT(StartMPGame()));
    connect(ui.pageMultiplayer->teamsSelect, SIGNAL(setEnabledGameStart(bool)),
            ui.pageMultiplayer->BtnStartMPGame, SLOT(setEnabled(bool)));
    connect(ui.pageMultiplayer, SIGNAL(SetupClicked()), this, SLOT(IntermediateSetup()));
    connect(ui.pageMultiplayer->gameCFG, SIGNAL(goToSchemes(int)), this, SLOT(GoToScheme(int)));
    connect(ui.pageMultiplayer->gameCFG, SIGNAL(goToWeapons(int)), this, SLOT(GoToWeapons(int)));
    connect(ui.pageMultiplayer->gameCFG, SIGNAL(goToDrawMap()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageMultiplayer->gameCFG, ID_PAGE_DRAWMAP);


    connect(ui.pagePlayDemo->BtnPlayDemo, SIGNAL(clicked()), this, SLOT(PlayDemo()));
    connect(ui.pagePlayDemo->DemosList, SIGNAL(doubleClicked (const QModelIndex &)), this, SLOT(PlayDemo()));

    connect(ui.pageOptions, SIGNAL(newTeamRequested()), this, SLOT(NewTeam()));
    connect(ui.pageOptions, SIGNAL(editTeamRequested(const QString&)), this, SLOT(EditTeam(const QString&)));
    connect(ui.pageOptions, SIGNAL(deleteTeamRequested(const QString&)), this, SLOT(DeleteTeam(const QString&)));
    connect(ui.pageOptions, SIGNAL(goBack()), config, SLOT(SaveOptions()));
    connect(ui.pageOptions->BtnAssociateFiles, SIGNAL(clicked()), this, SLOT(AssociateFiles()));

    connect(ui.pageOptions->WeaponEdit, SIGNAL(clicked()), this, SLOT(GoToEditWeapons()));
    connect(ui.pageOptions->WeaponNew, SIGNAL(clicked()), this, SLOT(GoToNewWeapons()));
    connect(ui.pageOptions->WeaponDelete, SIGNAL(clicked()), this, SLOT(DeleteWeaponSet()));
    connect(ui.pageOptions->SchemeEdit, SIGNAL(clicked()), this, SLOT(GoToEditScheme()));
    connect(ui.pageOptions->SchemeNew, SIGNAL(clicked()), this, SLOT(GoToNewScheme()));
    connect(ui.pageOptions->SchemeDelete, SIGNAL(clicked()), this, SLOT(DeleteScheme()));
    connect(ui.pageOptions->CBFrontendEffects, SIGNAL(toggled(bool)), this, SLOT(onFrontendEffects(bool)) );

    connect(ui.pageNet->BtnSpecifyServer, SIGNAL(clicked()), this, SLOT(NetConnect()));
    connect(ui.pageNet->BtnNetSvrStart, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageNet->BtnNetSvrStart, ID_PAGE_NETSERVER);

    connect(ui.pageNet, SIGNAL(connectClicked(const QString &, quint16)), this, SLOT(NetConnectServer(const QString &, quint16)));

    connect(ui.pageNetServer->BtnStart, SIGNAL(clicked()), this, SLOT(NetStartServer()));

    connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(setEnabledGameStart(bool)),
            ui.pageNetGame->BtnStart, SLOT(setEnabled(bool)));
    connect(ui.pageNetGame, SIGNAL(SetupClicked()), this, SLOT(IntermediateSetup()));
    connect(ui.pageNetGame->pGameCFG, SIGNAL(goToSchemes(int)), this, SLOT(GoToScheme(int)));
    connect(ui.pageNetGame->pGameCFG, SIGNAL(goToWeapons(int)), this, SLOT(GoToWeapons(int)));
    connect(ui.pageNetGame->pGameCFG, SIGNAL(goToDrawMap()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageNetGame->pGameCFG, ID_PAGE_DRAWMAP);

    connect(ui.pageRoomsList->BtnAdmin, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageRoomsList->BtnAdmin, ID_PAGE_ADMIN);

    connect(ui.pageInfo->BtnSnapshots, SIGNAL(clicked()), this, SLOT(OpenSnapshotFolder()));

    connect(ui.pageGameStats, SIGNAL(saveDemoRequested()), this, SLOT(saveDemoWithCustomName()));
    connect(ui.pageGameStats, SIGNAL(restartGameRequested()), this, SLOT(restartGame()));

    connect(ui.pageSinglePlayer->BtnSimpleGamePage, SIGNAL(clicked()), this, SLOT(SimpleGame()));
    connect(ui.pageSinglePlayer->BtnTrainPage, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageSinglePlayer->BtnTrainPage, ID_PAGE_TRAINING);

    connect(ui.pageSinglePlayer->BtnCampaignPage, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageSinglePlayer->BtnCampaignPage, ID_PAGE_CAMPAIGN);

    connect(ui.pageSinglePlayer->BtnMultiplayer, SIGNAL(clicked()), pageSwitchMapper, SLOT(map()));
    pageSwitchMapper->setMapping(ui.pageSinglePlayer->BtnMultiplayer, ID_PAGE_MULTIPLAYER);

    connect(ui.pageSinglePlayer->BtnLoad, SIGNAL(clicked()), this, SLOT(GoToSaves()));
    connect(ui.pageSinglePlayer->BtnDemos, SIGNAL(clicked()), this, SLOT(GoToDemos()));

    connect(ui.pageTraining, SIGNAL(startMission(const QString&, const QString&)), this, SLOT(startTraining(const QString&, const QString&)));

    connect(ui.pageCampaign->BtnStartCampaign, SIGNAL(clicked()), this, SLOT(StartCampaign()));
    connect(ui.pageCampaign->btnPreview, SIGNAL(clicked()), this, SLOT(StartCampaign()));
    connect(ui.pageCampaign->CBTeam, SIGNAL(currentIndexChanged(int)), this, SLOT(UpdateCampaignPage(int)));
    connect(ui.pageCampaign->CBTeam, SIGNAL(currentIndexChanged(int)), this, SLOT(UpdateCampaignPageTeam(int)));
    connect(ui.pageCampaign->CBCampaign, SIGNAL(currentIndexChanged(int)), this, SLOT(UpdateCampaignPage(int)));
    connect(ui.pageCampaign->CBMission, SIGNAL(currentIndexChanged(int)), this, SLOT(UpdateCampaignPageMission(int)));
    connect(ui.pageTraining->CBTeam, SIGNAL(currentIndexChanged(int)), this, SLOT(UpdateTrainingPageTeam(int)));
    connect(ui.pageCampaign->CBTeam, SIGNAL(currentIndexChanged(int)), ui.pageTraining->CBTeam, SLOT(setCurrentIndex(int)));
    connect(ui.pageTraining->CBTeam, SIGNAL(currentIndexChanged(int)), ui.pageCampaign->CBTeam, SLOT(setCurrentIndex(int)));

    connect(ui.pageSelectWeapon->pWeapons, SIGNAL(weaponsDeleted(QString)),
             this, SLOT(DeleteWeapons(QString)));
    connect(ui.pageSelectWeapon->pWeapons, SIGNAL(weaponsAdded(QString, QString)),
             this, SLOT(AddWeapons(QString, QString)));
    connect(ui.pageSelectWeapon->pWeapons, SIGNAL(weaponsEdited(QString, QString, QString)),
             this, SLOT(EditWeapons(QString, QString, QString)));
    connect(ui.pageSelectWeapon->pWeapons, SIGNAL(weaponsEdited(QString, QString, QString)),
             ui.pageNetGame->pGameCFG, SLOT(resendAmmoData()));

    connect(ui.pageMain->BtnNetLocal, SIGNAL(clicked()), this, SLOT(GoToNet()));
    connect(ui.pageMain->BtnNetOfficial, SIGNAL(clicked()), this, SLOT(NetConnectOfficialServer()));

    connect(ui.pageVideos, SIGNAL(goBack()), config, SLOT(SaveVideosOptions()));

    gameSchemeModel = new GameSchemeModel(this, cfgdir->absolutePath() + "/Schemes/Game");
    ui.pageScheme->setModel(gameSchemeModel);
    ui.pageMultiplayer->gameCFG->GameSchemes->setModel(gameSchemeModel);
    ui.pageOptions->SchemesName->setModel(gameSchemeModel);

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

    ui.Pages->setCurrentIndex(ID_PAGE_INFO);
    PagesStack.push(ID_PAGE_MAIN);
    ((AbstractPage*)ui.Pages->widget(ID_PAGE_MAIN))->triggerPageEnter();
    GoBack();

    connect(config, SIGNAL(frontendFullscreen(bool)), this, SLOT(onFrontendFullscreen(bool)));
    onFrontendFullscreen(config->isFrontendFullscreen());
}

void HWForm::onFrontendFullscreen(bool value)
{
    if (value)
        setWindowState(windowState() | Qt::WindowFullScreen);
    else
    {
        setWindowState(windowState() & ~Qt::WindowFullScreen);
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
    // Scroll bar widget palette
    QList<QScrollBar *> allSBars = findChildren<QScrollBar *>();
    QPalette pal = palette();
    pal.setColor(QPalette::WindowText, QColor(0xff, 0xcc, 0x00));
    pal.setColor(QPalette::Button, QColor(0x00, 0x35, 0x1d));
    pal.setColor(QPalette::Base, QColor(0x00, 0x35, 0x1d));
    pal.setColor(QPalette::Window, QColor(0x00, 0x00, 0x00));

    for (int i = 0; i < allSBars.size(); ++i)
        allSBars.at(i)->setPalette(pal);

    // Set default hyperlink color
    QPalette appPal = qApp->palette();
    appPal.setColor(QPalette::Link, QColor(0xff, 0xff, 0x6e));
    qApp->setPalette(appPal);
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

void HWForm::AddWeapons(QString weaponsName, QString ammo)
{
    QVector<QComboBox*> combos;
    combos.push_back(ui.pageOptions->WeaponsName);
    combos.push_back(ui.pageMultiplayer->gameCFG->WeaponsName);
    combos.push_back(ui.pageNetGame->pGameCFG->WeaponsName);
    combos.push_back(ui.pageSelectWeapon->selectWeaponSet);

    QStringList names = ui.pageSelectWeapon->pWeapons->getWeaponNames();

    for(QVector<QComboBox*>::iterator it = combos.begin(); it != combos.end(); ++it)
    {
        (*it)->addItem(weaponsName, QVariant(ammo));
    }
    ui.pageSelectWeapon->selectWeaponSet->setCurrentIndex(ui.pageSelectWeapon->selectWeaponSet->count()-1);
}

void HWForm::DeleteWeapons(QString weaponsName)
{
    QVector<QComboBox*> combos;
    combos.push_back(ui.pageOptions->WeaponsName);
    combos.push_back(ui.pageMultiplayer->gameCFG->WeaponsName);
    combos.push_back(ui.pageNetGame->pGameCFG->WeaponsName);
    combos.push_back(ui.pageSelectWeapon->selectWeaponSet);

    QStringList names = ui.pageSelectWeapon->pWeapons->getWeaponNames();

    for(QVector<QComboBox*>::iterator it = combos.begin(); it != combos.end(); ++it)
    {
        int pos = (*it)->findText(weaponsName);
        if (pos != -1)
        {
            (*it)->removeItem(pos);
        }
    }
    ui.pageSelectWeapon->pWeapons->deletionDone();
}

void HWForm::EditWeapons(QString oldWeaponsName, QString newWeaponsName, QString ammo)
{
    QVector<QComboBox*> combos;
    combos.push_back(ui.pageOptions->WeaponsName);
    combos.push_back(ui.pageMultiplayer->gameCFG->WeaponsName);
    combos.push_back(ui.pageNetGame->pGameCFG->WeaponsName);
    combos.push_back(ui.pageSelectWeapon->selectWeaponSet);

    QStringList names = ui.pageSelectWeapon->pWeapons->getWeaponNames();

    for(QVector<QComboBox*>::iterator it = combos.begin(); it != combos.end(); ++it)
    {
        int pos = (*it)->findText(oldWeaponsName);
        (*it)->setItemText(pos, newWeaponsName);
        (*it)->setItemData(pos, ammo);
    }
}

void HWForm::UpdateTeamsLists()
{
    QStringList teamslist = config->GetTeamsList();

    if(teamslist.empty())
    {
        QString currentNickName = config->value("net/nick",tr("Guest")+QString("%1").arg(rand())).toString();
        QString teamName;
        int firstHumanTeam = 1;
        int lastHumanTeam = 2;

        // Default team
        if (currentNickName.isEmpty())
        {
            teamName = tr("Team 1");
            firstHumanTeam++;
        }
        else
        {
            teamName = tr("%1's Team").arg(currentNickName);
            lastHumanTeam--;
        }

        HWTeam defaultTeam(teamName);
        // Randomize fort and grave for greater variety by default.
        // But we exclude DLC graves and forts to not have desyncing teams by default
        // TODO: Remove DLC filtering when it isn't neccessary anymore
        HWNamegen::teamRandomGrave(defaultTeam, false);
        HWNamegen::teamRandomFort(defaultTeam, false);
        defaultTeam.saveToFile();
        teamslist.push_back(teamName);

        // Add additional default teams

        // More human teams to allow local multiplayer instantly
        for(int i=firstHumanTeam; i<=lastHumanTeam; i++)
        {
            //: Default team name
            teamName = tr("Team %1").arg(i);
            HWTeam numberTeam(teamName);
            HWNamegen::teamRandomGrave(numberTeam, false);
            HWNamegen::teamRandomFort(numberTeam, false);
            numberTeam.saveToFile();
            teamslist.push_back(teamName);
        }
        // Add 2 default CPU teams
        for(int i=1; i<=5; i=i+2)
        {
            //: Default computer team name
            teamName = tr("Computer %1").arg(i);
            HWTeam numberTeam(teamName);
            HWNamegen::teamRandomGrave(numberTeam, false);
            HWNamegen::teamRandomFort(numberTeam, false);
            numberTeam.setDifficulty(6-i);
            numberTeam.saveToFile();
            teamslist.push_back(teamName);
        }
    }

    ui.pageOptions->CBTeamName->clear();
    ui.pageOptions->CBTeamName->addItems(teamslist);
    ui.pageCampaign->CBTeam->clear();
    ui.pageTraining->CBTeam->clear();
    /* Only show human teams in campaign/training page */
    bool playable = false;
    for(int i=0; i<teamslist.length(); i++)
    {
        HWTeam testTeam = HWTeam(teamslist[i]);
        testTeam.loadFromFile();
        if(testTeam.difficulty() == 0)
        {
            ui.pageCampaign->CBTeam->addItem(teamslist[i]);
            ui.pageTraining->CBTeam->addItem(teamslist[i]);
            playable = true;
        }
    }
    ui.pageCampaign->BtnStartCampaign->setEnabled(playable);
    ui.pageCampaign->btnPreview->setEnabled(playable);
    ui.pageTraining->btnStart->setEnabled(playable);
    ui.pageTraining->btnPreview->setEnabled(playable);
    UpdateTrainingPageTeam(0);
}

void HWForm::GoToNewWeapons()
{
    ui.pageSelectWeapon->pWeapons->newWeaponsName();
    GoToPage(ID_PAGE_SELECTWEAPON);
}

void HWForm::GoToEditWeapons()
{
    ui.pageSelectWeapon->selectWeaponSet->setCurrentIndex(ui.pageOptions->WeaponsName->currentIndex());
    GoToPage(ID_PAGE_SELECTWEAPON);
}

void HWForm::GoToWeapons(int index)
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

void HWForm::GoToHelp()
{
    // For now just opens the Hedgewars Wiki in external browser.
    // TODO: Replace this with an offline help someday (bug 660).
    QDesktopServices::openUrl(QUrl("https://hedgewars.org/wiki"));
}

void HWForm::GoToVideos()
{
    GoToPage(ID_PAGE_VIDEOS);
}

void HWForm::GoToTraining()
{
    GoToPage(ID_PAGE_TRAINING);
}

//TODO: maybe find a better place for this?
QString HWForm::stringifyPageId(quint32 id)
{
    QString pageName;
    switch (id)
    {
      case ID_PAGE_SETUP_TEAM :   pageName = "PAGE_SETUP_TEAM"; break;
      case ID_PAGE_SETUP :        pageName = "PAGE_SETUP"; break;
      case ID_PAGE_MULTIPLAYER :  pageName = "PAGE_MULTIPLAYER"; break;
      case ID_PAGE_DEMOS :        pageName = "PAGE_DEMOS"; break;
      case ID_PAGE_NET :          pageName = "PAGE_NET"; break;
      case ID_PAGE_NETGAME :      pageName = "PAGE_NETGAME"; break;
      case ID_PAGE_INFO :         pageName = "PAGE_INFO"; break;
      case ID_PAGE_MAIN :         pageName = "PAGE_MAIN"; break;
      case ID_PAGE_GAMESTATS :    pageName = "PAGE_GAMESTATS"; break;
      case ID_PAGE_SINGLEPLAYER : pageName = "PAGE_SINGLEPLAYER"; break;
      case ID_PAGE_TRAINING :     pageName = "PAGE_TRAINING"; break;
      case ID_PAGE_SELECTWEAPON : pageName = "PAGE_SELECTWEAPON"; break;
      case ID_PAGE_NETSERVER :    pageName = "PAGE_NETSERVER"; break;
      case ID_PAGE_INGAME :       pageName = "PAGE_INGAME"; break;
      case ID_PAGE_ROOMSLIST :    pageName = "PAGE_ROOMSLIST"; break;
      case ID_PAGE_CONNECTING :   pageName = "PAGE_CONNECTING"; break;
      case ID_PAGE_SCHEME :       pageName = "PAGE_SCHEME"; break;
      case ID_PAGE_ADMIN :        pageName = "PAGE_ADMIN"; break;
      case ID_PAGE_CAMPAIGN :     pageName = "PAGE_CAMPAIGN"; break;
      case ID_PAGE_DRAWMAP :      pageName = "PAGE_DRAWMAP"; break;
      case ID_PAGE_DATADOWNLOAD : pageName = "PAGE_DATADOWNLOAD"; break;
      case ID_PAGE_VIDEOS :       pageName = "PAGE_VIDEOS"; break;
      case MAX_PAGE :             pageName = "MAX_PAGE"; break;
      default :                   pageName = "UNKNOWN_PAGE"; break;
    }
    return pageName;
}

void HWForm::OnPageShown(quint8 id, quint8 lastid)
{
#ifdef QT_DEBUG
    qDebug("Leaving %s, entering %s", qPrintable(stringifyPageId(lastid)), qPrintable(stringifyPageId(id)));
#endif
    if (lastid == ID_PAGE_MAIN)
    {
        ui.pageMain->resetNetworkChoice();
    }

    // pageEnter and pageLeave events
    ((AbstractPage*)ui.Pages->widget(lastid))->triggerPageLeave();
    ((AbstractPage*)ui.Pages->widget(id))->triggerPageEnter();

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
        for (QStringList::iterator it = tmNames.begin(); it != tmNames.end(); ++it)
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

    if (id == ID_PAGE_GAMESTATS)
    {
        switch(lastGameType) {
        case gtLocal:
        case gtQLocal:
        case gtTraining:
        case gtCampaign:
            ui.pageGameStats->restartBtnVisible(true);
            break;
        default:
            ui.pageGameStats->restartBtnVisible(false);
            break;
        }
    }

    if (id == ID_PAGE_MAIN)
    {
        ui.pageOptions->setTeamOptionsEnabled(true);
    }
}

void HWForm::GoToPage(int id)
{
    //bool stopAnim = false;

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
    //if (!stopAnim)
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

        // let's hide the old slide after its animation has finished
        connect(animationOldSlide, SIGNAL(finished()), ui.Pages->widget(lastid), SLOT(hide()));

        // start animations
        animationOldSlide->start(QAbstractAnimation::DeleteWhenStopped);
        animationNewSlide->start(QAbstractAnimation::DeleteWhenStopped);

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
        ((AbstractPage*)ui.Pages->widget(ID_PAGE_MAIN))->triggerPageLeave();
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
        if (id == ID_PAGE_NETGAME)
        {
            stopAnim = true;
            GoBack();
        }

    if (curid == ID_PAGE_CAMPAIGN)
        config->setValue("frontend/lastSingleplayerTeam", ui.pageCampaign->CBTeam->currentText());
    if (curid == ID_PAGE_TRAINING)
        config->setValue("frontend/lastSingleplayerTeam", ui.pageTraining->CBTeam->currentText());

    if (curid == ID_PAGE_ROOMSLIST || curid == ID_PAGE_CONNECTING) NetDisconnect();
    if (curid == ID_PAGE_NETGAME && hwnet && hwnet->isInRoom()) hwnet->partRoom();
    // need to work on this, can cause invalid state for admin quit trying to prevent bad state message on kick
    //if (curid == ID_PAGE_NETGAME && (!game || game->gameState != gsStarted)) hwnet->partRoom();

    if (curid == ID_PAGE_SCHEME)
        gameSchemeModel->Save();

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

        // let's hide the old slide after its animation has finished
        connect(animationNewSlide, SIGNAL(finished()), ui.Pages->widget(curid), SLOT(hide()));

        // start animations
        animationOldSlide->start(QAbstractAnimation::DeleteWhenStopped);
        animationNewSlide->start(QAbstractAnimation::DeleteWhenStopped);
    }
#endif

    if (stopAnim)
        ui.Pages->widget(curid)->hide();

// TODO the whole pages shown and effects stuff should be moved
// out of hwform.cpp and into a subclass of QStackedLayout

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
    QString teamName = QLineEdit::tr("unnamed");
    QStringList teamslist = config->GetTeamsList();
    if(teamslist.contains(teamName))
    {
        //name already used -> look for an appropriate name:
        int i=2;
        while(teamslist.contains(teamName = QLineEdit::tr("unnamed (%1)").arg(i++)));
    }

    ui.pageEditTeam->createTeam(teamName, playerHash);
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
    ui.pageEditTeam->deleteTeam(teamName);
    UpdateTeamsLists();
}

void HWForm::DeleteScheme()
{
    ui.pageScheme->selectScheme->setCurrentIndex(ui.pageOptions->SchemesName->currentIndex());
    if (ui.pageOptions->SchemesName->currentIndex() < gameSchemeModel->numberOfDefaultSchemes)
    {
        MessageDialog::ShowErrorMessage(QMessageBox::tr("Cannot delete default scheme '%1'!").arg(ui.pageOptions->SchemesName->currentText()), this);
    }
    else
    {
        ui.pageScheme->deleteRow();
        gameSchemeModel->Save();
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
        MessageDialog::ShowErrorMessage(QMessageBox::tr("Please select a record from the list"), this);
        return;
    }
    CreateGame(0, 0, 0);
    game->PlayDemo(curritem->data(Qt::UserRole).toString(), ui.pagePlayDemo->isSave());
}

void HWForm::PlayDemoQuick(const QString & demofilename)
{
    GoToPage(ID_PAGE_MAIN);
    //GoBack() <- don't or you'll close the socket
    CreateGame(0, 0, 0);
    game->PlayDemo(demofilename, false);
}

void HWForm::NetConnectQuick(const QString & host, quint16 port)
{
    GoToPage(ID_PAGE_MAIN);
    NetConnectServer(host, port);
}

void HWForm::NetConnectServer(const QString & host, quint16 port)
{
    qDebug("connecting to %s:%d", qPrintable(host), port);
    _NetConnect(host, port, ui.pageOptions->editNetNick->text().trimmed());
}

void HWForm::NetConnectOfficialServer()
{
    NetConnectServer(NETGAME_DEFAULT_SERVER, NETGAME_DEFAULT_PORT);
}

void HWForm::NetPassword(const QString & nick)
{
    Q_UNUSED(nick);
    //Get hashes
    QString hash =  config->passwordHash();
    QString temphash =  config->tempHash();

    //Check them

    if (temphash.isEmpty() && hash.isEmpty()) { //If the user enters a registered nick with no password, sends a bogus hash
        hwnet->SendPasswordHash("THISISNOHASH");
    }
    else if (temphash.isEmpty()) { //Send saved hash as default
        hwnet->SendPasswordHash(hash);
    }
    else { //Send the hash
        hwnet->SendPasswordHash(temphash);
    }

    //Remove temporary hash from config
    config->clearTempHash();
}

void HWForm::NetNickRegistered(const QString & nick)
{
    //Get hashes
    QString hash =  config->passwordHash();
    QString temphash =  config->tempHash();

    if (hash.isEmpty()) {
        if (temphash.isEmpty()) { //If the user enters a registered nick with no password
            QString suppliedpass;
            while (suppliedpass.isEmpty()) {
                QInputDialog nickRegedDialog(this);
                nickRegedDialog.setWindowModality(Qt::WindowModal);
                nickRegedDialog.setInputMode(QInputDialog::TextInput);
                nickRegedDialog.setWindowTitle(tr("Hedgewars - Nick registered"));
                nickRegedDialog.setLabelText(tr("This nick is registered, and you haven't specified a password.\n\nIf this nick isn't yours, please register your own nick at www.hedgewars.org\n\nPassword:"));
                nickRegedDialog.setTextEchoMode(QLineEdit::Password);
                nickRegedDialog.exec();

                suppliedpass = nickRegedDialog.textValue();

                if (nickRegedDialog.result() == QDialog::Rejected) {
                    config->clearPasswordHash();
                    config->clearTempHash();
                    GoBack();
                    return;
                }
                temphash = QCryptographicHash::hash(suppliedpass.toUtf8(), QCryptographicHash::Md5).toHex();
                config->setTempHash(temphash);
            }
        }
    }
    NetPassword(nick);
}

void HWForm::NetNickNotRegistered(const QString & nick)
{
    Q_UNUSED(nick);

    QMessageBox noRegMsg(this);
    noRegMsg.setIcon(QMessageBox::Information);
    noRegMsg.setWindowTitle(QMessageBox::tr("Hedgewars - Nick not registered"));
    noRegMsg.setWindowModality(Qt::WindowModal);
    noRegMsg.setText(tr("Your nickname is not registered.\nTo prevent someone else from using it,\nplease register it at www.hedgewars.org"));

    if (!config->passwordHash().isEmpty())
    {
        config->clearPasswordHash();
        noRegMsg.setText(noRegMsg.text()+tr("\n\nYour password wasn't saved either."));
    }
    if (!config->tempHash().isEmpty())
    {
        config->clearTempHash();
    }
    noRegMsg.exec();
}

void HWForm::NetNickTaken(const QString & nick)
{
    bool ok = false;
    QString newNick = QInputDialog::getText(this, tr("Nickname"), tr("Someone already uses your nickname %1 on the server.\nPlease pick another nickname:").arg(nick), QLineEdit::Normal, nick, &ok);

    if (!ok || newNick.isEmpty())
    {
        //ForcedDisconnect(tr("No nickname supplied."));
        bool retry = RetryDialog(tr("Hedgewars - Empty nickname"), tr("No nickname supplied."));
        GoBack();
        if (retry && hwnet) {
            if (hwnet->m_private_game) {
                QStringList list = hwnet->getHost().split(":");
                NetConnectServer(list.at(0), list.at(1).toShort());
            } else
                NetConnectOfficialServer();
        }
        return;
    }

    if(hwnet)
        hwnet->NewNick(newNick);
    config->setValue("net/nick", newNick);
    config->updNetNick();

    ui.pageRoomsList->setUser(nick);
    ui.pageNetGame->setUser(nick);
}

void HWForm::NetAuthFailed()
{
    // Set the password blank if case the user tries to join and enter his password again
    config->clearTempHash();

    //Try to login again
    bool retry = RetryDialog(tr("Hedgewars - Wrong password"), tr("You entered a wrong password."));
    GoBack();

    config->clearPasswordHash();
    config->clearTempHash();
    if (retry) {
       NetConnectOfficialServer();
    }
}

void HWForm::askRoomPassword()
{
    QString password = QInputDialog::getText(this, tr("Room password"), tr("The room is protected with password.\nPlease, enter the password:"));
    if(hwnet && !password.isEmpty())
        hwnet->roomPasswordEntered(password);
}

bool HWForm::RetryDialog(const QString & title, const QString & label)
{
    QMessageBox retryMsg(this);
    retryMsg.setIcon(QMessageBox::Warning);
    retryMsg.setWindowTitle(title);
    retryMsg.setText(label);
    retryMsg.setWindowModality(Qt::WindowModal);

    retryMsg.addButton(QMessageBox::Cancel);

    QPushButton *retryButton = retryMsg.addButton(QMessageBox::Ok);
    retryButton->setText(tr("Try Again"));
    retryButton->setFocus();

    retryMsg.exec();

    if (retryMsg.clickedButton() == retryButton) {
       return true;
    }
    return false;
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
            MessageDialog::ShowErrorMessage(errmsg, this);
            /* fallthrough */
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
    Q_UNUSED(nick);

    if (hwnet) {
        // destroy old connection
        hwnet->Disconnect();
        delete hwnet;
        hwnet = NULL;
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
    connect(hwnet, SIGNAL(NickRegistered(const QString&)), this, SLOT(NetNickRegistered(const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(NickNotRegistered(const QString&)), this, SLOT(NetNickNotRegistered(const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(NickTaken(const QString&)), this, SLOT(NetNickTaken(const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(AuthFailed()), this, SLOT(NetAuthFailed()), Qt::QueuedConnection);
    //connect(ui.pageNetGame->BtnBack, SIGNAL(clicked()), hwnet, SLOT(partRoom()));
    connect(hwnet, SIGNAL(askForRoomPassword()), this, SLOT(askRoomPassword()), Qt::QueuedConnection);

    ui.pageRoomsList->chatWidget->setUsersModel(hwnet->lobbyPlayersModel());
    ui.pageNetGame->chatWidget->setUsersModel(hwnet->roomPlayersModel());

// rooms list page stuff
    ui.pageRoomsList->setModel(hwnet->roomsListModel());
    connect(hwnet, SIGNAL(adminAccess(bool)),
            ui.pageRoomsList, SLOT(setAdmin(bool)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(adminAccess(bool)),
            ui.pageRoomsList->chatWidget, SLOT(adminAccess(bool)), Qt::QueuedConnection);

    connect(hwnet, SIGNAL(serverMessage(const QString&)),
            ui.pageRoomsList->chatWidget, SLOT(onServerMessage(const QString&)), Qt::QueuedConnection);

    connect(ui.pageRoomsList, SIGNAL(askForCreateRoom(const QString &, const QString &)),
            hwnet, SLOT(CreateRoom(const QString&, const QString &)));
    connect(ui.pageRoomsList, SIGNAL(askForJoinRoom(const QString &, const QString &)),
            hwnet, SLOT(JoinRoom(const QString&, const QString &)));
//  connect(ui.pageRoomsList, SIGNAL(askForCreateRoom(const QString &)),
//      this, SLOT(NetGameMaster()));
//  connect(ui.pageRoomsList, SIGNAL(askForJoinRoom(const QString &)),
//      this, SLOT(NetGameSlave()));
    connect(ui.pageRoomsList, SIGNAL(askForRoomList()),
            hwnet, SLOT(askRoomsList()));

// room status stuff
    connect(hwnet, SIGNAL(roomMaster(bool)),
            this, SLOT(NetGameChangeStatus(bool)));

// net page stuff
    connect(hwnet, SIGNAL(roomNameUpdated(const QString &)),
            ui.pageNetGame, SLOT(setRoomName(const QString &)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(roomChatAction(const QString&, const QString&)),
            ui.pageNetGame->chatWidget, SLOT(onChatAction(const QString&, const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(roomChatMessage(const QString&, const QString&)),
            ui.pageNetGame->chatWidget, SLOT(onChatMessage(const QString&, const QString&)), Qt::QueuedConnection);

    connect(hwnet, SIGNAL(roomMaster(bool)),
            ui.pageNetGame->chatWidget, SLOT(adminAccess(bool)), Qt::QueuedConnection);
    connect(ui.pageNetGame->chatWidget, SIGNAL(chatLine(const QString&)),
            hwnet, SLOT(chatLineToNetWithEcho(const QString&)));
    connect(ui.pageNetGame->BtnGo, SIGNAL(clicked()), hwnet, SLOT(ToggleReady()));
    connect(hwnet, SIGNAL(setMyReadyStatus(bool)),
            ui.pageNetGame, SLOT(setReadyStatus(bool)), Qt::QueuedConnection);

// chat widget actions
    connect(ui.pageNetGame->chatWidget, SIGNAL(kick(const QString&)),
            hwnet, SLOT(kickPlayer(const QString&)));
    connect(ui.pageNetGame->chatWidget, SIGNAL(delegate(const QString&)),
            hwnet, SLOT(delegateToPlayer(const QString&)));
    connect(ui.pageNetGame->chatWidget, SIGNAL(ban(const QString&)),
            hwnet, SLOT(banPlayer(const QString&)));
    connect(ui.pageNetGame->chatWidget, SIGNAL(info(const QString&)),
            hwnet, SLOT(infoPlayer(const QString&)));
    connect(ui.pageNetGame->chatWidget, SIGNAL(follow(const QString&)),
            hwnet, SLOT(followPlayer(const QString&)));
    connect(ui.pageNetGame->chatWidget, SIGNAL(consoleCommand(const QString&)),
            hwnet, SLOT(consoleCommand(const QString&)));
    connect(ui.pageRoomsList->chatWidget, SIGNAL(kick(const QString&)),
            hwnet, SLOT(kickPlayer(const QString&)));
    connect(ui.pageRoomsList->chatWidget, SIGNAL(ban(const QString&)),
            hwnet, SLOT(banPlayer(const QString&)));
    connect(ui.pageRoomsList->chatWidget, SIGNAL(info(const QString&)),
            hwnet, SLOT(infoPlayer(const QString&)));
    connect(ui.pageRoomsList->chatWidget, SIGNAL(follow(const QString&)),
            hwnet, SLOT(followPlayer(const QString&)));
    connect(ui.pageRoomsList->chatWidget, SIGNAL(consoleCommand(const QString&)),
            hwnet, SLOT(consoleCommand(const QString&)));

// player info
    connect(hwnet, SIGNAL(playerInfo(const QString&, const QString&, const QString&, const QString&)),
            ui.pageRoomsList->chatWidget, SLOT(onPlayerInfo(const QString&, const QString&, const QString&, const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(playerInfo(const QString&, const QString&, const QString&, const QString&)),
            ui.pageNetGame->chatWidget, SLOT(onPlayerInfo(const QString&, const QString&, const QString&, const QString&)), Qt::QueuedConnection);

// chatting
    connect(ui.pageRoomsList->chatWidget, SIGNAL(chatLine(const QString&)),
            hwnet, SLOT(chatLineToLobby(const QString&)));
    connect(hwnet, SIGNAL(lobbyChatAction(const QString&,const QString&)),
            ui.pageRoomsList->chatWidget, SLOT(onChatAction(const QString&,const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(lobbyChatMessage(const QString&, const QString&)),
            ui.pageRoomsList->chatWidget, SLOT(onChatMessage(const QString&, const QString&)), Qt::QueuedConnection);

// nick list stuff
    {
        QSortFilterProxyModel * playersSortFilterModel = qobject_cast<QSortFilterProxyModel *>(hwnet->lobbyPlayersModel());
        if(playersSortFilterModel)
        {
            PlayersListModel * players = qobject_cast<PlayersListModel *>(playersSortFilterModel->sourceModel());
            connect(players, SIGNAL(nickAdded(const QString&, bool)),
                    ui.pageNetGame->chatWidget, SLOT(nickAdded(const QString&, bool)));
            connect(players, SIGNAL(nickRemoved(const QString&)),
                    ui.pageNetGame->chatWidget, SLOT(nickRemoved(const QString&)));
            connect(players, SIGNAL(nickAddedLobby(const QString&, bool)),
                    ui.pageRoomsList->chatWidget, SLOT(nickAdded(const QString&, bool)));
            connect(players, SIGNAL(nickRemovedLobby(const QString&)),
                    ui.pageRoomsList->chatWidget, SLOT(nickRemoved(const QString&)));
            connect(players, SIGNAL(nickRemovedLobby(const QString&, const QString&)),
                    ui.pageRoomsList->chatWidget, SLOT(nickRemoved(const QString&, const QString&)));
        }
    }

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
    connect(hwnet, SIGNAL(bansList(const QStringList &)), ui.pageAdmin, SLOT(setBansList(const QStringList &)));
    connect(ui.pageAdmin, SIGNAL(setServerMessageNew(const QString&)), hwnet, SLOT(setServerMessageNew(const QString &)));
    connect(ui.pageAdmin, SIGNAL(setServerMessageOld(const QString&)), hwnet, SLOT(setServerMessageOld(const QString &)));
    connect(ui.pageAdmin, SIGNAL(setProtocol(int)), hwnet, SLOT(setLatestProtocolVar(int)));
    connect(ui.pageAdmin, SIGNAL(askServerVars()), hwnet, SLOT(askServerVars()));
    connect(ui.pageAdmin, SIGNAL(clearAccountsCache()), hwnet, SLOT(clearAccountsCache()));
    connect(ui.pageAdmin, SIGNAL(bansListRequest()), hwnet, SLOT(getBanList()));
    connect(ui.pageAdmin, SIGNAL(removeBan(QString)), hwnet, SLOT(removeBan(QString)));
    connect(ui.pageAdmin, SIGNAL(banIP(QString,QString,int)), hwnet, SLOT(banIP(QString,QString,int)));
    connect(ui.pageAdmin, SIGNAL(banNick(QString,QString,int)), hwnet, SLOT(banNick(QString,QString,int)));

// disconnect
    connect(hwnet, SIGNAL(disconnected(const QString&)), this, SLOT(ForcedDisconnect(const QString&)), Qt::QueuedConnection);

// config stuff
    connect(hwnet, SIGNAL(paramChanged(const QString &, const QStringList &)), ui.pageNetGame->pGameCFG, SLOT(setParam(const QString &, const QStringList &)));
    connect(ui.pageNetGame->pGameCFG, SIGNAL(paramChanged(const QString &, const QStringList &)), hwnet, SLOT(onParamChanged(const QString &, const QStringList &)));
    connect(hwnet, SIGNAL(configAsked()), ui.pageNetGame->pGameCFG, SLOT(fullNetConfig()));

    // using proxy slot to prevent loss of game messages when they're sent to not yet connected slot of game object
    connect(hwnet, SIGNAL(FromNet(const QByteArray &)), this, SLOT(FromNetProxySlot(const QByteArray &)), Qt::QueuedConnection);

    //nick and pass stuff
    hwnet->m_private_game = !(hostName == NETGAME_DEFAULT_SERVER && port == NETGAME_DEFAULT_PORT);
    if (hwnet->m_private_game == false && AskForNickAndPwd() != 0)
        return;

    QString nickname = config->value("net/nick",tr("Guest")+QString("%1").arg(rand())).toString();
    ui.pageRoomsList->setUser(nickname);
    ui.pageNetGame->setUser(nickname);

    hwnet->Connect(hostName, port, nickname);
}

int HWForm::AskForNickAndPwd(void)
{
    //remove temppasswordhash just in case
    config->clearTempHash();

    //initialize
    QString hash;
    QString temphash;
    QString nickname;
    QString password;

    do {
        nickname = config->value("net/nick",tr("Guest")+QString("%1").arg(rand())).toString();
        hash = config->passwordHash();
        temphash = config->tempHash();

        //if something from login is missing, start dialog loop
        if (nickname.isEmpty() || hash.isEmpty()) {
            //open dialog
            HWPasswordDialog * pwDialog = new HWPasswordDialog(this);
            // make the "new account" button dialog open a browser with the registration page
            connect(pwDialog->pbNewAccount, SIGNAL(clicked()), this, SLOT(openRegistrationPage()));
            pwDialog->cbSave->setChecked(config->value("net/savepassword", true).toBool());

            //if nickname is present, put it into the field
            if (!nickname.isEmpty()) {
                pwDialog->leNickname->setText(nickname);
                pwDialog->lePassword->setFocus();
            }

            //if dialog aborted, return failure
            if (pwDialog->exec() != QDialog::Accepted) {
                delete pwDialog;
                GoBack();
                return 1;
            }

            //set nick and pass from the dialog
            nickname = pwDialog->leNickname->text();
            password = pwDialog->lePassword->text();
            bool save = pwDialog->cbSave->isChecked();
            //clean up
            delete pwDialog;

            //check the nickname variable
            if (nickname.isEmpty()) {
                int retry = RetryDialog(tr("Hedgewars - Empty nickname"), tr("No nickname supplied."));
                GoBack();
                if (retry) {
                    if (hwnet->m_private_game) {
                        QStringList list = hwnet->getHost().split(":");
                        NetConnectServer(list.at(0), list.at(1).toShort());
                    } else
                        NetConnectOfficialServer();
                }
                break; //loop restart
            } else {
                //update nickname if it's fine
                config->setValue("net/nick", nickname);
                config->updNetNick();
            }

            //check the password variable
            if (password.isEmpty()) {
                config->clearPasswordHash();
                break;
            }  else {
                //calculate temphash and set it into config
                temphash = QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Md5).toHex();
                config->setTempHash(temphash);

                //if user wants to save password
                config->setValue("net/savepassword", save);
                if (save) {
                    // user wants to save password
                    ui.pageOptions->CBSavePassword->setChecked(true);
                    config->setPasswordHash(temphash);
                }
            }
        }
    } while (nickname.isEmpty() || (hash.isEmpty() && temphash.isEmpty())); //while a nickname, or both hashes are missing

    return 0;
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
        MessageDialog::ShowErrorMessage(QMessageBox::tr("Unable to start server"), this);

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
    if (reason == "Reconnected too fast") { //TODO: this is a hack, which should be remade
        bool retry = RetryDialog(tr("Hedgewars - Connection error"), tr("You reconnected too fast.\nPlease wait a few seconds and try again."));
        if (retry) {
            if (hwnet->m_private_game) {
                QStringList list = hwnet->getHost().split(":");
                NetConnectServer(list.at(0), list.at(1).toUInt());
            } else
                NetConnectOfficialServer();
        }
        else {
            while (ui.Pages->currentIndex() != ID_PAGE_NET
                && ui.Pages->currentIndex() != ID_PAGE_MAIN)
            {
                GoBack();
            }
        }
        return;
    }
    if (pnetserver)
        return; // we have server - let it care of all things
    if (hwnet && (reason != "bye"))
    {
        QString errorStr = QMessageBox::tr("The connection to the server is lost.") + (reason.isEmpty()?"":("\n\n" + HWNewNet::tr("Reason:") + "\n" + reason));
        MessageDialog::ShowErrorMessage(errorStr, this);
    }

    while (ui.Pages->currentIndex() != ID_PAGE_NET
        && ui.Pages->currentIndex() != ID_PAGE_MAIN)
    {
        GoBack();
    }
}

void HWForm::NetConnected()
{
    GoToPage(ID_PAGE_ROOMSLIST);
}

void HWForm::NetGameEnter()
{
    ui.pageNetGame->chatWidget->clear();
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
            Music(ui.pageOptions->CBFrontendMusic->isChecked());
            if (wBackground) wBackground->startAnimation();
            GoToPage(ID_PAGE_GAMESTATS);
            if (hwnet)
            {
                if (!game || !game->netSuspend)
                    hwnet->gameFinished(true);
                // After a game, the local player might have pseudo-teams left
                // when rejoining a previously left game. This makes sure the
                // teams list is in a consistent state.
                ui.pageNetGame->cleanupFakeNetTeams();
            }
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
                Music(ui.pageOptions->CBFrontendMusic->isChecked());
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
    connect(game, SIGNAL(TrainingStateChanged(int)), this, SLOT(UpdateTrainingPageTeam(int)));
    connect(game, SIGNAL(GameStateChanged(GameState)), this, SLOT(GameStateChanged(GameState)));
    connect(game, SIGNAL(GameStats(char, const QString &)), ui.pageGameStats, SLOT(GameStats(char, const QString &)));
    connect(game, SIGNAL(ErrorMessage(const QString &)), this, SLOT(ShowFatalErrorMessage(const QString &)), Qt::QueuedConnection);
    connect(game, SIGNAL(HaveRecord(RecordType, const QByteArray &)), this, SLOT(GetRecord(RecordType, const QByteArray &)));
    m_lastDemo = QByteArray();
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

        recordFileName += "_" + *cRevisionString + "-" + *cHashString;

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
            MessageDialog::ShowErrorMessage(tr("Cannot save record to file %1").arg(filename), this);
        else
        {
            demofile.write(demo);
            demofile.close();
        }
    }

    ui.pageVideos->startEncoding(record);
}

void HWForm::startTraining(const QString & scriptName, const QString & subFolder)
{
    CreateGame(0, 0, 0);

    QString trainTeam = ui.pageTraining->CBTeam->currentText();
    game->StartTraining(scriptName, subFolder, trainTeam);
}

void HWForm::StartCampaign()
{
    CreateGame(0, 0, 0);
    QString camp = ui.pageCampaign->CBCampaign->itemData(ui.pageCampaign->CBCampaign->currentIndex()).toString();
    QString miss = campaignMissionInfo[ui.pageCampaign->CBMission->currentIndex()].script;
    QString campTeam = ui.pageCampaign->CBTeam->currentText();
    game->StartCampaign(camp, miss, campTeam);
}

void HWForm::CreateNetGame()
{
    // go back in pages to prevent user from being stuck on certain pages
    if(ui.Pages->currentIndex() == ID_PAGE_GAMESTATS ||
       ui.Pages->currentIndex() == ID_PAGE_INGAME)
        GoBack();

    QString ammo;
    ammo = ui.pageNetGame->pGameCFG->WeaponsName->itemData(
               ui.pageNetGame->pGameCFG->WeaponsName->currentIndex()
           ).toString();

    CreateGame(ui.pageNetGame->pGameCFG, ui.pageNetGame->pNetTeamsWidget, ammo);

    connect(game, SIGNAL(SendNet(const QByteArray &)), hwnet, SLOT(SendNet(const QByteArray &)));
    connect(game, SIGNAL(SendChat(const QString &)), hwnet, SLOT(chatLineToNet(const QString &)));
    connect(game, SIGNAL(SendConsoleCommand(const QString&)), hwnet, SLOT(consoleCommand(const QString&)));
    connect(game, SIGNAL(SendTeamMessage(const QString &)), hwnet, SLOT(SendTeamMessage(const QString &)));
    connect(hwnet, SIGNAL(chatStringFromNet(const QString &)), game, SLOT(FromNetChat(const QString &)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(Warning(const QString&)), game, SLOT(FromNetWarning(const QString&)), Qt::QueuedConnection);
    connect(hwnet, SIGNAL(Error(const QString&)), game, SLOT(FromNetError(const QString&)), Qt::QueuedConnection);

    game->StartNet();
}

void HWForm::closeEvent(QCloseEvent *event)
{
    config->SaveOptions();
#ifdef VIDEOREC
    config->SaveVideosOptions();
#endif
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
    ui.pageNetGame->restrictUnregistered->setChecked(false);
    ui.pageNetGame->pGameCFG->GameSchemes->setModel(gameSchemeModel);
    ui.pageNetGame->pGameCFG->setMaster(true);
    ui.pageNetGame->pNetTeamsWidget->setInteractivity(true);

    if (hwnet)
    {
        // disconnect connections first to ensure their inexistance and not to connect twice
        ui.pageNetGame->BtnStart->disconnect(this);
        ui.pageNetGame->BtnUpdate->disconnect(hwnet);
        ui.pageNetGame->leRoomName->disconnect(hwnet);
        ui.pageNetGame->restrictJoins->disconnect(hwnet);
        ui.pageNetGame->restrictTeamAdds->disconnect(hwnet);
        ui.pageNetGame->restrictUnregistered->disconnect(hwnet);
        ui.pageNetGame->disconnect(hwnet, SLOT(updateRoomName(const QString&)));

        ui.pageNetGame->setRoomName(hwnet->getRoom());

        connect(ui.pageNetGame->BtnStart, SIGNAL(clicked()), this, SLOT(startGame()));
        connect(ui.pageNetGame, SIGNAL(askForUpdateRoomName(const QString &)), hwnet, SLOT(updateRoomName(const QString &)));
        connect(ui.pageNetGame->restrictJoins, SIGNAL(triggered()), hwnet, SLOT(toggleRestrictJoins()));
        connect(ui.pageNetGame->restrictTeamAdds, SIGNAL(triggered()), hwnet, SLOT(toggleRestrictTeamAdds()));
        connect(ui.pageNetGame->restrictUnregistered, SIGNAL(triggered()), hwnet, SLOT(toggleRegisteredOnly()));
        connect(ui.pageNetGame->pGameCFG->GameSchemes->model(),
                SIGNAL(dataChanged(const QModelIndex &, const QModelIndex &)),
                ui.pageNetGame->pGameCFG,
                SLOT(resendSchemeData())
               );
    }
}

void HWForm::NetGameSlave()
{
    ui.pageNetGame->pGameCFG->setMaster(false);
    ui.pageNetGame->pNetTeamsWidget->setInteractivity(false);

    if (hwnet)
    {
        NetGameSchemeModel * netAmmo = new NetGameSchemeModel(hwnet);
        connect(hwnet, SIGNAL(netSchemeConfig(QStringList)), netAmmo, SLOT(setNetSchemeConfig(QStringList)));

        ui.pageNetGame->pGameCFG->GameSchemes->setModel(netAmmo);

        ui.pageNetGame->setRoomName(hwnet->getRoom());

        ui.pageNetGame->pGameCFG->GameSchemes->view()->disconnect(hwnet);
        connect(hwnet, SIGNAL(netSchemeConfig(QStringList)),
                this, SLOT(selectFirstNetScheme()));
    }

    ui.pageNetGame->setMasterMode(false);
}

void HWForm::FromNetProxySlot(const QByteArray & msg)
{
    if(game)
        game->FromNet(msg);

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

void HWForm::UpdateTrainingPageTeam(int index)
{
    Q_UNUSED(index);
    HWTeam team(ui.pageTraining->CBTeam->currentText());
    QString tName = team.name();

    QListWidget* listWidget;
    for(int w = 0; w < 3; w++)
    {
        switch(w) {
            case 0: listWidget = ui.pageTraining->lstTrainings; break;
            case 1: listWidget = ui.pageTraining->lstChallenges; break;
            case 2: listWidget = ui.pageTraining->lstScenarios; break;
            default: listWidget = ui.pageTraining->lstTrainings; break;
        }
        unsigned int n = listWidget->count();

        for(unsigned int i = 0; i < n; i++)
        {
            QListWidgetItem* item = listWidget->item(i);
            QString missionName = QString(item->data(Qt::UserRole).toString()).replace(QString(" "),QString("_"));
            if(isMissionWon(missionName, tName))
                item->setIcon(finishedIcon);
            else
                item->setIcon(notFinishedIcon);
        }
    }
    ui.pageTraining->updateInfo();
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
        const QString & campaignName = entries[i];
        QString tName = team.name();
        ui.pageCampaign->CBCampaign->addItem(getRealCampName(campaignName), campaignName);
    }

}

void HWForm::RestoreSingleplayerTeamSelection()
{
    QString lastTeam = config->value("frontend/lastSingleplayerTeam", QString()).toString();
    if (!lastTeam.isNull() && !lastTeam.isEmpty())
    {
        int index = ui.pageCampaign->CBTeam->findData(lastTeam, Qt::DisplayRole);
        if(index != -1)
        {
            ui.pageCampaign->CBTeam->setCurrentIndex(index);
            UpdateCampaignPageTeam(index);
        }
        index = ui.pageTraining->CBTeam->findData(lastTeam, Qt::DisplayRole);
        if(index != -1)
        {
            ui.pageTraining->CBTeam->setCurrentIndex(index);
            UpdateTrainingPageTeam(index);
        }
    }
}

void HWForm::UpdateCampaignPage(int index)
{
    Q_UNUSED(index);
    HWTeam team(ui.pageCampaign->CBTeam->currentText());
    QString campaignName = ui.pageCampaign->CBCampaign->currentData().toString();
    QString tName = team.name();

    campaignMissionInfo = getCampMissionList(campaignName,tName);
    ui.pageCampaign->CBMission->clear();

    // Populate mission list
    for(int i=0;i<campaignMissionInfo.size();i++)
    {
        ui.pageCampaign->CBMission->addItem(QString(campaignMissionInfo[i].realName), QString(campaignMissionInfo[i].name));
        if(isCampMissionWon(campaignName, i, tName))
            ui.pageCampaign->CBMission->setItemIcon(i, finishedIcon);
        else
            ui.pageCampaign->CBMission->setItemIcon(i, notFinishedIcon);
    }

    // Select first open mission
    int missionIndex = ui.pageCampaign->CBMission->currentIndex();
    if(isCampMissionWon(campaignName, missionIndex, tName))
    {
        for(int m = 0; m < ui.pageCampaign->CBMission->count(); m++)
        {
            if(!isCampMissionWon(campaignName, m, tName))
            {
                ui.pageCampaign->CBMission->setCurrentIndex(m);
                break;
            }
        }
    }
}

void HWForm::UpdateCampaignPageTeam(int index)
{
    Q_UNUSED(index);
    HWTeam team(ui.pageCampaign->CBTeam->currentText());
    QString tName = team.name();

    QStringList entries = DataManager::instance().entryList(
                                  "Missions/Campaign",
                                  QDir::Dirs,
                                  QStringList("[^\\.]*")
                              );

    unsigned int n = entries.count();

    // Update campaign status
    for(unsigned int i = 0; i < n; i++)
    {
        QString campaignName = QString(entries[i]).replace(QString(" "),QString("_"));
        if(isCampWon(campaignName, tName))
            ui.pageCampaign->CBCampaign->setItemIcon(i, finishedIcon);
        else
            ui.pageCampaign->CBCampaign->setItemIcon(i, notFinishedIcon);
    }
}

void HWForm::UpdateCampaignPageMission(int index)
{
    // update thumbnail and description
    QString campaignName = ui.pageCampaign->CBCampaign->currentData().toString();
    // when campaign changes the UpdateCampaignPageMission is triggered with wrong values
    // this will cause segfault. This check prevents illegal memory reads
    if(index > -1 && index < campaignMissionInfo.count()) {
        ui.pageCampaign->lbltitle->setText("<h2>"+ui.pageCampaign->CBMission->currentText()+"</h2>");
        ui.pageCampaign->lbldescription->setText(campaignMissionInfo[index].description);
        ui.pageCampaign->btnPreview->setIcon(QIcon(campaignMissionInfo[index].image));
    }
}

void HWForm::UpdateCampaignPageProgress(int index)
{
    QString missionTitle = ui.pageCampaign->CBMission->currentData().toString();
    UpdateCampaignPage(0);
    int missionIndex = 0;
    // Restore selected mission (because UpdateCampaignPage repopulated the list)
    for(int i=0;i<ui.pageCampaign->CBMission->count();i++)
    {
        if (ui.pageCampaign->CBMission->itemData(i).toString() == missionTitle)
        {
            missionIndex = i;
            break;
        }
    }

    // Get metadata
    int c = ui.pageCampaign->CBCampaign->currentIndex();
    QString campaignName = ui.pageCampaign->CBCampaign->itemData(c).toString();
    HWTeam team(ui.pageCampaign->CBTeam->currentText());
    QString tName = team.name();

    if(index == gsFinished)
    {
        // Select new mission when current mission went from
        // unfinished to finished.
        if(ui.pageCampaign->currentMissionWon == false &&
           isCampMissionWon(campaignName, missionIndex, tName))
        {
            // Traverse all missions and pick first mission that
            // has not been won.
            bool selected = false;
            // start from mission that comes after the selected one
            for(int m = missionIndex-1; m >= 0;m--)
            {
                if(!isCampMissionWon(campaignName, m, tName))
                {
                    missionIndex = m;
                    selected = true;
                    break;
                }
            }
            // No mission selected? Let's try again from the end of the list
            if(!selected)
            {
                for(int m = ui.pageCampaign->CBMission->count()-1; m > missionIndex-1; m--)
                {
                    if(!isCampMissionWon(campaignName, m, tName))
                    {
                        missionIndex = m;
                        break;
                    }
                }
            }
            // If no mission was selected, the old selection remains unchanged.
        }
    }
    else if(index == gsStarted)
    {
        // Remember the "won" state of current mission before we start it.
        // We'll need it when the game has finished.
        ui.pageCampaign->currentMissionWon = isCampMissionWon(campaignName, missionIndex, tName);
    }

    ui.pageCampaign->CBMission->setCurrentIndex(missionIndex);

    // Update campaign victory status
    if(isCampWon(campaignName, tName))
        ui.pageCampaign->CBCampaign->setItemIcon(c, finishedIcon);
    else
        ui.pageCampaign->CBCampaign->setItemIcon(c, notFinishedIcon);
}

// used for --set-everything [screen width] [screen height] [color dept] [volume] [enable music] [enable sounds] [language file] [full screen] [show FPS] [alternate damage] [timer value] [reduced quality]
QString HWForm::getDemoArguments()
{

    QString prefix = "\"" + datadir->absolutePath() + "\"";
    QString userPrefix = "\"" + cfgdir->absolutePath() + "\"";
#ifdef Q_OS_WIN
    prefix = prefix.replace("/","\\");
    userPrefix = userPrefix.replace("/","\\");
#endif

    std::pair<QRect, QRect> resolutions = config->vid_ResolutionPair();
    return QString("--prefix " + prefix
                   + " --user-prefix " + userPrefix
                   + " --fullscreen-width " + QString::number(resolutions.first.width())
                   + " --fullscreen-height " + QString::number(resolutions.first.height())
                   + " --width " + QString::number(resolutions.second.width())
                   + " --height " + QString::number(resolutions.second.height())
                   + " --volume " + QString::number(config->volume())
                   + (config->isMusicEnabled() ? "" : " --nomusic")
                   + (config->isSoundEnabled() ? "" : " --nosound")
                   + (config->isAudioDampenEnabled() ? "" : " --nodampen")
                   + " --locale " + config->language() + ".txt"
                   + (config->vid_Fullscreen() ? " --fullscreen" : "")
                   + (config->isShowFPSEnabled() ? " --showfps" : "")
                   + (config->isAltDamageEnabled() ? " --altdmg" : "")
                   + " --frame-interval " + QString::number(config->timerInterval())
                   + " --raw-quality " + QString::number(config->translateQuality()))
                   + (!config->Form->ui.pageOptions->CBTeamTag->isChecked() ? " --no-teamtag" : "")
                   + (!config->Form->ui.pageOptions->CBHogTag->isChecked() ? " --no-hogtag" : "")
                   + (!config->Form->ui.pageOptions->CBHealthTag->isChecked() ? " --no-healthtag" : "")
                   + (config->Form->ui.pageOptions->CBTagOpacity->isChecked() ? " --translucent-tags" : "")
                   + (!config->isHolidaySillinessEnabled() ? " --no-holiday-silliness" : "");
}

void HWForm::AssociateFiles()
{
    bool success = true;
    QString arguments = getDemoArguments();
#ifdef _WIN32
    QSettings registry_hkcr("HKEY_CLASSES_ROOT", QSettings::NativeFormat);

    // file extension(s)
    registry_hkcr.setValue(".hwd/Default", "Hedgewars.Demo");
    registry_hkcr.setValue(".hws/Default", "Hedgewars.Save");
    registry_hkcr.setValue("Hedgewars.Demo/Default", tr("Hedgewars Demo File", "File Types"));
    registry_hkcr.setValue("Hedgewars.Save/Default", tr("Hedgewars Save File", "File Types"));
    registry_hkcr.setValue("Hedgewars.Demo/DefaultIcon/Default", "\"" + bindir->absolutePath().replace("/", "\\") + "\\hwdfile.ico\",0");
    registry_hkcr.setValue("Hedgewars.Save/DefaultIcon/Default", "\"" + bindir->absolutePath().replace("/", "\\") + "\\hwsfile.ico\",0");
    registry_hkcr.setValue("Hedgewars.Demo/Shell/Open/Command/Default", "\"" + bindir->absolutePath().replace("/", "\\") + "\\hwengine.exe\" " + arguments + " %1");
    registry_hkcr.setValue("Hedgewars.Save/Shell/Open/Command/Default", "\"" + bindir->absolutePath().replace("/", "\\") + "\\hwengine.exe\" " + arguments + " %1");

    // custom url scheme(s)
    registry_hkcr.setValue("hwplay/Default", "\"URL:Hedgewars ServerAccess Scheme\"");
    registry_hkcr.setValue("hwplay/URL Protocol", "");
    registry_hkcr.setValue("hwplay/DefaultIcon/Default", "\"" + bindir->absolutePath().replace("/", "\\") + "\\hedgewars.exe\",0");
    registry_hkcr.setValue("hwplay/Shell/Open/Command/Default", "\"" + bindir->absolutePath().replace("/", "\\") + "\\hedgewars.exe\"  %1");
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
    if (success) success = system(("cp "+datadir->absolutePath()+"/misc/hedgewars.desktop "+QDir::home().absolutePath()+"/.local/share/applications").toLocal8Bit().constData())==0;
    if (success) success = system(("cp "+datadir->absolutePath()+"/misc/hwengine.desktop "+QDir::home().absolutePath()+"/.local/share/applications").toLocal8Bit().constData())==0;
    if (success) success = system(("update-mime-database "+QDir::home().absolutePath()+"/.local/share/mime").toLocal8Bit().constData())==0;
    if (success) success = system("xdg-mime default hedgewars.desktop x-scheme-handler/hwplay")==0;
    if (success) success = system("xdg-mime default hwengine.desktop application/x-hedgewars-demo")==0;
    if (success) success = system("xdg-mime default hwengine.desktop application/x-hedgewars-save")==0;
    // hack to add user's settings to hwengine. might be better at this point to read in the file, append it, and write it out to its new home.  This assumes no spaces in the data dir path
    if (success) success = system(("sed -i 's|^\\(Exec=.*\\) \\(%f\\)|\\1 \\2 "+arguments+"|' "+QDir::home().absolutePath()+"/.local/share/applications/hwengine.desktop").toLocal8Bit().constData())==0;
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
        MessageDialog::ShowErrorMessage(QMessageBox::tr("File association failed."), this);
}

void HWForm::openRegistrationPage()
{
    QDesktopServices::openUrl(QUrl("https://www.hedgewars.org/user/register"));
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
                    MessageDialog::ShowErrorMessage(tr("Cannot save record to file %1").arg(filePath), this);
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

void HWForm::restartGame()
{
    // get rid off old game stats page
    if(ui.Pages->currentIndex() == ID_PAGE_GAMESTATS)
        GoBack();

    CreateGame(lastGameCfg, lastGameTeamSel, lastGameAmmo);

    switch(lastGameType) {
    case gtTraining:
        game->StartTraining(lastGameStartArgs.at(0).toString(), lastGameStartArgs.at(1).toString(), lastGameStartArgs.at(2).toString());
        break;
    case gtQLocal:
        game->StartQuick();
        break;
    case gtCampaign:
        game->StartCampaign(lastGameStartArgs.at(0).toString(), lastGameStartArgs.at(1).toString(), lastGameStartArgs.at(2).toString());
        break;
    case gtLocal:
        game->StartLocal();
        break;
    default:
        break;
    }
}

void HWForm::ShowFatalErrorMessage(const QString & msg)
{
    MessageDialog::ShowFatalMessage(msg, this);
}

void HWForm::showFeedbackDialog()
{
    QNetworkRequest newRequest(QUrl("https://www.hedgewars.org"));

    QNetworkAccessManager *manager = new QNetworkAccessManager(this);
    QNetworkReply *reply = manager->get(newRequest);
    connect(reply, SIGNAL(finished()), this, SLOT(showFeedbackDialogNetChecked()));
}

void HWForm::showFeedbackDialogNetChecked()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply *>(sender());

    if (reply) {
        switch (reply->error()) {
            case QNetworkReply::NoError:
                {
                    FeedbackDialog dialog(this);
                    dialog.exec();
                }
                break;
            case QNetworkReply::UnknownNetworkError:
                MessageDialog::ShowFatalMessage(
                    tr("Unknown network error (possibly missing SSL library)."), this);
                break;
            default:
                MessageDialog::ShowFatalMessage(
                    QString(tr("This feature requires an Internet connection, but you don't appear to be online (error code: %1).")).arg(reply->error()), this);
                break;
        }
    }
    else {
        MessageDialog::ShowFatalMessage(tr("Internal error: Reply object is invalid."), this);
    }
}

void HWForm::startGame()
{
    QMessageBox questionMsg(this);
    questionMsg.setIcon(QMessageBox::Question);
    questionMsg.setWindowTitle(QMessageBox::tr("Not all players are ready"));
    questionMsg.setText(QMessageBox::tr("Are you sure you want to start this game?\nNot all players are ready."));
    questionMsg.setWindowModality(Qt::WindowModal);
    questionMsg.addButton(QMessageBox::Yes);
    questionMsg.addButton(QMessageBox::Cancel);

    if (hwnet->allPlayersReady() || questionMsg.exec() == QMessageBox::Yes)
        hwnet->startGame();
}
