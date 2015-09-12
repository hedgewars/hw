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

#ifndef _FRAME_TEAM_INCLUDED
#define _FRAME_TEAM_INCLUDED

#include <QFrame>
#include <QList>
#include <QColor>

#include "teamselect.h"

class FrameTeams : public QFrame
{
        Q_OBJECT

        friend class CHedgehogerWidget;
        friend class TeamShowWidget;

    public:
        FrameTeams(QWidget* parent=0);
        QWidget* getTeamWidget(HWTeam team);
        bool isFullTeams() const;
        void resetColors();
        void resetTeams();
        void setHHNum(const HWTeam& team);
        void setTeamColor(const HWTeam& team);
        void setInteractivity(bool interactive);
        int getNextColor();
        QSize sizeHint() const;

    signals:
        void teamColorChanged(const HWTeam&);

    public slots:
        void addTeam(HWTeam team, bool willPlay);
        void removeTeam(HWTeam team);

    private:
        int currentColor;

        void emitTeamColorChanged(const HWTeam& team);

        QVBoxLayout mainLayout;
        typedef QMap<HWTeam, QWidget*> tmapTeamToWidget;
        tmapTeamToWidget teamToWidget;
        bool nonInteractive;
};

#endif // _FRAME_TAM_INCLUDED
