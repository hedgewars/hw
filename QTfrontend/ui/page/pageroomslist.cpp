/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2014 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGridLayout>
#include <QPushButton>
#include <QComboBox>
#include <QLabel>
#include <QLineEdit>
#include <QMessageBox>
#include <QHeaderView>
#include <QGroupBox>
#include <QMenu>
#include <QDebug>
#include <QSplitter>

#include <QSortFilterProxyModel>

#include "roomslistmodel.h"

#include "ammoSchemeModel.h"
#include "hwconsts.h"
#include "chatwidget.h"
#include "roomnameprompt.h"
#include "lineeditcursor.h"
#include "pageroomslist.h"

void RoomTableView::moveDown()
{
    setCurrentIndex(moveCursor(QAbstractItemView::MoveDown, Qt::NoModifier));
}

void RoomTableView::moveUp()
{
    setCurrentIndex(moveCursor(QAbstractItemView::MoveUp, Qt::NoModifier));
}

QLayout * PageRoomsList::bodyLayoutDefinition()
{
    // TODO move stylesheet stuff into css/qt.css

    QVBoxLayout * pageLayout = new QVBoxLayout();
    pageLayout->setSpacing(0);

    QGridLayout * topLayout = new QGridLayout();
    topLayout->setSpacing(0);
    pageLayout->addLayout(topLayout, 0);

    // State button

    QPushButton * btnState = new QPushButton(tr("Room state"));
    btnState->setStyleSheet("QPushButton { background-color: #F6CB1C; border-color: #F6CB1C; color: #130F2A; padding: 1px 3px 3px 3px; margin: 0px; border-bottom: none; border-radius: 0px; border-top-left-radius: 10px; } QPushButton:hover { background-color: #FFEB3C; border-color: #F6CB1C; color: #000000 } QPushButton:pressed { background-color: #FFEB3C; border-color: #F6CB1C; color: #000000; }");
    btnState->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Preferred);

    // State menu

    QMenu * stateMenu = new QMenu(btnState);
    showGamesInLobby = new QAction(QAction::tr("Show games in lobby"), stateMenu);
    showGamesInLobby->setCheckable(true);
    showGamesInLobby->setChecked(true);
    showGamesInProgress = new QAction(QAction::tr("Show games in-progress"), stateMenu);
    showGamesInProgress->setCheckable(true);
    showGamesInProgress->setChecked(true);
    showPassword = new QAction(QAction::tr("Show password protected"), stateMenu);
    showPassword->setCheckable(true);
    showPassword->setChecked(true);
    showJoinRestricted = new QAction(QAction::tr("Show join restricted"), stateMenu);
    showJoinRestricted->setCheckable(true);
    showJoinRestricted->setChecked(true);
    stateMenu->addAction(showGamesInLobby);
    stateMenu->addAction(showGamesInProgress);
    stateMenu->addAction(showPassword);
    stateMenu->addAction(showJoinRestricted);
    btnState->setMenu(stateMenu);

    // Help/prompt message at top
    QLabel * lblDesc = new QLabel(tr("Search for a room:"));
    lblDesc->setObjectName("lblDesc");
    lblDesc->setStyleSheet("#lblDesc { color: #130F2A; background: #F6CB1C; border: solid 4px #F6CB1C; padding: 5px 10px 3px 6px;}");
    lblDesc->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
    lblDesc->setFixedHeight(24);
    lblDesc->setMinimumWidth(0);

    // Search text box
    QWidget * searchContainer = new QWidget();
    searchContainer->setFixedHeight(24);
    searchContainer->setObjectName("searchContainer");
    searchContainer->setStyleSheet("#searchContainer { background: #F6CB1C; border-top-right-radius: 10px; padding: 3px; }");
    searchContainer->setFixedWidth(200);
    searchText = new LineEditCursor(searchContainer);
    searchText->setFixedWidth(200);
    searchText->setMaxLength(60);
    searchText->setFixedHeight(22);
    searchText->setStyleSheet("LineEditCursor { border-width: 0px; border-radius: 6px; margin-top: 3px; margin-right: 3px; padding-left: 4px; padding-bottom: 2px; background-color: rgb(23, 11, 54); } LineEditCursor:hover, LineEditCursor:focus { background-color: rgb(13, 5, 68); }");

    // Corner widget
    QLabel * corner = new QLabel();
    corner->setPixmap(QPixmap(QString::fromUtf8(":/res/inverse-corner-bl.png")));
    corner->setFixedSize(10, 10);

    const QIcon& lp = QIcon(":/res/new.png");
    //QSize sz = lp.actualSize(QSize(65535, 65535));
    BtnCreate = new QPushButton();
    BtnCreate->setText(tr("Create room"));
    BtnCreate->setIcon(lp);
    BtnCreate->setStyleSheet("padding: 4px 8px; margin-bottom: 6px;");

    BtnJoin = new QPushButton(tr("Join room"));
    BtnJoin->setStyleSheet("padding: 4px 8px; margin-bottom: 6px; margin-left: 6px;");
    BtnJoin->setEnabled(false);

    // Add widgets to top layout
    topLayout->addWidget(btnState, 1, 0);
    topLayout->addWidget(lblDesc, 1, 1);
    topLayout->addWidget(searchContainer, 1, 2);
    topLayout->addWidget(corner, 1, 3, Qt::AlignBottom);
    topLayout->addWidget(BtnCreate, 0, 5, 2, 1);
    topLayout->addWidget(BtnJoin, 0, 6, 2, 1);

    // Top layout stretch
    topLayout->setRowStretch(0, 1);
    topLayout->setRowStretch(1, 0);
    topLayout->setColumnStretch(4, 1);

    // Rooms list and chat with splitter
    m_splitter = new QSplitter();
    m_splitter->setChildrenCollapsible(false);
    pageLayout->addWidget(m_splitter, 100);

    // Room list
    QWidget * roomsListWidget = new QWidget(this);
    m_splitter->setOrientation(Qt::Vertical);
    m_splitter->addWidget(roomsListWidget);

    QVBoxLayout * roomsLayout = new QVBoxLayout(roomsListWidget);
    roomsLayout->setMargin(0);

    roomsList = new RoomTableView(this);
    roomsList->setSelectionBehavior(QAbstractItemView::SelectRows);
    roomsList->verticalHeader()->setVisible(false);
    roomsList->horizontalHeader()->setResizeMode(QHeaderView::Interactive);
    roomsList->setAlternatingRowColors(true);
    roomsList->setShowGrid(false);
    roomsList->setSelectionMode(QAbstractItemView::SingleSelection);
    roomsList->setStyleSheet("QTableView { border-top-left-radius: 0px; }");
    roomsList->setFocusPolicy(Qt::NoFocus);
    roomsLayout->addWidget(roomsList, 200);

    // Lobby chat

    chatWidget = new HWChatWidget(this, false);
    m_splitter->addWidget(chatWidget);

    return pageLayout;
}

QLayout * PageRoomsList::footerLayoutDefinition()
{
    QHBoxLayout * bottomLayout = new QHBoxLayout();

    BtnAdmin = addButton(tr("Admin features"), bottomLayout, 0);
    BtnAdmin->setStyleSheet("padding: 4px auto;");
    BtnAdmin->setWhatsThis(tr("Open server administration page"));

    return bottomLayout;
}

void PageRoomsList::connectSignals()
{
    connect(chatWidget, SIGNAL(nickCountUpdate(const int)), this, SLOT(updateNickCounter(const int)));

    connect(BtnCreate, SIGNAL(clicked()), this, SLOT(onCreateClick()));
    connect(BtnJoin, SIGNAL(clicked()), this, SLOT(onJoinClick()));
    connect(searchText, SIGNAL(moveUp()), this, SLOT(moveSelectionUp()));
    connect(searchText, SIGNAL(moveDown()), this, SLOT(moveSelectionDown()));
    connect(searchText, SIGNAL(returnPressed()), this, SLOT(onJoinClick()));
    connect(roomsList, SIGNAL(doubleClicked (const QModelIndex &)), this, SLOT(onJoinClick()));
    connect(roomsList, SIGNAL(clicked (const QModelIndex &)), searchText, SLOT(setFocus()));
    connect(showGamesInLobby, SIGNAL(triggered()), this, SLOT(onFilterChanged()));
    connect(showGamesInProgress, SIGNAL(triggered()), this, SLOT(onFilterChanged()));
    connect(showPassword, SIGNAL(triggered()), this, SLOT(onFilterChanged()));
    connect(showJoinRestricted, SIGNAL(triggered()), this, SLOT(onFilterChanged()));
    connect(searchText, SIGNAL(textChanged (const QString &)), this, SLOT(onFilterChanged()));
    connect(this, SIGNAL(askJoinConfirmation (const QString &)), this, SLOT(onJoinConfirmation(const QString &)), Qt::QueuedConnection);

    // Set focus on search box
    connect(this, SIGNAL(pageEnter()), searchText, SLOT(setFocus()));

    // sorting
    connect(roomsList->horizontalHeader(), SIGNAL(sortIndicatorChanged(int, Qt::SortOrder)),
            this, SLOT(onSortIndicatorChanged(int, Qt::SortOrder)));
}

void PageRoomsList::moveSelectionUp()
{
    roomsList->moveUp();
}

void PageRoomsList::moveSelectionDown()
{
    roomsList->moveDown();
}

void PageRoomsList::roomSelectionChanged(const QModelIndex & current, const QModelIndex & previous)
{
    Q_UNUSED(previous);

    BtnJoin->setEnabled(current.isValid());
}

PageRoomsList::PageRoomsList(QWidget* parent) :
    AbstractPage(parent)
{
    roomsModel = NULL;
    stateFilteredModel = NULL;

    initPage();
}


void PageRoomsList::displayError(const QString & message)
{
    chatWidget->displayError(message);
}


void PageRoomsList::displayNotice(const QString & message)
{
    chatWidget->displayNotice(message);
}

void PageRoomsList::displayWarning(const QString & message)
{
    chatWidget->displayWarning(message);
}


void PageRoomsList::setAdmin(bool flag)
{
    BtnAdmin->setVisible(flag);
}

/*
void PageRoomsList::setRoomsList(const QStringList & list)
{
    QBrush red(QColor(255, 0, 0));
    QBrush orange(QColor(127, 127, 0));
    QBrush yellow(QColor(255, 255, 0));
    QBrush green(QColor(0, 255, 0));

    listFromServer = list;

    QString selection = "";

    if(QTableWidgetItem *item = roomsList->item(roomsList->currentRow(), 0))
        selection = item->text();

    roomsList->clear();
    roomsList->setColumnCount(7);
    roomsList->setHorizontalHeaderLabels(

    );

    // set minimum sizes
//  roomsList->horizontalHeader()->resizeSection(0, 200);
//  roomsList->horizontalHeader()->resizeSection(1, 50);
//  roomsList->horizontalHeader()->resizeSection(2, 50);
//  roomsList->horizontalHeader()->resizeSection(3, 100);
//  roomsList->horizontalHeader()->resizeSection(4, 100);
//  roomsList->horizontalHeader()->resizeSection(5, 100);
//  roomsList->horizontalHeader()->resizeSection(6, 100);

    // set resize modes
//  roomsList->horizontalHeader()->setResizeMode(QHeaderView::Interactive);

    bool gameCanBeJoined = true;

    if (list.size() % 8)
        return;

    roomsList->setRowCount(list.size() / 8);
    for(int i = 0, r = 0; i < list.size(); i += 8, r++)
    {
        // if we are joining a game
        // TODO: Should NOT be done here
        if (gameInLobby)
        {
            if (gameInLobbyName == list[i + 1])
            {
                gameCanBeJoined = list[i].compare("True");
            }
        }

        // check filter settings
#define NO_FILTER_MATCH roomsList->setRowCount(roomsList->rowCount() - 1); --r; continue

        if (list[i].compare("True") && CBState->currentIndex() == 2)
        {
            NO_FILTER_MATCH;
        }
        if (list[i].compare("False") && CBState->currentIndex() == 1)
        {
            NO_FILTER_MATCH;
        }
        if (CBRules->currentIndex() != 0 && list[i + 6].compare(CBRules->currentText()))
        {
            NO_FILTER_MATCH;
        }
        if (CBWeapons->currentIndex() != 0 && list[i + 7].compare(CBWeapons->currentText()))
        {
            NO_FILTER_MATCH;
        }
        bool found = list[i + 1].contains(searchText->text(), Qt::CaseInsensitive);
        if (!found)
        {
            for (int a = 4; a <= 7; ++a)
            {
                QString compString = list[i + a];
                if (a == 5 && compString == "+rnd+")
                {
                    compString = "Random Map";
                }
                else if (a == 5 && compString == "+maze+")
                {
                    compString = "Random Maze";
                }
                else if (a == 5 && compString == "+drawn+")
                {
                    compString = "Drawn Map";
                }
                if (compString.contains(searchText->text(), Qt::CaseInsensitive))
                {
                    found = true;
                    break;
                }
            }
        }
        if (!searchText->text().isEmpty() && !found)
        {
            NO_FILTER_MATCH;
        }

        QTableWidgetItem * item;
        item = new QTableWidgetItem(list[i + 1]); // room name
        item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);

        // pick appropriate room icon and tooltip (game in progress yes/no; later maybe locked rooms etc.)
        if(list[i].compare("True"))
        {
            item->setIcon(QIcon(":/res/iconTime.png"));// game is in lobby
            item->setToolTip(tr("Waiting..."));
            item->setWhatsThis(tr("This game is in lobby: you may join and start playing once the game starts."));
        }
        else
        {
            item->setIcon(QIcon(":/res/iconDamage.png"));// game has started
            item->setToolTip(tr("In progress..."));
            item->setWhatsThis(tr("This game is in progress: you may join and spectate now but you'll have to wait for the game to end to start playing."));
        }

        roomsList->setItem(r, 0, item);

        item = new QTableWidgetItem(list[i + 2]); // number of clients
        item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
        item->setTextAlignment(Qt::AlignCenter);
        item->setWhatsThis(tr("There are %1 clients connected to this room.", "", list[i + 2].toInt()).arg(list[i + 2]));
        roomsList->setItem(r, 1, item);

        item = new QTableWidgetItem(list[i + 3]); // number of teams
        item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
        item->setTextAlignment(Qt::AlignCenter);
        item->setWhatsThis(tr("There are %1 teams participating in this room.", "", list[i + 3].toInt()).arg(list[i + 3]));
        //Should we highlight "full" games? Might get misinterpreted
        //if(list[i + 3].toInt() >= cMaxTeams)
        //    item->setForeground(red);
        roomsList->setItem(r, 2, item);

        item = new QTableWidgetItem(list[i + 4].left(15)); // name of host
        item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
        item->setWhatsThis(tr("%1 is the host. He may adjust settings and start the game.").arg(list[i + 4]));
        roomsList->setItem(r, 3, item);

        if(list[i + 5] == "+rnd+")
        {
            item = new QTableWidgetItem(tr("Random Map")); // selected map (is randomized)
// FIXME - need real icons. Disabling until then
//            item->setIcon(QIcon(":/res/mapRandom.png"));
        }
        else if (list[i+5] == "+maze+")
        {
            item = new QTableWidgetItem(tr("Random Maze"));
// FIXME - need real icons. Disabling until then
//            item->setIcon(QIcon(":/res/mapMaze.png"));
        }
        else
        {
            item = new QTableWidgetItem(list[i + 5]); // selected map

            // check to see if we've got this map
            // not perfect but a start
            if(!mapList->contains(list[i + 5]))
            {
                item->setForeground(red);
                item->setIcon(QIcon(":/res/mapMissing.png"));
            }
            else
            {
                // todo: mission icon?
// FIXME - need real icons. Disabling until then
//               item->setIcon(QIcon(":/res/mapCustom.png"));
            }
        }

        item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
        item->setWhatsThis(tr("Games may be played on precreated or randomized maps."));
        roomsList->setItem(r, 4, item);

        item = new QTableWidgetItem(list[i + 6].left(24)); // selected game scheme
        item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
        item->setWhatsThis(tr("The Game Scheme defines general options and preferences like Round Time, Sudden Death or Vampirism."));
        roomsList->setItem(r, 5, item);

        item = new QTableWidgetItem(list[i + 7].left(24)); // selected weapon scheme
        item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
        item->setWhatsThis(tr("The Weapon Scheme defines available weapons and their ammunition count."));
        roomsList->setItem(r, 6, item);

        if(!list[i + 1].compare(selection) && !selection.isEmpty())
            roomsList->selectionModel()->setCurrentIndex(roomsList->model()->index(r, 0), QItemSelectionModel::SelectCurrent | QItemSelectionModel::Rows);
    }

    roomsList->horizontalHeader()->setResizeMode(0, QHeaderView::Stretch);
    roomsList->horizontalHeader()->setResizeMode(1, QHeaderView::ResizeToContents);
    roomsList->horizontalHeader()->setResizeMode(2, QHeaderView::ResizeToContents);
    roomsList->horizontalHeader()->setResizeMode(3, QHeaderView::ResizeToContents);
    roomsList->horizontalHeader()->setResizeMode(4, QHeaderView::ResizeToContents);
    roomsList->horizontalHeader()->setResizeMode(5, QHeaderView::ResizeToContents);
    roomsList->horizontalHeader()->setResizeMode(6, QHeaderView::ResizeToContents);

    // TODO: Should NOT be done here
    if (gameInLobby)
    {
        gameInLobby = false;
        if (gameCanBeJoined)
        {
            emit askForJoinRoom(gameInLobbyName);
        }
        else
        {
            emit askJoinConfirmation(gameInLobbyName);
        }
    }

//  roomsList->resizeColumnsToContents();
}
*/

void PageRoomsList::onCreateClick()
{
    RoomNamePrompt prompt(this, m_gameSettings->value("frontend/lastroomname", QString()).toString());
    if(prompt.exec())
        onRoomNameChosen(prompt.getRoomName(), prompt.getPassword());
}

void PageRoomsList::onRoomNameChosen(const QString & roomName, const QString & password)
{
    if (!roomName.trimmed().isEmpty())
    {
        m_gameSettings->setValue("frontend/lastroomname", roomName);
        emit askForCreateRoom(roomName, password);
    }
    else
    {
        onCreateClick();
    }
}

void PageRoomsList::onJoinClick()
{
    QModelIndexList mdl = roomsList->selectionModel()->selectedRows();

    if(mdl.size() != 1)
    {
        QMessageBox roomNameMsg(this);
        roomNameMsg.setIcon(QMessageBox::Warning);
        roomNameMsg.setWindowTitle(QMessageBox::tr("Room Name - Error"));
        roomNameMsg.setText(QMessageBox::tr("Please select room from the list"));
        roomNameMsg.setWindowModality(Qt::WindowModal);
        roomNameMsg.exec();
        return;
    }

    bool gameInLobby = roomsList->model()->index(mdl[0].row(), 0).data().toString().compare("True");
    QString roomName = roomsList->model()->index(mdl[0].row(), 1).data().toString();

    if (!gameInLobby)
        emit askJoinConfirmation(roomName);
    else
        emit askForJoinRoom(roomName, QString());
}

void PageRoomsList::onRefreshClick()
{
    emit askForRoomList();
}

void PageRoomsList::onJoinConfirmation(const QString & room)
{

    QMessageBox reallyJoinMsg(this);
    reallyJoinMsg.setIcon(QMessageBox::Question);
    reallyJoinMsg.setWindowTitle(QMessageBox::tr("Room Name - Are you sure?"));
    reallyJoinMsg.setText(QMessageBox::tr("The game you are trying to join has started.\nDo you still want to join the room?"));
    reallyJoinMsg.setWindowModality(Qt::WindowModal);
    reallyJoinMsg.setStandardButtons(QMessageBox::Ok | QMessageBox::Cancel);

    if (reallyJoinMsg.exec() == QMessageBox::Ok)
    {
        emit askForJoinRoom(room, QString());
    }
}

void PageRoomsList::updateNickCounter(int cnt)
{
    setDefaultDescription(tr("%1 players online", 0, cnt).arg(cnt));
}

void PageRoomsList::setUser(const QString & nickname)
{
    chatWidget->setUser(nickname);
}

void PageRoomsList::setModel(RoomsListModel * model)
{
    // filter chain:
    // model -> stateFilteredModel -> schemeFilteredModel ->
    // -> weaponsFilteredModel -> roomsModel (search filter+sorting)

    if (roomsModel == NULL)
    {
        roomsModel = new QSortFilterProxyModel(this);
        roomsModel->setDynamicSortFilter(true);
        roomsModel->setSortCaseSensitivity(Qt::CaseInsensitive);
        roomsModel->sort(RoomsListModel::StateColumn, Qt::AscendingOrder);

        stateFilteredModel = new QSortFilterProxyModel(this);

        stateFilteredModel->setDynamicSortFilter(true);

        roomsModel->setFilterKeyColumn(-1); // search in all columns
        stateFilteredModel->setFilterKeyColumn(RoomsListModel::StateColumn);

        roomsModel->setFilterCaseSensitivity(Qt::CaseInsensitive);

        roomsModel->setSourceModel(stateFilteredModel);

        // let the table view display the last model in the filter chain
        roomsList->setModel(roomsModel);

        // When the data changes
        connect(roomsModel, SIGNAL(layoutChanged()), roomsList, SLOT(repaint()));

        // When a selection changes
        connect(roomsList->selectionModel(), SIGNAL(currentRowChanged(const QModelIndex &, const QModelIndex &)), this, SLOT(roomSelectionChanged(const QModelIndex &, const QModelIndex &)));
    }

    stateFilteredModel->setSourceModel(model);

    QHeaderView * h = roomsList->horizontalHeader();

    h->setSortIndicatorShown(true);
    h->setSortIndicator(RoomsListModel::StateColumn, Qt::AscendingOrder);
    h->setResizeMode(RoomsListModel::NameColumn, QHeaderView::Stretch);

    if (!restoreHeaderState())
    {
        h->resizeSection(RoomsListModel::PlayerCountColumn, 32);
        h->resizeSection(RoomsListModel::TeamCountColumn, 32);
        h->resizeSection(RoomsListModel::OwnerColumn, 100);
        h->resizeSection(RoomsListModel::MapColumn, 100);
        h->resizeSection(RoomsListModel::SchemeColumn, 100);
        h->resizeSection(RoomsListModel::WeaponsColumn, 100);
    }

    // hide column used for filtering
    roomsList->hideColumn(RoomsListModel::StateColumn);

    // save header state on change
    connect(roomsList->horizontalHeader(), SIGNAL(sortIndicatorChanged(int, Qt::SortOrder)),
            this, SLOT(saveHeaderState()));
    connect(roomsList->horizontalHeader(), SIGNAL(sectionResized(int, int, int)),
            this, SLOT(saveHeaderState()));

    roomsList->repaint();
}


void PageRoomsList::onSortIndicatorChanged(int logicalIndex, Qt::SortOrder order)
{
    if (roomsModel == NULL)
        return;

    if (logicalIndex == 0)
    {
        roomsModel->sort(0, Qt::AscendingOrder);
        return;
    }

    // three state sorting: asc -> dsc -> default (by room state)
    if ((order == Qt::AscendingOrder) && (logicalIndex == roomsModel->sortColumn()))
        roomsList->horizontalHeader()->setSortIndicator(
            RoomsListModel::StateColumn, Qt::AscendingOrder);
    else
        roomsModel->sort(logicalIndex, order);
}


void PageRoomsList::onFilterChanged()
{
    if (roomsModel == NULL)
        return;

    roomsModel->setFilterFixedString(searchText->text());

    bool stateLobby = showGamesInLobby->isChecked();
    bool stateProgress = showGamesInProgress->isChecked();
    bool statePassword = showPassword->isChecked();
    bool stateJoinRestricted = showJoinRestricted->isChecked();

    QString filter;
    if (!stateLobby && !stateProgress)
        filter = "O_o";
    else if (stateLobby && stateProgress && statePassword && stateJoinRestricted)
        filter = "";
    else
    {
        QString exclude = "[^";
        if (!stateProgress) exclude += "g";
        if (!statePassword) exclude += "p";
        if (!stateJoinRestricted) exclude += "j";
        exclude += "]*";
        if (stateProgress && statePassword && stateJoinRestricted) exclude = ".*";
        filter = "^" + exclude;
        if (!stateLobby) filter += "g" + exclude;
        filter += "$";
    }
    //qDebug() << filter;

    stateFilteredModel->setFilterRegExp(filter);
}

void PageRoomsList::setSettings(QSettings *settings)
{
    m_gameSettings = settings;
}

bool PageRoomsList::restoreHeaderState()
{
    if (m_gameSettings->contains("frontend/roomslist_splitter"))
    {
        m_splitter->restoreState(QByteArray::fromBase64(
            (m_gameSettings->value("frontend/roomslist_splitter").toByteArray())));
    }

    if (m_gameSettings->contains("frontend/roomslist_header"))
    {
        return roomsList->horizontalHeader()->restoreState(QByteArray::fromBase64(
            (m_gameSettings->value("frontend/roomslist_header").toByteArray())));
    } else return false;
}

void PageRoomsList::saveHeaderState()
{
    m_gameSettings->setValue("frontend/roomslist_header",
        QString(roomsList->horizontalHeader()->saveState().toBase64()));

    m_gameSettings->setValue("frontend/roomslist_splitter",
        QString(m_splitter->saveState().toBase64()));
}
