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

#include <QMessageBox>
#include <QDebug>

#include "hwconsts.h"
#include "newnetclient.h"
#include "proto.h"
#include "gameuiconfig.h"
#include "game.h"
#include "gamecfgwidget.h"
#include "teamselect.h"

char delimeter='\n';

HWNewNet::HWNewNet(GameUIConfig * config, GameCFGWidget* pGameCFGWidget, TeamSelWidget* pTeamSelWidget) :
  config(config),
  m_pGameCFGWidget(pGameCFGWidget),
  m_pTeamSelWidget(pTeamSelWidget),
  isChief(false),
  m_game_connected(false)
{
  connect(&NetSocket, SIGNAL(readyRead()), this, SLOT(ClientRead()));
  connect(&NetSocket, SIGNAL(connected()), this, SLOT(OnConnect()));
  connect(&NetSocket, SIGNAL(disconnected()), this, SLOT(OnDisconnect()));
  connect(&NetSocket, SIGNAL(error(QAbstractSocket::SocketError)), this,
	  SLOT(displayError(QAbstractSocket::SocketError)));
}

void HWNewNet::Connect(const QString & hostName, quint16 port, const QString & nick)
{
  mynick = nick;
  NetSocket.connectToHost(hostName, port);
}

void HWNewNet::Disconnect()
{
  m_game_connected=false;
  NetSocket.disconnectFromHost();
}

void HWNewNet::CreateRoom(const QString & room)
{
	RawSendNet(QString("CREATE%1%2").arg(delimeter).arg(room));
}

void HWNewNet::JoinRoom(const QString & room)
{
	RawSendNet(QString("JOIN%1%2").arg(delimeter).arg(room));
}

void HWNewNet::AddTeam(const HWTeam & team)
{
	QString cmd = QString("ADDTEAM:") + delimeter +
	     team.TeamName + delimeter +
	     team.teamColor.name() + delimeter +
	     team.Grave + delimeter +
	     team.Fort + delimeter +
	     QString::number(team.difficulty);

	for(int i = 0; i < 8; ++i)
	{
		cmd.append(delimeter);
		cmd.append(team.HHName[i]);
		cmd.append(delimeter);
		cmd.append(team.HHHat[i]);
	}
	RawSendNet(cmd);
}

void HWNewNet::RemoveTeam(const HWTeam & team)
{
  RawSendNet(QString("REMOVETEAM:") + delimeter + team.TeamName);
  m_networkToLocalteams.remove(m_networkToLocalteams.key(team.TeamName));
}

void HWNewNet::StartGame()
{
  RawSendNet(QString("START:"));
}

void HWNewNet::SendNet(const QByteArray & buf)
{
  QString msg = QString(buf.toBase64());

  RawSendNet(QString("GAMEMSG:%1%2").arg(delimeter).arg(msg));
}

void HWNewNet::RawSendNet(const QString & str)
{
  RawSendNet(str.toUtf8());
}

void HWNewNet::RawSendNet(const QByteArray & buf)
{
  qDebug() << "Client: " << buf;
  NetSocket.write(buf);
  NetSocket.write("\n\n", 2);
}

void HWNewNet::ClientRead()
{
	while (NetSocket.canReadLine()) {
		QString s = QString::fromUtf8(NetSocket.readLine().trimmed());

		if (s.size() == 0) {
			ParseCmd(cmdbuf);
			cmdbuf.clear();
		} else
			cmdbuf << s;
	}
}

void HWNewNet::OnConnect()
{
  RawSendNet(QString("NICK%1%2").arg(delimeter).arg(mynick));
  RawSendNet(QString("PROTO%1%2").arg(delimeter).arg(*cProtoVer));
  RawSendNet(QString("CREATE%1%2").arg(delimeter).arg("myroom"));
  RawSendNet(QString("JOIN%1%2").arg(delimeter).arg("myroom"));
}

void HWNewNet::OnDisconnect()
{
  //emit ChangeInTeams(QStringList());
  if(m_game_connected) emit Disconnected();
  m_game_connected=false;
}

void HWNewNet::displayError(QAbstractSocket::SocketError socketError)
{
	switch (socketError) {
		case QAbstractSocket::RemoteHostClosedError:
			break;
		case QAbstractSocket::HostNotFoundError:
			QMessageBox::information(0, tr("Error"),
					tr("The host was not found. Please check the host name and port settings."));
			break;
		case QAbstractSocket::ConnectionRefusedError:
			QMessageBox::information(0, tr("Error"),
					tr("Connection refused"));
			break;
		default:
			QMessageBox::information(0, tr("Error"),
					NetSocket.errorString());
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

	if (lst[0] == "ERROR") {
		if (lst.size() == 2)
			QMessageBox::information(0, 0, "Error: " + lst[1]);
		else
			QMessageBox::information(0, 0, "Unknown error");
		return;
	}

	if (lst[0] == "WARNING") {
		if (lst.size() == 2)
			QMessageBox::information(0, 0, "Warning: " + lst[1]);
		else
			QMessageBox::information(0, 0, "Unknown warning");
		return;
	}

  if (lst[0] == "CONNECTED") {
    m_game_connected=true;
    emit Connected();
    emit EnteredGame();
    return;
  }

  if (lst[0] == "CHAT_STRING") {
    if(lst.size() < 3)
    {
	  qWarning("Net: Empty CHAT_STRING message");
	  return;
    }
    QStringList tmp = lst;
    tmp.removeFirst();
    emit chatStringFromNet(tmp);
    return;
  }

  if (lst[0] == "ADDTEAM:") {
    if(lst.size() < 22)
    {
	  qWarning("Net: Too short ADDTEAM message");
	  return;
    }
    QStringList tmp = lst;
    tmp.removeFirst();
    emit AddNetTeam(tmp);
    return;
  }

  if (lst[0] == "REMOVETEAM:") {
    if(lst.size() < 3)
    {
      qWarning("Net: Bad REMOVETEAM message");
      return;
    }
    m_pTeamSelWidget->removeNetTeam(HWTeam(lst[1], lst[2].toUInt()));
    return;
  }

  if(lst[0]=="SLAVE") {
    m_pGameCFGWidget->setEnabled(false);
    m_pTeamSelWidget->setNonInteractive();
    return;
  }

  if(lst[0]=="JOINED") {
    if(lst.size() < 2)
    {
      qWarning("Net: Bad JOINED message");
      return;
    }
    emit nickAdded(lst[1]);
    return;
  }

  if(lst[0]=="LEFT") {
    if(lst.size() < 2)
    {
      qWarning("Net: Bad LEFT message");
      return;
    }
    emit nickRemoved(lst[1]);
    return;
  }

  if (lst[0] == "CONFIGASKED") {
    isChief=true;
    ConfigAsked();
    return;
  }

  if (lst[0] == "RUNGAME") {
    RunGame();
    return;
  }

  if (lst[0] == "CONFIGURED") {
    QStringList tmp = lst;
    tmp.removeFirst();
    if(tmp.size() < 6)
    {
      qWarning("Net: Bad CONFIGURED message");
      return;
    }
    emit seedChanged(tmp[0]);
    emit mapChanged(tmp[1]);
    emit themeChanged(tmp[2]);
    emit initHealthChanged(tmp[3].toUInt());
    emit turnTimeChanged(tmp[4].toUInt());
    emit fortsModeChanged(tmp[5].toInt() != 0);
    return;
  }

  if(lst[0]=="TEAM_ACCEPTED") {
    if(lst.size() < 3)
    {
      qWarning("Net: Bad TEAM_ACCEPTED message");
      return;
    }
    m_networkToLocalteams.insert(lst[2].toUInt(), lst[1]);
    m_pTeamSelWidget->changeTeamStatus(lst[1]);
    return;
  }

  if (lst[0] == "CONFIG_PARAM") {
    if(lst.size() < 3)
    {
      qWarning("Net: Bad CONFIG_PARAM message");
      return;
    }
  	if (lst[1] == "SEED") {
	  emit seedChanged(lst[2]);
	  return;
  	}
  	if (lst[1] == "MAP") {
	  emit mapChanged(lst[2]);
	  return;
  	}
  	if (lst[1] == "THEME") {
	  emit themeChanged(lst[2]);
	  return;
  	}
  	if (lst[1] == "HEALTH") {
	  emit initHealthChanged(lst[2].toUInt());
	  return;
  	}
  	if (lst[1] == "TURNTIME") {
	  emit turnTimeChanged(lst[2].toUInt());
	  return;
  	}
  	if (lst[1] == "FORTSMODE") {
	  emit fortsModeChanged(lst[2].toInt() != 0);
	  return;
  	}
	if (lst[1] == "AMMO") {
	  if(lst.size() < 4) return;
	  emit ammoChanged(lst[3], lst[2]);
	  return;
	}
	QStringList hhTmpList=lst[1].split('+');
  	if (hhTmpList[0] == "TEAM_COLOR") {
	  HWTeam tmptm(hhTmpList[1], hhTmpList[2].toUInt());
	  if(m_networkToLocalteams.find(hhTmpList[2].toUInt())!=m_networkToLocalteams.end()) {
	    tmptm=HWTeam(hhTmpList[1]); // local team should be changed
	  }
	  tmptm.teamColor=QColor(lst[2]);
	  emit teamColorChanged(tmptm);
	  return;
  	}
  	if (hhTmpList[0] == "HHNUM") {
	  HWTeam tmptm(hhTmpList[1], hhTmpList[2].toUInt());
	  if(m_networkToLocalteams.find(hhTmpList[2].toUInt())!=m_networkToLocalteams.end()) {
	    tmptm=HWTeam(hhTmpList[1]); // local team should be changed
	  }
	  tmptm.numHedgehogs=lst[2].toUInt();
	  emit hhnumChanged(tmptm);
	  return;
  	}
    qWarning() << "Net: Unknown 'CONFIG_PARAM' message:" << lst;
    return;
  }


  // should be kinda game states, which don't allow "GAMEMSG:" at configure step,
  // "CONNECTED" at round phase, etc.
  if (lst[0] == "GAMEMSG:") {
    if(lst.size() < 2)
    {
      qWarning("Net: Bad LEFT message");
      return;
    }
    QByteArray em = QByteArray::fromBase64(lst[1].toAscii());
    emit FromNet(em);
    return;
  }

  qWarning() << "Net: Unknown message:" << lst;
}


void HWNewNet::ConfigAsked()
{
  QString map = m_pGameCFGWidget->getCurrentMap();
  if (map.size())
    onMapChanged(map);

  onSeedChanged(m_pGameCFGWidget->getCurrentSeed());
  onThemeChanged(m_pGameCFGWidget->getCurrentTheme());
  onInitHealthChanged(m_pGameCFGWidget->getInitHealth());
  onTurnTimeChanged(m_pGameCFGWidget->getTurnTime());
  onFortsModeChanged(m_pGameCFGWidget->getGameFlags() & 0x1);
  // always initialize with default ammo (also avoiding complicated cross-class dependencies)
  onWeaponsNameChanged("Default", cDefaultAmmoStore->mid(10)); 
}

void HWNewNet::RunGame()
{
  emit AskForRunGame();
}

void HWNewNet::onHedgehogsNumChanged(const HWTeam& team)
{
  RawSendNet(QString("HHNUM%1%2%1%3%1%4").arg(delimeter).arg(team.TeamName)\
	     .arg(team.getNetID() ? team.getNetID() : m_networkToLocalteams.key(team.TeamName))\
	     .arg(team.numHedgehogs));
}

void HWNewNet::onTeamColorChanged(const HWTeam& team)
{
  RawSendNet(QString("CONFIG_PARAM%1TEAM_COLOR+%2+%3%1%4").arg(delimeter).arg(team.TeamName)\
	     .arg(team.getNetID() ? team.getNetID() : m_networkToLocalteams.key(team.TeamName))\
	     .arg(team.teamColor.name()));
}

void HWNewNet::onSeedChanged(const QString & seed)
{
  RawSendNet(QString("CONFIG_PARAM%1SEED%1%2").arg(delimeter).arg(seed));
}

void HWNewNet::onMapChanged(const QString & map)
{
  RawSendNet(QString("CONFIG_PARAM%1MAP%1%2").arg(delimeter).arg(map));
}

void HWNewNet::onThemeChanged(const QString & theme)
{
  RawSendNet(QString("CONFIG_PARAM%1THEME%1%2").arg(delimeter).arg(theme));
}

void HWNewNet::onInitHealthChanged(quint32 health)
{
  RawSendNet(QString("CONFIG_PARAM%1HEALTH%1%2").arg(delimeter).arg(health));
}

void HWNewNet::onTurnTimeChanged(quint32 time)
{
  RawSendNet(QString("CONFIG_PARAM%1TURNTIME%1%2").arg(delimeter).arg(time));
}

void HWNewNet::onFortsModeChanged(bool value)
{
  RawSendNet(QString("CONFIG_PARAM%1FORTSMODE%1%2").arg(delimeter).arg(value));
}

void HWNewNet::onWeaponsNameChanged(const QString& name, const QString& ammo)
{
  RawSendNet(QString("CONFIG_PARAM%1AMMO%1%2%1%3").arg(delimeter).arg(ammo).arg(name));
}

void HWNewNet::chatLineToNet(const QString& str)
{
  if(str!="") {
    RawSendNet(QString("CHAT_STRING")+delimeter+mynick+delimeter+str);
    emit(chatStringFromNet(QStringList(mynick) << str));
  }
}
