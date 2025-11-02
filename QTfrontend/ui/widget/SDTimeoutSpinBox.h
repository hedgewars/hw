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
 * @brief SDTimeoutSpinBox class definition
 */

#ifndef HEDGEWARS_SDTIMEOUTSPINBOX_H
#define HEDGEWARS_SDTIMEOUTSPINBOX_H

#include <QObject>
#include <QSpinBox>

/**
 * <code>SpinBox</code> for Sudden Death timeout.
 * The internally stored Sudden Death timeout is different
 * from the actual number of rounds it takes until SD starts.
 * e.g. value 0 means SD starts in 2nd round
 * @author Wuzzy
 * @since  0.9.25
 */
class SDTimeoutSpinBox : public QSpinBox
{
        Q_OBJECT

    public:
        /**
         * @brief Class constructor.
         * @param parent parent widget.
         */
        SDTimeoutSpinBox(QWidget * parent);

    protected:
        /**
         * Returns its value in real number of rounds.
         * @param internal value integer value to be represented as string.
         * @return the real number of rounds
         */
        QString textFromValue(int value) const;
        /**
         * Returns the internally-used value for SD timeout.
         * @param user-facing string, i.e. real number of rounds
         * @return internally-stored SD timeout value
         */
        int valueFromText(const QString & text) const;
};


#endif // HEDGEWARS_SDTIMEOUTSPINBOX_H
