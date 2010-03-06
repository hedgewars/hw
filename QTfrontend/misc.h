/*
 * Hedgewars, a free turn based strategy game
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

#ifndef _MISC_H
#define _MISC_H


#include <QObject>
#include <QSpinBox>

class FreqSpinBox : public QSpinBox
{
    Q_OBJECT

public:
    FreqSpinBox(QWidget* parent) : QSpinBox(parent)
    {

    }

    QString textFromValue(int value) const
    {
        if (!value)
            return tr("Never");
        else
            return tr("Every %1 turn", "", value).arg(value);
    }
};


#endif // _MISC_H
