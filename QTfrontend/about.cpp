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

#include <QGridLayout>
#include <QSvgWidget>
#include "about.h"

About::About(QWidget * parent) :
  QWidget(parent)
{
	QGridLayout *mainLayout = new QGridLayout(this);
	QSvgWidget *hedgehog = new QSvgWidget(":/res/Hedgehog.svg", this);
	hedgehog->setFixedSize(300, 329);
	mainLayout->addWidget(hedgehog);
}
