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
#include "gamecfgwidget.h"

GameCFGWidget::GameCFGWidget(QWidget* parent) : 
  QWidget(parent), mainLayout(this)
{
	CB_mode_Forts = new QCheckBox(this);
	CB_mode_Forts->setText(QCheckBox::tr("Forts mode"));
	mainLayout.addWidget(CB_mode_Forts);
	pMapContainer=new HWMapContainer(this);
	mainLayout.addWidget(pMapContainer, 80);
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
