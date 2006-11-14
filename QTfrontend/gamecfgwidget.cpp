/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QResizeEvent>
#include <QGroupBox>
#include <QHBoxLayout>
#include "gamecfgwidget.h"

GameCFGWidget::GameCFGWidget(QWidget* parent) :
  QWidget(parent), mainLayout(this)
{
	mainLayout.setMargin(0);
	QGroupBox *GBoxMap = new QGroupBox(this);
	GBoxMap->setTitle(QGroupBox::tr("Landscape"));
	GBoxMap->setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum);
	mainLayout.addWidget(GBoxMap);

	QHBoxLayout *GBoxMapLayout = new QHBoxLayout(GBoxMap);
	GBoxMapLayout->setMargin(0);
	pMapContainer = new HWMapContainer(GBoxMap);
	GBoxMapLayout->addWidget(new QWidget);
	GBoxMapLayout->addWidget(pMapContainer);
	GBoxMapLayout->addWidget(new QWidget);

	QGroupBox *GBoxOptions = new QGroupBox(this);
	GBoxOptions->setTitle(QGroupBox::tr("Game scheme"));
	GBoxOptions->setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum);
	mainLayout.addWidget(GBoxOptions);

	QVBoxLayout *GBoxOptionsLayout = new QVBoxLayout(GBoxOptions);
	CB_mode_Forts = new QCheckBox(GBoxOptions);
	CB_mode_Forts->setText(QCheckBox::tr("Forts mode"));
	GBoxOptionsLayout->addWidget(CB_mode_Forts);

	mainLayout.addWidget(new QWidget, 100);
}

quint32 GameCFGWidget::getGameFlags()
{
	quint32 result = 0;
	if (CB_mode_Forts->isChecked())
		result |= 1;
	return result;
}

QString GameCFGWidget::getCurrentSeed() const
{
  return pMapContainer->getCurrentSeed();
}
