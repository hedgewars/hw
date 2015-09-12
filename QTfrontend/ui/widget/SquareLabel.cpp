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

#include <QPaintEvent>
#include <QPainter>
#include "SquareLabel.h"
#include "hwform.h"

SquareLabel::SquareLabel(QWidget * parent) :
    QWidget(parent)
{
    //if(frontendEffects) setAttribute(Qt::WA_PaintOnScreen, true);
}

void SquareLabel::paintEvent(QPaintEvent * event)
{
    Q_UNUSED(event);

    QPainter painter(this);
    int pixsize;
    if (width() > height())
    {
        pixsize = height();
        painter.translate((width() - pixsize) / 2, 0);
    }
    else
    {
        pixsize = width();
        painter.translate(0, (height() - pixsize) / 2);
    }
    painter.drawPixmap(0, 0, pixsize, pixsize, pixmap.scaled(pixsize, pixsize, Qt::KeepAspectRatio));
}

void SquareLabel::setPixmap(const QPixmap & pixmap)
{
    this->pixmap = pixmap;
    repaint();
}
