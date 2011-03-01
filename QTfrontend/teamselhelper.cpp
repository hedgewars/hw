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

#include <QPixmap>
#include <QPainter>
#include <QStyleFactory>

#include <algorithm>

#include "teamselhelper.h"
#include "hwconsts.h"
#include "frameTeam.h"

void TeamLabel::teamButtonClicked()
{
  emit teamActivated(text());
}

TeamShowWidget::TeamShowWidget(HWTeam team, bool isPlaying, QWidget * parent) :
  QWidget(parent), mainLayout(this), m_team(team), m_isPlaying(isPlaying), phhoger(0),
  colorButt(0)
{
    QPalette newPalette = palette();
    newPalette.setColor(QPalette::Window, QColor(0x00, 0x00, 0x00));
    setPalette(newPalette);
    setAutoFillBackground(true);

    mainLayout.setSpacing(3);
    mainLayout.setMargin(0);
    this->setMaximumHeight(38);
    this->setMinimumHeight(38);
    QIcon difficultyIcon=team.isNetTeam() ?
        QIcon(QString(":/res/botlevels/net%1.png").arg(m_team.difficulty))
        : QIcon(QString(":/res/botlevels/%1.png").arg(m_team.difficulty));

    butt = new QPushButton(difficultyIcon, team.TeamName, this);
    butt->setFlat(true);
    butt->setToolTip(team.Owner);
    mainLayout.addWidget(butt);
    butt->setStyleSheet("QPushButton{"
            "icon-size: 48px;"
            "text-align: left;"
            "background-color: #0d0544;"
            "color: orange;"
            "font: bold;"
            "border-width: 2px;"
            "margin: 6px 0px 6px 0px;"
            "}");

    if(m_isPlaying) {
        // team color
        colorButt = new QPushButton(this);
        colorButt->setMaximumWidth(26);
        colorButt->setMinimumHeight(26);
        colorButt->setGeometry(0, 0, 26, 26);

        changeTeamColor();
        connect(colorButt, SIGNAL(clicked()), this, SLOT(changeTeamColor()));
        mainLayout.addWidget(colorButt);

        phhoger = new CHedgehogerWidget(QImage(":/res/hh25x25.png"), QImage(":/res/hh25x25grey.png"), this);
        connect(phhoger, SIGNAL(hedgehogsNumChanged()), this, SLOT(hhNumChanged()));
        phhoger->setHHNum(team.numHedgehogs);
        mainLayout.addWidget(phhoger);
    } else {
    }

    QObject::connect(butt, SIGNAL(clicked()), this, SLOT(activateTeam()));
    //QObject::connect(bText, SIGNAL(clicked()), this, SLOT(activateTeam()));
}

void TeamShowWidget::setInteractivity(bool interactive)
{
    if(m_team.isNetTeam()) {
        butt->setEnabled(interactive);
    }

    colorButt->setEnabled(interactive);
    phhoger->setEnabled(interactive);
}

void TeamShowWidget::setHHNum(unsigned int num)
{
  phhoger->setHHNum(num);
}

void TeamShowWidget::hhNumChanged()
{
  m_team.numHedgehogs=phhoger->getHedgehogsNum();
  emit hhNmChanged(m_team);
}

void TeamShowWidget::activateTeam()
{
  emit teamStatusChanged(m_team);
}

/*HWTeamTempParams TeamShowWidget::getTeamParams() const
{
  if(!phhoger) throw;
  HWTeamTempParams params;
  params.numHedgehogs=phhoger->getHedgehogsNum();
  params.teamColor=colorButt->palette().color(QPalette::Button);
  return params;
}*/

void TeamShowWidget::changeTeamColor(QColor color)
{
    FrameTeams* pOurFrameTeams=dynamic_cast<FrameTeams*>(parentWidget());
    if(!color.isValid()) {
        if(++pOurFrameTeams->currentColor==pOurFrameTeams->availableColors.end()) {
            pOurFrameTeams->currentColor=pOurFrameTeams->availableColors.begin();
        }
        color=*pOurFrameTeams->currentColor;
    } else {
        // set according color iterator
        pOurFrameTeams->currentColor=std::find(pOurFrameTeams->availableColors.begin(),
                pOurFrameTeams->availableColors.end(), color);
        if(pOurFrameTeams->currentColor==pOurFrameTeams->availableColors.end()) {
            // error condition
            pOurFrameTeams->currentColor=pOurFrameTeams->availableColors.begin();
        }
    }

    colorButt->setStyleSheet(QString("QPushButton{"
            "background-color: %1;"
            "border-width: 1px;"
            "border-radius: 2px;"
            "}").arg(pOurFrameTeams->currentColor->name()));

    m_team.teamColor=color;
    emit teamColorChanged(m_team);
}

HWTeam TeamShowWidget::getTeam() const
{
  return m_team;
}
