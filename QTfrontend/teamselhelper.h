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

#ifndef _TEAMSEL_HELPER_INCLUDED
#define _TEAMSEL_HELPER_INCLUDED

#include <QLabel>
#include <QWidget>
#include <QString>

#include "teamselect.h"
#include "hedgehogerWidget.h"

class TeamLabel : public QLabel
{
 Q_OBJECT

 public:
 TeamLabel(const QString& inp_str) : QLabel(inp_str) {};

 signals:
 void teamActivated(QString team_name);

 public slots:
 void teamButtonClicked();

};

class TeamShowWidget : public QWidget
{
 Q_OBJECT

 private slots:
 void activateTeam();

 public:
 TeamShowWidget(HWTeam team, bool isPlaying, QWidget * parent);
 void setPlaying(bool isPlaying);
 unsigned char getHedgehogsNum() const;
 
 private:
 TeamShowWidget();
 QHBoxLayout mainLayout;
 HWTeam m_team;
 bool m_isPlaying;
 CHedgehogerWidget* phhoger;

 signals:
 void teamStatusChanged(HWTeam team);
};

#endif // _TEAMSEL_HELPER_INCLUDED
