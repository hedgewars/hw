/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2008 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QPainter>
#include <QPoint>
#include "igbox.h"

IconedGroupBox::IconedGroupBox(QWidget * parent)
{

}

void IconedGroupBox::setIcon(const QIcon & icon)
{
	this->icon = icon;
}

void IconedGroupBox::paintEvent(QPaintEvent * event)
{
	QPainter painter(this);

	icon.paint(&painter, QRect(QPoint(0, 0), size()));
}
