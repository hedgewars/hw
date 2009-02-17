/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Ulyanov Igor <iulyanov@gmail.com>
 * Copyright (c) 2009 Andrey Korotaev <unC0Rr@gmail.com>
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
  m_game_connected(false),
  loginStep(0),
  netClientState(0)
{
	connect(&NetSocket, SIGNAL(readyRead()), this, SLOT(ClientRead()));
	connect(&NetSocket, SIGNAL(connected()), this, SLOT(OnConnect()));
	connect(&NetSocket, SIGNAL(disconnected()), this, SLOT(OnDisconnect()));
	connect(&NetSocket, SIGNAL(error(QAbstractSocket::SocketError)), this,
			SLOT(displayError(QAbstractSocket::SocketError)));
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
	mynick = nick;
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
	
	RawSendNet(QString("CREATE%1%2").arg(delimeter).arg(room));
	m_pGameCFGWidget->setEnabled(true);
	m_pTeamSelWidget->setInteractivity(true);
	isChief = true;
}

void HWNewNet::JoinRoom(const QString & room)
{
	if(netClientState != 2)
	{
		qWarning("Illegal try to join room!");
		return;
	}
	
	loginStep++;

	RawSendNet(QString("JOIN%1%2").arg(delimeter).arg(room));
	m_pGameCFGWidget->setEnabled(false);
	m_pTeamSelWidget->setInteractivity(false);
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
	RawSendNet(QString("REMOVE_TEAM") + delimeter + team.TeamName);
}

void HWNewNet::ToggleReady()
{
  RawSendNet(QString("TOGGLE_READY"));
}

void HWNewNet::SendNet(const QByteArray & buf)
{
  QString msg = QString(buf.toBase64());

  RawSendNet(QString("GAMEMSG%1%2").arg(delimeter).arg(msg));
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
}

void HWNewNet::OnDisconnect()
{
  //emit ChangeInTeams(QStringList());
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

	if ((lst[0] == "NICK") || (lst[0] == "PROTO"))
	{
		loginStep++;
		if (loginStep == 2)
		{
			netClientState = 2;
			RawSendNet(QString("LIST"));
		}
		return ;
	}

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
		RawSendNet(QString("NICK%1%2").arg(delimeter).arg(mynick));
		RawSendNet(QString("PROTO%1%2").arg(delimeter).arg(*cProtoVer));
		netClientState = 1;
		m_game_connected = true;
		emit Connected();
		return;
	}

	if (lst[0] == "PING") {
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

	if (lst[0] == "CHAT_STRING") {
		if(lst.size() < 3)
		{
			qWarning("Net: Empty CHAT_STRING message");
			return;
		}
		if (netClientState == 2)
			emit chatStringLobby(formatChatMsg(lst[1], lst[2]));
		else
			emit chatStringFromNet(formatChatMsg(lst[1], lst[2]));
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
			emit chatStringLobby(tmp.join("\n"));
		else
			emit chatStringFromNet(tmp.join("\n"));
		return;
	}

	if (lst[0] == "READY") {
		if(lst.size() != 2)
		{
			qWarning("Net: Malformed READY message");
			return;
		}
		emit setReadyStatus(lst[1], true);
		if (lst[1] == mynick)
			emit setMyReadyStatus(true);
		return;
	}
	
	if (lst[0] == "NOT_READY") {
		if(lst.size() != 2)
		{
			qWarning("Net: Malformed NOT_READY message");
			return;
		}
		emit setReadyStatus(lst[1], false);
		if (lst[1] == mynick)
			emit setMyReadyStatus(false);
		return;
	}

	if (lst[0] == "ADD_TEAM") {
		if(lst.size() != 23)
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
		if (netClientState == 5) // we're in game, need to tell the engine about this
		{
			QByteArray em;
			HWProto::addStringToBuffer(em, "F" + lst[1]);
			emit FromNet(em);
		}
		return;
	}

	if(lst[0]=="ROOMABANDONED") {
		netClientState = 2;
		emit showMessage(HWNewNet::tr("Room destroyed"));
		emit LeftRoom();
		return;
	}

	if(lst[0]=="JOINED") {
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
				if (isChief)
					ConfigAsked();
			}
			emit nickAdded(lst[i]);
			emit chatStringFromNet(QString(tr("*** %1 joined")).arg(lst[i]));
		}
		return;
	}

	if(lst[0]=="LOBBY:JOINED") {
		if(lst.size() < 2)
		{
			qWarning("Net: Bad JOINED message");
			return;
		}
		
		for(int i = 1; i < lst.size(); ++i)
		{
			emit nickAddedLobby(lst[i]);
			emit chatStringLobby(QString(tr("*** %1 joined")).arg(lst[i]));
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
			emit chatStringFromNet(QString(tr("*** %1 left")).arg(lst[1]));
		else
			emit chatStringFromNet(QString(tr("*** %1 left (%2)")).arg(lst[1], lst[2]));
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
			emit chatStringLobby(QString(tr("*** %1 left")).arg(lst[1]));
		else
			emit chatStringLobby(QString(tr("*** %1 left (%2)")).arg(lst[1], lst[2]));
		return;
	}

	if (lst[0] == "RUN_GAME") {
		netClientState = 5;
		RunGame();
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

	if (lst[0] == "MAP") {
		if (lst.size() != 2)
		{
			qWarning("Net: Bad MAP message");
			return;
		}
		emit mapChanged(lst[1]);
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
		if (lst[1] == "SD_TURNS") {
			emit suddenDeathTurnsChanged(lst[2].toUInt());
			return;
		}
		if (lst[1] == "CASEFACTOR") {
			emit caseProbabilityChanged(lst[2].toUInt());
			return;
		}
		if (lst[1] == "FORTSMODE") {
			emit fortsModeChanged(lst[2].toInt() != 0);
			return;
		}
		if (lst[1] == "DIVIDETEAMS") {
			emit teamsDivideChanged(lst[2].toInt() != 0);
			return;
		}
		if (lst[1] == "SOLIDLAND") {
			emit solidChanged(lst[2].toInt() != 0);
			return;
		}
		if (lst[1] == "BORDER") {
			emit borderChanged(lst[2].toInt() != 0);
			return;
		}
		if (lst[1] == "AMMO") {
			if(lst.size() < 4) return;
			emit ammoChanged(lst[3], lst[2]);
			return;
		}
		if (lst[1] == "TEMPLATE_FILTER") {
			emit templateFilterChanged(lst[2].toUInt());
			return;
		}
		qWarning() << "Net: Unknown 'CONFIG_PARAM' message:" << lst;
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

	if (lst[0] == "GAMEMSG") {
		if(lst.size() < 2)
		{
			qWarning("Net: Bad GAMEMSG message");
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

	qWarning() << "Net: Unknown message:" << lst;
}


void HWNewNet::ConfigAsked()
{
	QString map = m_pGameCFGWidget->getCurrentMap();
	if (map.size())
		onMapChanged(map);

	onSuddenDeathTurnsChanged(m_pGameCFGWidget->getSuddenDeathTurns());
	onCaseProbabilityChanged(m_pGameCFGWidget->getCaseProbability());
	onSeedChanged(m_pGameCFGWidget->getCurrentSeed());
	onThemeChanged(m_pGameCFGWidget->getCurrentTheme());
	onInitHealthChanged(m_pGameCFGWidget->getInitHealth());
	onTurnTimeChanged(m_pGameCFGWidget->getTurnTime());
	onFortsModeChanged(m_pGameCFGWidget->getGameFlags() & 0x1);
	onTeamsDivideChanged(m_pGameCFGWidget->getGameFlags() & 0x10);
	onSolidChanged(m_pGameCFGWidget->getGameFlags() & 0x04);
	onBorderChanged(m_pGameCFGWidget->getGameFlags() & 0x08);
	// always initialize with default ammo (also avoiding complicated cross-class dependencies)
	QString name = m_pGameCFGWidget->WeaponsName->currentText();
	QString ammo = m_pGameCFGWidget->WeaponsName->itemData(
			m_pGameCFGWidget->WeaponsName->currentIndex()
			).toString();
	onWeaponsNameChanged(name, ammo);
	onTemplateFilterChanged(m_pGameCFGWidget->pMapContainer->getTemplateFilter());
}

void HWNewNet::RunGame()
{
	emit AskForRunGame();
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

void HWNewNet::onSeedChanged(const QString & seed)
{
	if (isChief) RawSendNet(QString("CONFIG_PARAM%1SEED%1%2").arg(delimeter).arg(seed));
}

void HWNewNet::onMapChanged(const QString & map)
{
	if (isChief) RawSendNet(QString("MAP%1%2").arg(delimeter).arg(map));
}

void HWNewNet::onThemeChanged(const QString & theme)
{
	if (isChief) RawSendNet(QString("CONFIG_PARAM%1THEME%1%2").arg(delimeter).arg(theme));
}

void HWNewNet::onInitHealthChanged(int health)
{
	if (isChief) RawSendNet(QString("CONFIG_PARAM%1HEALTH%1%2").arg(delimeter).arg(health));
}

void HWNewNet::onTurnTimeChanged(int time)
{
	if (isChief) RawSendNet(QString("CONFIG_PARAM%1TURNTIME%1%2").arg(delimeter).arg(time));
}

void HWNewNet::onSuddenDeathTurnsChanged(int turns)
{
	if (isChief) RawSendNet(QString("CONFIG_PARAM%1SD_TURNS%1%2").arg(delimeter).arg(turns));
}

void HWNewNet::onCaseProbabilityChanged(int prob)
{
	if (isChief) RawSendNet(QString("CONFIG_PARAM%1CASEFACTOR%1%2").arg(delimeter).arg(prob));
}

void HWNewNet::onFortsModeChanged(bool value)
{
	if (isChief) RawSendNet(QString("CONFIG_PARAM%1FORTSMODE%1%2").arg(delimeter).arg(value));
}

void HWNewNet::onTeamsDivideChanged(bool value)
{
	if (isChief) RawSendNet(QString("CONFIG_PARAM%1DIVIDETEAMS%1%2").arg(delimeter).arg(value));
}

void HWNewNet::onSolidChanged(bool value)
{
	if (isChief) RawSendNet(QString("CONFIG_PARAM%1SOLIDLAND%1%2").arg(delimeter).arg(value));
}

void HWNewNet::onBorderChanged(bool value)
{
	if (isChief) RawSendNet(QString("CONFIG_PARAM%1BORDER%1%2").arg(delimeter).arg(value));
}

void HWNewNet::onWeaponsNameChanged(const QString& name, const QString& ammo)
{
	if (isChief) RawSendNet(QString("CONFIG_PARAM%1AMMO%1%2%1%3").arg(delimeter).arg(ammo).arg(name));
}

void HWNewNet::onTemplateFilterChanged(int filter)
{
	if (isChief) RawSendNet(QString("CONFIG_PARAM%1TEMPLATE_FILTER%1%2").arg(delimeter).arg(filter));
}

void HWNewNet::chatLineToNet(const QString& str)
{
	if(str != "") {
		RawSendNet(QString("CHAT_STRING") + delimeter + str);
		emit(chatStringFromMe(formatChatMsg(mynick, str)));
	}
}

void HWNewNet::chatLineToLobby(const QString& str)
{
	if(str != "") {
		RawSendNet(QString("CHAT_STRING") + delimeter + str);
		emit(chatStringFromMeLobby(formatChatMsg(mynick, str)));
	}
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

bool HWNewNet::isRoomChief()
{
	return isChief;
}

void HWNewNet::gameFinished()
{
	netClientState = 3;
	RawSendNet(QString("ROUNDFINISHED"));
}

QString HWNewNet::formatChatMsg(const QString & nick, const QString & msg)
{
	if(msg.left(4) == "/me ")
		return QString("* %1 %2").arg(nick).arg(msg.mid(4));
	else
		return QString("%1: %2").arg(nick).arg(msg);
}

void HWNewNet::kickPlayer(const QString & nick)
{
	RawSendNet(QString("KICK%1%2").arg(delimeter).arg(nick));
}

void HWNewNet::infoPlayer(const QString & nick)
{
	RawSendNet(QString("INFO%1%2").arg(delimeter).arg(nick));
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

void HWNewNet::partRoom()
{
	netClientState = 2;
	RawSendNet(QString("PART"));
}

bool HWNewNet::isInRoom()
{
	return netClientState > 2;
}
