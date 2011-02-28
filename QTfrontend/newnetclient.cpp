/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Ulyanov Igor <iulyanov@gmail.com>
 * Copyright (c) 2010 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QDebug>
#include <QInputDialog>
#include <QCryptographicHash>

#include "hwconsts.h"
#include "newnetclient.h"
#include "proto.h"
#include "gameuiconfig.h"
#include "game.h"
#include "gamecfgwidget.h"
#include "teamselect.h"
#include "misc.h"
/* only to get the ignoreList from the chat widget */
#include "hwform.h"
#include "pages.h"
#include "chatwidget.h"

char delimeter='\n';

HWNewNet::HWNewNet(GameUIConfig * config, GameCFGWidget* pGameCFGWidget, TeamSelWidget* pTeamSelWidget) :
  config(config),
  m_pGameCFGWidget(pGameCFGWidget),
  m_pTeamSelWidget(pTeamSelWidget),
  isChief(false),
  m_game_connected(false),
  loginStep(0),
  netClientState(0)
{
// socket stuff
    connect(&NetSocket, SIGNAL(readyRead()), this, SLOT(ClientRead()));
    connect(&NetSocket, SIGNAL(connected()), this, SLOT(OnConnect()));
    connect(&NetSocket, SIGNAL(disconnected()), this, SLOT(OnDisconnect()));
    connect(&NetSocket, SIGNAL(error(QAbstractSocket::SocketError)), this,
            SLOT(displayError(QAbstractSocket::SocketError)));

// config stuff
    connect(this, SIGNAL(paramChanged(const QString &, const QStringList &)), pGameCFGWidget, SLOT(setParam(const QString &, const QStringList &)));
    connect(pGameCFGWidget, SIGNAL(paramChanged(const QString &, const QStringList &)), this, SLOT(onParamChanged(const QString &, const QStringList &)));
    connect(this, SIGNAL(configAsked()), pGameCFGWidget, SLOT(fullNetConfig()));
}

HWNewNet::~HWNewNet()
{
    if (m_game_connected)
    {
        RawSendNet(QString("QUIT%1%2").arg(delimeter).arg("User quit"));
        emit Disconnected();
    }
    NetSocket.flush();
}

void HWNewNet::Connect(const QString & hostName, quint16 port, const QString & nick)
{
    mynick = nick.isEmpty() ? QLineEdit::tr("unnamed") : nick;
    myhost = hostName + QString(":%1").arg(port);
    NetSocket.connectToHost(hostName, port);
}

void HWNewNet::Disconnect()
{
    if (m_game_connected)
        RawSendNet(QString("QUIT%1%2").arg(delimeter).arg("User quit"));
    m_game_connected = false;

    NetSocket.disconnectFromHost();
}

void HWNewNet::CreateRoom(const QString & room)
{
    if(netClientState != 2)
    {
        qWarning("Illegal try to create room!");
        return;
    }

    myroom = room;

    RawSendNet(QString("CREATE_ROOM%1%2").arg(delimeter).arg(room));
    isChief = true;
}

void HWNewNet::JoinRoom(const QString & room)
{
    if(netClientState != 2)
    {
        qWarning("Illegal try to join room!");
        return;
    }

    myroom = room;

    RawSendNet(QString("JOIN_ROOM%1%2").arg(delimeter).arg(room));
    isChief = false;
}

void HWNewNet::AddTeam(const HWTeam & team)
{
    QString cmd = QString("ADD_TEAM") + delimeter +
         team.TeamName + delimeter +
         team.teamColor.name() + delimeter +
         team.Grave + delimeter +
         team.Fort + delimeter +
         team.Voicepack + delimeter +
         team.Flag + delimeter +
         QString::number(team.difficulty);

    for(int i = 0; i < 8; ++i)
    {
        cmd.append(delimeter);
        cmd.append(team.Hedgehogs[i].Name);
        cmd.append(delimeter);
        cmd.append(team.Hedgehogs[i].Hat);
    }
    RawSendNet(cmd);
}

void HWNewNet::RemoveTeam(const HWTeam & team)
{
    RawSendNet(QString("REMOVE_TEAM") + delimeter + team.TeamName);
}

void HWNewNet::ToggleReady()
{
  RawSendNet(QString("TOGGLE_READY"));
}

void HWNewNet::SendNet(const QByteArray & buf)
{
  QString msg = QString(buf.toBase64());

  RawSendNet(QString("EM%1%2").arg(delimeter).arg(msg));
}

void HWNewNet::RawSendNet(const QString & str)
{
  RawSendNet(str.toUtf8());
}

void HWNewNet::RawSendNet(const QByteArray & buf)
{
  qDebug() << "Client: " << QString(buf).split("\n");
    NetSocket.write(buf);
    NetSocket.write("\n\n", 2);
}

void HWNewNet::ClientRead()
{
    while (NetSocket.canReadLine()) {
        QString s = QString::fromUtf8(NetSocket.readLine());
        if (s.endsWith('\n')) s.chop(1);

        if (s.size() == 0) {
            ParseCmd(cmdbuf);
            cmdbuf.clear();
        } else
            cmdbuf << s;
    }
}

void HWNewNet::OnConnect()
{
}

void HWNewNet::OnDisconnect()
{
    if(m_game_connected) emit Disconnected();
    m_game_connected = false;
}

void HWNewNet::displayError(QAbstractSocket::SocketError socketError)
{
    emit Disconnected();

    switch (socketError) {
        case QAbstractSocket::RemoteHostClosedError:
            break;
        case QAbstractSocket::HostNotFoundError:
            emit showMessage(tr("The host was not found. Please check the host name and port settings."));
            break;
        case QAbstractSocket::ConnectionRefusedError:
            emit showMessage(tr("Connection refused"));
            break;
        default:
            emit showMessage(NetSocket.errorString());
        }
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
        return ;
    }

    if (lst[0] == "PROTO")
        return ;

    if (lst[0] == "ERROR") {
        if (lst.size() == 2)
            emit showMessage("Error: " + lst[1]);
        else
            emit showMessage("Unknown error");
        return;
    }

    if (lst[0] == "WARNING") {
        if (lst.size() == 2)
            emit showMessage("Warning: " + lst[1]);
        else
            emit showMessage("Unknown warning");
        return;
    }

    if (lst[0] == "CONNECTED") {
        if(lst.size() < 3 || lst[2].toInt() < cMinServerVersion)
        {
            // TODO: Warn user, disconnect
            qWarning() << "Server too old";
        }

        RawSendNet(QString("NICK%1%2").arg(delimeter).arg(mynick));
        RawSendNet(QString("PROTO%1%2").arg(delimeter).arg(*cProtoVer));
        netClientState = 1;
        m_game_connected = true;
        emit adminAccess(false);
        return;
    }

    if (lst[0] == "PING") {
        if (lst.size() > 1)
            RawSendNet(QString("PONG%1%2").arg(delimeter).arg(lst[1]));
        else
            RawSendNet(QString("PONG"));
        return;
    }

    if (lst[0] == "ROOMS") {
        QStringList tmp = lst;
        tmp.removeFirst();
        emit roomsList(tmp);
        return;
    }

    if (lst[0] == "SERVER_MESSAGE") {
        if(lst.size() < 2)
        {
            qWarning("Net: Empty SERVERMESSAGE message");
            return;
        }
        emit serverMessage(lst[1]);
        return;
    }

    if (lst[0] == "CHAT") {
        if(lst.size() < 3)
        {
            qWarning("Net: Empty CHAT message");
            return;
        }
        if (netClientState == 2)
            emit chatStringLobby(lst[1], HWProto::formatChatMsgForFrontend(lst[2]));
        else
            emit chatStringFromNet(HWProto::formatChatMsg(lst[1], lst[2]));
        return;
    }

    if (lst[0] == "INFO") {
        if(lst.size() < 5)
        {
            qWarning("Net: Malformed INFO message");
            return;
        }
        QStringList tmp = lst;
        tmp.removeFirst();
        if (netClientState == 2)
            emit chatStringLobby(tmp.join("\n").prepend('\x01'));
        else
            emit chatStringFromNet(tmp.join("\n").prepend('\x01'));
        return;
    }

    if (lst[0] == "SERVER_VARS") {
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

    if (lst[0] == "CLIENT_FLAGS")
    {
        if(lst.size() < 3 || lst[1].size() < 2)
        {
            qWarning("Net: Malformed CLIENT_FLAGS message");
            return;
        }

        QString flags = lst[1];
        bool setFlag = flags[0] == '+';

        while(flags.size() > 1)
        {
            flags.remove(0, 1);
            char c = flags[0].toAscii();

            switch(c)
            {
            case 'r':
                {
                    for(int i = 2; i < lst.size(); ++i)
                    {
                        if (lst[i] == mynick)
                            emit setMyReadyStatus(setFlag);
                        emit setReadyStatus(lst[i], setFlag);
                    }
                }
            }
        }

        return;
    }

    if (lst[0] == "ADD_TEAM") {
        if(lst.size() != 24)
        {
            qWarning("Net: Bad ADDTEAM message");
            return;
        }
        QStringList tmp = lst;
        tmp.removeFirst();
        emit AddNetTeam(tmp);
        return;
    }

    if (lst[0] == "REMOVE_TEAM") {
        if(lst.size() != 2)
        {
            qWarning("Net: Bad REMOVETEAM message");
            return;
        }
        m_pTeamSelWidget->removeNetTeam(HWTeam(lst[1]));
        return;
    }

    if(lst[0] == "ROOMABANDONED") {
        netClientState = 2;
        emit showMessage(HWNewNet::tr("Room destroyed"));
        emit LeftRoom();
        return;
    }

    if(lst[0] == "KICKED") {
        netClientState = 2;
        emit showMessage(HWNewNet::tr("You got kicked"));
        emit LeftRoom();
        return;
    }

    if(lst[0] == "JOINED") {
        if(lst.size() < 2)
        {
            qWarning("Net: Bad JOINED message");
            return;
        }

        for(int i = 1; i < lst.size(); ++i)
        {
            if (lst[i] == mynick)
            {
                netClientState = 3;
                emit EnteredGame();
                emit roomMaster(isChief);
                if (isChief)
                    emit configAsked();
            }
            if (lst[i] != mynick && isChief && config->Form->ui.pageRoomsList->chatWidget->ignoreList.contains(lst[i], Qt::CaseInsensitive) && !config->Form->ui.pageRoomsList->chatWidget->friendsList.contains(lst[i], Qt::CaseInsensitive))
            {
                kickPlayer(lst[i]);
            }
            else
            {
                emit nickAdded(lst[i], isChief && (lst[i] != mynick));
                emit chatStringFromNet(tr("%1 *** %2 has joined the room").arg('\x03').arg(lst[i]));
            }
        }
        return;
    }

    if(lst[0] == "LOBBY:JOINED") {
        if(lst.size() < 2)
        {
            qWarning("Net: Bad JOINED message");
            return;
        }

        for(int i = 1; i < lst.size(); ++i)
        {
            if (lst[i] == mynick)
            {
                netClientState = 2;
                RawSendNet(QString("LIST"));
                emit Connected();
            }

            emit nickAddedLobby(lst[i], false);
            emit chatStringLobby(lst[i], tr("%1 *** %2 has joined").arg('\x03').arg("|nick|"));
        }
        return;
    }

    if(lst[0] == "LEFT") {
        if(lst.size() < 2)
        {
            qWarning("Net: Bad LEFT message");
            return;
        }
        emit nickRemoved(lst[1]);
        if (lst.size() < 3)
            emit chatStringFromNet(tr("%1 *** %2 has left").arg('\x03').arg(lst[1]));
        else
            emit chatStringFromNet(tr("%1 *** %2 has left (%3)").arg('\x03').arg(lst[1], lst[2]));
        return;
    }

    if(lst[0] == "ROOM") {
        if(lst.size() < 2)
        {
            qWarning("Net: Bad ROOM message");
            return;
        }
        RawSendNet(QString("LIST"));
        return;
    }

    if(lst[0] == "LOBBY:LEFT") {
        if(lst.size() < 2)
        {
            qWarning("Net: Bad LOBBY:LEFT message");
            return;
        }
        emit nickRemovedLobby(lst[1]);
        if (lst.size() < 3)
            emit chatStringLobby(tr("%1 *** %2 has left").arg('\x03').arg(lst[1]));
        else
            emit chatStringLobby(tr("%1 *** %2 has left (%3)").arg('\x03').arg(lst[1], lst[2]));
        return;
    }

    if (lst[0] == "RUN_GAME") {
        netClientState = 5;
        emit AskForRunGame();
        return;
    }

    if (lst[0] == "ASKPASSWORD") {
        bool ok = false;
        int passLength = config->value("net/passwordlength", 0).toInt();
        QString hash = config->value("net/passwordhash", "").toString();
        QString password = QInputDialog::getText(0, tr("Password"), tr("Your nickname %1 is\nregistered on Hedgewars.org\nPlease provide your password below\nor pick another nickname in game config:").arg(mynick), QLineEdit::Password, passLength==0?NULL:QString(passLength,'\0'), &ok);

        if (!ok) {
            Disconnect();
            emit Disconnected();
            return;
        }

        if (!passLength || password!=QString(passLength, '\0')) {
            hash = QCryptographicHash::hash(password.toLatin1(), QCryptographicHash::Md5).toHex();
            config->setValue("net/passwordhash", hash);
            config->setValue("net/passwordlength", password.size());
        }

        RawSendNet(QString("PASSWORD%1%2").arg(delimeter).arg(hash));
        return;
    }

    if (lst[0] == "NOTICE") {
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

    if (lst[0] == "TEAM_ACCEPTED") {
        if (lst.size() != 2)
        {
            qWarning("Net: Bad TEAM_ACCEPTED message");
            return;
        }
        m_pTeamSelWidget->changeTeamStatus(lst[1]);
        return;
    }


    if (lst[0] == "CFG") {
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

    if (lst[0] == "HH_NUM") {
        if (lst.size() != 3)
        {
            qWarning("Net: Bad TEAM_ACCEPTED message");
            return;
        }
        HWTeam tmptm(lst[1]);
        tmptm.numHedgehogs = lst[2].toUInt();
        emit hhnumChanged(tmptm);
        return;
    }

    if (lst[0] == "TEAM_COLOR") {
        if (lst.size() != 3)
        {
            qWarning("Net: Bad TEAM_COLOR message");
            return;
        }
        HWTeam tmptm(lst[1]);
        tmptm.teamColor = QColor(lst[2]);
        emit teamColorChanged(tmptm);
        return;
    }

    if (lst[0] == "EM") {
        if(lst.size() < 2)
        {
            qWarning("Net: Bad EM message");
            return;
        }
        for(int i = 1; i < lst.size(); ++i)
        {
            QByteArray em = QByteArray::fromBase64(lst[i].toAscii());
            emit FromNet(em);
        }
        return;
    }

    if (lst[0] == "BYE") {
        if (lst.size() < 2)
        {
            qWarning("Net: Bad BYE message");
            return;
        }
        emit showMessage(HWNewNet::tr("Quit reason: ") + lst[1]);
        return;
    }


    if (lst[0] == "ADMIN_ACCESS") {
        emit adminAccess(true);
        return;
    }

    if (lst[0] == "ROOM_CONTROL_ACCESS") {
        if (lst.size() < 2)
        {
            qWarning("Net: Bad BYE message");
            return;
        }
        bool b = lst[1] != "0";
        m_pGameCFGWidget->setEnabled(b);
        m_pTeamSelWidget->setInteractivity(b);
        isChief = b;
        emit roomMaster(isChief);

        return;
    }

    qWarning() << "Net: Unknown message:" << lst;
}

void HWNewNet::onHedgehogsNumChanged(const HWTeam& team)
{
    if (isChief)
    RawSendNet(QString("HH_NUM%1%2%1%3")
            .arg(delimeter)
            .arg(team.TeamName)
            .arg(team.numHedgehogs));
}

void HWNewNet::onTeamColorChanged(const HWTeam& team)
{
    if (isChief)
    RawSendNet(QString("TEAM_COLOR%1%2%1%3")
            .arg(delimeter)
            .arg(team.TeamName)
            .arg(team.teamColor.name()));
}

void HWNewNet::onParamChanged(const QString & param, const QStringList & value)
{
    if (isChief)
        RawSendNet(
                QString("CFG%1%2%1%3")
                    .arg(delimeter)
                    .arg(param)
                    .arg(value.join(QString(delimeter)))
                );
}

void HWNewNet::chatLineToNet(const QString& str)
{
    if(str != "") {
        RawSendNet(QString("CHAT") + delimeter + str);
        emit(chatStringFromMe(HWProto::formatChatMsg(mynick, str)));
    }
}

void HWNewNet::chatLineToLobby(const QString& str)
{
    if(str != "") {
        RawSendNet(QString("CHAT") + delimeter + str);
        emit(chatStringFromMeLobby(HWProto::formatChatMsg(mynick, str)));
    }
}

void HWNewNet::SendTeamMessage(const QString& str)
{
    RawSendNet(QString("TEAMCHAT") + delimeter + str);
}

void HWNewNet::askRoomsList()
{
    if(netClientState != 2)
    {
        qWarning("Illegal try to get rooms list!");
        return;
    }
    RawSendNet(QString("LIST"));
}

int HWNewNet::getClientState()
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
    if (netClientState == 5) netClientState = 3;
    RawSendNet(QString("ROUNDFINISHED%1%2").arg(delimeter).arg(correctly ? "1" : "0"));
}

void HWNewNet::banPlayer(const QString & nick)
{
    RawSendNet(QString("BAN%1%2").arg(delimeter).arg(nick));
}

void HWNewNet::kickPlayer(const QString & nick)
{
    RawSendNet(QString("KICK%1%2").arg(delimeter).arg(nick));
}

void HWNewNet::infoPlayer(const QString & nick)
{
    RawSendNet(QString("INFO%1%2").arg(delimeter).arg(nick));
}

void HWNewNet::followPlayer(const QString & nick)
{
    if (!isInRoom()) {
        RawSendNet(QString("FOLLOW%1%2").arg(delimeter).arg(nick));
        isChief = false;
    }
}

void HWNewNet::startGame()
{
    RawSendNet(QString("START_GAME"));
}

void HWNewNet::toggleRestrictJoins()
{
    RawSendNet(QString("TOGGLE_RESTRICT_JOINS"));
}

void HWNewNet::toggleRestrictTeamAdds()
{
    RawSendNet(QString("TOGGLE_RESTRICT_TEAMS"));
}

void HWNewNet::clearAccountsCache()
{
    RawSendNet(QString("CLEAR_ACCOUNTS_CACHE"));
}

void HWNewNet::partRoom()
{
    netClientState = 2;
    RawSendNet(QString("PART"));
}

bool HWNewNet::isInRoom()
{
    return netClientState > 2;
}

void HWNewNet::setServerMessageNew(const QString & msg)
{
    RawSendNet(QString("SET_SERVER_VAR%1MOTD_NEW%1%2").arg(delimeter).arg(msg));
}

void HWNewNet::setServerMessageOld(const QString & msg)
{
    RawSendNet(QString("SET_SERVER_VAR%1MOTD_OLD%1%2").arg(delimeter).arg(msg));
}

void HWNewNet::setLatestProtocolVar(int proto)
{
    RawSendNet(QString("SET_SERVER_VAR%1LATEST_PROTO%1%2").arg(delimeter).arg(proto));
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
        {
            bool ok = false;
            QString newNick = QInputDialog::getText(0, tr("Nickname"), tr("Some one already uses\n your nickname %1\non the server.\nPlease pick another nickname:").arg(mynick), QLineEdit::Normal, mynick, &ok);

            if (!ok || newNick.isEmpty()) {
                Disconnect();
                emit Disconnected();
                return;
            }

            config->setValue("net/nick", newNick);
            mynick = newNick;

            RawSendNet(QString("NICK%1%2").arg(delimeter).arg(newNick));

            break;
        }
    }
}
