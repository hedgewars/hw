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

#include <algorithm>

#include <QLabel>
#include <QPixmap>
#include <QPushButton>
#include <QFrame>
#include <QDebug>

#include "vertScrollArea.h"
#include "teamselect.h"
#include "teamselhelper.h"
#include "frameTeam.h"

void TeamSelWidget::addTeam(HWTeam team)
{
    if(team.isNetTeam())
    {
        framePlaying->addTeam(team, true);
        curPlayingTeams.push_back(team);
        connect(framePlaying->getTeamWidget(team), SIGNAL(hhNmChanged(const HWTeam&)),
                this, SLOT(hhNumChanged(const HWTeam&)));
        blockSignals(true);
        dynamic_cast<TeamShowWidget*>(framePlaying->getTeamWidget(team))->hhNumChanged();
        blockSignals(false);
        connect(framePlaying->getTeamWidget(team), SIGNAL(teamColorChanged(const HWTeam&)),
                this, SLOT(proxyTeamColorChanged(const HWTeam&)));

        // Hide team notice if at least two teams.
        if (curPlayingTeams.size() >= 2)
        {
            numTeamNotice->hide();
        }
    }
    else
    {
        frameDontPlaying->addTeam(team, false);
        m_curNotPlayingTeams.push_back(team);
        if(m_acceptOuter)
        {
            connect(frameDontPlaying->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
                    this, SLOT(pre_changeTeamStatus(HWTeam)));
        }
        else
        {
            connect(frameDontPlaying->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
                    this, SLOT(changeTeamStatus(HWTeam)));
        }
    }

    emit setEnabledGameStart(curPlayingTeams.size()>1);
}

void TeamSelWidget::setInteractivity(bool interactive)
{
    framePlaying->setInteractivity(interactive);
}

void TeamSelWidget::hhNumChanged(const HWTeam& team)
{
    QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);
    if(itPlay==curPlayingTeams.end())
    {
        qWarning() << QString("hhNumChanged: team '%1' not found").arg(team.name());
        return;
    }
    itPlay->setNumHedgehogs(team.numHedgehogs());
    emit hhogsNumChanged(team);
}

void TeamSelWidget::proxyTeamColorChanged(const HWTeam& team)
{
    QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);
    if(itPlay==curPlayingTeams.end())
    {
        qWarning() << QString("proxyTeamColorChanged: team '%1' not found").arg(team.name());
        return;
    }
    itPlay->setColor(team.color());
    emit teamColorChanged(team);
}

void TeamSelWidget::changeHHNum(const HWTeam& team)
{
    QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);
    if(itPlay==curPlayingTeams.end())
    {
        qWarning() << QString("changeHHNum: team '%1' not found").arg(team.name());
        return;
    }
    itPlay->setNumHedgehogs(team.numHedgehogs());

    framePlaying->setHHNum(team);
}

void TeamSelWidget::changeTeamColor(const HWTeam& team)
{
    QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);
    if(itPlay==curPlayingTeams.end())
    {
        qWarning() << QString("changeTeamColor: team '%1' not found").arg(team.name());
        return;
    }
    itPlay->setColor(team.color());

    framePlaying->setTeamColor(team);
}

void TeamSelWidget::removeNetTeam(const HWTeam& team)
{
    //qDebug() << QString("removeNetTeam: removing team '%1'").arg(team.TeamName);
    QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);
    if(itPlay==curPlayingTeams.end())
    {
        qWarning() << QString("removeNetTeam: team '%1' not found").arg(team.name());
        return;
    }

    if(itPlay->isNetTeam())
    {
        QObject::disconnect(framePlaying->getTeamWidget(*itPlay), SIGNAL(teamStatusChanged(HWTeam)));
        framePlaying->removeTeam(team);
        curPlayingTeams.erase(itPlay);
        // Show team notice if less than two teams.
        if (curPlayingTeams.size() < 2)
        {
            numTeamNotice->show();
        }
    }
    else
    {
        qWarning() << QString("removeNetTeam: team '%1' was actually a local team!").arg(team.name());
    }
    emit setEnabledGameStart(curPlayingTeams.size()>1);
}

void TeamSelWidget::changeTeamStatus(HWTeam team)
{
    QList<HWTeam>::iterator itDontPlay=std::find(m_curNotPlayingTeams.begin(), m_curNotPlayingTeams.end(), team);
    QList<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);

    bool willBePlaying=itDontPlay!=m_curNotPlayingTeams.end();

    if(!willBePlaying)
    {
        // playing team => dont playing
        m_curNotPlayingTeams.push_back(*itPlay);
        emit teamNotPlaying(*itPlay);
        curPlayingTeams.erase(itPlay);

        // Show team notice if less than two teams.
        if (curPlayingTeams.size() < 2)
        {
            numTeamNotice->show();
        }
    }
    else
    {
        // return if max playing teams reached
        if(framePlaying->isFullTeams()) return;
        // dont playing team => playing
        itDontPlay->setColor(framePlaying->getNextColor());
        team=*itDontPlay; // for net team info saving in framePlaying (we have only name with netID from network)
        curPlayingTeams.push_back(*itDontPlay);
        if(!m_acceptOuter) emit teamWillPlay(*itDontPlay);
        m_curNotPlayingTeams.erase(itDontPlay);

        // Hide team notice if at least two teams.
        if (curPlayingTeams.size() >= 2)
        {
            numTeamNotice->hide();
        }
    }

    FrameTeams* pRemoveTeams;
    FrameTeams* pAddTeams;
    if(!willBePlaying)
    {
        pRemoveTeams=framePlaying;
        pAddTeams=frameDontPlaying;
    }
    else
    {
        pRemoveTeams=frameDontPlaying;
        pAddTeams=framePlaying;
    }

    pAddTeams->addTeam(team, willBePlaying);
    pRemoveTeams->removeTeam(team);
    if(!team.isNetTeam() && m_acceptOuter && !willBePlaying)
    {
        connect(frameDontPlaying->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
                this, SLOT(pre_changeTeamStatus(HWTeam)));
    }
    else
    {
        connect(pAddTeams->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
                this, SLOT(changeTeamStatus(HWTeam)));
    }
    if(willBePlaying)
    {
        connect(framePlaying->getTeamWidget(team), SIGNAL(hhNmChanged(const HWTeam&)),
                this, SLOT(hhNumChanged(const HWTeam&)));
        blockSignals(true);
        dynamic_cast<TeamShowWidget*>(framePlaying->getTeamWidget(team))->hhNumChanged();
        blockSignals(false);
        connect(framePlaying->getTeamWidget(team), SIGNAL(teamColorChanged(const HWTeam&)),
                this, SLOT(proxyTeamColorChanged(const HWTeam&)));
        emit teamColorChanged(((TeamShowWidget*)framePlaying->getTeamWidget(team))->getTeam());
    }

    QSize szh=pAddTeams->sizeHint();
    QSize szh1=pRemoveTeams->sizeHint();
    if(szh.isValid() && szh1.isValid())
    {
        pAddTeams->resize(pAddTeams->size().width(), szh.height());
        pRemoveTeams->resize(pRemoveTeams->size().width(), szh1.height());
    }

    repaint();

    emit setEnabledGameStart(curPlayingTeams.size()>1);
}

void TeamSelWidget::addScrArea(FrameTeams* pfteams, QColor color, int minHeight, int maxHeight, bool setFrame)
{
    VertScrArea* area = new VertScrArea(color);
    area->setWidget(pfteams);
    mainLayout.addWidget(area);
    if (minHeight > 0)
        area->setMinimumHeight(minHeight);
    if (maxHeight > 0)
        area->setMaximumHeight(maxHeight);
    if (setFrame)
    {
        area->setStyleSheet(
            "FrameTeams{"
            "border: solid;"
            "border-width: 1px;"
            "border-radius: 16px;"
            "border-color: #ffcc00;"
            "}"
        );
    }
}

TeamSelWidget::TeamSelWidget(QWidget* parent) :
    QGroupBox(parent), mainLayout(this), m_acceptOuter(false)
{
    setTitle(QGroupBox::tr("Playing teams"));
    framePlaying = new FrameTeams();
    frameDontPlaying = new FrameTeams();

    // Add notice about number of required teams.
    numTeamNotice = new QLabel(tr("At least two teams are required to play!"));
    numTeamNotice->setWordWrap(true);
    mainLayout.addWidget(numTeamNotice);

    QPalette p;
    p.setColor(QPalette::Window, QColor(0x00, 0x00, 0x00));
    addScrArea(framePlaying, p.color(QPalette::Window).light(105), 161, 325, true);
    addScrArea(frameDontPlaying, p.color(QPalette::Window).dark(105), 80, 0, false);

    this->setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Expanding);
    this->setMinimumWidth(200);
}

void TeamSelWidget::setAcceptOuter(bool acceptOuter)
{
    m_acceptOuter=acceptOuter;
}

void TeamSelWidget::resetPlayingTeams(const QList<HWTeam>& teamslist)
{
    //for(it=curPlayingTeams.begin(); it!=curPlayingTeams.end(); it++) {
    //framePlaying->removeTeam(*it);
    //}
    framePlaying->resetTeams();
    framePlaying->resetColors();
    curPlayingTeams.clear();
    //for(it=curDontPlayingTeams.begin(); it!=curDontPlayingTeams.end(); it++) {
    //frameDontPlaying->removeTeam(*it);
    //}
    frameDontPlaying->resetTeams();
    m_curNotPlayingTeams.clear();

    foreach(HWTeam team, teamslist)
        addTeam(team);

    numTeamNotice->show();

    repaint();
}

bool TeamSelWidget::isPlaying(const HWTeam &team) const
{
    return curPlayingTeams.contains(team);
}

QList<HWTeam> TeamSelWidget::getPlayingTeams() const
{
    return curPlayingTeams;
}

QList<HWTeam> TeamSelWidget::getNotPlayingTeams() const
{
    return m_curNotPlayingTeams;
}

unsigned short TeamSelWidget::getNumHedgehogs() const
{
    unsigned short numHogs = 0;
    QList<HWTeam>::const_iterator team;
    for(team = curPlayingTeams.begin(); team != curPlayingTeams.end(); ++team)
    {
        numHogs += (*team).numHedgehogs();
    }
    return numHogs;
}

void TeamSelWidget::pre_changeTeamStatus(const HWTeam & team)
{
    //team.setColor(framePlaying->getNextColor());
    emit acceptRequested(team);
}

void TeamSelWidget::repaint()
{
    QWidget::repaint();
    framePlaying->repaint();
    frameDontPlaying->repaint();
}
