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

#include <QMessageBox>
#include <QDebug>

#include "newnetclient.h"
#include "proto.h"
#include "gameuiconfig.h"
#include "game.h"
#include "gamecfgwidget.h"

char delimeter='\t';

HWNewNet::HWNewNet(GameUIConfig * config, GameCFGWidget* pGameCFGWidget, TeamSelWidget* pTeamSelWidget) :
  config(config),
  m_pGameCFGWidget(pGameCFGWidget),
  m_pTeamSelWidget(pTeamSelWidget),
  isChief(false)
{
  connect(&NetSocket, SIGNAL(readyRead()), this, SLOT(ClientRead()));
  connect(&NetSocket, SIGNAL(connected()), this, SLOT(OnConnect()));
  connect(&NetSocket, SIGNAL(disconnected()), this, SLOT(OnDisconnect()));
  connect(&NetSocket, SIGNAL(error(QAbstractSocket::SocketError)), this,
	  SLOT(displayError(QAbstractSocket::SocketError)));
}

void HWNewNet::Connect(const QString & hostName, quint16 port, const QString & nick)
{
  qDebug() << hostName << ":" << port;
  NetSocket.connectToHost(hostName, port);
  mynick = nick;
}

void HWNewNet::Disconnect()
{
  NetSocket.disconnect();
}

void HWNewNet::JoinGame(const QString & game)
{
  RawSendNet(QString("JOIN %1").arg(game));
}

void HWNewNet::AddTeam(const HWTeam & team)
{
  RawSendNet(QString("ADDTEAM:") + delimeter +
	     team.TeamName + delimeter + team.HHName[0] + delimeter + team.HHName[1] + delimeter +
	     team.HHName[2] + delimeter + team.HHName[3] + delimeter + team.HHName[4] + delimeter +
	     team.HHName[5] + delimeter + team.HHName[6] + delimeter + team.HHName[7]);
}

void HWNewNet::StartGame()
{
  RawSendNet(QString("START:"));
}

void HWNewNet::SendConfigToEngine()
{

}

void HWNewNet::SendNet(const QByteArray & buf)
{
  QString msg = QString(buf.toBase64());
  qDebug() << "to net:" << buf << ":" << msg;

  if(msg == "AUM=") {
    SendConfigToEngine();
    return ;
  }
  //NetBuffer += buf;
  RawSendNet(QString("GAMEMSG:%1%2").arg(delimeter).arg(msg));
}

void HWNewNet::RawSendNet(const QString & str)
{
  RawSendNet(str.toUtf8());
}

void HWNewNet::RawSendNet(const QByteArray & buf)
{
  NetSocket.write(buf);
  NetSocket.write("\n", 1);
}

void HWNewNet::ClientRead()
{
  while (NetSocket.canReadLine()) {
    ParseLine(NetSocket.readLine().trimmed());
  }
}

void HWNewNet::OnConnect()
{
  RawSendNet(QString("USER") + delimeter + "hwgame 1 2 Hedgewars game");
  RawSendNet(QString("NICK%1%2").arg(delimeter).arg(mynick));
}

void HWNewNet::OnDisconnect()
{
  //emit ChangeInTeams(QStringList());
  emit Disconnected();
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

void HWNewNet::ParseLine(const QByteArray & line)
{
  QString msg = QString::fromUtf8 (line.data(), line.size());

  qDebug() << "line " << msg << " received";

  QStringList lst = msg.split(delimeter);
  if (lst[0] == "ERRONEUSNICKNAME") {
    QMessageBox::information(0, 0, "Your net nickname is in use or cannot be used");
    return;
  }

  if (lst[0] == "CONNECTED") {
    emit Connected();
    emit EnteredGame();
    return;
  }

  if (lst[0] == "ADDTEAM:") {
    lst.pop_front();
    emit AddNetTeam(lst);
    return;
  }

  if (lst[0] == "CONFIGASKED") {
    isChief=true;
    ConfigAsked();
    return;
  }

  if (lst[0] == "RUNGAME") {
    HWGame* game = new HWGame(config, m_pGameCFGWidget, m_pTeamSelWidget); // FIXME: memory leak here (stackify it?)
    connect(game, SIGNAL(SendNet(const QByteArray &)), this, SLOT(SendNet(const QByteArray &)));
    connect(this, SIGNAL(FromNet(const QByteArray &)), game, SLOT(FromNet(const QByteArray &)));
    connect(this, SIGNAL(LocalCFG(const QString &)), game, SLOT(LocalCFG(const QString &)));
    game->StartNet();
  }

  if (lst[0] == "CONFIGURED") {
    lst.pop_front();
    if(lst.size()<5) return;
    qDebug() << lst;
    emit seedChanged(lst[0]);
    emit mapChanged(lst[1]);
    emit themeChanged(lst[2]);
    emit initHealthChanged(lst[3].toUInt());
    emit turnTimeChanged(lst[4].toUInt());
    //emit fortsModeChanged(lst[5].toInt() != 0); // FIXME: add a getFortsMode in ConfigAsked
    return;
  }

  if (lst[0] == "CONFIG_PARAM") {
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
  	qDebug() << "unknow config param: " << lst[1];
    return;
  }


  // should be kinda game states, which don't allow "GAMEMSG:" at configure step,
  // "CONNECTED" at round phase, etc.
  if (lst[0] == "GAMEMSG:") {
    QByteArray em = QByteArray::fromBase64(lst[1].toAscii());
    qDebug() << "to engine:" << em;
    emit FromNet(em);
    return;
  }

  qDebug() << "unknown net command: " << msg;

}


void HWNewNet::ConfigAsked()
{
  onSeedChanged(m_pGameCFGWidget->getCurrentSeed());
  onMapChanged(m_pGameCFGWidget->getCurrentMap());
  onThemeChanged(m_pGameCFGWidget->getCurrentTheme());
  onInitHealthChanged(m_pGameCFGWidget->getInitHealth());
  onTurnTimeChanged(m_pGameCFGWidget->getTurnTime());
}

void HWNewNet::RunGame()
{
  HWGame * game = new HWGame(config, 0);
  connect(game, SIGNAL(SendNet(const QByteArray &)), this, SLOT(SendNet(const QByteArray &)));
  connect(this, SIGNAL(FromNet(const QByteArray &)), game, SLOT(FromNet(const QByteArray &)));
  connect(this, SIGNAL(LocalCFG(const QString &)), game, SLOT(LocalCFG(const QString &)));
  game->StartNet();
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
