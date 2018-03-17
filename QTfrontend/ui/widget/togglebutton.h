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

#ifndef TOGGLEBUTTONWIDGET_H
#define TOGGLEBUTTONWIDGET_H

#include <QWidget>
#include <QPainter>
#include <QPushButton>
#include <QVBoxLayout>
#include <QLabel>
#include <QIcon>

class ToggleButtonWidget : public QPushButton
{
        Q_OBJECT
    public:
        ToggleButtonWidget(QWidget * parent, QString img);
        ~ToggleButtonWidget();
    private:
        QIcon icoUnchecked;
        QIcon icoChecked;
    private slots:
        void eventToggled(bool checked);
};

#endif // TOGGLEBUTTONWIDGET_H
