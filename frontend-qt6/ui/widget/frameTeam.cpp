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

#include "frameTeam.h"

#include <QCoreApplication>
#include <QPalette>
#include <QResizeEvent>
#include <QStandardItemModel>

#include "DataManager.h"
#include "hwconsts.h"
#include "teamselhelper.h"

FrameTeams::FrameTeams(QWidget* parent)
    : QFrame(parent),
      mainLayout(this),
      nonInteractive(false),
      hasDecoFrame(false) {
  QPalette newPalette = palette();
  newPalette.setColor(QPalette::Window, QColor(0x00, 0x00, 0x00));
  setPalette(newPalette);
  setAutoFillBackground(true);

  mainLayout.setSpacing(1);
  mainLayout.setContentsMargins(4, 4, 4, 4);

  resetColors();
  this->setSizePolicy(QSizePolicy::Maximum, QSizePolicy::Fixed);
}

void FrameTeams::setInteractivity(bool interactive) {
  nonInteractive = !interactive;
  for (auto it = teamToWidget.cbegin(); it != teamToWidget.cend(); ++it) {
    TeamShowWidget* pts = qobject_cast<TeamShowWidget*>(it.value());
    Q_ASSERT(pts != nullptr);
    pts->setInteractivity(interactive);
  }
}

void FrameTeams::resetColors() {
  currentColor = DataManager::instance().colorsModel()->rowCount() -
                 1;  // ensure next color is the first one
}

int FrameTeams::getNextColor() {
  currentColor =
      (currentColor + 1) % DataManager::instance().colorsModel()->rowCount();
  return currentColor;
}

void FrameTeams::addTeam(const HWTeam& team, bool willPlay) {
  TeamShowWidget* pTeamShowWidget = new TeamShowWidget(team, willPlay, this);
  if (nonInteractive) pTeamShowWidget->setInteractivity(false);
  //  int hght=teamToWidget.empty() ? 0 :
  //  teamToWidget.begin()->second->size().height();
  mainLayout.addWidget(pTeamShowWidget);
  teamToWidget.insert(team, pTeamShowWidget);
  QResizeEvent* pevent =
      new QResizeEvent(parentWidget()->size(), parentWidget()->size());
  updateDecoFrame();
  QCoreApplication::postEvent(parentWidget(), pevent);
}

void FrameTeams::removeTeam(const HWTeam& team) {
  auto it = teamToWidget.constFind(team);
  if (it == teamToWidget.end()) return;
  mainLayout.removeWidget(it.value());
  it.value()->deleteLater();
  teamToWidget.erase(it);
  QResizeEvent* pevent =
      new QResizeEvent(parentWidget()->size(), parentWidget()->size());
  updateDecoFrame();
  QCoreApplication::postEvent(parentWidget(), pevent);
}

void FrameTeams::resetTeams() {
  for (auto it = teamToWidget.cbegin(); it != teamToWidget.cend();) {
    mainLayout.removeWidget(it.value());
    it.value()->deleteLater();
    teamToWidget.erase(it++);
  }
  QResizeEvent* pevent =
      new QResizeEvent(parentWidget()->size(), parentWidget()->size());
  updateDecoFrame();
  QCoreApplication::postEvent(parentWidget(), pevent);
}

void FrameTeams::setHHNum(const HWTeam& team) {
  TeamShowWidget* pTeamShowWidget =
      dynamic_cast<TeamShowWidget*>(getTeamWidget(team));
  if (!pTeamShowWidget) return;
  pTeamShowWidget->setHHNum(team.numHedgehogs());
}

void FrameTeams::setTeamColor(const HWTeam& team) {
  TeamShowWidget* pTeamShowWidget =
      dynamic_cast<TeamShowWidget*>(getTeamWidget(team));
  if (!pTeamShowWidget) return;
  pTeamShowWidget->changeTeamColor(team.color());
}

QWidget* FrameTeams::getTeamWidget(const HWTeam& team) {
  // qDebug() << "FrameTeams::getTeamWidget getNetID() = " << team.getNetID();
  auto it = teamToWidget.constFind(team);
  QWidget* ret = it != teamToWidget.end() ? it.value() : 0;
  return ret;
}

bool FrameTeams::isFullTeams() const {
  return teamToWidget.size() >= cMaxTeams;
}

void FrameTeams::emitTeamColorChanged(const HWTeam& team) {
  Q_EMIT teamColorChanged(team);
}

QSize FrameTeams::sizeHint() const {
  return QSize(-1, teamToWidget.size() * 39 + 9);
}

void FrameTeams::setDecoFrameEnabled(bool enabled) {
  hasDecoFrame = enabled;
  updateDecoFrame();
}

void FrameTeams::updateDecoFrame() {
  if (hasDecoFrame && teamToWidget.size() >= 1) {
    setStyleSheet(
        "FrameTeams{"
        "border-top: transparent;"
        "border-left: transparent;"
        "border-right: transparent;"
        "border-bottom: solid;"
        "border-width: 1px;"
        "border-color: #ffcc00;"
        "}");
  } else {
    setStyleSheet(QStringLiteral("FrameTeams{ border: transparent }"));
  }
}

void FrameTeams::resizeEvent(QResizeEvent* event) {
  Q_UNUSED(event);

  QResizeEvent* pevent =
      new QResizeEvent(parentWidget()->size(), parentWidget()->size());
  QCoreApplication::postEvent(parentWidget(), pevent);
}
