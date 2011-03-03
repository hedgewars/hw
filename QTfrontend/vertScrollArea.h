/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2006-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef _VERT_SCROLL_AREA_INCLUDED
#define _VERT_SCROLL_AREA_INCLUDED

#include <QScrollArea>

class VertScrArea : public QScrollArea
{
    Q_OBJECT

public:
    VertScrArea(QColor frameColor, QWidget * parent = 0);

protected:
    virtual void resizeEvent(QResizeEvent * event);
};

#endif // _VERT_SCROLL_AREA_INCLUDED
