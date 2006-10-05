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

#ifndef _TEAM_SELECT_INCLUDED
#define _TEAM_SELECT_INCLUDED

#include <QWidget>
#include <QVBoxLayout>
class QFrame;

#include <list>
#include <map>

#include "team.h"

class TeamSelWidget;
class FrameTeams;

using namespace std;

class TeamSelWidget : public QWidget
{
  Q_OBJECT
 
 public:
  TeamSelWidget(QWidget* parent=0);
  void addTeam(HWTeam team);
  //void removeTeam(HWTeam team);
  void resetPlayingTeams(const QStringList& teamslist);
  bool isPlaying(HWTeam team) const;
  unsigned char numHedgedogs(HWTeam team) const;
  list<HWTeam> getPlayingTeams() const;

private slots:
  void changeTeamStatus(HWTeam team);

 private:
  void addScrArea(FrameTeams* pfteams, QColor color);
  FrameTeams* frameDontPlaying;
  FrameTeams* framePlaying;

  QVBoxLayout mainLayout;

  list<HWTeam> curPlayingTeams;
  list<HWTeam> curDontPlayingTeams;
};

#endif // _TEAM_SELECT_INCLUDED
