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

#ifndef _FRAME_TEAM_INCLUDED
#define _FRAME_TEAM_INCLUDED

#include <QWidget>
#include <QList>
#include <QColor>

#include "teamselect.h"
#include <map>

class FrameTeams : public QWidget
{
  Q_OBJECT

 friend class CHedgehogerWidget;
 friend class TeamShowWidget;

 public:
  FrameTeams(QWidget* parent=0);
  QWidget* getTeamWidget(HWTeam team);
  bool isFullTeams() const;
  void resetColors();

 public slots:
  void addTeam(HWTeam team, bool willPlay);
  void removeTeam(HWTeam team);

 private:
  const int maxHedgehogsPerGame;
  int overallHedgehogs;
  QList<QColor> availableColors;
  QList<QColor>::Iterator currentColor;
    
  QVBoxLayout mainLayout;
  typedef map<HWTeam, QWidget*> tmapTeamToWidget;
  tmapTeamToWidget teamToWidget;
};

#endif // _FRAME_TAM_INCLUDED
