/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2009 Kristian Lehmann <email@thexception.net>
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

#include "togglebutton.h"

ToggleButtonWidget::ToggleButtonWidget(QWidget * parent, QString img)
{
    setCheckable(true);

    QPixmap pm(":/res/btnDisabled.png");
    QPainter * painter = new QPainter();

    pmChecked.load(img);
    pmDisabled.load(img);

    setMaximumWidth(pmChecked.width() + 6);

    painter->begin(&pmDisabled);
    painter->drawPixmap(pmDisabled.rect(), pm);
    painter->end();

    setIconSize(pmDisabled.size());
    setIcon(pmDisabled);

    connect(this, SIGNAL(toggled(bool)), this, SLOT(eventToggled(bool)));
}

ToggleButtonWidget::~ToggleButtonWidget()
{
}

void ToggleButtonWidget::eventToggled(bool checked)
{
    setIcon(checked ? pmChecked : pmDisabled);
}
