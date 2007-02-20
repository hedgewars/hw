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

#include "netconnectedclient.h"
#include "netserver.h"

#include <QTcpServer>
#include <QTcpSocket>
#include <QStringList>

#include <QDebug>

extern char delimeter;

HWConnectedClient::HWConnectedClient(HWNetServer* hwserver, QTcpSocket* client) :
  readyToStart(false),
  m_hwserver(hwserver),
  m_client(client)
{
  connect(client, SIGNAL(disconnected()), this, SLOT(ClientDisconnect()));
  connect(client, SIGNAL(readyRead()), this, SLOT(ClientRead()));
}

HWConnectedClient::~HWConnectedClient()
{
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
    if(m_hwserver->isChiefClient(this)) RawSendNet(QString("CONFIGASKED"));
    else {
      RawSendNet(QString("SLAVE"));
      // send teams
      QList<QStringList> team_conf=m_hwserver->getTeamsConfig();
      for(QList<QStringList>::iterator tmit=team_conf.begin(); tmit!=team_conf.end(); ++tmit) {
	RawSendNet(QString("ADDTEAM:")+delimeter+tmit->join(QString(delimeter)));
      }
      // send config
      QMap<QString, QStringList> conf=m_hwserver->getGameCfg();
      qDebug() << "Config:";
      for(QMap<QString, QStringList>::iterator it=conf.begin(); it!=conf.end(); ++it) {
	RawSendNet(QString("CONFIG_PARAM")+delimeter+it.key()+delimeter+it.value().join(QString(delimeter)));
	qDebug() << QString("CONFIG_PARAM")+delimeter+it.key()+delimeter+it.value().join(QString(delimeter));
      }
    }
    m_hwserver->sendOthers(this, QString("JOINED")+delimeter+client_nick);
    return;
  }
  if(client_nick=="") return;

  if (lst[0]=="START:") {
    readyToStart=true;
    if(m_hwserver->shouldStart(this)) {
      // start
      m_hwserver->sendAll("RUNGAME");
      m_hwserver->resetStart();
    }
    return;
  }

  if(lst[0]=="HHNUM") {
    if(!m_hwserver->isChiefClient(this) || lst.size()<4) return; // error or permission denied :)
    const QString confstr=lst[0]+"+"+lst[1]+"+"+lst[2];
    QMap<QString, QStringList>::iterator it=m_hwserver->m_gameCfg.find(confstr);
    int oldTeamHHNum = it==m_hwserver->m_gameCfg.end() ? 0 : it.value()[0].toUInt();
    int newTeamHHNum = lst[3].toUInt();
    m_hwserver->hhnum+=newTeamHHNum-oldTeamHHNum;
    // create CONFIG_PARAM to save HHNUM at server from lst
    lst=QStringList("CONFIG_PARAM") << confstr << lst[3];
  }

  if(lst[0]=="CONFIG_PARAM") {
    if(!m_hwserver->isChiefClient(this) || lst.size()<3) return; // error or permission denied :)
    else m_hwserver->m_gameCfg[lst[1]]=lst.mid(2);
    qDebug() << msg;
  }

  if(lst[0]=="ADDTEAM:") {
    if(lst.size()<14) return;
    lst.pop_front();
    
    // add team ID
    static unsigned int netTeamID=0;
    lst.insert(1, QString::number(++netTeamID));

    // hedgehogs num count
    int maxAdd=18-m_hwserver->hhnum;
    if (maxAdd<=0) return; // reject command
    int toAdd=maxAdd<4 ? maxAdd : 4;
    m_hwserver->hhnum+=toAdd;
    qDebug() << "added " << toAdd << " hedgehogs";
    // hedgehogs num config
    QString hhnumCfg=QString("CONFIG_PARAM%1HHNUM+%2+%3%1%4").arg(delimeter).arg(lst[0])\
      .arg(netTeamID)\
      .arg(toAdd);
    
    // creating color config for new team
    QString colorCfg=QString("CONFIG_PARAM%1TEAM_COLOR+%2+%3%1%4").arg(delimeter).arg(lst[0])\
      .arg(netTeamID)\
      .arg(lst.takeAt(2));
    qDebug() << "color config:" << colorCfg;

    m_hwserver->m_gameCfg[colorCfg.split(delimeter)[1]]=colorCfg.split(delimeter).mid(2);
    m_hwserver->m_gameCfg[hhnumCfg.split(delimeter)[1]]=hhnumCfg.split(delimeter).mid(2);
    m_teamsCfg.push_back(lst);

    m_hwserver->sendOthers(this, QString("ADDTEAM:")+delimeter+lst.join(QString(delimeter)));
    RawSendNet(QString("TEAM_ACCEPTED%1%2%1%3").arg(delimeter).arg(lst[0]).arg(lst[1]));
    m_hwserver->sendAll(colorCfg);
    m_hwserver->sendAll(hhnumCfg);
    return;
  }

  if(lst[0]=="REMOVETEAM:") {
    if(lst.size()<2) return;
    
    for(QMap<QString, QStringList>::iterator it=m_hwserver->m_gameCfg.begin(); it!=m_hwserver->m_gameCfg.end(); ++it) {
      QStringList hhTmpList=it.key().split('+');
      if(hhTmpList[0] == "HHNUM") {
	if(hhTmpList[1]==lst[1]) {
	  qDebug() << "removed " << it.value()[0].toUInt() << " hedgehogs";
	  m_hwserver->hhnum-=it.value()[0].toUInt();
	  break;
	}
      }
    }

    unsigned int netID=removeTeam(lst[1]);
    m_hwserver->sendOthers(this, QString("REMOVETEAM:")+delimeter+lst[1]+delimeter+QString::number(netID));
    qDebug() << QString("REMOVETEAM:")+delimeter+lst[1]+delimeter+QString::number(netID);
    return;
  }

  m_hwserver->sendOthers(this, msg);
}

unsigned int HWConnectedClient::removeTeam(const QString& tname)
{
  unsigned int netID=0;
  for(QList<QStringList>::iterator it=m_teamsCfg.begin(); it!=m_teamsCfg.end(); ++it) {
    if((*it)[0]==tname) {
      netID=(*it)[1].toUInt();
      m_teamsCfg.erase(it);
      break;
    }
  }
  return netID;
}

QList<QStringList> HWConnectedClient::getTeamNames() const
{
  return m_teamsCfg;
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

bool HWConnectedClient::isReady() const
{
  return readyToStart;
}

QString HWConnectedClient::getHedgehogsDescription() const
{
  return QString();//pclent_team->TeamGameConfig(65535, 4, 100, true).join((QString)delimeter);
}
