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
 * @brief MinesTimeSpinBox class definition
 */

#ifndef HEDGEWARS_MINESTIMESPINBOX_H
#define HEDGEWARS_MINESTIMESPINBOX_H

#include <QObject>
#include <QSpinBox>

/**
 * <code>SpinBox</code> that returns its value as localized mines time.
 * @since  0.9.23
 */
class MinesTimeSpinBox : public QSpinBox
{
        Q_OBJECT

    public:
        /**
         * @brief Class constructor.
         * @param parent parent widget.
         */
        MinesTimeSpinBox(QWidget * parent);

    protected:
        /**
         * Returns it's value localized.
         * @param value integer value to be representing as string.
         * @return string representation
         */
        QString textFromValue(int value) const;
};


#endif // HEDGEWARS_MINESTIMESPINBOX_H
