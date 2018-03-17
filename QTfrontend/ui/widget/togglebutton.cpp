/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2009 Kristian Lehmann <email@thexception.net>
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

#include "togglebutton.h"

ToggleButtonWidget::ToggleButtonWidget(QWidget * parent, QString img)
    : QPushButton(parent)
{
    setCheckable(true);

    QPixmap pixOffOverlay(":/res/btnDisabled.png");
    QPainter * painter = new QPainter();

    QPixmap pixOn = QPixmap(img);
    QPixmap pixOff = QPixmap(img);

    // Use the same image for disabled (i.e. non-clickable) button.
    // The default would be gray which is a little bit hard on the eye.
    // The disabled state is communicated to the user by the button
    // border, which turns gray.
    icoChecked.addPixmap(pixOn, QIcon::Normal);
    icoChecked.addPixmap(pixOn, QIcon::Disabled);

    pixOff.setDevicePixelRatio(pixOffOverlay.devicePixelRatio());

    setMaximumWidth(pixOn.width() + 6);

    painter->begin(&pixOff);
    painter->drawPixmap(pixOff.rect(), pixOffOverlay);
    painter->end();

    icoUnchecked.addPixmap(pixOff, QIcon::Normal);
    icoUnchecked.addPixmap(pixOff, QIcon::Disabled);

    setIconSize(pixOff.size());
    setIcon(icoUnchecked);

    connect(this, SIGNAL(toggled(bool)), this, SLOT(eventToggled(bool)));
}

ToggleButtonWidget::~ToggleButtonWidget()
{
}

void ToggleButtonWidget::eventToggled(bool checked)
{
    setIcon(checked ? icoChecked : icoUnchecked);
}
