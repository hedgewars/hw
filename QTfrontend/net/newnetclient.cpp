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

#include <QDebug>
#include <QInputDialog>
#include <QCryptographicHash>
#include <QSortFilterProxyModel>
#include <QUuid>

#include "hwconsts.h"
#include "newnetclient.h"
#include "proto.h"
#include "game.h"
#include "roomslistmodel.h"
#include "playerslistmodel.h"
#include "servermessages.h"
#include "HWApplication.h"

char delimiter='\n';

HWNewNet::HWNewNet() :
    isChief(false),
    m_game_connected(false),
    netClientState(Disconnected)
{
    m_private_game = false;
    m_nick_registered = false;

    m_roomsListModel = new RoomsListModel(this);

    m_playersModel = new PlayersListModel(this);

    m_lobbyPlayersModel = new QSortFilterProxyModel(this);
    m_lobbyPlayersModel->setSourceModel(m_playersModel);
    m_lobbyPlayersModel->setSortRole(PlayersListModel::SortRole);
    m_lobbyPlayersModel->setDynamicSortFilter(true);
    m_lobbyPlayersModel->sort(0);

    m_roomPlayersModel = new QSortFilterProxyModel(this);
    m_roomPlayersModel->setSourceModel(m_playersModel);
    m_roomPlayersModel->setSortRole(PlayersListModel::SortRole);
    m_roomPlayersModel->setDynamicSortFilter(true);
    m_roomPlayersModel->sort(0);
    m_roomPlayersModel->setFilterRole(PlayersListModel::RoomFilterRole);
    m_roomPlayersModel->setFilterFixedString("true");

    // socket stuff
    connect(&NetSocket, SIGNAL(readyRead()), this, SLOT(ClientRead()));
    connect(&NetSocket, SIGNAL(connected()), this, SLOT(OnConnect()));
    connect(&NetSocket, SIGNAL(disconnected()), this, SLOT(OnDisconnect()));
    connect(&NetSocket, SIGNAL(error(QAbstractSocket::SocketError)), this,
            SLOT(displayError(QAbstractSocket::SocketError)));

    connect(this, SIGNAL(messageProcessed()), this, SLOT(ClientRead()), Qt::QueuedConnection);
}

HWNewNet::~HWNewNet()
{
    if (m_game_connected)
    {
        RawSendNet(QString("QUIT%1").arg(delimiter));
        emit disconnected(tr("User quit"));
    }
    NetSocket.flush();
}

void HWNewNet::Connect(const QString & hostName, quint16 port, const QString & nick)
{
    netClientState = Connecting;
    mynick = nick;
    myhost = hostName + QString(":%1").arg(port);
    NetSocket.connectToHost(hostName, port);
}

void HWNewNet::Disconnect()
{
    if (m_game_connected)
        RawSendNet(QString("QUIT%1").arg(delimiter));
    m_game_connected = false;

    NetSocket.disconnectFromHost();
}

void HWNewNet::CreateRoom(const QString & room, const QString & password)
{
    if(netClientState != InLobby || !ByteLength(room))
    {
        qWarning("Illegal try to create room!");
        return;
    }

    myroom = room;

    if(password.isEmpty())
        RawSendNet(QString("CREATE_ROOM%1%2").arg(delimiter).arg(room));
    else
        RawSendNet(QString("CREATE_ROOM%1%2%1%3").arg(delimiter).arg(room).arg(password));

    isChief = true;
}

void HWNewNet::JoinRoom(const QString & room, const QString &password)
{
    if(netClientState != InLobby)
    {
        qWarning("Illegal try to join room!");
        return;
    }

    myroom = room;

    if(password.isEmpty())
        RawSendNet(QString("JOIN_ROOM%1%2").arg(delimiter).arg(room));
    else
        RawSendNet(QString("JOIN_ROOM%1%2%1%3").arg(delimiter).arg(room).arg(password));

    isChief = false;
}

void HWNewNet::AddTeam(const HWTeam & team)
{
    QString cmd = QString("ADD_TEAM") + delimiter +
                  team.name() + delimiter +
                  QString::number(team.color()) + delimiter +
                  team.grave() + delimiter +
                  team.fort() + delimiter +
                  team.voicepack() + delimiter +
                  team.flag() + delimiter +
                  QString::number(team.difficulty());

    for(int i = 0; i < HEDGEHOGS_PER_TEAM; ++i)
    {
        cmd.append(delimiter);
        cmd.append(team.hedgehog(i).Name);
        cmd.append(delimiter);
        cmd.append(team.hedgehog(i).Hat);
    }
    RawSendNet(cmd);
}

void HWNewNet::RemoveTeam(const HWTeam & team)
{
    RawSendNet(QString("REMOVE_TEAM") + delimiter + team.name());
}

void HWNewNet::NewNick(const QString & nick)
{
    RawSendNet(QString("NICK%1%2").arg(delimiter).arg(nick));
}

void HWNewNet::ToggleReady()
{
    RawSendNet(QString("TOGGLE_READY"));
}

void HWNewNet::SendNet(const QByteArray & buf)
{
    QString msg = QString(buf.toBase64());

    RawSendNet(QString("EM%1%2").arg(delimiter).arg(msg));
}

int HWNewNet::ByteLength(const QString & str)
{
	return str.toUtf8().size();
}

void HWNewNet::RawSendNet(const QString & str)
{
    RawSendNet(str.toUtf8());
}

void HWNewNet::RawSendNet(const QByteArray & buf)
{
    qDebug() << "Client: " << QString(QString::fromUtf8(buf)).split("\n");
    NetSocket.write(buf);
    NetSocket.write("\n\n", 2);
}

void HWNewNet::ClientRead()
{
    while (NetSocket.canReadLine())
    {
        QString s = QString::fromUtf8(NetSocket.readLine());
        if (s.endsWith('\n')) s.chop(1);

        if (s.size() == 0)
        {
            ParseCmd(cmdbuf);
            cmdbuf.clear();
            emit messageProcessed();
            return ;
        }
        else
            cmdbuf << s;
    }
}

void HWNewNet::OnConnect()
{
    netClientState = Connected;
}

void HWNewNet::OnDisconnect()
{
    netClientState = Disconnected;
    if(m_game_connected) emit disconnected("");
    m_game_connected = false;
}

void HWNewNet::displayError(QAbstractSocket::SocketError socketError)
{
    m_game_connected = false;

    switch (socketError)
    {
        case QAbstractSocket::RemoteHostClosedError:
            emit disconnected(tr("Remote host has closed connection"));
            break;
        case QAbstractSocket::HostNotFoundError:
            emit disconnected(tr("The host was not found. Please check the host name and port settings."));
            break;
        case QAbstractSocket::ConnectionRefusedError:
            if (getHost() == (QString("%1:%2").arg(NETGAME_DEFAULT_SERVER).arg(NETGAME_DEFAULT_PORT)))
                // Error for official server
                emit disconnected(tr("The connection was refused by the official server or timed out. Something seems to be wrong with the official server at the moment. This might be a temporary problem. Please try again later."));
            else
                // Error for every other host
                emit disconnected(tr("The connection was refused by the host or timed out. This might have one of the following reasons:\n- The Hedgewars Server program does currently not run on the host\n- The specified port number is incorrect\n- There is a temporary network problem\n\nPlease check the host name and port settings and/or try again later."));
            break;
        default:
            emit disconnected(NetSocket.errorString());
    }
}

void HWNewNet::SendPasswordHash(const QString & hash)
{
    // don't send it immediately, only store and check if server asked us for a password
    m_passwordHash = hash.toLatin1();

    maybeSendPassword();
}

void HWNewNet::ParseCmd(const QStringList & lst)
{
    qDebug() << "Server: " << lst;

    if(!lst.size())
    {
        qWarning("Net client: Bad message");
        return;
    }

    if (lst[0] == "NICK")
    {
        mynick = lst[1];
        m_playersModel->setNickname(mynick);
        m_nick_registered = false;
        return ;
    }

    if (lst[0] == "PROTO")
        return ;

    if (lst[0] == "ERROR")
    {
        if (lst.size() == 2)
            emit Error(HWApplication::translate("server", lst[1].toLatin1().constData()));
        else
            emit Error("Unknown error");
        return;
    }

    if (lst[0] == "WARNING")
    {
        if (lst.size() == 2)
            emit Warning(HWApplication::translate("server", lst[1].toLatin1().constData()));
        else
            emit Warning("Unknown warning");
        return;
    }

    if (lst[0] == "CONNECTED")
    {
        if(lst.size() < 3 || lst[2].toInt() < cMinServerVersion)
        {
            // TODO: Warn user, disconnect
            qWarning() << "Server too old";
            RawSendNet(QString("QUIT%1%2").arg(delimiter).arg("Server too old"));
            Disconnect();
            emit disconnected(tr("The server is too old. Disconnecting now."));
            return;
        }

        RawSendNet(QString("NICK%1%2").arg(delimiter).arg(mynick));
        RawSendNet(QString("PROTO%1%2").arg(delimiter).arg(*cProtoVer));
        netClientState = Connected;
        m_game_connected = true;
        emit adminAccess(false);
        return;
    }

    if (lst[0] == "SERVER_AUTH")
    {
        if(lst.size() < 2)
        {
            qWarning("Net: Malformed SERVER_AUTH message");
            return;
        }

        if(lst[1] != m_serverHash)
        {
            Error("Server authentication error");
            Disconnect();
        } else
        {
            // empty m_serverHash variable means no authentication was performed
            // or server passed authentication
            m_serverHash.clear();
        }

        return;
    }

    if (lst[0] == "PING")
    {
        if (lst.size() > 1)
            RawSendNet(QString("PONG%1%2").arg(delimiter).arg(lst[1]));
        else
            RawSendNet(QString("PONG"));
        return;
    }

    if (lst[0] == "ROOMS")
    {
        if(lst.size() % 9 != 1)
        {
            qWarning("Net: Malformed ROOMS message");
            return;
        }
        m_roomsListModel->setRoomsList(lst.mid(1));
        if (m_private_game == false && m_nick_registered == false)
        {
            emit NickNotRegistered(mynick);
        }
        return;
    }

    if (lst[0] == "SERVER_MESSAGE")
    {
        if(lst.size() < 2)
        {
            qWarning("Net: Empty SERVERMESSAGE message");
            return;
        }
        emit serverMessage(lst[1]);
        return;
    }

    if (lst[0] == "CHAT")
    {
        if(lst.size() < 3)
        {
            qWarning("Net: Empty CHAT message");
            return;
        }

        QString action;
        QString message;
        // Fake nicks are nicks used for messages from the server with nicks like
        // [server], [random], etc.
        // The '[' character is not allowed in real nicks.
        bool isFakeNick = lst[1].startsWith('[');
        if(!isFakeNick)
        {
            // Normal message
            message = lst[2];
            // Check for action (/me command)
            action = HWProto::chatStringToAction(message);
        }
        else
        {
            // Server message
            // Server messages are translated client-side
            message = HWApplication::translate("server", lst[2].toLatin1().constData());
        }

        if (netClientState == InLobby)
        {
            if (!action.isNull())
                emit lobbyChatAction(lst[1], action);
            else
                emit lobbyChatMessage(lst[1], message);
        }
        else
        {
            emit chatStringFromNet(HWProto::formatChatMsg(lst[1], message));
            if (!action.isNull())
                emit roomChatAction(lst[1], action);
            else
                emit roomChatMessage(lst[1], message);
        }
        return;
    }

    if (lst[0] == "INFO")
    {
        if(lst.size() < 5)
        {
            qWarning("Net: Malformed INFO message");
            return;
        }
        emit playerInfo(lst[1], lst[2], lst[3], lst[4]);
        if (netClientState != InLobby)
        {
            QStringList tmp = lst;
            tmp.removeFirst();
            emit chatStringFromNet(tmp.join(" ").prepend('\x01'));
        }
        return;
    }

    if (lst[0] == "SERVER_VARS")
    {
        QStringList tmp = lst;
        tmp.removeFirst();
        while (tmp.size() >= 2)
        {
            if(tmp[0] == "MOTD_NEW") emit serverMessageNew(tmp[1]);
            else if(tmp[0] == "MOTD_OLD") emit serverMessageOld(tmp[1]);
            else if(tmp[0] == "LATEST_PROTO") emit latestProtocolVar(tmp[1].toInt());

            tmp.removeFirst();
            tmp.removeFirst();
        }
        return;
    }

    if (lst[0] == "BANLIST")
    {
        QStringList tmp = lst;
        tmp.removeFirst();
        emit bansList(tmp);
        return;
    }

    if (lst[0] == "CLIENT_FLAGS" || lst[0] == "CF")
    {
        if(lst.size() < 3 || lst[1].size() < 2)
        {
            qWarning("Net: Malformed CLIENT_FLAGS message");
            return;
        }

        QString flags = lst[1];
        bool setFlag = flags[0] == '+';
        const QStringList nicks = lst.mid(2);

        while(flags.size() > 1)
        {
            flags.remove(0, 1);
            char c = flags[0].toLatin1();
            bool inRoom = (netClientState == InRoom || netClientState == InGame);

            switch(c)
            {
                // flag indicating if a player is ready to start a game
                case 'r':
                    if(inRoom)
                        foreach (const QString & nick, nicks)
                        {
                            if (nick == mynick)
                            {
                                emit setMyReadyStatus(setFlag);
                            }
                            m_playersModel->setFlag(nick, PlayersListModel::Ready, setFlag);
                        }
                        break;

                // flag indicating if a player is a registered user
                case 'u':
                        foreach(const QString & nick, nicks)
                            m_playersModel->setFlag(nick, PlayersListModel::Registered, setFlag);
                        break;
                // flag indicating if a player is in room
                case 'i':
                        foreach(const QString & nick, nicks)
                            m_playersModel->setFlag(nick, PlayersListModel::InRoom, setFlag);
                        break;
                // flag indicating if a player is contributor
                case 'c':
                        foreach(const QString & nick, nicks)
                            m_playersModel->setFlag(nick, PlayersListModel::Contributor, setFlag);
                        break;
                // flag indicating if a player has engine running
                case 'g':
                    if(inRoom)
                        foreach(const QString & nick, nicks)
                            m_playersModel->setFlag(nick, PlayersListModel::InGame, setFlag);
                        break;

                // flag indicating if a player is the host/master of the room
                case 'h':
                    if(inRoom)
                        foreach (const QString & nick, nicks)
                        {
                            if (nick == mynick)
                            {
                                isChief = setFlag;
                                emit roomMaster(isChief);
                            }

                            m_playersModel->setFlag(nick, PlayersListModel::RoomAdmin, setFlag);
                        }
                        break;

                // flag indicating if a player is admin (if so -> worship them!)
                case 'a':
                        foreach (const QString & nick, nicks)
                        {
                            if (nick == mynick)
                                emit adminAccess(setFlag);

                            m_playersModel->setFlag(nick, PlayersListModel::ServerAdmin, setFlag);
                        }
                        break;

                default:
                        qWarning() << "Net: Unknown client-flag: " << c;
            }
        }

        return;
    }

    if(lst[0] == "KICKED")
    {
        netClientState = InLobby;
        askRoomsList();
        emit LeftRoom(tr("You got kicked"));
        m_playersModel->resetRoomFlags();

        return;
    }

    if(lst[0] == "LOBBY:JOINED")
    {
        if(lst.size() < 2)
        {
            qWarning("Net: Bad JOINED message");
            return;
        }

        for(int i = 1; i < lst.size(); ++i)
        {
            if (lst[i] == mynick)
            {
                // check if server is authenticated or no authentication was performed at all
                if(!m_serverHash.isEmpty())
                {
                    Error(tr("Server authentication error"));

                    Disconnect();
                }

                netClientState = InLobby;
                //RawSendNet(QString("LIST")); //deprecated
                emit connected();
            }

            m_playersModel->addPlayer(lst[i], false);
        }
        return;
    }

    if(lst[0] == "ROOM" && lst.size() == 11 && lst[1] == "ADD")
    {
        QStringList tmp = lst;
        tmp.removeFirst();
        tmp.removeFirst();

        m_roomsListModel->addRoom(tmp);
        return;
    }

    if(lst[0] == "ROOM" && lst.size() == 12 && lst[1] == "UPD")
    {
        QStringList tmp = lst;
        tmp.removeFirst();
        tmp.removeFirst();

        QString roomName = tmp.takeFirst();
        m_roomsListModel->updateRoom(roomName, tmp);

        // keep track of room name so correct name is displayed
        if(myroom == roomName && myroom != tmp[1])
        {
            myroom = tmp[1];
            emit roomNameUpdated(myroom);
        }

        return;
    }

    if(lst[0] == "ROOM" && lst.size() == 3 && lst[1] == "DEL")
    {
        m_roomsListModel->removeRoom(lst[2]);
        return;
    }

    if(lst[0] == "LOBBY:LEFT")
    {
        if(lst.size() < 2)
        {
            qWarning("Net: Bad LOBBY:LEFT message");
            return;
        }

        if (lst.size() < 3)
            m_playersModel->removePlayer(lst[1]);
        else
            m_playersModel->removePlayer(lst[1], lst[2]);

        return;
    }

    if (lst[0] == "ASKPASSWORD")
    {
        // server should send us salt of at least 16 characters

        if(lst.size() < 2 || lst[1].size() < 16)
        {
            qWarning("Net: Bad ASKPASSWORD message");
            return;
        }

        emit NickRegistered(mynick);
        m_nick_registered = true;

        // store server salt
        // when this variable is set, it is assumed that server asked us for a password
        m_serverSalt = lst[1];
        m_clientSalt = QUuid::createUuid().toString();

        maybeSendPassword();

        return;
    }

    if (lst[0] == "NOTICE")
    {
        if(lst.size() < 2)
        {
            qWarning("Net: Bad NOTICE message");
            return;
        }

        bool ok;
        int n = lst[1].toInt(&ok);
        if(!ok)
        {
            qWarning("Net: Bad NOTICE message");
            return;
        }

        handleNotice(n);

        return;
    }

    if (lst[0] == "BYE")
    {
        if (lst.size() < 2)
        {
            qWarning("Net: Bad BYE message");
            return;
        }
        if (lst[1] == "Authentication failed")
        {
            emit AuthFailed();
            m_game_connected = false;
            Disconnect();
            //omitted 'emit disconnected()', we don't want the error message
            return;
        }
        m_game_connected = false;
        Disconnect();
        emit disconnected(HWApplication::translate("server", lst[1].toLatin1().constData()));
        return;
    }

    if(lst[0] == "JOINING")
    {
        if(lst.size() != 2)
        {
            qWarning("Net: Bad JOINING message");
            return;
        }

        myroom = lst[1];
        emit roomNameUpdated(myroom);
        return;
    }

    if(netClientState == InLobby && lst[0] == "JOINED")
    {
        if(lst.size() < 2 || lst[1] != mynick)
        {
            qWarning("Net: Bad JOINED message");
            return;
        }

        for(int i = 1; i < lst.size(); ++i)
        {
            if (lst[i] == mynick)
            {
                netClientState = InRoom;
                emit EnteredGame();
                emit roomMaster(isChief);
                if (isChief)
                    emit configAsked();
            }

            m_playersModel->playerJoinedRoom(lst[i], isChief && (lst[i] != mynick));

            emit chatStringFromNet(tr("%1 *** %2 has joined the room").arg('\x03').arg(lst[i]));
        }
        return;
    }

    if(netClientState == InRoom || netClientState == InGame)
    {
        if (lst[0] == "EM")
        {
            if(lst.size() < 2)
            {
                qWarning("Net: Bad EM message");
                return;
            }
            for(int i = 1; i < lst.size(); ++i)
            {
                QByteArray em = QByteArray::fromBase64(lst[i].toLatin1());
                emit FromNet(em);
            }
            return;
        }

        if (lst[0] == "ROUND_FINISHED")
        {
            emit FromNet(QByteArray("\x01o"));
            return;
        }

        if (lst[0] == "ADD_TEAM")
        {
            if(lst.size() != 24)
            {
                qWarning("Net: Bad ADDTEAM message");
                return;
            }
            QStringList tmp = lst;
            tmp.removeFirst();
            HWTeam team(tmp);
            emit AddNetTeam(team);
            return;
        }

        if (lst[0] == "REMOVE_TEAM")
        {
            if(lst.size() != 2)
            {
                qWarning("Net: Bad REMOVETEAM message");
                return;
            }
            emit RemoveNetTeam(HWTeam(lst[1]));
            return;
        }

        if(lst[0] == "ROOMABANDONED")
        {
            netClientState = InLobby;
            m_playersModel->resetRoomFlags();
            emit LeftRoom(tr("Room destroyed"));
            return;
        }

        if (lst[0] == "RUN_GAME")
        {
            netClientState = InGame;
            emit AskForRunGame();
            return;
        }

        if (lst[0] == "TEAM_ACCEPTED")
        {
            if (lst.size() != 2)
            {
                qWarning("Net: Bad TEAM_ACCEPTED message");
                return;
            }
            emit TeamAccepted(lst[1]);
            return;
        }

        if (lst[0] == "CFG")
        {
            if(lst.size() < 3)
            {
                qWarning("Net: Bad CFG message");
                return;
            }
            QStringList tmp = lst;
            tmp.removeFirst();
            tmp.removeFirst();
            if (lst[1] == "SCHEME")
                emit netSchemeConfig(tmp);
            else
                emit paramChanged(lst[1], tmp);
            return;
        }

        if (lst[0] == "HH_NUM")
        {
            if (lst.size() != 3)
            {
                qWarning("Net: Bad TEAM_ACCEPTED message");
                return;
            }
            HWTeam tmptm(lst[1]);
            tmptm.setNumHedgehogs(lst[2].toUInt());
            emit hhnumChanged(tmptm);
            return;
        }

        if (lst[0] == "TEAM_COLOR")
        {
            if (lst.size() != 3)
            {
                qWarning("Net: Bad TEAM_COLOR message");
                return;
            }
            HWTeam tmptm(lst[1]);
            tmptm.setColor(lst[2].toInt());
            emit teamColorChanged(tmptm);
            return;
        }

        if(lst[0] == "JOINED")
        {
            if(lst.size() < 2)
            {
                qWarning("Net: Bad JOINED message");
                return;
            }

            for(int i = 1; i < lst.size(); ++i)
            {
                emit chatStringFromNet(tr("%1 *** %2 has joined the room").arg('\x03').arg(lst[i]));
                m_playersModel->playerJoinedRoom(lst[i], isChief && (lst[i] != mynick));
            }
            return;
        }

        if(lst[0] == "LEFT")
        {
            if(lst.size() < 2)
            {
                qWarning("Net: Bad LEFT message");
                return;
            }

            if (lst.size() < 3)
                emit chatStringFromNet(tr("%1 *** %2 has left").arg('\x03').arg(lst[1]));
            else
            {
                QString leaveMsg = QString(lst[2]);
                if (leaveMsg.startsWith("User quit: "))
                {
                    leaveMsg.remove(0, 11);
                    emit chatStringFromNet(tr("%1 *** %2 has left (message: \"%3\")").arg('\x03').arg(lst[1]).arg(leaveMsg));
                }
                else if (leaveMsg.startsWith("part: "))
                {
                    leaveMsg.remove(0, 6);
                    emit chatStringFromNet(tr("%1 *** %2 has left (%3)").arg('\x03').arg(lst[1]).arg(leaveMsg));
                }
                else
                    emit chatStringFromNet(tr("%1 *** %2 has left (%3)").arg('\x03').arg(lst[1]).arg(HWApplication::translate("server", leaveMsg.toLatin1().constData())));
            }
            m_playersModel->playerLeftRoom(lst[1]);
            return;
        }
    }

    qWarning() << "Net: Unknown message or wrong state:" << lst;
}

void HWNewNet::onHedgehogsNumChanged(const HWTeam& team)
{
    if (isChief)
        RawSendNet(QString("HH_NUM%1%2%1%3")
                   .arg(delimiter)
                   .arg(team.name())
                   .arg(team.numHedgehogs()));
}

void HWNewNet::onTeamColorChanged(const HWTeam& team)
{
    if (isChief)
        RawSendNet(QString("TEAM_COLOR%1%2%1%3")
                   .arg(delimiter)
                   .arg(team.name())
                   .arg(team.color()));
}

void HWNewNet::onParamChanged(const QString & param, const QStringList & value)
{
    if (isChief)
        RawSendNet(
            QString("CFG%1%2%1%3")
            .arg(delimiter)
            .arg(param)
            .arg(value.join(QString(delimiter)))
        );
}

void HWNewNet::chatLineToNetWithEcho(const QString& str)
{
    if(str != "")
    {
        emit chatStringFromNet(HWProto::formatChatMsg(mynick, str));
        chatLineToNet(str);
    }
}

void HWNewNet::chatLineToNet(const QString& str)
{
    if(ByteLength(str))
    {
        RawSendNet(QString("CHAT") + delimiter + str);
        QString action = HWProto::chatStringToAction(str);
        if (action != NULL)
            emit(roomChatAction(mynick, action));
        else
            emit(roomChatMessage(mynick, str));
    }
}

void HWNewNet::chatLineToLobby(const QString& str)
{
    if(ByteLength(str))
    {
        RawSendNet(QString("CHAT") + delimiter + str);
        QString action = HWProto::chatStringToAction(str);
        if (action != NULL)
            emit(lobbyChatAction(mynick, action));
        else
            emit(lobbyChatMessage(mynick, str));
    }
}

void HWNewNet::SendTeamMessage(const QString& str)
{
    RawSendNet(QString("TEAMCHAT") + delimiter + str);
}

void HWNewNet::askRoomsList()
{
    if(netClientState != InLobby)
    {
        qWarning("Illegal try to get rooms list!");
        return;
    }
    //RawSendNet(QString("LIST")); //deprecated
}

HWNewNet::ClientState HWNewNet::clientState()
{
    return netClientState;
}

QString HWNewNet::getNick()
{
    return mynick;
}

QString HWNewNet::getRoom()
{
    return myroom;
}

QString HWNewNet::getHost()
{
    return myhost;
}

bool HWNewNet::isRoomChief()
{
    return isChief;
}

void HWNewNet::gameFinished(bool correctly)
{
    if (netClientState == InGame)
    {
        netClientState = InRoom;
        RawSendNet(QString("ROUNDFINISHED%1%2").arg(delimiter).arg(correctly ? "1" : "0"));
    }
}

void HWNewNet::banPlayer(const QString & nick)
{
    RawSendNet(QString("BAN%1%2").arg(delimiter).arg(nick));
}

void HWNewNet::banIP(const QString & ip, const QString & reason, int seconds)
{
    RawSendNet(QString("BANIP%1%2%1%3%1%4").arg(delimiter).arg(ip).arg(reason).arg(seconds));
}

void HWNewNet::banNick(const QString & nick, const QString & reason, int seconds)
{
    RawSendNet(QString("BANNICK%1%2%1%3%1%4").arg(delimiter).arg(nick).arg(reason).arg(seconds));
}

void HWNewNet::getBanList()
{
    RawSendNet(QByteArray("BANLIST"));
}

void HWNewNet::removeBan(const QString & b)
{
    RawSendNet(QString("UNBAN%1%2").arg(delimiter).arg(b));
}

void HWNewNet::kickPlayer(const QString & nick)
{
    RawSendNet(QString("KICK%1%2").arg(delimiter).arg(nick));
}

void HWNewNet::delegateToPlayer(const QString & nick)
{
    RawSendNet(QString("DELEGATE%1%2").arg(delimiter).arg(nick));
}

void HWNewNet::infoPlayer(const QString & nick)
{
    RawSendNet(QString("INFO%1%2").arg(delimiter).arg(nick));
}

void HWNewNet::followPlayer(const QString & nick)
{
    if (!isInRoom())
    {
        RawSendNet(QString("FOLLOW%1%2").arg(delimiter).arg(nick));
        isChief = false;
    }
}

void HWNewNet::consoleCommand(const QString & cmd)
{
    RawSendNet(QString("CMD%1%2").arg(delimiter).arg(cmd));
}

bool HWNewNet::allPlayersReady()
{
    int ready = 0;
    for (int i = 0; i < m_roomPlayersModel->rowCount(); i++)
        if (m_roomPlayersModel->index(i, 0).data(PlayersListModel::Ready).toBool()) ready++;

    return (ready == m_roomPlayersModel->rowCount());
}

void HWNewNet::startGame()
{
    RawSendNet(QString("START_GAME"));
}

void HWNewNet::updateRoomName(const QString & name)
{
    RawSendNet(QString("ROOM_NAME%1%2").arg(delimiter).arg(name));
}


void HWNewNet::toggleRestrictJoins()
{
    RawSendNet(QString("TOGGLE_RESTRICT_JOINS"));
}

void HWNewNet::toggleRestrictTeamAdds()
{
    RawSendNet(QString("TOGGLE_RESTRICT_TEAMS"));
}

void HWNewNet::toggleRegisteredOnly()
{
    RawSendNet(QString("TOGGLE_REGISTERED_ONLY"));
}

void HWNewNet::clearAccountsCache()
{
    RawSendNet(QString("CLEAR_ACCOUNTS_CACHE"));
}

void HWNewNet::partRoom()
{
    netClientState = InLobby;
    m_playersModel->resetRoomFlags();
    RawSendNet(QString("PART"));
}

bool HWNewNet::isInRoom()
{
    return netClientState >= InRoom;
}

void HWNewNet::setServerMessageNew(const QString & msg)
{
    RawSendNet(QString("SET_SERVER_VAR%1MOTD_NEW%1%2").arg(delimiter).arg(msg));
}

void HWNewNet::setServerMessageOld(const QString & msg)
{
    RawSendNet(QString("SET_SERVER_VAR%1MOTD_OLD%1%2").arg(delimiter).arg(msg));
}

void HWNewNet::setLatestProtocolVar(int proto)
{
    RawSendNet(QString("SET_SERVER_VAR%1LATEST_PROTO%1%2").arg(delimiter).arg(proto));
}

void HWNewNet::askServerVars()
{
    RawSendNet(QString("GET_SERVER_VAR"));
}

void HWNewNet::handleNotice(int n)
{
    switch(n)
    {
        case 0:
            emit NickTaken(mynick);
            break;
        case 2:
            emit askForRoomPassword();
            break;
    }
}

RoomsListModel * HWNewNet::roomsListModel()
{
    return m_roomsListModel;
}

QAbstractItemModel *HWNewNet::lobbyPlayersModel()
{
    return m_lobbyPlayersModel;
}

QAbstractItemModel *HWNewNet::roomPlayersModel()
{
    return m_roomPlayersModel;
}

void HWNewNet::roomPasswordEntered(const QString &password)
{
    if(!myroom.isEmpty())
        JoinRoom(myroom, password);
}

void HWNewNet::maybeSendPassword()
{
/* When we got password hash, and server asked us for a password, perform mutual authentication:
 * at this point we have salt chosen by server
 * client sends client salt and hash of secret (password hash) salted with client salt, server salt,
 * and static salt (predefined string + protocol number)
 * server should respond with hash of the same set in different order.
 */

    if(m_passwordHash.isEmpty() || m_serverSalt.isEmpty())
        return;

    QString hash = QCryptographicHash::hash(
                m_clientSalt.toLatin1()
                .append(m_serverSalt.toLatin1())
                .append(m_passwordHash)
                .append(cProtoVer->toLatin1())
                .append("!hedgewars")
                , QCryptographicHash::Sha1).toHex();

    m_serverHash = QCryptographicHash::hash(
                m_serverSalt.toLatin1()
                .append(m_clientSalt.toLatin1())
                .append(m_passwordHash)
                .append(cProtoVer->toLatin1())
                .append("!hedgewars")
                , QCryptographicHash::Sha1).toHex();

    RawSendNet(QString("PASSWORD%1%2%1%3").arg(delimiter).arg(hash).arg(m_clientSalt));
}
