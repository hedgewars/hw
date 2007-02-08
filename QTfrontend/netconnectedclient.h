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

#ifndef _HET_CONNECTEDCLIENT_INCLUDED
#define _HET_CONNECTEDCLIENT_INCLUDED

#include <QObject>
#include <QList>
#include <QMap>

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
  QList<QStringList> m_teamsCfg; // TeamName - hhs
  class ShouldDisconnectException {};

  QString client_nick;
  void ParseLine(const QByteArray & line);
  unsigned int removeTeam(const QString& tname); // returns netID

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

#endif // _HET_CONNECTEDCLIENT_INCLUDED
