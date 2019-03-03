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

#ifndef PAGE_ROOMLIST_H
#define PAGE_ROOMLIST_H

#include <QTableView>
#include "AbstractPage.h"

class HWChatWidget;
class GameSchemeModel;
class QTableView;
class RoomsListModel;
class QSortFilterProxyModel;
class QSplitter;

class RoomTableView : public QTableView
{
    friend class PageRoomsList;

    public:
        RoomTableView(QWidget* parent = 0) : QTableView(parent){}
        void moveUp();
        void moveDown();
};

class PageRoomsList : public AbstractPage
{
        Q_OBJECT

    public:
        PageRoomsList(QWidget* parent);
        void displayError(const QString & message);
        void displayNotice(const QString & message);
        void displayWarning(const QString & message);
        void setSettings(QSettings * settings);

        QLineEdit * searchText;
        RoomTableView * roomsList;
        QPushButton * BtnCreate;
        QPushButton * BtnJoin;
        QPushButton * BtnAdmin;
        QComboBox * CBState;
        HWChatWidget * chatWidget;
        QLabel * lblCount;

        void setModel(RoomsListModel * model);

    public slots:
        void setAdmin(bool);
        void setUser(const QString & nickname);
        void updateNickCounter(int cnt);

    signals:
        void askForCreateRoom(const QString &, const QString &);
        void askForJoinRoom(const QString &, const QString &);
        void askForRoomList();
        void askJoinConfirmation(const QString &);

    protected:
        QLayout * bodyLayoutDefinition();
        QLayout * footerLayoutDefinition();
        void connectSignals();

    private slots:
        void onCreateClick();
        void onJoinClick();
        void onRefreshClick();
        void onJoinConfirmation(const QString &);
        void onSortIndicatorChanged(int logicalIndex, Qt::SortOrder order);
        void onFilterChanged();
        void onRoomNameChosen(const QString &, const QString &password);
        void roomSelectionChanged(const QModelIndex &, const QModelIndex &);
        void moveSelectionUp();
        void moveSelectionDown();

    private:
        QSettings * m_gameSettings;
        QSortFilterProxyModel * roomsModel;
        QSortFilterProxyModel * stateFilteredModel;
        QAction * showGamesInLobby;
        QAction * showGamesInProgress;
        QAction * showPassword;
        QAction * showJoinRestricted;
        QSplitter * m_splitter;

        GameSchemeModel * gameSchemeModel;

        bool restoreHeaderState();
};

#endif
