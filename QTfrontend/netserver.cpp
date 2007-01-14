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

#include "netserver.h"

#include <QTcpServer>
#include <QTcpSocket>
#include <QMessageBox>

#include <algorithm>

#include <QDebug>

const quint16 HWNetServer::ds_port=46631;

extern char delimeter;

void HWNetServer::StartServer()
{
  IPCServer = new QTcpServer(this);
  if (!IPCServer->listen(QHostAddress::LocalHost, ds_port)) {
    QMessageBox::critical(0, tr("Error"),
			  tr("Unable to start the server: %1.")
			  .arg(IPCServer->errorString()));
  }

  connect(IPCServer, SIGNAL(newConnection()), this, SLOT(NewConnection()));
}

void HWNetServer::StopServer()
{
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
  connclients.erase(it);
  teamChanged();
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

QMap<QString, QString> HWNetServer::getGameCfg() const
{
  for(QList<HWConnectedClient*>::const_iterator it=connclients.begin(); it!=connclients.end(); ++it) {
    if(isChiefClient(*it)) {
      return (*it)->m_gameCfg;
    }
  }
  // error happened if we are here
  return QMap<QString, QString>();
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

QStringList HWNetServer::getTeams() const
{
  QStringList lst;
  for(QList<HWConnectedClient*>::const_iterator it=connclients.begin(); it!=connclients.end(); ++it) {
    try {
      lst.push_back((*it)->getTeamName());
    } catch(HWConnectedClient::NoTeamNameException& e) {
    }
  }
  return lst;
}

void HWNetServer::teamChanged()
{
  for(QList<HWConnectedClient*>::const_iterator it=connclients.begin(); it!=connclients.end(); ++it) {
    (*it)->teamChangedNotify();
  }
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

QString HWNetServer::prepareConfig(QStringList lst)
{
  QString msg=lst.join((QString)delimeter)+delimeter;
  for(QList<HWConnectedClient*>::iterator it=connclients.begin(); it!=connclients.end(); ++it) {
    if(!(*it)->isReady()) continue;
    msg+=(*it)->getHedgehogsDescription()+delimeter;
  }
  qDebug() << msg;
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

HWConnectedClient::HWConnectedClient(HWNetServer* hwserver, QTcpSocket* client) :
  readyToStart(false),
  m_hwserver(hwserver),
  m_client(client),
  pclent_team(0)
{
  connect(client, SIGNAL(disconnected()), this, SLOT(ClientDisconnect()));
  connect(client, SIGNAL(readyRead()), this, SLOT(ClientRead()));
}

HWConnectedClient::~HWConnectedClient()
{
  if(pclent_team) delete pclent_team;
}

void HWConnectedClient::ClientDisconnect()
{
  emit(HWClientDisconnected(this));
}

void HWConnectedClient::ClientRead()
{
  try {
    while (m_client->canReadLine()) {
      ParseLine(m_client->readLine().trimmed());
    }
  } catch(ShouldDisconnectException& e) {
    m_client->close();
  }
}

void HWConnectedClient::ParseLine(const QByteArray & line)
{
  QString msg = QString::fromUtf8 (line.data(), line.size());

  qDebug() << "line " << msg << " received";

  QStringList lst = msg.split(delimeter);
  if(!lst.size()) return;
  if (lst[0] == "NICK") {
    if(lst.size()<2) return;
    if(m_hwserver->haveNick(lst[1])) {
      RawSendNet(QString("ERRONEUSNICKNAME"));
      throw ShouldDisconnectException();
    }

    client_nick=lst[1];
    qDebug() << "send connected";
    RawSendNet(QString("CONNECTED"));
    m_hwserver->teamChanged();
    if(m_hwserver->isChiefClient(this)) RawSendNet(QString("CONFIGASKED"));
    else {
      QMap<QString, QString> conf=m_hwserver->getGameCfg();
      for(QMap<QString, QString>::iterator it=conf.begin(); it!=conf.end(); ++it) {
	RawSendNet(QString("CONFIG_PARAM")+delimeter+it.key()+delimeter+it.value());
      }
    }
    return;
  }
  if(client_nick=="") return;

  if (lst[0]=="START:") {
    readyToStart=true;
    if(m_hwserver->shouldStart(this)) {
      // start
    }
    return;
  }

  if(lst[0]=="CONFIG_PARAM") {
    if(!m_hwserver->isChiefClient(this) || lst.size()<3) return; // error or permission denied :)
    else m_gameCfg[lst[1]]=lst[2];
  }

  if(lst[0]=="ADDTEAM:") {
    if(lst.size()<10) return;
    lst.pop_front();
    if(pclent_team) delete pclent_team;
    pclent_team=new HWTeam(lst);
    m_hwserver->teamChanged();
    return;
  }

  m_hwserver->sendOthers(this, msg);
}

void HWConnectedClient::teamChangedNotify()
{
  QString teams;
  QStringList lst=m_hwserver->getTeams();
  for(int i=0; i<lst.size(); i++) {
    teams+=delimeter+lst[i];
  }
  RawSendNet(QString("TEAMCHANGED")+teams);
}

void HWConnectedClient::RawSendNet(const QString & str)
{
  RawSendNet(str.toUtf8());
}

void HWConnectedClient::RawSendNet(const QByteArray & buf)
{
  m_client->write(buf);
  m_client->write("\n", 1);
}

QString HWConnectedClient::getClientNick() const
{
  return client_nick;
}

QString HWConnectedClient::getTeamName() const
{
  if(!pclent_team) throw NoTeamNameException();
  return pclent_team->TeamName;
}

bool HWConnectedClient::isReady() const
{
  return readyToStart;
}

QString HWConnectedClient::getHedgehogsDescription() const
{
  return pclent_team->TeamGameConfig(65535, 4, 100, true).join((QString)delimeter);
}
