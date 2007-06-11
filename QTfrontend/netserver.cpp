/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006-2007 Ulyanov Igor <iulyanov@gmail.com>
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

#include "netserver.h"
#include "netconnectedclient.h"

#include <QTcpServer>
#include <QTcpSocket>
#include <QMessageBox>

const quint16 HWNetServer::ds_port=46631;

extern char delimeter;

void HWNetServer::StartServer()
{
  hhnum=0;
  IPCServer = new QTcpServer(this);
  if (!IPCServer->listen(QHostAddress::Any, ds_port)) {
    QMessageBox::critical(0, tr("Error"),
			  tr("Unable to start the server: %1.")
			  .arg(IPCServer->errorString()));
  }

  connect(IPCServer, SIGNAL(newConnection()), this, SLOT(NewConnection()));
}

void HWNetServer::StopServer()
{
  QList<HWConnectedClient*>::iterator it;
  for(it=connclients.begin(); it!=connclients.end(); ++it) {
    ClientDisconnect(*it);
  }
  IPCServer->close();
}

void HWNetServer::NewConnection()
{
  QTcpSocket* client = IPCServer->nextPendingConnection();
  if(!client) return;
  connclients.push_back(new HWConnectedClient(this, client));
  connect(connclients.back(), SIGNAL(HWClientDisconnected(HWConnectedClient*)),
	  this, SLOT(ClientDisconnect(HWConnectedClient*)));
}

void HWNetServer::ClientDisconnect(HWConnectedClient* client)
{
  QList<HWConnectedClient*>::iterator it=std::find(connclients.begin(), connclients.end(), client);
  if(it==connclients.end()) return;
  for(QList<QStringList>::iterator tmIt=(*it)->m_teamsCfg.begin(); tmIt!=(*it)->m_teamsCfg.end(); ++tmIt) {
    sendOthers(*it, QString("REMOVETEAM:")+delimeter+*(tmIt->begin()) + delimeter + *(tmIt->begin()+1));
  }
  sendOthers(*it, QString("LEFT")+delimeter+client->client_nick);
  connclients.erase(it);
  //teamChanged();
}

QString HWNetServer::getRunningHostName() const
{
  return IPCServer->serverAddress().toString();
}

quint16 HWNetServer::getRunningPort() const
{
  return ds_port;
}

HWConnectedClient* HWNetServer::getChiefClient() const
{
  for(QList<HWConnectedClient*>::const_iterator it=connclients.begin(); it!=connclients.end(); ++it) {
    // watch for first fully connected client (with confirmed nick)
    if((*it)->getClientNick()!="") return *it;
  }
  return 0;
}

bool HWNetServer::isChiefClient(HWConnectedClient* cl) const
{
  return getChiefClient()==cl;
}

QMap<QString, QStringList> HWNetServer::getGameCfg() const
{
  return m_gameCfg;
}

bool HWNetServer::haveNick(const QString& nick) const
{
  for(QList<HWConnectedClient*>::const_iterator it=connclients.begin(); it!=connclients.end(); ++it) {
    if((*it)->getClientNick()==nick) {
      return true;
    }
  }
  return false;
}

void HWNetServer::sendNicks(HWConnectedClient* cl) const
{
  for(QList<HWConnectedClient*>::const_iterator it=connclients.begin(); it!=connclients.end(); ++it) {
      cl->RawSendNet(QString("JOINED")+delimeter+(*it)->client_nick);
  }
}

QList<QStringList> HWNetServer::getTeamsConfig() const
{
  QList<QStringList> lst;
  for(QList<HWConnectedClient*>::const_iterator it=connclients.begin(); it!=connclients.end(); ++it) {
    try {
      lst+=(*it)->getTeamNames();
    } catch(HWConnectedClient::NoTeamNameException& e) {
    }
  }
  return lst;
}

bool HWNetServer::shouldStart(HWConnectedClient* client)
{
  QList<HWConnectedClient*>::iterator it=std::find(connclients.begin(), connclients.end(), client);
  if(it==connclients.end() || *it!=client) return false;
  for(it=connclients.begin(); it!=connclients.end(); ++it) {
    if(!(*it)->isReady()) return false;
  }
  return true;
}

void HWNetServer::resetStart()
{
  QList<HWConnectedClient*>::iterator it;
  for(it=connclients.begin(); it!=connclients.end(); ++it) {
    (*it)->readyToStart=false;
  }
}

QString HWNetServer::prepareConfig(QStringList lst)
{
  QString msg=lst.join((QString)delimeter)+delimeter;
  for(QList<HWConnectedClient*>::iterator it=connclients.begin(); it!=connclients.end(); ++it) {
    if(!(*it)->isReady()) continue;
    msg+=(*it)->getHedgehogsDescription()+delimeter;
  }
  return msg;
}

void HWNetServer::sendAll(QString gameCfg)
{
  for(QList<HWConnectedClient*>::iterator it=connclients.begin(); it!=connclients.end(); ++it) {
    (*it)->RawSendNet(gameCfg);
  }
}

void HWNetServer::sendOthers(HWConnectedClient* this_cl, QString gameCfg)
{
  for(QList<HWConnectedClient*>::iterator it=connclients.begin(); it!=connclients.end(); ++it) {
    if(*it==this_cl) continue;
    (*it)->RawSendNet(gameCfg);
  }
}
