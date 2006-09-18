/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Ulyanov Igor <iulyanov@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
