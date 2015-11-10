/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Igor Ulyanov <iulyanov@gmail.com>
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

#ifndef _NEW_NETCLIENT_INCLUDED
#define _NEW_NETCLIENT_INCLUDED

#include <QObject>
#include <QString>
#include <QTcpSocket>
#include <QMap>

#include "team.h"
#include "game.h" // for GameState

class GameUIConfig;
class GameCFGWidget;
class TeamSelWidget;
class RoomsListModel;
class PlayersListModel;
class QSortFilterProxyModel;
class QAbstractItemModel;

extern char delimiter;

class HWNewNet : public QObject
{
        Q_OBJECT

    public:
        enum ClientState { Disconnected, Connecting, Connected, InLobby, InRoom, InGame };

        HWNewNet();
        ~HWNewNet();
        void Connect(const QString & hostName, quint16 port, const QString & nick);
        void Disconnect();
        void SendPasswordHash(const QString & hash);
        void NewNick(const QString & nick);
        bool isRoomChief();
        bool isInRoom();
        ClientState clientState();
        QString getNick();
        QString getRoom();
        QString getHost();
        RoomsListModel * roomsListModel();
        QAbstractItemModel * lobbyPlayersModel();
        QAbstractItemModel * roomPlayersModel();
        bool allPlayersReady();
        bool m_private_game;

    private:
        bool isChief;
        QString mynick;
        QString myroom;
        QString myhost;
        QTcpSocket NetSocket;
        QString seed;
        bool m_game_connected;
        bool m_nick_registered;
        RoomsListModel * m_roomsListModel;
        PlayersListModel * m_playersModel;
        QSortFilterProxyModel * m_lobbyPlayersModel;
        QSortFilterProxyModel * m_roomPlayersModel;
        QString m_lastRoom;
        QString m_passwordHash;
        QString m_serverSalt;
        QString m_clientSalt;
        QString m_serverHash;

        QStringList cmdbuf;

        void RawSendNet(const QString & buf);
        void RawSendNet(const QByteArray & buf);
        void ParseCmd(const QStringList & lst);
        void handleNotice(int n);

        void maybeSendPassword();

        ClientState netClientState;

    signals:
        void AskForRunGame();
        void connected();
        void disconnected(const QString & reason);
        void Error(const QString & errmsg);
        void Warning(const QString & wrnmsg);
        void NickRegistered(const QString & nick);
        void NickNotRegistered(const QString & nick);
        void NickTaken(const QString & nick);
        void AuthFailed();
        void EnteredGame();
        void LeftRoom(const QString & reason);
        void FromNet(const QByteArray & buf);
        void adminAccess(bool);
        void roomMaster(bool);
        void roomNameUpdated(const QString & name);
        void askForRoomPassword();

        void netSchemeConfig(QStringList);
        void paramChanged(const QString & param, const QStringList & value);
        void configAsked();

        void TeamAccepted(const QString&);
        void AddNetTeam(const HWTeam&);
        void RemoveNetTeam(const HWTeam&);
        void hhnumChanged(const HWTeam&);
        void teamColorChanged(const HWTeam&);
        void playerInfo(
            const QString & nick,
            const QString & ip,
            const QString & version,
            const QString & roomInfo);
        void lobbyChatMessage(const QString & nick, const QString & message);
        void lobbyChatAction(const QString & nick, const QString & action);
        void roomChatMessage(const QString & nick, const QString & message);
        void roomChatAction(const QString & nick, const QString & action);
        void chatStringFromNet(const QString&);

        void roomsList(const QStringList&);
        void serverMessage(const QString &);
        void serverMessageNew(const QString &);
        void serverMessageOld(const QString &);
        void latestProtocolVar(int);
        void bansList(const QStringList &);

        void setMyReadyStatus(bool isReady);

        void messageProcessed();

    public slots:
        void ToggleReady();
        void chatLineToNet(const QString& str);
        void chatLineToNetWithEcho(const QString&);
        void chatLineToLobby(const QString& str);
        void SendTeamMessage(const QString& str);
        void SendNet(const QByteArray & buf);
        void AddTeam(const HWTeam & team);
        void RemoveTeam(const HWTeam& team);
        void onHedgehogsNumChanged(const HWTeam& team);
        void onTeamColorChanged(const HWTeam& team);
        void onParamChanged(const QString & param, const QStringList & value);

        void setServerMessageNew(const QString &);
        void setServerMessageOld(const QString &);
        void setLatestProtocolVar(int proto);
        void askServerVars();

        void JoinRoom(const QString & room, const QString & password);
        void CreateRoom(const QString & room, const QString &password);
        void updateRoomName(const QString &);
        void askRoomsList();
        void gameFinished(bool correcly);
        void banPlayer(const QString &);
        void kickPlayer(const QString &);
        void infoPlayer(const QString &);
        void followPlayer(const QString &);
        void consoleCommand(const QString &);
        void startGame();
        void toggleRestrictJoins();
        void toggleRestrictTeamAdds();
        void toggleRegisteredOnly();
        void partRoom();
        void clearAccountsCache();
        void getBanList();
        void removeBan(const QString &);
        void banIP(const QString & ip, const QString & reason, int seconds);
        void banNick(const QString & nick, const QString & reason, int seconds);
        void roomPasswordEntered(const QString & password);

    private slots:
        void ClientRead();
        void OnConnect();
        void OnDisconnect();
        void displayError(QAbstractSocket::SocketError socketError);
};

#endif // _NEW_NETCLIENT_INCLUDED
