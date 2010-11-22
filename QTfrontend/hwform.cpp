/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

#include "hwform.h"
#include "game.h"
#include "team.h"
#include "namegen.h"
#include "teamselect.h"
#include "selectWeapon.h"
#include "gameuiconfig.h"
#include "pages.h"
#include "statsPage.h"
#include "hwconsts.h"
#include "newnetclient.h"
#include "gamecfgwidget.h"
#include "netserverslist.h"
#include "netudpserver.h"
#include "chatwidget.h"
#include "playrecordpage.h"
#include "input_ip.h"
#include "ammoSchemeModel.h"
#include "bgwidget.h"
#include "xfire.h"

#ifdef __APPLE__
#include "CocoaInitializer.h"
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

HWForm::HWForm(QWidget *parent)
  : QMainWindow(parent), pnetserver(0), pRegisterServer(0), editedTeam(0), hwnet(0)
{
#ifdef USE_XFIRE
    xfire_init();
#endif
    gameSettings = new QSettings(cfgdir->absolutePath() + "/hedgewars.ini", QSettings::IniFormat);
    frontendEffects = gameSettings->value("frontend/effects", true).toBool();
    playerHash = QString(QCryptographicHash::hash(gameSettings->value("net/nick","").toString().toLatin1(), QCryptographicHash::Md5).toHex());

    ui.setupUi(this);
    setMinimumSize(760, 580);
    setFocusPolicy(Qt::StrongFocus);
    CustomizePalettes();

    ui.pageOptions->CBResolution->addItems(sdli.getResolutions());

    config = new GameUIConfig(this, cfgdir->absolutePath() + "/hedgewars.ini");

    namegen = new HWNamegen();

#ifdef __APPLE__
    panel = new M3Panel;
#ifdef SPARKLE_ENABLED
    AutoUpdater* updater;
    CocoaInitializer initializer;
    updater = new SparkleAutoUpdater(SPARKLE_APPCAST_URL);
    if (updater && config->isAutoUpdateEnabled())
        updater->checkForUpdates();
#endif
#endif

    UpdateTeamsLists();
    UpdateCampaignPage(0);
    UpdateWeapons();

    connect(config, SIGNAL(frontendFullscreen(bool)), this, SLOT(onFrontendFullscreen(bool)));
    onFrontendFullscreen(config->isFrontendFullscreen());

    connect(ui.pageMain->BtnSinglePlayer, SIGNAL(clicked()), this, SLOT(GoToSinglePlayer()));
    connect(ui.pageMain->BtnSetup, SIGNAL(clicked()), this, SLOT(GoToSetup()));
    connect(ui.pageMain->BtnNet, SIGNAL(clicked()), this, SLOT(GoToNetType()));
    connect(ui.pageMain->BtnInfo, SIGNAL(clicked()), this, SLOT(GoToInfo()));
    connect(ui.pageMain->BtnExit, SIGNAL(pressed()), this, SLOT(btnExitPressed()));
    connect(ui.pageMain->BtnExit, SIGNAL(clicked()), this, SLOT(btnExitClicked()));

    connect(ui.pageEditTeam->BtnTeamSave, SIGNAL(clicked()), this, SLOT(TeamSave()));
    connect(ui.pageEditTeam->BtnTeamDiscard, SIGNAL(clicked()), this, SLOT(TeamDiscard()));

    connect(ui.pageEditTeam->signalMapper, SIGNAL(mapped(const int &)), this, SLOT(RandomName(const int &)));
    connect(ui.pageEditTeam->randTeamButton, SIGNAL(clicked()), this, SLOT(RandomNames()));

    connect(ui.pageMultiplayer->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));
    connect(ui.pageMultiplayer->BtnStartMPGame, SIGNAL(clicked()), this, SLOT(StartMPGame()));
    connect(ui.pageMultiplayer->teamsSelect, SIGNAL(setEnabledGameStart(bool)),
        ui.pageMultiplayer->BtnStartMPGame, SLOT(setEnabled(bool)));
    connect(ui.pageMultiplayer, SIGNAL(SetupClicked()), this, SLOT(IntermediateSetup()));
    connect(ui.pageMultiplayer->gameCFG, SIGNAL(goToSchemes(int)), this, SLOT(GoToScheme(int)));
    connect(ui.pageMultiplayer->gameCFG, SIGNAL(goToWeapons(int)), this, SLOT(GoToSelectWeaponSet(int)));

    connect(ui.pagePlayDemo->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));
    connect(ui.pagePlayDemo->BtnPlayDemo, SIGNAL(clicked()), this, SLOT(PlayDemo()));
    connect(ui.pagePlayDemo->DemosList, SIGNAL(doubleClicked (const QModelIndex &)), this, SLOT(PlayDemo()));

    connect(ui.pageOptions->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));
    connect(ui.pageOptions->BtnNewTeam, SIGNAL(clicked()), this, SLOT(NewTeam()));
    connect(ui.pageOptions->BtnEditTeam, SIGNAL(clicked()), this, SLOT(EditTeam()));
    connect(ui.pageOptions->BtnDeleteTeam, SIGNAL(clicked()), this, SLOT(DeleteTeam()));
    connect(ui.pageOptions->BtnSaveOptions, SIGNAL(clicked()), config, SLOT(SaveOptions()));
    connect(ui.pageOptions->BtnSaveOptions, SIGNAL(clicked()), this, SLOT(GoBack()));
#ifndef __APPLE__
    connect(ui.pageOptions->BtnAssociateFiles, SIGNAL(clicked()), this, SLOT(AssociateFiles()));
#endif

    connect(ui.pageOptions->WeaponEdit, SIGNAL(clicked()), this, SLOT(GoToSelectWeapon()));
    connect(ui.pageOptions->WeaponNew, SIGNAL(clicked()), this, SLOT(GoToSelectNewWeapon()));
    connect(ui.pageOptions->WeaponDelete, SIGNAL(clicked()), this, SLOT(DeleteWeaponSet()));
    connect(ui.pageOptions->SchemeEdit, SIGNAL(clicked()), this, SLOT(GoToEditScheme()));
    connect(ui.pageOptions->SchemeNew, SIGNAL(clicked()), this, SLOT(GoToNewScheme()));
    connect(ui.pageOptions->SchemeDelete, SIGNAL(clicked()), this, SLOT(DeleteScheme()));
    connect(ui.pageSelectWeapon->pWeapons, SIGNAL(weaponsChanged()), this, SLOT(UpdateWeapons()));

    connect(ui.pageNet->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));
    connect(ui.pageNet->BtnSpecifyServer, SIGNAL(clicked()), this, SLOT(NetConnect()));
    connect(ui.pageNet->BtnNetSvrStart, SIGNAL(clicked()), this, SLOT(GoToNetServer()));
    connect(ui.pageNet, SIGNAL(connectClicked(const QString &, quint16)), this, SLOT(NetConnectServer(const QString &, quint16)));

    connect(ui.pageNetServer->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));
    connect(ui.pageNetServer->BtnStart, SIGNAL(clicked()), this, SLOT(NetStartServer()));

    connect(ui.pageNetGame->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));
    connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(setEnabledGameStart(bool)),
        ui.pageNetGame->BtnGo, SLOT(setEnabled(bool)));
    connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(setEnabledGameStart(bool)),
        ui.pageNetGame->BtnStart, SLOT(setEnabled(bool)));
    connect(ui.pageNetGame, SIGNAL(SetupClicked()), this, SLOT(IntermediateSetup()));
    connect(ui.pageNetGame->pGameCFG, SIGNAL(goToSchemes(int)), this, SLOT(GoToScheme(int)));
    connect(ui.pageNetGame->pGameCFG, SIGNAL(goToWeapons(int)), this, SLOT(GoToSelectWeaponSet(int)));

    connect(ui.pageRoomsList->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));
    connect(ui.pageRoomsList->BtnAdmin, SIGNAL(clicked()), this, SLOT(GoToAdmin()));

    connect(ui.pageInfo->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));

    connect(ui.pageGameStats->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));

    connect(ui.pageSinglePlayer->BtnSimpleGamePage, SIGNAL(clicked()), this, SLOT(SimpleGame()));
    connect(ui.pageSinglePlayer->BtnTrainPage, SIGNAL(clicked()), this, SLOT(GoToTraining()));
    connect(ui.pageSinglePlayer->BtnCampaignPage, SIGNAL(clicked()), this, SLOT(GoToCampaign()));
    connect(ui.pageSinglePlayer->BtnMultiplayer, SIGNAL(clicked()), this, SLOT(GoToMultiplayer()));
    connect(ui.pageSinglePlayer->BtnLoad, SIGNAL(clicked()), this, SLOT(GoToSaves()));
    connect(ui.pageSinglePlayer->BtnDemos, SIGNAL(clicked()), this, SLOT(GoToDemos()));
    connect(ui.pageSinglePlayer->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));

    connect(ui.pageTraining->BtnStartTrain, SIGNAL(clicked()), this, SLOT(StartTraining()));
    connect(ui.pageTraining->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));

    connect(ui.pageCampaign->BtnStartCampaign, SIGNAL(clicked()), this, SLOT(StartCampaign()));
    connect(ui.pageCampaign->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));
    connect(ui.pageCampaign->CBTeam, SIGNAL(currentIndexChanged(int)), this, SLOT(UpdateCampaignPage(int)));

    connect(ui.pageSelectWeapon->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));

    connect(ui.pageSelectWeapon->BtnDelete, SIGNAL(clicked()),
        ui.pageSelectWeapon->pWeapons, SLOT(deleteWeaponsName())); // executed first
    connect(ui.pageSelectWeapon->pWeapons, SIGNAL(weaponsDeleted()),
        this, SLOT(UpdateWeapons())); // executed second
    //connect(ui.pageSelectWeapon->pWeapons, SIGNAL(weaponsDeleted()),
    //    this, SLOT(GoBack())); // executed third

    connect(ui.pageScheme->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));

    connect(ui.pageAdmin->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));

    connect(ui.pageNetType->BtnBack, SIGNAL(clicked()), this, SLOT(GoBack()));
    connect(ui.pageNetType->BtnLAN, SIGNAL(clicked()), this, SLOT(GoToNet()));
    connect(ui.pageNetType->BtnOfficialServer, SIGNAL(clicked()), this, SLOT(NetConnectOfficialServer()));


    ammoSchemeModel = new AmmoSchemeModel(this, cfgdir->absolutePath() + "/schemes.ini");
    ui.pageScheme->setModel(ammoSchemeModel);
    ui.pageMultiplayer->gameCFG->GameSchemes->setModel(ammoSchemeModel);
    ui.pageOptions->SchemesName->setModel(ammoSchemeModel);

    wBackground = NULL;
    if (config->isFrontendEffects()) {
       wBackground = new BGWidget(this);
       wBackground->setFixedSize(this->width(), this->height());
       wBackground->lower();
       wBackground->init();
       wBackground->startAnimation();
    }

    PagesStack.push(ID_PAGE_MAIN);
    GoBack();
}

#ifdef USE_XFIRE
void HWForm::updateXfire(void)
{
    if(hwnet)
    {
        xfire_setvalue(XFIRE_SERVER, !hwnet->getHost().compare("netserver.hedgewars.org:46631") ? "Official server" : hwnet->getHost().toAscii());
        switch(hwnet->getClientState())
        {
            case 1: // Connecting
            xfire_setvalue(XFIRE_STATUS, "Connecting");
            xfire_setvalue(XFIRE_NICKNAME, "-");
            xfire_setvalue(XFIRE_ROOM, "-");
            case 2: // In lobby
            xfire_setvalue(XFIRE_STATUS, "Online");
            xfire_setvalue(XFIRE_NICKNAME, hwnet->getNick().toAscii());
            xfire_setvalue(XFIRE_ROOM, "In game lobby");
            break;
            case 3: // In room
            xfire_setvalue(XFIRE_STATUS, "Online");
            xfire_setvalue(XFIRE_NICKNAME, hwnet->getNick().toAscii());
            xfire_setvalue(XFIRE_ROOM, (hwnet->getRoom() + " (waiting for players)").toAscii());
            break;
            case 5: // In game
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
  else {
    setWindowState(windowState() & !Qt::WindowFullScreen);
  }
}

void HWForm::keyReleaseEvent(QKeyEvent *event)
{
  if (event->key() == Qt::Key_Escape /*|| event->key() == Qt::Key_Backspace*/ ) 
    this->GoBack();
}

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

    for(QVector<QComboBox*>::iterator it = combos.begin(); it != combos.end(); ++it) {
        (*it)->clear();

        for(int i = 0; i < names.size(); ++i)
            (*it)->addItem(names[i], ui.pageSelectWeapon->pWeapons->getWeaponsString(names[i]));

        int pos = (*it)->findText("Default");
        if (pos != -1) {
            (*it)->setCurrentIndex(pos);
        }
    }
}

void HWForm::UpdateTeamsLists(const QStringList* editable_teams)
{
    QStringList teamslist;
    if(editable_teams) {
      teamslist =* editable_teams;
    } else {
      teamslist = config->GetTeamsList();
    }

    if(teamslist.empty()) {
        HWTeam defaultTeam(tr("DefaultTeam"));
        defaultTeam.SaveToFile();
        teamslist.push_back(tr("DefaultTeam"));
    }

    ui.pageOptions->CBTeamName->clear();
    ui.pageOptions->CBTeamName->addItems(teamslist);
    ui.pageCampaign->CBTeam->clear();
    ui.pageCampaign->CBTeam->addItems(teamslist);
}

void HWForm::GoToMain()
{
    GoToPage(ID_PAGE_MAIN);
}

void HWForm::GoToSinglePlayer()
{
    GoToPage(ID_PAGE_SINGLEPLAYER);
}

void HWForm::GoToTraining()
{
    GoToPage(ID_PAGE_TRAINING);
}

void HWForm::GoToCampaign()
{
    GoToPage(ID_PAGE_CAMPAIGN);
}

void HWForm::GoToSetup()
{
    GoToPage(ID_PAGE_SETUP);
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

void HWForm::GoToInfo()
{
    GoToPage(ID_PAGE_INFO);
}

void HWForm::GoToMultiplayer()
{
    GoToPage(ID_PAGE_MULTIPLAYER);
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

void HWForm::GoToNetType()
{
    GoToPage(ID_PAGE_NETTYPE);
}

void HWForm::GoToNetServer()
{
    GoToPage(ID_PAGE_NETSERVER);
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

void HWForm::GoToAdmin()
{
    GoToPage(ID_PAGE_ADMIN);
}

void HWForm::OnPageShown(quint8 id, quint8 lastid)
{
#ifdef USE_XFIRE
    updateXfire();
#endif
    if (id == ID_PAGE_MULTIPLAYER || id == ID_PAGE_NETGAME) {
        QStringList tmNames = config->GetTeamsList();
        TeamSelWidget* curTeamSelWidget;
        ui.pageOptions->BtnNewTeam->setVisible(false);
        ui.pageOptions->BtnEditTeam->setVisible(false);
        ui.pageOptions->BtnDeleteTeam->setVisible(false);
        ui.pageOptions->CBTeamName->setVisible(false);
        ui.pageOptions->LblNoEditTeam->setVisible(true);

        if(id == ID_PAGE_MULTIPLAYER) {
          curTeamSelWidget = ui.pageMultiplayer->teamsSelect;
        } else {
          curTeamSelWidget = ui.pageNetGame->pNetTeamsWidget;
        }

        QList<HWTeam> teamsList;
        for(QStringList::iterator it = tmNames.begin(); it != tmNames.end(); it++) {
          HWTeam team(*it);
          team.LoadFromFile();
          teamsList.push_back(team);
        }

        if(lastid == ID_PAGE_SETUP) { // _TEAM
          if (editedTeam) {
            curTeamSelWidget->addTeam(*editedTeam);
          }
        } else if(lastid != ID_PAGE_GAMESTATS
                && lastid != ID_PAGE_INGAME
                && lastid != ID_PAGE_SCHEME
                && lastid != ID_PAGE_SELECTWEAPON) {
            curTeamSelWidget->resetPlayingTeams(teamsList);
        }
    } else
    if (id == ID_PAGE_GAMESTATS)
    {
        ui.pageGameStats->renderStats();
    }

    if(id == ID_PAGE_MAIN)
    {
        ui.pageOptions->BtnNewTeam->setVisible(true);
        ui.pageOptions->BtnEditTeam->setVisible(true);
        ui.pageOptions->BtnDeleteTeam->setVisible(true);
        ui.pageOptions->CBTeamName->setVisible(true);
        ui.pageOptions->LblNoEditTeam->setVisible(false);
    }

    // load and save ignore/friends lists
    if(lastid == ID_PAGE_NETGAME) // leaving a room
        ui.pageNetGame->pChatWidget->saveLists(ui.pageOptions->editNetNick->text());
    else if(lastid == ID_PAGE_ROOMSLIST) // leaving the lobby
        ui.pageRoomsList->chatWidget->saveLists(ui.pageOptions->editNetNick->text());

    if(id == ID_PAGE_NETGAME) // joining a room
        ui.pageNetGame->pChatWidget->loadLists(ui.pageOptions->editNetNick->text());
    else if(id == ID_PAGE_ROOMSLIST) // joining the lobby
        ui.pageRoomsList->chatWidget->loadLists(ui.pageOptions->editNetNick->text());
}

void HWForm::GoToPage(quint8 id)
{
    quint8 lastid = ui.Pages->currentIndex();
    PagesStack.push(ui.Pages->currentIndex());
    OnPageShown(id, lastid);
    ui.Pages->setCurrentIndex(id);
}

void HWForm::GoBack()
{
    quint8 id = PagesStack.isEmpty() ? ID_PAGE_MAIN : PagesStack.pop();
    quint8 curid = ui.Pages->currentIndex();
    ui.Pages->setCurrentIndex(id);
    OnPageShown(id, curid);

    if (id == ID_PAGE_CONNECTING)
        GoBack();
    if (id == ID_PAGE_NETSERVER)
        GoBack();
    if ((!hwnet) && (id == ID_PAGE_ROOMSLIST))
        GoBack();

    if ((!hwnet) || (!hwnet->isInRoom()))
        if (id == ID_PAGE_NETGAME || id == ID_PAGE_NETGAME)
            GoBack();

    if (curid == ID_PAGE_ROOMSLIST) NetDisconnect();
    if (curid == ID_PAGE_NETGAME) hwnet->partRoom();

    if (curid == ID_PAGE_SCHEME)
        ammoSchemeModel->Save();
}

void HWForm::btnExitPressed()
{
    eggTimer.start();
}

void HWForm::btnExitClicked()
{
    if (eggTimer.elapsed() < 3000){
#ifdef __APPLE__
        panel->showInstallController();
#endif
        close();
    }
    else
    {
        QPushButton * btn = findChild<QPushButton *>("imageButt");
        if (btn)
        {
            btn->setIcon(QIcon(":/res/bonus.png"));
        }
    }
}

void HWForm::IntermediateSetup()
{
    quint8 id=ui.Pages->currentIndex();
    TeamSelWidget* curTeamSelWidget;

    if(id == ID_PAGE_MULTIPLAYER) {
        curTeamSelWidget = ui.pageMultiplayer->teamsSelect;
    } else {
        curTeamSelWidget = ui.pageNetGame->pNetTeamsWidget;
    }

    QList<HWTeam> teams = curTeamSelWidget->getDontPlayingTeams();
    QStringList tmnames;
    for(QList<HWTeam>::iterator it = teams.begin(); it != teams.end(); ++it) {
        tmnames += it->TeamName;
    }
    //UpdateTeamsLists(&tmnames); // FIXME: still need more work if teamname is updated while configuring
    UpdateTeamsLists();

    GoToPage(ID_PAGE_SETUP);
}

void HWForm::NewTeam()
{
    editedTeam = new HWTeam("unnamed");
    editedTeam->SetToPage(this);
    GoToPage(ID_PAGE_SETUP_TEAM);
}

void HWForm::EditTeam()
{
    editedTeam = new HWTeam(ui.pageOptions->CBTeamName->currentText());
    editedTeam->LoadFromFile();
    editedTeam->SetToPage(this);
    GoToPage(ID_PAGE_SETUP_TEAM);
}

void HWForm::DeleteTeam()
{
    QMessageBox reallyDelete(QMessageBox::Question, QMessageBox::tr("Teams"), QMessageBox::tr("Really delete this team?"), QMessageBox::Ok | QMessageBox::Cancel);

    if (reallyDelete.exec() == QMessageBox::Ok) {
        editedTeam = new HWTeam(ui.pageOptions->CBTeamName->currentText());
        editedTeam->DeleteFile();

        // Remove from lists
        ui.pageOptions->CBTeamName->removeItem(ui.pageOptions->CBTeamName->currentIndex());
    }
}

void HWForm::RandomNames()
{
    editedTeam->GetFromPage(this);
    namegen->TeamRandomNames(editedTeam,FALSE);
    editedTeam->SetToPage(this);
}

void HWForm::RandomName(const int &i)
{
    editedTeam->GetFromPage(this);
    namegen->TeamRandomName(editedTeam,i);
    editedTeam->SetToPage(this);
}

void HWForm::TeamSave()
{
    editedTeam->GetFromPage(this);
    editedTeam->SaveToFile();
    delete editedTeam;
    editedTeam=0;
    UpdateTeamsLists();
    GoBack();
}

void HWForm::TeamDiscard()
{
    delete editedTeam;
    editedTeam=0;
    GoBack();
}

void HWForm::DeleteScheme()
{
    ui.pageScheme->selectScheme->setCurrentIndex(ui.pageOptions->SchemesName->currentIndex());
    if (ui.pageOptions->SchemesName->currentIndex() < ammoSchemeModel->numberOfDefaultSchemes) {
        QMessageBox::warning(0, QMessageBox::tr("Schemes"), QMessageBox::tr("Can not delete default scheme '%1'!").arg(ui.pageOptions->SchemesName->currentText()));
    } else {
        ui.pageScheme->deleteRow();
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
        QMessageBox::critical(this,
                tr("Error"),
                tr("Please select record from the list above"),
                tr("OK"));
        return ;
    }
    CreateGame(0, 0, 0);
    game->PlayDemo(curritem->data(Qt::UserRole).toString());
}

void HWForm::NetConnectServer(const QString & host, quint16 port)
{
    _NetConnect(host, port, ui.pageOptions->editNetNick->text());
}

void HWForm::NetConnectOfficialServer()
{
    NetConnectServer("netserver.hedgewars.org", 46631);
}

void HWForm::_NetConnect(const QString & hostName, quint16 port, const QString & nick)
{
    if(hwnet) {
        hwnet->Disconnect();
        delete hwnet;
        hwnet=0;
    }

    ui.pageRoomsList->chatWidget->clear();

    hwnet = new HWNewNet(config, ui.pageNetGame->pGameCFG, ui.pageNetGame->pNetTeamsWidget);

    GoToPage(ID_PAGE_CONNECTING);

    connect(hwnet, SIGNAL(showMessage(const QString &)), this, SLOT(ShowErrorMessage(const QString &)), Qt::QueuedConnection);

    connect(hwnet, SIGNAL(AskForRunGame()), this, SLOT(CreateNetGame()));
    connect(hwnet, SIGNAL(Connected()), this, SLOT(NetConnected()));
    connect(hwnet, SIGNAL(EnteredGame()), this, SLOT(NetGameEnter()));
    connect(hwnet, SIGNAL(LeftRoom()), this, SLOT(NetLeftRoom()));
    connect(hwnet, SIGNAL(AddNetTeam(const HWTeam&)), this, SLOT(AddNetTeam(const HWTeam&)));
    //connect(ui.pageNetGame->BtnBack, SIGNAL(clicked()), hwnet, SLOT(partRoom()));

// rooms list page stuff
    connect(hwnet, SIGNAL(roomsList(const QStringList&)),
        ui.pageRoomsList, SLOT(setRoomsList(const QStringList&)));
    connect(hwnet, SIGNAL(adminAccess(bool)),
        ui.pageRoomsList, SLOT(setAdmin(bool)));
    connect(hwnet, SIGNAL(adminAccess(bool)),
        ui.pageRoomsList->chatWidget, SLOT(adminAccess(bool)));

    connect(hwnet, SIGNAL(serverMessage(const QString&)),
        ui.pageRoomsList->chatWidget, SLOT(onServerMessage(const QString&)));

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
        this, SLOT(NetGameChangeStatus(bool)));

// net page stuff
    connect(hwnet, SIGNAL(chatStringFromNet(const QString&)),
        ui.pageNetGame->pChatWidget, SLOT(onChatString(const QString&)));
    connect(hwnet, SIGNAL(setReadyStatus(const QString &, bool)),
        ui.pageNetGame->pChatWidget, SLOT(setReadyStatus(const QString &, bool)));
    connect(hwnet, SIGNAL(chatStringFromMe(const QString&)),
        ui.pageNetGame->pChatWidget, SLOT(onChatString(const QString&)));
    connect(hwnet, SIGNAL(roomMaster(bool)),
        ui.pageNetGame->pChatWidget, SLOT(adminAccess(bool)));
    connect(ui.pageNetGame->pChatWidget, SIGNAL(chatLine(const QString&)),
        hwnet, SLOT(chatLineToNet(const QString&)));
    connect(ui.pageNetGame->BtnGo, SIGNAL(clicked()), hwnet, SLOT(ToggleReady()));
    connect(hwnet, SIGNAL(setMyReadyStatus(bool)),
        ui.pageNetGame, SLOT(setReadyStatus(bool)));

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
        ui.pageRoomsList->chatWidget, SLOT(onChatString(const QString&)));
    connect(hwnet, SIGNAL(chatStringFromMeLobby(const QString&)),
        ui.pageRoomsList->chatWidget, SLOT(onChatString(const QString&)));

// nick list stuff
    connect(hwnet, SIGNAL(nickAdded(const QString&, bool)),
        ui.pageNetGame->pChatWidget, SLOT(nickAdded(const QString&, bool)));
    connect(hwnet, SIGNAL(nickRemoved(const QString&)),
        ui.pageNetGame->pChatWidget, SLOT(nickRemoved(const QString&)));
    connect(hwnet, SIGNAL(nickAddedLobby(const QString&, bool)),
        ui.pageRoomsList->chatWidget, SLOT(nickAdded(const QString&, bool)));
    connect(hwnet, SIGNAL(nickRemovedLobby(const QString&)),
        ui.pageRoomsList->chatWidget, SLOT(nickRemoved(const QString&)));

// teams selecting stuff
    connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(hhogsNumChanged(const HWTeam&)),
        hwnet, SLOT(onHedgehogsNumChanged(const HWTeam&)));
    connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(teamColorChanged(const HWTeam&)),
        hwnet, SLOT(onTeamColorChanged(const HWTeam&)));
    connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(teamWillPlay(HWTeam)), hwnet, SLOT(AddTeam(HWTeam)));
    connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(acceptRequested(HWTeam)), hwnet, SLOT(AddTeam(HWTeam)));
    connect(ui.pageNetGame->pNetTeamsWidget, SIGNAL(teamNotPlaying(const HWTeam&)), hwnet, SLOT(RemoveTeam(const HWTeam&)));
    connect(hwnet, SIGNAL(hhnumChanged(const HWTeam&)),
        ui.pageNetGame->pNetTeamsWidget, SLOT(changeHHNum(const HWTeam&)));
    connect(hwnet, SIGNAL(teamColorChanged(const HWTeam&)),
        ui.pageNetGame->pNetTeamsWidget, SLOT(changeTeamColor(const HWTeam&)));

// admin stuff
    connect(hwnet, SIGNAL(serverMessageNew(const QString&)), ui.pageAdmin, SLOT(serverMessageNew(const QString &)));
    connect(hwnet, SIGNAL(serverMessageOld(const QString&)), ui.pageAdmin, SLOT(serverMessageOld(const QString &)));
    connect(hwnet, SIGNAL(latestProtocolVar(int)), ui.pageAdmin, SLOT(protocol(int)));
    connect(ui.pageAdmin, SIGNAL(setServerMessageNew(const QString&)), hwnet, SLOT(setServerMessageNew(const QString &)));
    connect(ui.pageAdmin, SIGNAL(setServerMessageOld(const QString&)), hwnet, SLOT(setServerMessageOld(const QString &)));
    connect(ui.pageAdmin, SIGNAL(setProtocol(int)), hwnet, SLOT(setLatestProtocolVar(int)));
    connect(ui.pageAdmin, SIGNAL(askServerVars()), hwnet, SLOT(askServerVars()));
    connect(ui.pageAdmin->pbClearAccountsCache, SIGNAL(clicked()), hwnet, SLOT(clearAccountsCache()));

// disconnect
    connect(hwnet, SIGNAL(Disconnected()), this, SLOT(ForcedDisconnect()), Qt::QueuedConnection);

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
}

void HWForm::NetStartServer()
{
    config->SaveOptions();

    pnetserver = new HWNetServer;
    if(!pnetserver->StartServer(ui.pageNetServer->sbPort->value()))
    {
        QMessageBox::critical(0, tr("Error"),
                tr("Unable to start the server"));
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
    //qDebug("NetDisconnect");
    if(hwnet) {
        hwnet->Disconnect();
        delete hwnet;
        hwnet = 0;
    }
    if(pnetserver) {
        if (pRegisterServer)
        {
            pRegisterServer->unregister();
            pRegisterServer = 0;
        }

        pnetserver->StopServer();
        delete pnetserver;
        pnetserver = 0;
    }
}

void HWForm::ForcedDisconnect()
{
    if(pnetserver) return; // we have server - let it care of all things
    if (hwnet) {
        hwnet->deleteLater();
        hwnet = 0;
        QMessageBox::warning(this, QMessageBox::tr("Network"),
                QMessageBox::tr("Connection to server is lost"));

    }
    if (ui.Pages->currentIndex() != ID_PAGE_NET) GoBack();
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
    switch(gameState) {
        case gsStarted: {
            Music(false);
            if (wBackground) wBackground->stopAnimation();
            GoToPage(ID_PAGE_INGAME);
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
        case gsFinished: {
            //setVisible(true);
            setFocusPolicy(Qt::StrongFocus);
            GoBack();
            Music(ui.pageOptions->CBEnableFrontendMusic->isChecked());
            if (wBackground) wBackground->startAnimation();
            GoToPage(ID_PAGE_GAMESTATS);
            if (hwnet) hwnet->gameFinished();
            break;
        }
        default: {
            //setVisible(true);
            setFocusPolicy(Qt::StrongFocus);
            quint8 id = ui.Pages->currentIndex();
            if (id == ID_PAGE_INGAME) {
                GoBack();
                Music(ui.pageOptions->CBEnableFrontendMusic->isChecked());
                if (wBackground) wBackground->startAnimation();
                if (hwnet) hwnet->gameFinished();
            }
        };
    }
}

void HWForm::CreateGame(GameCFGWidget * gamecfg, TeamSelWidget* pTeamSelWidget, QString ammo)
{
    game = new HWGame(config, gamecfg, ammo, pTeamSelWidget);
    connect(game, SIGNAL(GameStateChanged(GameState)), this, SLOT(GameStateChanged(GameState)));
    connect(game, SIGNAL(GameStats(char, const QString &)), ui.pageGameStats, SLOT(GameStats(char, const QString &)));
    connect(game, SIGNAL(ErrorMessage(const QString &)), this, SLOT(ShowErrorMessage(const QString &)), Qt::QueuedConnection);
    connect(game, SIGNAL(HaveRecord(bool, const QByteArray &)), this, SLOT(GetRecord(bool, const QByteArray &)));
}

void HWForm::ShowErrorMessage(const QString & msg)
{
    QMessageBox::warning(this,
            "Hedgewars",
            msg);
}

void HWForm::GetRecord(bool isDemo, const QByteArray & record)
{
    QString filename;
    QByteArray demo = record;
    QString recordFileName =
            config->appendDateTimeToRecordName() ?
                QDateTime::currentDateTime().toString("yyyy-MM-dd_hh-mm") :
                "LastRound";

    if (isDemo)
    {
        demo.replace(QByteArray("\x02TL"), QByteArray("\x02TD"));
        demo.replace(QByteArray("\x02TN"), QByteArray("\x02TD"));
        demo.replace(QByteArray("\x02TS"), QByteArray("\x02TD"));
        filename = cfgdir->absolutePath() + "/Demos/" + recordFileName + "." + *cProtoVer + ".hwd";
    } else
    {
        demo.replace(QByteArray("\x02TL"), QByteArray("\x02TS"));
        demo.replace(QByteArray("\x02TN"), QByteArray("\x02TS"));
        filename = cfgdir->absolutePath() + "/Saves/" + recordFileName + "." + *cProtoVer + ".hws";
    }


    QFile demofile(filename);
    if (!demofile.open(QIODevice::WriteOnly))
    {
        ShowErrorMessage(tr("Cannot save record to file %1").arg(filename));
        return ;
    }
    demofile.write(demo.constData(), demo.size());
    demofile.close();
}

void HWForm::StartTraining()
{
    CreateGame(0, 0, 0);

    game->StartTraining(ui.pageTraining->CBSelect->itemData(ui.pageTraining->CBSelect->currentIndex()).toString());
}

void HWForm::StartCampaign()
{
    CreateGame(0, 0, 0);

    game->StartCampaign(ui.pageCampaign->CBSelect->itemData(ui.pageCampaign->CBSelect->currentIndex()).toString());
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
    event->accept();
}

void HWForm::Music(bool checked)
{
    if (checked)
        sdli.StartMusic();
    else
        sdli.StopMusic();
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
    ui.pageNetGame->pGameCFG->GameSchemes->setModel(ammoSchemeModel);
    ui.pageNetGame->pGameCFG->setEnabled(true);
    ui.pageNetGame->pNetTeamsWidget->setInteractivity(true);

    if (hwnet)
    {
        // disconnect connections first to ensure their inexistance and not to connect twice
        ui.pageNetGame->BtnStart->disconnect(hwnet);
        ui.pageNetGame->restrictJoins->disconnect(hwnet);
        ui.pageNetGame->restrictTeamAdds->disconnect(hwnet);
        connect(ui.pageNetGame->BtnStart, SIGNAL(clicked()), hwnet, SLOT(startGame()));
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

void HWForm::NetLeftRoom()
{
    if (ui.Pages->currentIndex() == ID_PAGE_NETGAME)
        GoBack();
    else
        qWarning("Left room while not in room");
}

void HWForm::resizeEvent(QResizeEvent * event)
{
    int w = event->size().width();
    int h = event->size().height();
    if (wBackground) {
        wBackground->setFixedSize(w, h);
        wBackground->move(0, 0);
    }
}

void HWForm::UpdateCampaignPage(int index)
{
    HWTeam team(ui.pageCampaign->CBTeam->currentText());
    ui.pageCampaign->CBSelect->clear();

    QDir tmpdir;
    tmpdir.cd(datadir->absolutePath());
    tmpdir.cd("Missions/Campaign");
    tmpdir.setFilter(QDir::Files);
    QStringList entries = tmpdir.entryList(QStringList("*#*.lua"));
    //entries.sort();
    for(int i = 0; (i < entries.count()) && (i <= team.CampaignProgress); i++)
        ui.pageCampaign->CBSelect->addItem(QString(entries[i]).replace(QRegExp("^(\\d+)#(.+)\\.lua"), QComboBox::tr("Mission") + " \\1: \\2"), QString(entries[i]).replace(QRegExp("^(.*)\\.lua"), "\\1"));
}

void HWForm::AssociateFiles()
{
    bool success = true;
#ifdef _WIN32
    QSettings registry_hkcr("HKEY_CLASSES_ROOT", QSettings::NativeFormat);
    registry_hkcr.setValue(".hwd/Default", "Hedgewars.Demo");
    registry_hkcr.setValue(".hws/Default", "Hedgewars.Save");
    registry_hkcr.setValue("Hedgewars.Demo/Default", tr("Hedgewars Demo File", "File Types"));
    registry_hkcr.setValue("Hedgewars.Save/Default", tr("Hedgewars Save File", "File Types"));
    registry_hkcr.setValue("Hedgewars.Demo/DefaultIcon/Default", "\"" + bindir->absolutePath().replace("/", "\\") + "\\hwdfile.ico\",0");
    registry_hkcr.setValue("Hedgewars.Save/DefaultIcon/Default", "\"" + bindir->absolutePath().replace("/", "\\") + "\\hwsfile.ico\",0");
    registry_hkcr.setValue("Hedgewars.Demo/Shell/Open/Command/Default", "\"" + bindir->absolutePath().replace("/", "\\") + "\\hwengine.exe\" \"" + datadir->absolutePath().replace("/", "\\") + "\" \"%1\"");
    registry_hkcr.setValue("Hedgewars.Save/Shell/Open/Command/Default", "\"" + bindir->absolutePath().replace("/", "\\") + "\\hwengine.exe\" \"" + datadir->absolutePath().replace("/", "\\") + "\" \"%1\"");
#elif defined __APPLE__
    success = false;
    // TODO; also enable button in pages.cpp and signal in hwform.cpp
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
#endif
    if (success) QMessageBox::information(0, "", QMessageBox::tr("All file associations have been set."));
    else QMessageBox::information(0, "", QMessageBox::tr("File association failed."));
}

