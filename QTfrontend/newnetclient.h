/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Ulyanov Igor <iulyanov@gmail.com>
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

extern char delimeter;

class HWNewNet : public QObject
{
  Q_OBJECT

 public:
  HWNewNet(GameUIConfig * config, GameCFGWidget* pGameCFGWidget, TeamSelWidget* pTeamSelWidget);
  ~HWNewNet();
  void Connect(const QString & hostName, quint16 port, const QString & nick);
  void Disconnect();
  bool isRoomChief();
  bool isInRoom();
  int getClientState();
  QString getNick();
  QString getRoom();
  QString getHost();

 private:
  GameUIConfig* config;
  GameCFGWidget* m_pGameCFGWidget;
  TeamSelWidget* m_pTeamSelWidget;

  bool isChief;
  QString mynick;
  QString myroom;
  QString myhost;
  QTcpSocket NetSocket;
  QString seed;
  bool m_game_connected;

  template <typename T>
  void SendCfgStrNet(T a) {
    QByteArray strmsg;
    strmsg.append(a);
    quint8 sz = strmsg.size();
    QByteArray enginemsg = QByteArray((char *)&sz, 1) + strmsg;
    QString _msg = delimeter + QString(enginemsg.toBase64());
    RawSendNet(_msg);
  }

  template <typename T>
  void SendCfgStrLoc(T a) {
    QByteArray strmsg;
    strmsg.append(QString(a).toUtf8());
    quint8 sz = strmsg.size();
    QByteArray enginemsg = QByteArray((char *)&sz, 1) + strmsg;
    emit FromNet(enginemsg);
  }

  QStringList cmdbuf;

  void RawSendNet(const QString & buf);
  void RawSendNet(const QByteArray & buf);
  void ParseCmd(const QStringList & lst);
  void handleNotice(int n);

  int loginStep;
  int netClientState;

 signals:
  void AskForRunGame();
  void Connected();
  void Disconnected();
  void EnteredGame();
  void LeftRoom();
  void nickAdded(const QString& nick, bool notifyNick);
  void nickRemoved(const QString& nick);
  void nickAddedLobby(const QString& nick, bool notifyNick);
  void nickRemovedLobby(const QString& nick);
  void FromNet(const QByteArray & buf);
  void adminAccess(bool);
  void roomMaster(bool);

  void netSchemeConfig(QStringList &);
  void paramChanged(const QString & param, const QStringList & value);
  void configAsked();

  void AddNetTeam(const HWTeam&);
  void hhnumChanged(const HWTeam&);
  void teamColorChanged(const HWTeam&);
  void chatStringLobby(const QString&);
  void chatStringFromNet(const QString&);
  void chatStringFromMe(const QString&);
  void chatStringFromMeLobby(const QString&);

  void roomsList(const QStringList&);
  void serverMessage(const QString &);
  void serverMessageNew(const QString &);
  void serverMessageOld(const QString &);
  void latestProtocolVar(int);

  void setReadyStatus(const QString & nick, bool isReady);
  void setMyReadyStatus(bool isReady);
  void showMessage(const QString &);

 public slots:
  void ToggleReady();
  void chatLineToNet(const QString& str);
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

  void JoinRoom(const QString & room);
  void CreateRoom(const QString & room);
  void askRoomsList();
  void gameFinished();
  void banPlayer(const QString &);
  void kickPlayer(const QString &);
  void infoPlayer(const QString &);
  void followPlayer(const QString &);
  void startGame();
  void toggleRestrictJoins();
  void toggleRestrictTeamAdds();
  void partRoom();
  void clearAccountsCache();

 private slots:
  void ClientRead();
  void OnConnect();
  void OnDisconnect();
  void displayError(QAbstractSocket::SocketError socketError); 
};

#endif // _NEW_NETCLIENT_INCLUDED
