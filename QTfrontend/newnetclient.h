/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Ulyanov Igor <iulyanov@gmail.com>
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

#include "team.h"

class GameUIConfig;
class GameCFGWidget;

extern char delimeter;

class HWNewNet : public QObject
{
  Q_OBJECT

 public:
  HWNewNet(GameUIConfig * config, GameCFGWidget* pGameCFGWidget);
  void Connect(const QString & hostName, quint16 port, const QString & nick);
  void Disconnect();
  void JoinGame(const QString & game);
  void StartGame();

 private:
  GameUIConfig* config;
  GameCFGWidget* m_pGameCFGWidget;

  bool isChief;
  QString mynick;
  QTcpSocket NetSocket;
  QString seed;

  void ConfigAsked();
  void RunGame();

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

  void RawSendNet(const QString & buf);
  void RawSendNet(const QByteArray & buf);
  void ParseLine(const QByteArray & line);

 signals:
  void Connected();
  void Disconnected();
  void AddGame(const QString & chan);
  void EnteredGame();
  void FromNet(const QByteArray & buf);
  void LocalCFG(const QString & team);
  void AddNetTeam(const QString&);

  void seedChanged(const QString & seed);
  void mapChanged(const QString & map);
  void themeChanged(const QString & theme);
  void initHealthChanged(quint32 health);
  void turnTimeChanged(quint32 time);
  void fortsModeChanged(bool value);

 public slots:
  void SendNet(const QByteArray & buf);
  void AddTeam(const HWTeam & team);
  void onSeedChanged(const QString & seed);
  void onMapChanged(const QString & map);
  void onThemeChanged(const QString & theme);
  void onInitHealthChanged(quint32 health);
  void onTurnTimeChanged(quint32 time);
  void onFortsModeChanged(bool value);

 private slots:
  void ClientRead();
  void OnConnect();
  void OnDisconnect();
  //void Perform();
  void displayError(QAbstractSocket::SocketError socketError);
  //void FlushNetBuf();
};

#endif // _NEW_NETCLIENT_INCLUDED
