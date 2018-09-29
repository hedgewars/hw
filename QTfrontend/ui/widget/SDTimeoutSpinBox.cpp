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

/**
 * @file
 * @brief SDTimeoutSpinBox class implementation
 */

#include "SDTimeoutSpinBox.h"

SDTimeoutSpinBox::SDTimeoutSpinBox(QWidget* parent) : QSpinBox(parent)
{
    // do nothing
};


QString SDTimeoutSpinBox::textFromValue(int internalValue) const
{
    // user-facing value = internal value + 1
    return QString::number(internalValue + 1);
}

int SDTimeoutSpinBox::valueFromText(const QString & userFacingString) const
{
    // internal value = user-facing value - 1
    bool ok;
    int value = userFacingString.toInt(&ok);

    if (ok)
        return value - 1;
    // Fallback
    else
        return 15;
}
