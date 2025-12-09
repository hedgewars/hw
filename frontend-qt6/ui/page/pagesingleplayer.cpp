/*
 * Hedgewars, a free turn based strategy game
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

#include "pagesingleplayer.h"

#include <QGridLayout>
#include <QPushButton>

#include "gamecfgwidget.h"

QLayout* PageSinglePlayer::bodyLayoutDefinition() {
  QVBoxLayout* vLayout = new QVBoxLayout();

  QHBoxLayout* topLine = new QHBoxLayout();
  QHBoxLayout* middleLine = new QHBoxLayout();
  vLayout->addStretch();
  vLayout->addLayout(topLine);
  vLayout->addSpacing(30);
  vLayout->addLayout(middleLine);
  vLayout->addStretch();

  topLine->addStretch();
  BtnSimpleGamePage =
      addButton(QStringLiteral(":/res/SimpleGame.png"), topLine, 0, true);
  BtnSimpleGamePage->setWhatsThis(
      tr("Play a quick game against the computer with random settings"));
  topLine->addSpacing(60);
  BtnMultiplayer =
      addButton(QStringLiteral(":/res/Multiplayer.png"), topLine, 1, true);
  BtnMultiplayer->setWhatsThis(
      tr("Play a hotseat game against your friends, or AI teams"));
  topLine->addStretch();

  BtnCampaignPage =
      addButton(QStringLiteral(":/res/Campaign.png"), middleLine, 0, true);
  BtnCampaignPage->setWhatsThis(tr("Campaign Mode"));
  BtnCampaignPage->setVisible(true);

  BtnTrainPage =
      addButton(QStringLiteral(":/res/Trainings.png"), middleLine, 1, true);
  BtnTrainPage->setWhatsThis(
      tr("Singleplayer missions: Learn how to play in the training, practice "
         "your skills in challenges or try to complete goals in scenarios."));

  return vLayout;
}

QLayout* PageSinglePlayer::footerLayoutDefinition() {
  QHBoxLayout* bottomLine = new QHBoxLayout();
  bottomLine->addStretch();

  BtnDemos = addButton(QStringLiteral(":/res/Record.png"), bottomLine, 1, true);
  BtnDemos->setWhatsThis(tr("Watch recorded demos"));
  BtnLoad = addButton(QStringLiteral(":/res/Load.png"), bottomLine, 2, true);
  BtnLoad->setStyleSheet(QStringLiteral("QPushButton{margin: 24px 0 0 0;}"));
  BtnLoad->setWhatsThis(tr("Load a previously saved game"));

  bottomLine->setStretch(1, 0);
  bottomLine->setStretch(2, 0);
  bottomLine->setAlignment(BtnDemos, Qt::AlignRight | Qt::AlignBottom);
  bottomLine->setAlignment(BtnLoad, Qt::AlignRight | Qt::AlignBottom);

  return bottomLine;
}

void PageSinglePlayer::connectSignals() {
  // TODO
}

PageSinglePlayer::PageSinglePlayer(QWidget* parent) : AbstractPage(parent) {
  initPage();
}
