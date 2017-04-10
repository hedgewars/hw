/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2007 Igor Ulyanov <iulyanov@gmail.com>
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

#ifndef _TEAM_SELECT_INCLUDED
#define _TEAM_SELECT_INCLUDED

#include <QLabel>
#include <QGroupBox>
#include <QVBoxLayout>
#include <QColor>
#include <QMultiMap>

#include "team.h"

class TeamSelWidget;
class FrameTeams;
class QFrame;
class QPushButton;

using namespace std;

class TeamSelWidget : public QGroupBox
{
        Q_OBJECT

    public:
        TeamSelWidget(QWidget* parent);
        void setAcceptOuter(bool acceptOuter);
        void removeNetTeam(const HWTeam& team);
        void resetPlayingTeams(const QList<HWTeam>& teamslist);
        bool isPlaying(const HWTeam &team) const;
        QList<HWTeam> getPlayingTeams() const;
        QList<HWTeam> getNotPlayingTeams() const;
	unsigned short getNumHedgehogs() const;
        void setInteractivity(bool interactive);

    public slots:
        void addTeam(HWTeam team);
        void changeHHNum(const HWTeam&);
        void changeTeamColor(const HWTeam&);
        void changeTeamStatus(HWTeam team);

    signals:
        void setEnabledGameStart(bool);
        void teamWillPlay(const HWTeam& team);
        void teamNotPlaying(const HWTeam& team);
        void hhogsNumChanged(const HWTeam&);
        void teamColorChanged(const HWTeam&);
        void acceptRequested(const HWTeam& team);

    private slots:
        void pre_changeTeamStatus(const HWTeam&);
        void hhNumChanged(const HWTeam& team);
        void proxyTeamColorChanged(const HWTeam& team);

    private:
        void addScrArea(FrameTeams* pfteams, QColor color, int maxHeight);
        FrameTeams* frameDontPlaying;
        FrameTeams* framePlaying;

        QVBoxLayout mainLayout;
        QLabel *numTeamNotice;
        bool m_acceptOuter;
        void repaint();

        QList<HWTeam> curPlayingTeams;
        QList<HWTeam> m_curNotPlayingTeams;
};

#endif // _TEAM_SELECT_INCLUDED
