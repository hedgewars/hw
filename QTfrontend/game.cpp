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
#include <utility>

#include "hwform.h"
#include "ui/page/pageoptions.h"
#include "game.h"
#include "hwconsts.h"
#include "gameuiconfig.h"
#include "gamecfgwidget.h"
#include "teamselect.h"
#include "proto.h"
#include "binds.h"
#include "campaign.h"

#include <QTextStream>
#include "ThemeModel.h"

// last game info
QList<QVariant> lastGameStartArgs = QList<QVariant>();
GameType lastGameType = gtNone;
GameCFGWidget * lastGameCfg = NULL;
QString lastGameAmmo = NULL;
TeamSelWidget * lastGameTeamSel = NULL;

QString training, campaign, campaignScript, campaignTeam; // TODO: Cleaner solution?

HWGame::HWGame(GameUIConfig * config, GameCFGWidget * gamecfg, QString ammo, TeamSelWidget* pTeamSelWidget) :
    TCPBase(true, 0),
    ammostr(ammo),
    m_pTeamSelWidget(pTeamSelWidget)
{
    this->config = config;
    this->gamecfg = gamecfg;
    netSuspend = false;

    lastGameCfg = gamecfg;
    lastGameAmmo = ammo;
    lastGameTeamSel = pTeamSelWidget;
}

HWGame::~HWGame()
{
    SetGameState(gsDestroyed);
}

void HWGame::onClientDisconnect()
{
    switch (gameType)
    {
        case gtDemo:
            // for video recording we need demo anyway
            emit HaveRecord(rtNeither, demo);
            break;
        case gtNet:
            emit HaveRecord(rtDemo, demo);
            break;
        default:
            if (gameState == gsInterrupted || gameState == gsHalted)
                emit HaveRecord(rtSave, demo);
            else if (gameState == gsFinished)
                emit HaveRecord(rtDemo, demo);
            else
                emit HaveRecord(rtNeither, demo);
    }
    SetGameState(gsStopped);
}

void HWGame::addKeyBindings(QByteArray * buf)
{
    for(int i = 0; i < BINDS_NUMBER; i++)
    {
        QString value = config->value(QString("Binds/%1").arg(cbinds[i].action), cbinds[i].strbind).toString();
        if (value.isEmpty() || value == "default") continue;

        QString bind = QString("edbind " + value + " " + cbinds[i].action);
        HWProto::addStringToBuffer(*buf, bind);
    }
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

    addKeyBindings(&buf);

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
                                           team.teamGameConfig(gamecfg->getInitHealth(), config));
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

    addKeyBindings(&teamscfg);

    HWProto::addStringToBuffer(teamscfg, "TL");
    HWProto::addStringToBuffer(teamscfg, QString("etheme %1")
                               .arg((themeModel->rowCount() > 0) ? themeModel->index(rand() % themeModel->rowCount()).data().toString() : "steel"));
    HWProto::addStringToBuffer(teamscfg, "eseed " + QUuid::createUuid().toString());

    HWProto::addStringToBuffer(teamscfg, "e$template_filter 2");

    HWTeam team1;
    team1.setDifficulty(0);
    team1.setColor(0);
    team1.setNumHedgehogs(4);
    HWNamegen::teamRandomNames(team1,true);
    HWProto::addStringListToBuffer(teamscfg,
                                   team1.teamGameConfig(100, config));

    HWTeam team2;
    team2.setDifficulty(4);
    team2.setColor(1);
    team2.setNumHedgehogs(4);
    do
        HWNamegen::teamRandomNames(team2,true);
    while(!team2.name().compare(team1.name()) || !team2.hedgehog(0).Hat.compare(team1.hedgehog(0).Hat));
    HWProto::addStringListToBuffer(teamscfg,
                                   team2.teamGameConfig(100, config));

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

    addKeyBindings(&traincfg);

    RawSendIPC(traincfg);
}

void HWGame::SendCampaignConfig()
{
    QByteArray campaigncfg;
    HWProto::addStringToBuffer(campaigncfg, "TL");
    HWProto::addStringToBuffer(campaigncfg, "eseed " + QUuid::createUuid().toString());

    HWProto::addStringToBuffer(campaigncfg, "escript " + campaignScript);

    addKeyBindings(&campaigncfg);

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
                case gtNone:
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
        case 'V':
        {
            if (msg.at(2) == '?')
                sendCampaignVar(msg.right(msg.size() - 3));
            else if (msg.at(2) == '!')
                writeCampaignVar(msg.right(msg.size() - 3));
            break;
        }
        case 'W':
        {
            // fetch new window resolution via IPC and save it in the settings
            int size = msg.size();
            QString newResolution = QString().append(msg.mid(2)).left(size - 4);
            QStringList wh = newResolution.split('x');
            config->Form->ui.pageOptions->windowWidthEdit->setValue(wh[0].toInt());
            config->Form->ui.pageOptions->windowHeightEdit->setValue(wh[1].toInt());
            break;
        }
        default:
        {
            if (gameType == gtNet && !netSuspend)
                m_netSendBuffer.append(msg);

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

    flushNetBuffer();
}

void HWGame::flushNetBuffer()
{
    if(m_netSendBuffer.size())
    {
        emit SendNet(m_netSendBuffer);

        m_netSendBuffer.clear();
    }
}

QStringList HWGame::getArguments()
{
    QStringList arguments;
    std::pair<QRect, QRect> resolutions = config->vid_ResolutionPair();
    QString nick = config->netNick().toUtf8().toBase64();

    arguments << "--internal"; //Must be passed as first argument
    arguments << "--port";
    arguments << QString("%1").arg(ipc_port);
    arguments << "--prefix";
    arguments << datadir->absolutePath();
    arguments << "--user-prefix";
    arguments << cfgdir->absolutePath();
    arguments << "--locale";
    arguments << tr("en.txt");
    arguments << "--frame-interval";
    arguments << QString::number(config->timerInterval());
    arguments << "--volume";
    arguments << QString::number(config->volume());
    arguments << "--fullscreen-width";
    arguments << QString::number(resolutions.first.width());
    arguments << "--fullscreen-height";
    arguments << QString::number(resolutions.first.height());
    arguments << "--width";
    arguments << QString::number(resolutions.second.width());
    arguments << "--height";
    arguments << QString::number(resolutions.second.height());
    arguments << "--raw-quality";
    arguments << QString::number(config->translateQuality());
    arguments << "--stereo";
    arguments << QString::number(config->stereoMode());
    if (config->vid_Fullscreen())
        arguments << "--fullscreen";
    if (config->isShowFPSEnabled())
        arguments << "--showfps";
    if (config->isAltDamageEnabled())
        arguments << "--altdmg";
    if (!config->isSoundEnabled())
        arguments << "--nosound";
    if (!config->isMusicEnabled())
        arguments << "--nomusic";
    if (!nick.isEmpty()) {
        arguments << "--nick";
        arguments << nick;
    }

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
    Start(false);
    SetGameState(gsStarted);
}

void HWGame::StartNet()
{
    gameType = gtNet;
    demo.clear();
    Start(false);
    SetGameState(gsStarted);
}

void HWGame::StartLocal()
{
    lastGameStartArgs.clear();
    lastGameType = gtLocal;

    gameType = gtLocal;
    demo.clear();
    Start(false);
    SetGameState(gsStarted);
}

void HWGame::StartQuick()
{
    lastGameStartArgs.clear();
    lastGameType = gtQLocal;

    gameType = gtQLocal;
    demo.clear();
    Start(false);
    SetGameState(gsStarted);
}

void HWGame::StartTraining(const QString & file)
{
    lastGameStartArgs.clear();
    lastGameStartArgs.append(file);
    lastGameType = gtTraining;

    gameType = gtTraining;
    training = "Missions/Training/" + file + ".lua";
    demo.clear();
    Start(false);
    SetGameState(gsStarted);
}

void HWGame::StartCampaign(const QString & camp, const QString & campScript, const QString & campTeam)
{
    lastGameStartArgs.clear();
    lastGameStartArgs.append(camp);
    lastGameStartArgs.append(campScript);
    lastGameStartArgs.append(campTeam);
    lastGameType = gtCampaign;

    gameType = gtCampaign;
    campaign = camp;
    campaignScript = "Missions/Campaign/" + camp + "/" + campScript;
    campaignTeam = campTeam;
    demo.clear();
    Start(false);
    SetGameState(gsStarted);
}

void HWGame::SetGameState(GameState state)
{
    gameState = state;
    emit GameStateChanged(state);
    if (gameType == gtCampaign)
    {
      emit CampStateChanged(1);
    }
}

void HWGame::abort()
{
    QByteArray buf;
    HWProto::addStringToBuffer(buf, QString("efinish"));
    RawSendIPC(buf);
}

void HWGame::sendCampaignVar(const QByteArray &varToSend)
{
    QString varToFind(varToSend);
    QSettings teamfile(QString("physfs://Teams/%1.hwt").arg(campaignTeam), QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    QString varValue = teamfile.value("Campaign " + campaign + "/" + varToFind, "").toString();
    QByteArray command;
    HWProto::addStringToBuffer(command, "V." + varValue);
    RawSendIPC(command);
}

void HWGame::writeCampaignVar(const QByteArray & varVal)
{
    int i = varVal.indexOf(" ");
    if(i < 0)
        return;

    QString varToWrite = QString::fromUtf8(varVal.left(i));
    QString varValue = QString::fromUtf8(varVal.mid(i + 1));

    QSettings teamfile(QString("physfs://Teams/%1.hwt").arg(campaignTeam), QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    teamfile.setValue("Campaign " + campaign + "/" + varToWrite, varValue);
}

