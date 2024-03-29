/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <QApplication>

#include <QString>
#include <QCheckBox>
#include <QByteArray>
#include <QUuid>
#include <QColor>
#include <QStringListModel>
#include <QTextStream>
#include <utility>

#include "hwform.h"
#include "ui/page/pageoptions.h"
#include "ui/page/pagetraining.h"
#include "ui/page/pagecampaign.h"
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

QString trainingName, trainingScript, trainingTeam, campaign, campaignScript, campaignTeam; // TODO: Cleaner solution?

HWGame::HWGame(GameUIConfig * config, GameCFGWidget * gamecfg, QString ammo, TeamSelWidget* pTeamSelWidget) :
    TCPBase(true, !config->language().isEmpty(), 0),
    ammostr(ammo),
    m_pTeamSelWidget(pTeamSelWidget)
{
    this->config = config;
    this->gamecfg = gamecfg;
    netSuspend = false;

    lastGameCfg = gamecfg;
    lastGameAmmo = ammo;
    lastGameTeamSel = pTeamSelWidget;

    gameState = gsNotStarted;
    gameType = gtNone;
}

HWGame::~HWGame()
{
    SetGameState(gsDestroyed);
}

void HWGame::onClientDisconnect()
{
    if (demoIsPresent)
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
    }
    else
    {
        emit HaveRecord(rtNeither, demo);
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
    /* Load and increase Quick Game experience level.
    Experience increases by 1 for each started game and maxes out
    at 20. Low experience levels will introduce a "beginner's bias" to make
    the first quick games easier and simpler. The max. possible difficulty
    increases progressively the longer you play.
    If experience is maxed out, the beginner's bias is gone and quick games
    are completely random. */
    int exp = config->quickGameExperience();
    if(exp < 20)
    {
       config->setQuickGameExperience(exp + 1);
    }
    qDebug("Starting quick game ...");
    qDebug("Quick Game experience level: %d", exp);

    // Init stuff
    QByteArray teamscfg;
    QAbstractItemModel * themeModel = DataManager::instance().themeModel()->withoutHidden();

    HWProto::addStringToBuffer(teamscfg, "TL");

    // Random seed
    HWProto::addStringToBuffer(teamscfg, "eseed " + QUuid::createUuid().toString());

    int r, minhogs, maxhogs;

    // Random map type
    r = rand() % 10000;
    if(r < 3000) { // 30%
        // Random
        r = 0;
    } else if(r < 5250) { // 22.5%
        // Maze
        if(exp <= 3)
            r = 0;
        else
            r = 1;
    } else if(r < 7490) { // 22.4%
        // Perlin
        if(exp <= 7)
            r = 1;
        else
            r = 2;
    } else if(r < 7500 && exp >= 5) { // 0.1%
        // Floating Flowers (just for fun)
        r = 5;
    } else if(r < 8750) { // 12.5%
        // Image map
        r = 3;
    } else { // 12.5%
        // Forts
        r = 4;
    }
    switch(r)
    {
        // Random map
        default:
        case 0: {
            r = rand() % 3;
            if(r == 0)
            {
                // small island
                HWProto::addStringToBuffer(teamscfg, "e$template_filter 1");
                minhogs = 3;
                maxhogs = 4;
            }
            else if(r == 1 || exp <= 6)
            {
                // medium island
                HWProto::addStringToBuffer(teamscfg, "e$template_filter 2");
                minhogs = 4;
                maxhogs = 5;
            }
            else
            {
                // cave (locked at low experience because these maps can be huge)
                HWProto::addStringToBuffer(teamscfg, "e$template_filter 4");
                minhogs = 4;
                maxhogs = 6;
            }
            HWProto::addStringToBuffer(teamscfg, "e$feature_size "+QString::number(rand()%18+4));
            break;
        }
        // Maze
        case 1: {
            minhogs = 4;
            maxhogs = 6;
            HWProto::addStringToBuffer(teamscfg, "e$mapgen 1");
            HWProto::addStringToBuffer(teamscfg, "e$template_filter "+QString::number(rand()%6));
            HWProto::addStringToBuffer(teamscfg, "e$feature_size "+QString::number(rand()%16+6));
            break;
        }
        // Perlin
        case 2: {
            minhogs = 4;
            maxhogs = 6;
            HWProto::addStringToBuffer(teamscfg, "e$mapgen 2");
            HWProto::addStringToBuffer(teamscfg, "e$template_filter "+QString::number(rand()%6));
            HWProto::addStringToBuffer(teamscfg, "e$feature_size "+QString::number(rand()%18+4));
            break;
        }
        // Image map
        case 3: {
            minhogs = 4;
            maxhogs = 6;
            HWProto::addStringToBuffer(teamscfg, "e$mapgen 3");
            // Select map from hardcoded list.
            // TODO: find a more dynamic solution.
            r = rand() % cQuickGameMaps.count();
            HWProto::addStringToBuffer(teamscfg, "e$map " + cQuickGameMaps[r]);
            break;
        }
        // Forts
        case 4: {
            minhogs = 4;
            maxhogs = 6;
            HWProto::addStringToBuffer(teamscfg, "e$mapgen 4");
            HWProto::addStringToBuffer(teamscfg, "e$feature_size "+QString::number(rand()%20+1));
            break;
        }
        // Floating Flowers
        // (actually empty map; this forces the engine to generate fallback structures to have
        // something for hogs to stand on)
        case 5: {
            minhogs = 4;
            maxhogs = 8;
            HWProto::addStringToBuffer(teamscfg, "e$mapgen 3");
            HWProto::addStringToBuffer(teamscfg, "e$feature_size "+QString::number(rand()%4+3));
            break;
        }
    }

    // Theme
    HWProto::addStringToBuffer(teamscfg, QString("etheme %1")
        .arg((themeModel->rowCount() > 0) ? themeModel->index(rand() % themeModel->rowCount(), 0).data(ThemeModel::ActualNameRole).toString() : "Nature"));

    int hogs = minhogs + rand() % (maxhogs-minhogs+1);
    // Cap hog count at low experience
    if((exp <= 8) && (hogs > 5))
        hogs = 5;
    else if((exp <= 5) && (hogs > 4))
        hogs = 4;

    // Teams
    // Player team
    HWTeam team1;
    team1.setDifficulty(0);
    team1.setColor(0);
    team1.setNumHedgehogs(hogs);
    HWNamegen::teamRandomEverything(team1);
    team1.setVoicepack("Default_qau");

    // Computer team
    HWTeam team2;
    // Random difficulty.
    // Max. possible difficulty is capped at low experience levels.
    if(exp >= 15) // very easy to very hard (full range)
        r = 5 - rand() % 5;
    else if(exp >= 9) // very easy to hard
        r = 5 - rand() % 4;
    else if(exp >= 6) // very easy to medium
        r = 5 - rand() % 3;
    else if(exp >= 2) // very easy to easy
        r = 5 - rand() % 2;
    else // very easy
        r = 5;
    team2.setDifficulty(r);
    team2.setColor(1);
    team2.setNumHedgehogs(hogs);
    // Make sure the team names are not equal
    do
        HWNamegen::teamRandomEverything(team2);
    while(!team2.name().compare(team1.name()) || !team2.hedgehog(0).Hat.compare(team1.hedgehog(0).Hat));
    team2.setVoicepack("Default_qau");

    // Team play order
    r = rand() % 2;
    if(r == 0 || exp <= 4) // player plays first
    {
        HWProto::addStringListToBuffer(teamscfg, team1.teamGameConfig(100));
        HWProto::addStringListToBuffer(teamscfg, team2.teamGameConfig(100));
    }
    else // computer plays first
    {
        HWProto::addStringListToBuffer(teamscfg, team2.teamGameConfig(100));
        HWProto::addStringListToBuffer(teamscfg, team1.teamGameConfig(100));
    }

    // Ammo scheme "Default"
    // TODO: Random schemes
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

    HWTeam missionTeam = HWTeam();
    missionTeam.setName(config->Form->ui.pageTraining->CBTeam->currentText());
    missionTeam.loadFromFile();
    missionTeam.setNumHedgehogs(HEDGEHOGS_PER_TEAM);
    missionTeam.setMissionTeam(true);
    HWProto::addStringListToBuffer(traincfg, missionTeam.teamGameConfig(100));

    HWProto::addStringToBuffer(traincfg, "eseed " + QUuid::createUuid().toString());
    HWProto::addStringToBuffer(traincfg, "escript " + trainingScript);

    RawSendIPC(traincfg);
}

void HWGame::SendCampaignConfig()
{
    QByteArray campaigncfg;
    HWProto::addStringToBuffer(campaigncfg, "TL");

    HWTeam missionTeam = HWTeam();
    missionTeam.setName(config->Form->ui.pageCampaign->CBTeam->currentText());
    missionTeam.loadFromFile();
    missionTeam.setNumHedgehogs(HEDGEHOGS_PER_TEAM);
    missionTeam.setMissionTeam(true);
    HWProto::addStringListToBuffer(campaigncfg, missionTeam.teamGameConfig(100));

    HWProto::addStringToBuffer(campaigncfg, "eseed " + QUuid::createUuid().toString());
    HWProto::addStringToBuffer(campaigncfg, "escript " + campaignScript);

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
            emit ErrorMessage(
                tr("A fatal ERROR occured! The game engine had to stop.\n\n"
                "We are very sorry for the inconvenience. :-(\n\n"
                "If this keeps happening, please click the 'Feedback' button in the main menu!\n\n"
                "Last engine message:\n%1")
                .arg(QString::fromUtf8(msg.mid(2).left(size - 4))));
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
        case 'm':
        {
            SetDemoPresence(false);
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
        case 'v':
        {
            if (msg.at(2) == '?')
                sendMissionVar(msg.right(msg.size() - 3));
            else if (msg.at(2) == '!')
                writeMissionVar(msg.right(msg.size() - 3));
            break;
        }
        case 'W':
        {
            // fetch new window resolution via IPC and save it in the settings
            int size = msg.size();
            QString newResolution = QString().append(msg.mid(2)).left(size - 4);
            bool windowMaximized;
            if (newResolution.endsWith('M'))
            {
                windowMaximized = true;
                newResolution.chop(1);
            }
            else
            {
                windowMaximized = false;
            }
            QStringList wh = newResolution.split('x');
            config->Form->ui.pageOptions->windowWidthEdit->setValue(wh[0].toInt());
            config->Form->ui.pageOptions->windowHeightEdit->setValue(wh[1].toInt());
            config->vid_SetMaximized(windowMaximized);
            break;
        }
        case '~':
        {
            int size = msg.size();
            QString msgbody = QString::fromUtf8(msg.mid(2).left(size - 4));
            emit SendConsoleCommand(msgbody);
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

void HWGame::FromNetWarning(const QString & msg)
{
    QByteArray buf;
    HWProto::addStringToBuffer(buf, "s\x00" + msg + "\x20\x20");
    RawSendIPC(buf);
}

void HWGame::FromNetError(const QString & msg)
{
    QByteArray buf;
    HWProto::addStringToBuffer(buf, "s\x05" + msg + "\x20\x20");
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
#ifdef _WIN32
    {
        QString path = datadir->absolutePath();
        if (path == QLatin1String(path.toLatin1())) {
            arguments << "--prefix";
            arguments << path;
        } else {
            arguments << "--prefix64";
            arguments << path.toUtf8().toBase64();
        }    
        path = cfgdir->absolutePath();
        if (path == QLatin1String(path.toLatin1())) {
            arguments << "--user-prefix";
            arguments << path;
        } else {
            arguments << "--user-prefix64";
            arguments << path.toUtf8().toBase64();
        }
    }         
#else 
    arguments << "--prefix";
    arguments << datadir->absolutePath();
    arguments << "--user-prefix";
    arguments << cfgdir->absolutePath();    
#endif
    arguments << "--locale";
    // TODO: Don't bother translators with this nonsense and detect this file automatically.
    //: IMPORTANT: This text has a special meaning, do not translate it directly. This is the file name of translation files for the game engine, found in Data/Locale/. Usually, you replace “en” with the ISO-639-1 language code of your language.
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
    if (config->vid_Maximized())
        arguments << "--maximized";
    if (config->zoom() != 100) {
        arguments << "--zoom";
        arguments << QString::number(config->zoom());
    }
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
    if (!config->isAudioDampenEnabled())
        arguments << "--nodampen";
    if (!nick.isEmpty()) {
        arguments << "--nick";
        arguments << nick;
    }

    if (!config->Form->ui.pageOptions->CBTeamTag->isChecked())
        arguments << "--no-teamtag";
    if (!config->Form->ui.pageOptions->CBHogTag->isChecked())
        arguments << "--no-hogtag";
    if (!config->Form->ui.pageOptions->CBHealthTag->isChecked())
        arguments << "--no-healthtag";
    if (config->Form->ui.pageOptions->CBTagOpacity->isChecked())
        arguments << "--translucent-tags";
    if (!config->isHolidaySillinessEnabled())
        arguments << "--no-holiday-silliness";
    arguments << "--chat-size";
    arguments << QString::number(config->chatSize());

    return arguments;
}

void HWGame::PlayDemo(const QString & demofilename, bool isSave)
{
    gameType = isSave ? gtSave : gtDemo;
    lastGameType = gameType;
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

void HWGame::PlayOfficialServerDemo()
{
    // TODO: Use gtDemo so fast-forward is available.
    // Needs engine support first.
    lastGameStartArgs.clear();
    lastGameType = gtLocal;

    gameType = gtLocal;
    demo.clear();
    Start(false);
    SetGameState(gsStarted);
}

void HWGame::StartNet()
{
    lastGameStartArgs.clear();
    lastGameType = gtNet;

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

void HWGame::StartTraining(const QString & file, const QString & subFolder, const QString & trainTeam)
{
    lastGameStartArgs.clear();
    lastGameStartArgs.append(file);
    lastGameStartArgs.append(subFolder);
    lastGameStartArgs.append(trainTeam);
    lastGameType = gtTraining;

    gameType = gtTraining;

    trainingScript  = "Missions/" + subFolder + "/" + file + ".lua";
    trainingName = file;
    trainingTeam = trainTeam;
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
        emit CampStateChanged(state);
    }
    else if (gameType == gtTraining)
    {
        emit TrainingStateChanged(1);
    }
}

void HWGame::SetDemoPresence(bool hasDemo)
{
    emit DemoPresenceChanged(hasDemo);
}

void HWGame::abort()
{
    QByteArray buf;
    HWProto::addStringToBuffer(buf, QString("eforcequit"));
    RawSendIPC(buf);
}

void HWGame::sendCampaignVar(const QByteArray &varToSend)
{
    QString varToFind = QString::fromUtf8(varToSend);
    QSettings teamfile(QString(cfgdir->absolutePath() + "/Teams/%1.hwt").arg(campaignTeam), QSettings::IniFormat, 0);
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

    QSettings teamfile(QString(cfgdir->absolutePath() + "/Teams/%1.hwt").arg(campaignTeam), QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    teamfile.setValue("Campaign " + campaign + "/" + varToWrite, varValue);
}

void HWGame::sendMissionVar(const QByteArray &varToSend)
{
    QString varToFind = QString::fromUtf8(varToSend);
    QSettings teamfile(QString(cfgdir->absolutePath() + "/Teams/%1.hwt").arg(trainingTeam), QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    QString varValue = teamfile.value("Mission " + trainingName + "/" + varToFind, "").toString();
    QByteArray command;
    HWProto::addStringToBuffer(command, "v." + varValue);
    RawSendIPC(command);
}

void HWGame::writeMissionVar(const QByteArray & varVal)
{
    int i = varVal.indexOf(" ");
    if(i < 0)
        return;

    QString varToWrite = QString::fromUtf8(varVal.left(i));
    QString varValue = QString::fromUtf8(varVal.mid(i + 1));

    QSettings teamfile(QString(cfgdir->absolutePath() + "/Teams/%1.hwt").arg(trainingTeam), QSettings::IniFormat, 0);
    teamfile.setIniCodec("UTF-8");
    teamfile.setValue("Mission " + trainingName + "/" + varToWrite, varValue);
}

