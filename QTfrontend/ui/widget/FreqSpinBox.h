/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef FREQSPINBOX_H
#define FREQSPINBOX_H


#include <QObject>
#include <QSpinBox>

/**
 * A SpinBox that returns it's value as localized turn frequency.
 * 'Never', 'Every Turn', 'Every 2 Turns', etc.
 * @author unc0rr
 * @since  0.9.12
 */
class FreqSpinBox : public QSpinBox
{
    Q_OBJECT

public:
    FreqSpinBox(QWidget* parent) : QSpinBox(parent) {};

protected:
    QString textFromValue(int value) const;
};


#endif // FREQSPINBOX_H
