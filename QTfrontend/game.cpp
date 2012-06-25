/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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
#include <QColor>
#include <QStringListModel>
#include <QTextStream>

#include "game.h"
#include "hwconsts.h"
#include "gameuiconfig.h"
#include "gamecfgwidget.h"
#include "teamselect.h"
#include "KB.h"
#include "proto.h"
#include "ThemeModel.h"

QString training, campaign; // TODO: Cleaner solution?

HWGame::HWGame(GameUIConfig * config, GameCFGWidget * gamecfg, QString ammo, TeamSelWidget* pTeamSelWidget) :
    TCPBase(true),
    ammostr(ammo),
    m_pTeamSelWidget(pTeamSelWidget)
{
    this->config = config;
    this->gamecfg = gamecfg;
    netSuspend = false;
}

HWGame::~HWGame()
{
    SetGameState(gsDestroyed);
}

void HWGame::onClientDisconnect()
{
    switch (gameType)
    {
        case gtSave:
            if (gameState == gsInterrupted || gameState == gsHalted)
                emit HaveRecord(false, demo);
            else if (gameState == gsFinished)
                emit HaveRecord(true, demo);
            break;
        case gtDemo:
            break;
        case gtNet:
            emit HaveRecord(true, demo);
            break;
        default:
            if (gameState == gsInterrupted || gameState == gsHalted) emit HaveRecord(false, demo);
            else if (gameState == gsFinished) emit HaveRecord(true, demo);
    }
    SetGameState(gsStopped);
}

void HWGame::commonConfig()
{
    QByteArray buf;
    QString gt;
    switch (gameType)
    {
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

    buf += gamecfg->getFullConfig();

    if (m_pTeamSelWidget)
    {
        foreach(HWTeam team, m_pTeamSelWidget->getPlayingTeams())
        {
            HWProto::addStringToBuffer(buf, QString("eammloadt %1").arg(ammostr.mid(0, cAmmoNumber)));
            HWProto::addStringToBuffer(buf, QString("eammprob %1").arg(ammostr.mid(cAmmoNumber, cAmmoNumber)));
            HWProto::addStringToBuffer(buf, QString("eammdelay %1").arg(ammostr.mid(2 * cAmmoNumber, cAmmoNumber)));
            HWProto::addStringToBuffer(buf, QString("eammreinf %1").arg(ammostr.mid(3 * cAmmoNumber, cAmmoNumber)));
            if(gamecfg->schemeData(15).toBool() || !gamecfg->schemeData(21).toBool()) HWProto::addStringToBuffer(buf, QString("eammstore"));
            HWProto::addStringListToBuffer(buf,
                                           team.teamGameConfig(gamecfg->getInitHealth()));
            ;
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
    ThemeModel * themeModel = DataManager::instance().themeModel();

    HWProto::addStringToBuffer(teamscfg, "TL");
    HWProto::addStringToBuffer(teamscfg, QString("etheme %1")
                               .arg((themeModel->rowCount() > 0) ? themeModel->index(rand() % themeModel->rowCount()).data().toString() : "steel"));
    HWProto::addStringToBuffer(teamscfg, "eseed " + QUuid::createUuid().toString());

    HWTeam team1;
    team1.setDifficulty(0);
    team1.setColor(0);
    team1.setNumHedgehogs(4);
    HWNamegen::teamRandomNames(team1,true);
    HWProto::addStringListToBuffer(teamscfg,
                                   team1.teamGameConfig(100));

    HWTeam team2;
    team2.setDifficulty(4);
    team2.setColor(1);
    team2.setNumHedgehogs(4);
    do
        HWNamegen::teamRandomNames(team2,true);
    while(!team2.name().compare(team1.name()) || !team2.hedgehog(0).Hat.compare(team1.hedgehog(0).Hat));
    HWProto::addStringListToBuffer(teamscfg,
                                   team2.teamGameConfig(100));

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
    HWProto::addStringToBuffer(traincfg, "eseed " + QUuid::createUuid().toString());
    HWProto::addStringToBuffer(traincfg, "escript " + training);

    RawSendIPC(traincfg);
}

void HWGame::SendCampaignConfig()
{
    QByteArray campaigncfg;
    HWProto::addStringToBuffer(campaigncfg, "TL");
    HWProto::addStringToBuffer(campaigncfg, "eseed " + QUuid::createUuid().toString());

    HWProto::addStringToBuffer(campaigncfg, "escript " + campaign);

    RawSendIPC(campaigncfg);
}

void HWGame::SendNetConfig()
{
    commonConfig();
}

void HWGame::ParseMessage(const QByteArray & msg)
{
    switch(msg.at(1))
    {
        case '?':
        {
            SendIPC("!");
            break;
        }
        case 'C':
        {
            switch (gameType)
            {
                case gtLocal:
                {
                    SendConfig();
                    break;
                }
                case gtQLocal:
                {
                    SendQuickConfig();
                    break;
                }
                case gtSave:
                case gtDemo:
                    break;
                case gtNet:
                {
                    SendNetConfig();
                    break;
                }
                case gtTraining:
                {
                    SendTrainingConfig();
                    break;
                }
                case gtCampaign:
                {
                    SendCampaignConfig();
                    break;
                }
            }
            break;
        }
        case 'E':
        {
            int size = msg.size();
            emit ErrorMessage(QString("Last two engine messages:\n") + QString().append(msg.mid(2)).left(size - 4));
            return;
        }
        case 'K':
        {
            ulong kb = msg.mid(2).toULong();
            if (kb==1)
            {
                qWarning("%s", KBMessages[kb - 1].toLocal8Bit().constData());
                return;
            }
            if (kb && kb <= KBmsgsCount)
            {
                emit ErrorMessage(KBMessages[kb - 1]);
            }
            return;
        }
        case 'i':
        {
            emit GameStats(msg.at(2), QString::fromUtf8(msg.mid(3)));
            break;
        }
        case 'Q':
        {
            SetGameState(gsInterrupted);
            break;
        }
        case 'q':
        {
            SetGameState(gsFinished);
            break;
        }
        case 'H':
        {
            SetGameState(gsHalted);
            break;
        }
        case 's':
        {
            int size = msg.size();
            QString msgbody = QString::fromUtf8(msg.mid(2).left(size - 4));
            emit SendChat(msgbody);
            // FIXME: /me command doesn't work here
            QByteArray buf;
            HWProto::addStringToBuffer(buf, "s" + HWProto::formatChatMsg(config->netNick(), msgbody) + "\x20\x20");
            demo.append(buf);
            break;
        }
        case 'b':
        {
            int size = msg.size();
            QString msgbody = QString::fromUtf8(msg.mid(2).left(size - 4));
            emit SendTeamMessage(msgbody);
            break;
        }
        default:
        {
            if (gameType == gtNet && !netSuspend)
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

QStringList HWGame::getArguments()
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
    arguments << (config->isMusicEnabled() ? "1" : "0");
    arguments << QString::number(config->volume()); // sound volume
    arguments << QString::number(config->timerInterval());
    arguments << datadir->absolutePath();
    arguments << (config->isShowFPSEnabled() ? "1" : "0");
    arguments << (config->isAltDamageEnabled() ? "1" : "0");
    arguments << config->netNick().toUtf8().toBase64();
    arguments << QString::number(config->translateQuality());
    arguments << QString::number(config->stereoMode());
    arguments << tr("en.txt");

    return arguments;
}

void HWGame::PlayDemo(const QString & demofilename, bool isSave)
{
    gameType = isSave ? gtSave : gtDemo;
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
    training = "Missions/Training/" + file + ".lua";
    demo.clear();
    Start();
    SetGameState(gsStarted);
}

void HWGame::StartCampaign(const QString & file)
{
    gameType = gtCampaign;
    campaign = "Missions/Campaign/" + file + ".lua";
    demo.clear();
    Start();
    SetGameState(gsStarted);
}

void HWGame::SetGameState(GameState state)
{
    gameState = state;
    emit GameStateChanged(state);
}

void HWGame::abort()
{
    QByteArray buf;
    HWProto::addStringToBuffer(buf, QString("efinish"));
    RawSendIPC(buf);
}
