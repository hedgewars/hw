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

#ifndef _IGBOX_H
#define _IGBOX_H

#include <QGroupBox>
#include <QIcon>

class IconedGroupBox : public QGroupBox
{
        Q_OBJECT

    public:
        IconedGroupBox(QWidget * parent = 0);

        void setIcon(const QIcon & icon);
        void setTitleTextPadding(int px);
        void setContentTopPadding(int px);
    protected:
        virtual void paintEvent(QPaintEvent * event);

    private:
        QIcon icon;
        int titleLeftPadding;
        int contentTopPadding;
};

#endif // _IGBOX_H
