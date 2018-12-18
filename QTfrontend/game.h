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

#ifndef GAME_H
#define GAME_H

#include <QString>
#include "team.h"
#include "namegen.h"

#include "tcpBase.h"

class GameUIConfig;
class GameCFGWidget;
class TeamSelWidget;

enum GameType
{
    gtNone     = 0,
    gtLocal    = 1,
    gtQLocal   = 2,
    gtDemo     = 3,
    gtNet      = 4,
    gtTraining = 5,
    gtCampaign = 6,
    gtSave     = 7,
};

enum GameState
{
    gsNotStarted = 0,
    gsStarted  = 1,
    gsInterrupted = 2,
    gsFinished = 3,
    gsStopped = 4,
    gsDestroyed = 5,
    gsHalted = 6
};

enum RecordType
{
    rtDemo,
    rtSave,
    rtNeither,
};

bool checkForDir(const QString & dir);

// last game info
extern QList<QVariant> lastGameStartArgs;
extern GameType lastGameType;
extern GameCFGWidget * lastGameCfg;
extern QString lastGameAmmo;
extern TeamSelWidget * lastGameTeamSel;

class HWGame : public TCPBase
{
        Q_OBJECT
    public:
        HWGame(GameUIConfig * config, GameCFGWidget * gamecfg, QString ammo, TeamSelWidget* pTeamSelWidget = 0);
        virtual ~HWGame();
        void AddTeam(const QString & team);
        void PlayDemo(const QString & demofilename, bool isSave);
        void StartLocal();
        void StartQuick();
        void StartNet();
        void StartTraining(const QString & file, const QString & subFolder, const QString & trainTeam);
        void StartCampaign(const QString & camp, const QString & campScript, const QString & campTeam);
        void abort();
        GameState gameState;
        bool netSuspend;

    protected:
        virtual QStringList getArguments();
        virtual void onClientRead();
        virtual void onClientDisconnect();

    signals:
        void SendNet(const QByteArray & msg);
        void SendChat(const QString & msg);
        void SendTeamMessage(const QString & msg);
        void GameStateChanged(GameState gameState);
        void GameStats(char type, const QString & info);
        void HaveRecord(RecordType type, const QByteArray & record);
        void ErrorMessage(const QString &);
        void CampStateChanged(int);
        void SendConsoleCommand(const QString & command);

    public slots:
        void FromNet(const QByteArray & msg);
        void FromNetChat(const QString & msg);
        void FromNetWarning(const QString & msg);
        void FromNetError(const QString & msg);

    private:
        char msgbuf[MAXMSGCHARS];
        QString ammostr;
        GameUIConfig * config;
        GameCFGWidget * gamecfg;
        TeamSelWidget* m_pTeamSelWidget;
        GameType gameType;
        QByteArray m_netSendBuffer;

        void commonConfig();
        void SendConfig();
        void SendQuickConfig();
        void SendNetConfig();
        void SendTrainingConfig();
        void SendCampaignConfig();
        void ParseMessage(const QByteArray & msg);
        void SetGameState(GameState state);
        void sendCampaignVar(const QByteArray & varToSend);
        void writeCampaignVar(const QByteArray &varVal);
        void sendMissionVar(const QByteArray & varToSend);
        void writeMissionVar(const QByteArray &varVal);
        void flushNetBuffer();
};

#endif
