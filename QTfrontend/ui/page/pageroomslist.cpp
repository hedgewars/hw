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

#include <QGridLayout>
#include <QHBoxLayout>
#include <QPushButton>
#include <QComboBox>
#include <QLabel>
#include <QLineEdit>
#include <QMessageBox>
#include <QHeaderView>
#include <QTableView>

#include "ammoSchemeModel.h"
#include "pageroomslist.h"
#include "hwconsts.h"
#include "chatwidget.h"

QLayout * PageRoomsList::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();

    QHBoxLayout * newRoomLayout = new QHBoxLayout();
    QLabel * roomNameLabel = new QLabel(this);
    roomNameLabel->setText(tr("Room Name:"));
    roomName = new QLineEdit(this);
    roomName->setMaxLength(60);
    newRoomLayout->addWidget(roomNameLabel);
    newRoomLayout->addWidget(roomName);
    pageLayout->addLayout(newRoomLayout, 0, 0, 1, 2);

    roomsList = new QTableView(this);
    roomsList->setSelectionBehavior(QAbstractItemView::SelectRows);
    roomsList->verticalHeader()->setVisible(false);
    roomsList->horizontalHeader()->setResizeMode(QHeaderView::Interactive);
    roomsList->setAlternatingRowColors(true);
    roomsList->setShowGrid(false);
    roomsList->setSelectionMode(QAbstractItemView::SingleSelection);
    pageLayout->addWidget(roomsList, 1, 0, 3, 2);
    pageLayout->setRowStretch(2, 100);

    QHBoxLayout * filterLayout = new QHBoxLayout();

    QLabel * stateLabel = new QLabel(this);
    CBState = new QComboBox(this);

    filterLayout->addWidget(stateLabel);
    filterLayout->addWidget(CBState);
    filterLayout->addSpacing(30);

    QLabel * ruleLabel = new QLabel(this);
    ruleLabel->setText(tr("Rules:"));
    CBRules = new QComboBox(this);

    filterLayout->addWidget(ruleLabel);
    filterLayout->addWidget(CBRules);
    filterLayout->addSpacing(30);

    QLabel * weaponLabel = new QLabel(this);
    weaponLabel->setText(tr("Weapons:"));
    CBWeapons = new QComboBox(this);

    filterLayout->addWidget(weaponLabel);
    filterLayout->addWidget(CBWeapons);
    filterLayout->addSpacing(30);

    QLabel * searchLabel = new QLabel(this);
    searchLabel->setText(tr("Search:"));
    searchText = new QLineEdit(this);
    searchText->setMaxLength(60);
    filterLayout->addWidget(searchLabel);
    filterLayout->addWidget(searchText);

    pageLayout->addLayout(filterLayout, 4, 0, 1, 2);

    chatWidget = new HWChatWidget(this, m_gameSettings, false);
    pageLayout->addWidget(chatWidget, 5, 0, 1, 3);
    pageLayout->setRowStretch(5, 350);

    BtnCreate = addButton(tr("Create"), pageLayout, 0, 2);
    BtnJoin = addButton(tr("Join"), pageLayout, 1, 2);
    BtnRefresh = addButton(tr("Refresh"), pageLayout, 3, 2);
    BtnClear = addButton(tr("Clear"), pageLayout, 4, 2);

    // strech all but the buttons column
    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 1);
    pageLayout->setColumnStretch(2, 0);

    CBRules->addItem(QComboBox::tr("Any"));
    CBState->addItem(QComboBox::tr("Any"));
    CBState->addItem(QComboBox::tr("In lobby"));
    CBState->addItem(QComboBox::tr("In progress"));

    return pageLayout;
}

QLayout * PageRoomsList::footerLayoutDefinition()
{
    QHBoxLayout * bottomLayout = new QHBoxLayout();

    lblCount = new QLabel(this);
    bottomLayout->addWidget(lblCount, 0, Qt::AlignHCenter);
    bottomLayout->setStretchFactor(lblCount, 1);
    lblCount->setText("?");
    lblCount->setSizePolicy(QSizePolicy::Maximum, QSizePolicy::Maximum);

    BtnAdmin = addButton(tr("Admin features"), bottomLayout, 1);
    BtnAdmin->setMinimumWidth(160);

    // strech left part
    bottomLayout->setStretch(0, 1);
    bottomLayout->setStretch(1, 0);

    return bottomLayout;
}

void PageRoomsList::connectSignals()
{
    connect(chatWidget, SIGNAL(nickCountUpdate(const int)), this, SLOT(updateNickCounter(const int)));

    connect(BtnCreate, SIGNAL(clicked()), this, SLOT(onCreateClick()));
    connect(BtnJoin, SIGNAL(clicked()), this, SLOT(onJoinClick()));
    connect(BtnRefresh, SIGNAL(clicked()), this, SLOT(onRefreshClick()));
    connect(BtnClear, SIGNAL(clicked()), this, SLOT(onClearClick()));
    connect(roomsList, SIGNAL(doubleClicked (const QModelIndex &)), this, SLOT(onJoinClick()));
    connect(CBState, SIGNAL(currentIndexChanged (int)), this, SLOT(onRefreshClick()));
    connect(CBRules, SIGNAL(currentIndexChanged (int)), this, SLOT(onRefreshClick()));
    connect(CBWeapons, SIGNAL(currentIndexChanged (int)), this, SLOT(onRefreshClick()));
    connect(searchText, SIGNAL(textChanged (const QString &)), this, SLOT(onRefreshClick()));
    connect(this, SIGNAL(askJoinConfirmation (const QString &)), this, SLOT(onJoinConfirmation(const QString &)), Qt::QueuedConnection);
}


PageRoomsList::PageRoomsList(QWidget* parent, QSettings * gameSettings) :
    AbstractPage(parent)
{
    m_gameSettings = gameSettings;

    initPage();

    // not the most elegant solution but it works
    ammoSchemeModel = new AmmoSchemeModel(this, NULL);
    for (int i = 0; i < ammoSchemeModel->predefSchemesNames.count(); i++)
        CBRules->addItem(ammoSchemeModel->predefSchemesNames.at(i).toAscii().constData());

    CBWeapons->addItem(QComboBox::tr("Any"));
    for (int i = 0; i < cDefaultAmmos.count(); i++)
    {
        QPair<QString,QString> ammo = cDefaultAmmos.at(i);
        CBWeapons->addItem(ammo.first.toAscii().constData());
    }
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
    if (roomName->text().size())
        emit askForCreateRoom(roomName->text());
    else
        QMessageBox::critical(this,
                              tr("Error"),
                              tr("Please enter room name"),
                              tr("OK"));
}

void PageRoomsList::onJoinClick()
{
    QModelIndexList mdl = roomsList->selectionModel()->selectedRows();

    if(mdl.size() != 1)
    {
        QMessageBox::critical(this,
                              tr("Error"),
                              tr("Please select room from the list"),
                              tr("OK"));
        return;
    }

    bool gameInLobby = roomsList->model()->index(mdl[0].row(), 0).data().toString().compare("True");
    QString roomName = roomsList->model()->index(mdl[0].row(), 1).data().toString();

    if (!gameInLobby)
        emit askJoinConfirmation(roomName);
    else
        emit askForJoinRoom(roomName);
}

void PageRoomsList::onRefreshClick()
{
    emit askForRoomList();
}

void PageRoomsList::onClearClick()
{
    CBState->setCurrentIndex(0);
    CBRules->setCurrentIndex(0);
    CBWeapons->setCurrentIndex(0);
    searchText->clear();
}

void PageRoomsList::onJoinConfirmation(const QString & room)
{
    if (QMessageBox::warning(this,
                             tr("Warning"),
                             tr("The game you are trying to join has started.\nDo you still want to join the room?"),
                             QMessageBox::Yes | QMessageBox::No) == QMessageBox::Yes)
    {
        emit askForJoinRoom(room);
    }
}

void PageRoomsList::updateNickCounter(int cnt)
{
    lblCount->setText(tr("%1 players online", 0, cnt).arg(cnt));
}

void PageRoomsList::setUser(const QString & nickname)
{
    chatWidget->setUser(nickname);
}

void PageRoomsList::setModel(QAbstractTableModel *model)
{
    roomsList->setModel(model);

    roomsList->hideColumn(0);

    QHeaderView * h = roomsList->horizontalHeader();
    h->setResizeMode(1, QHeaderView::Stretch);
    h->resizeSection(2, 16);
    h->resizeSection(3, 16);
    h->resizeSection(4, 100);
    h->resizeSection(5, 100);
    h->resizeSection(6, 100);
    h->resizeSection(7, 100);

}
