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

#include <QPixmap>
#include <QPainter>
#include <QStyleFactory>
#include <QDebug>

#include <algorithm>

#include "teamselhelper.h"
#include "hwconsts.h"
#include "frameTeam.h"
#include "colorwidget.h"
#include "DataManager.h"

void TeamLabel::teamButtonClicked()
{
    emit teamActivated(text());
}

TeamShowWidget::TeamShowWidget(const HWTeam & team, bool isPlaying, FrameTeams * parent) :
    QWidget(parent), mainLayout(this), m_team(team), m_isPlaying(isPlaying), phhoger(0),
    colorWidget(0)
{
    m_parentFrameTeams = parent;
    QPalette newPalette = palette();
    newPalette.setColor(QPalette::Window, QColor(0x00, 0x00, 0x00));
    setPalette(newPalette);
    setAutoFillBackground(true);

    mainLayout.setSpacing(3);
    mainLayout.setMargin(0);
    this->setMaximumHeight(38);
    this->setMinimumHeight(38);
    QIcon difficultyIcon=team.isNetTeam() ?
                         QIcon(QString(":/res/botlevels/net%1.png").arg(m_team.difficulty()))
                         : QIcon(QString(":/res/botlevels/%1.png").arg(m_team.difficulty()));

    butt = new QPushButton(difficultyIcon, team.name().replace("&","&&"), this);
    butt->setFlat(true);
    butt->setToolTip(team.owner());
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

    if(m_isPlaying)
    {
        // team color
        colorWidget = new ColorWidget(DataManager::instance().colorsModel(), this);
        colorWidget->setMinimumWidth(26);
        colorWidget->setMaximumWidth(26);
        colorWidget->setMinimumHeight(26);
        colorWidget->setMaximumHeight(26);
        colorWidget->setColor(team.color());
        connect(colorWidget, SIGNAL(colorChanged(int)), this, SLOT(onColorChanged(int)));
        mainLayout.addWidget(colorWidget);

        phhoger = new CHedgehogerWidget(QImage(":/res/hh25x25.png"), QImage(":/res/hh25x25grey.png"), this);
        connect(phhoger, SIGNAL(hedgehogsNumChanged()), this, SLOT(hhNumChanged()));
        phhoger->setHHNum(team.numHedgehogs());
        mainLayout.addWidget(phhoger);
    }
    else
    {
    }

    QObject::connect(butt, SIGNAL(clicked()), this, SLOT(activateTeam()));
    //QObject::connect(bText, SIGNAL(clicked()), this, SLOT(activateTeam()));
}

void TeamShowWidget::setInteractivity(bool interactive)
{
    if(m_team.isNetTeam())
    {
        butt->setEnabled(interactive);
    }

    colorWidget->setEnabled(interactive);
    phhoger->setEnabled(interactive);
}

void TeamShowWidget::setHHNum(unsigned int num)
{
    phhoger->setHHNum(num);
}

void TeamShowWidget::hhNumChanged()
{
    m_team.setNumHedgehogs(phhoger->getHedgehogsNum());
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


void TeamShowWidget::changeTeamColor(int color)
{
    colorWidget->setColor(color);
}

void TeamShowWidget::onColorChanged(int color)
{
    m_team.setColor(color);

    emit teamColorChanged(m_team);
}

HWTeam TeamShowWidget::getTeam() const
{
    return m_team;
}
