/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2007 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2007-2011 Andrey Korotaev <unC0Rr@gmail.com>
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
#include <QPushButton>

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

 public slots:
 void changeTeamColor(QColor color=QColor());
 void hhNumChanged();

 private slots:
 void activateTeam();

 public:
 TeamShowWidget(HWTeam team, bool isPlaying, QWidget * parent);
 void setPlaying(bool isPlaying);
 void setHHNum(unsigned int num);
 void setInteractivity(bool interactive);
 HWTeam getTeam() const;

 private:
 TeamShowWidget();
 QHBoxLayout mainLayout;
 HWTeam m_team;
 bool m_isPlaying;
 CHedgehogerWidget* phhoger;
 QPushButton* colorButt;
 QPushButton* butt;
// QPushButton* bText;

 signals:
 void teamStatusChanged(HWTeam team);
 void hhNmChanged(const HWTeam&);
 void teamColorChanged(const HWTeam&);
};

#endif // _TEAMSEL_HELPER_INCLUDED
