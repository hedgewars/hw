/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Igor Ulyanov <iulyanov@gmail.com>
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

#ifndef _NETSERVER_INCLUDED
#define _NETSERVER_INCLUDED

#include <QObject>
#include <QList>
#include <QMap>

#include "team.h"

class HWNetServer;
class QTcpSocket;
class QTcpServer;

class HWConnectedClient : public QObject
{
  Q_OBJECT

 friend class HWNetServer;

 private:
  HWConnectedClient(HWNetServer* hwserver, QTcpSocket* client);
  ~HWConnectedClient();
  QString getClientNick() const;

  QList<QStringList> getTeamNames() const;
  class NoTeamNameException{};
  bool isReady() const;

  QString getHedgehogsDescription() const;

  bool readyToStart;
  QMap<QString, QString> m_gameCfg; // config_param - value
  QList<QStringList> m_teamsCfg; // TeamName - hhs
  class ShouldDisconnectException {};

  QString client_nick;
  void ParseLine(const QByteArray & line);
  void removeTeam(const QString& tname);

  HWNetServer* m_hwserver;
  QTcpSocket* m_client;

  void RawSendNet(const QString & buf);
  void RawSendNet(const QByteArray & buf);

  //QByteArray readbuffer;

 signals:
  void HWClientDisconnected(HWConnectedClient* client);

 private slots:
  void ClientRead();
  void ClientDisconnect();
};

class HWNetServer : public QObject
{
  Q_OBJECT

 public:
  void StartServer();
  void StopServer();
  bool isChiefClient(HWConnectedClient* cl) const;
  QMap<QString, QString> getGameCfg() const;
  void sendAll(QString gameCfg);
  void sendOthers(HWConnectedClient* this_cl, QString gameCfg);
  bool haveNick(const QString& nick) const;
  QString getRunningHostName() const;
  quint16 getRunningPort() const;
  QList<QStringList> getTeamsConfig() const;
  void teamChanged();
  bool shouldStart(HWConnectedClient* client);
  QString prepareConfig(QStringList lst);

 private:
  HWConnectedClient* getChiefClient() const;
  static const quint16 ds_port;
  QTcpServer* IPCServer;
  QList<HWConnectedClient*> connclients;

 private slots:
  void NewConnection();
  void ClientDisconnect(HWConnectedClient* client);
};

#endif // _NETSERVER_INCLUDED
