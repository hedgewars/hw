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

#ifndef _TEAMSEL_HELPER_INCLUDED
#define _TEAMSEL_HELPER_INCLUDED

#include <QLabel>
#include <QPushButton>
#include <QString>
#include <QWidget>

#include "hedgehogerWidget.h"
#include "teamselect.h"

class ColorWidget;

class TeamLabel : public QLabel {
  Q_OBJECT

 public:
  explicit TeamLabel(const QString& inp_str) : QLabel(inp_str) {};

 Q_SIGNALS:
  void teamActivated(QString team_name);

 public Q_SLOTS:
  void teamButtonClicked();
};

class TeamShowWidget : public QWidget {
  Q_OBJECT

 public Q_SLOTS:
  void changeTeamColor(int color = 0);
  void hhNumChanged();

 private Q_SLOTS:
  void activateTeam();
  void onColorChanged(int color);

 public:
  TeamShowWidget(const HWTeam& team, bool isPlaying, FrameTeams* parent);
  void setPlaying(bool isPlaying);
  void setHHNum(unsigned int num);
  void setInteractivity(bool interactive);
  HWTeam getTeam() const;

 private:
  TeamShowWidget();
  QHBoxLayout mainLayout;
  HWTeam m_team;
  bool m_isPlaying;
  QPointer<CHedgehogerWidget> phhoger;
  QPointer<ColorWidget> colorWidget;
  QPointer<QPushButton> butt;
  QPointer<FrameTeams> m_parentFrameTeams;

 Q_SIGNALS:
  void teamStatusChanged(const HWTeam&);
  void hhNmChanged(const HWTeam&);
  void teamColorChanged(const HWTeam&);
};

#endif  // _TEAMSEL_HELPER_INCLUDED
