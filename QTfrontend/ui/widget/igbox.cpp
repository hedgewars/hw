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

#include <QPainter>
#include <QPoint>
#include <QStylePainter>
#include <QStyleOptionGroupBox>

#include "igbox.h"

IconedGroupBox::IconedGroupBox(QWidget * parent)
    : QGroupBox(parent)
{
// Has issues with border-radius on children
//    setAttribute(Qt::WA_PaintOnScreen, true);
    titleLeftPadding = 49;
    contentTopPadding = 5;
}

void IconedGroupBox::setIcon(const QIcon & icon)
{
    if (this->icon.isNull())
        setStyleSheet(QString(
                          "IconedGroupBox{"
                          "margin-top: 46px;"
                          "margin-left: 12px;"
                          "padding: %1px 2px 5px 2px;"
                          "}"
                          "IconedGroupBox::title{"
                          "subcontrol-origin: margin;"
                          "subcontrol-position: top left;"
                          "padding-left: %2px;"
                          "padding-top: 15px;"
                          "text-align: left;"
                          "}"
                      ).arg(contentTopPadding).arg(titleLeftPadding)
                     );

    this->icon = icon;
    repaint();
}

void IconedGroupBox::paintEvent(QPaintEvent * event)
{
    Q_UNUSED(event);

    QStylePainter painter(this);

    QStyleOptionGroupBox option;
    initStyleOption(&option);
    painter.drawComplexControl(QStyle::CC_GroupBox, option);

    icon.paint(&painter, QRect(QPoint(0, 0), icon.actualSize(size())));
}

void IconedGroupBox::setTitleTextPadding(int px)
{
    titleLeftPadding = px;
}

void IconedGroupBox::setContentTopPadding(int px)
{
    contentTopPadding = px;
}
