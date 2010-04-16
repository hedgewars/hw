/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QString>
#include <QByteArray>
#include <QUuid>

#include "game.h"
#include "hwconsts.h"
#include "gameuiconfig.h"
#include "gamecfgwidget.h"
#include "teamselect.h"
#include "KB.h"
#include "proto.h"

#include <QTextStream>

QString training; // TODO: Cleaner solution?

HWGame::HWGame(GameUIConfig * config, GameCFGWidget * gamecfg, QString ammo, TeamSelWidget* pTeamSelWidget) :
  TCPBase(true),
  ammostr(ammo),
  m_pTeamSelWidget(pTeamSelWidget)
{
    this->config = config;
    this->gamecfg = gamecfg;
    TeamCount = 0;
}

HWGame::~HWGame()
{
    SetGameState(gsDestroyed);
}

void HWGame::onClientDisconnect()
{
    switch (gameType) {
        case gtDemo: break;
        case gtNet:
            emit HaveRecord(true, demo);
            break;
        default:
            if (gameState == gsInterrupted) emit HaveRecord(false, demo);
            else if (gameState == gsFinished) emit HaveRecord(true, demo);
    }
    SetGameState(gsStopped);
}

void HWGame::commonConfig()
{
    QByteArray buf;
    QString gt;
    switch (gameType) {
        case gtDemo:
            gt = "TD";
            break;
        case gtNet:
            gt = "TN";
            break;
        default:
            gt = "TL";
    }
    HWProto::addStringToBuffer(buf, gt);

    HWProto::addStringListToBuffer(buf, gamecfg->getFullConfig());

    if (m_pTeamSelWidget)
    {
        QList<HWTeam> teams = m_pTeamSelWidget->getPlayingTeams();
        for(QList<HWTeam>::iterator it = teams.begin(); it != teams.end(); ++it)
        {
            HWProto::addStringListToBuffer(buf,
                (*it).TeamGameConfig(gamecfg->getInitHealth()));
            HWProto::addStringToBuffer(buf, QString("eammloadt %1").arg(ammostr.mid(0, cAmmoNumber)));
            HWProto::addStringToBuffer(buf, QString("eammprob %1").arg(ammostr.mid(cAmmoNumber, cAmmoNumber)));
            HWProto::addStringToBuffer(buf, QString("eammdelay %1").arg(ammostr.mid(2 * cAmmoNumber, cAmmoNumber)));
            HWProto::addStringToBuffer(buf, QString("eammreinf %1").arg(ammostr.mid(3 * cAmmoNumber, cAmmoNumber)));
            HWProto::addStringToBuffer(buf, QString("eammstore"));
        }
    }
    RawSendIPC(buf);
}

void HWGame::SendConfig()
{
    commonConfig();
}

void HWGame::SendQuickConfig()
{
    QByteArray teamscfg;

    HWProto::addStringToBuffer(teamscfg, "TL");
    HWProto::addStringToBuffer(teamscfg, QString("etheme %1")
            .arg((Themes->size() > 0) ? Themes->at(rand() % Themes->size()) : "steel"));
    HWProto::addStringToBuffer(teamscfg, "eseed " + QUuid::createUuid().toString());

    HWNamegen namegen;

    HWTeam * team1;
    team1 = new HWTeam;
    team1->difficulty = 0;
    team1->teamColor = *color1;
    team1->numHedgehogs = 4;
    namegen.TeamRandomNames(team1,TRUE);
    HWProto::addStringListToBuffer(teamscfg,
            team1->TeamGameConfig(100));

    HWTeam * team2;
    team2 = new HWTeam;
    team2->difficulty = 4;
    team2->teamColor = *color2;
    team2->numHedgehogs = 4;
	do
        namegen.TeamRandomNames(team2,TRUE);
	while(!team2->TeamName.compare(team1->TeamName) || !team2->Hedgehogs[0].Hat.compare(team1->Hedgehogs[0].Hat));
    HWProto::addStringListToBuffer(teamscfg,
            team2->TeamGameConfig(100));

    HWProto::addStringToBuffer(teamscfg, QString("eammloadt %1").arg(cDefaultAmmoStore->mid(0, cAmmoNumber)));
    HWProto::addStringToBuffer(teamscfg, QString("eammprob %1").arg(cDefaultAmmoStore->mid(cAmmoNumber, cAmmoNumber)));
    HWProto::addStringToBuffer(teamscfg, QString("eammdelay %1").arg(cDefaultAmmoStore->mid(2 * cAmmoNumber, cAmmoNumber)));
    HWProto::addStringToBuffer(teamscfg, QString("eammreinf %1").arg(cDefaultAmmoStore->mid(3 * cAmmoNumber, cAmmoNumber)));
    HWProto::addStringToBuffer(teamscfg, QString("eammstore"));
    HWProto::addStringToBuffer(teamscfg, QString("eammstore"));
    RawSendIPC(teamscfg);
}

void HWGame::SendTrainingConfig()
{
    QByteArray traincfg;
    HWProto::addStringToBuffer(traincfg, "TL");

    HWProto::addStringToBuffer(traincfg, "escript " + datadir->absolutePath() + "/Missions/Training/" + training + ".lua");

    RawSendIPC(traincfg);
}

void HWGame::SendNetConfig()
{
    commonConfig();
}

void HWGame::ParseMessage(const QByteArray & msg)
{
    switch(msg.at(1)) {
        case '?': {
            SendIPC("!");
            break;
        }
        case 'C': {
            switch (gameType) {
                case gtLocal: {
                    SendConfig();
                    break;
                }
                case gtQLocal: {
                    SendQuickConfig();
                    break;
                }
                case gtDemo: break;
                case gtNet: {
                    SendNetConfig();
                    break;
                }
                case gtTraining: {
                    SendTrainingConfig();
                    break;
                }
            }
            break;
        }
        case 'E': {
            int size = msg.size();
            emit ErrorMessage(QString("Last two engine messages:\n") + QString().append(msg.mid(2)).left(size - 4));
            return;
        }
        case 'K': {
            ulong kb = msg.mid(2).toULong();
            if (kb==1) {
              qWarning("%s", KBMessages[kb - 1].toLocal8Bit().constData());
              return;
            }
            if (kb && kb <= KBmsgsCount)
            {
                emit ErrorMessage(KBMessages[kb - 1]);
            }
            return;
        }
        case 'i': {
            emit GameStats(msg.at(2), QString::fromUtf8(msg.mid(3)));
            break;
        }
        case 'Q': {
            SetGameState(gsInterrupted);
            break;
        }
        case 'q': {
            SetGameState(gsFinished);
            break;
        }
        case 's': {
            int size = msg.size();
            QString msgbody = QString::fromUtf8(msg.mid(2).left(size - 4));
            emit SendChat(msgbody);
            // FIXME: /me command doesn't work here
            QByteArray buf;
            HWProto::addStringToBuffer(buf, "s" + HWProto::formatChatMsg(config->netNick(), msgbody) + "\x20\x20");
            demo.append(buf);
            break;
        }
        case 'b': {
            int size = msg.size();
            QString msgbody = QString::fromUtf8(msg.mid(2).left(size - 4));
            emit SendTeamMessage(msgbody);
            break;
        }
        default: {
            if (gameType == gtNet)
            {
                emit SendNet(msg);
            }
        if (msg.at(1) != 's')
            demo.append(msg);
        }
    }
}

void HWGame::FromNet(const QByteArray & msg)
{
    RawSendIPC(msg);
}

void HWGame::FromNetChat(const QString & msg)
{
    QByteArray buf;
    HWProto::addStringToBuffer(buf, 's' + msg + "\x20\x20");
    RawSendIPC(buf);
}

void HWGame::onClientRead()
{
    quint8 msglen;
    quint32 bufsize;
    while (!readbuffer.isEmpty() && ((bufsize = readbuffer.size()) > 0) &&
            ((msglen = readbuffer.data()[0]) < bufsize))
    {
        QByteArray msg = readbuffer.left(msglen + 1);
        readbuffer.remove(0, msglen + 1);
        ParseMessage(msg);
    }
}

QStringList HWGame::setArguments()
{
    QStringList arguments;
    QRect resolution = config->vid_Resolution();
    arguments << cfgdir->absolutePath();
    arguments << QString::number(resolution.width());
    arguments << QString::number(resolution.height());
    arguments << QString::number(config->bitDepth()); // bpp
    arguments << QString("%1").arg(ipc_port);
    arguments << (config->vid_Fullscreen() ? "1" : "0");
    arguments << (config->isSoundEnabled() ? "1" : "0");
#ifdef _WIN32
    arguments << (config->isSoundHardware() ? "1" : "0");
#else
    arguments << "0";
#endif
    arguments << (config->isWeaponTooltip() ? "1" : "0");
    arguments << tr("en.txt");
    arguments << QString::number(config->volume()); // sound volume
    arguments << QString::number(config->timerInterval());
    arguments << datadir->absolutePath();
    arguments << (config->isShowFPSEnabled() ? "1" : "0");
    arguments << (config->isAltDamageEnabled() ? "1" : "0");
    arguments << config->netNick().toUtf8().toBase64();
    arguments << (config->isMusicEnabled() ? "1" : "0");
    arguments << (config->isReducedQuality() ? "1" : "0");
    return arguments;
}

void HWGame::AddTeam(const QString & teamname)
{
    if (TeamCount == 5) return;
    teams[TeamCount] = teamname;
    TeamCount++;
}

void HWGame::PlayDemo(const QString & demofilename)
{
    gameType = gtDemo;
    QFile demofile(demofilename);
    if (!demofile.open(QIODevice::ReadOnly))
    {
        emit ErrorMessage(tr("Cannot open demofile %1").arg(demofilename));
        return ;
    }

    // read demo
    toSendBuf = demofile.readAll();

    // run engine
    demo.clear();
    Start();
    SetGameState(gsStarted);
}

void HWGame::StartNet()
{
    gameType = gtNet;
    demo.clear();
    Start();
    SetGameState(gsStarted);
}

void HWGame::StartLocal()
{
    gameType = gtLocal;
    demo.clear();
    Start();
    SetGameState(gsStarted);
}

void HWGame::StartQuick()
{
    gameType = gtQLocal;
    demo.clear();
    Start();
    SetGameState(gsStarted);
}

void HWGame::StartTraining(const QString & file)
{
    gameType = gtTraining;
    training = file;
    demo.clear();
    Start();
    SetGameState(gsStarted);
}

void HWGame::SetGameState(GameState state)
{
    gameState = state;
    emit GameStateChanged(state);
}
