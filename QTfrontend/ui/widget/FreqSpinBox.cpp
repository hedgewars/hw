/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

/**
 * @file
 * @brief FreqSpinBox class implementation
 */

#include "FreqSpinBox.h"


FreqSpinBox::FreqSpinBox(QWidget* parent) : QSpinBox(parent)
{
    // do nothing
};


QString FreqSpinBox::textFromValue(int value) const
{
    if (value == 0)
        return tr("Never");
    else
        return tr("Every %1 turn", "", value).arg(value);
}
