/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QObject>

#include "achievements.h"

const char achievements[][5][256] = {
    // 5 array members each: id, caption, description, image, required number
    //{"rounds1", QT_TRANSLATE_NOOP("achievements", "No complete Newbie!"),  QT_TRANSLATE_NOOP("achievements", "Manage to survive %1 games playing on the official server, no matter if it's a draw or win."), "nonewb",     1},
    //{"rounds2", QT_TRANSLATE_NOOP("achievements", "Getting used to it!"),  QT_TRANSLATE_NOOP("achievements", "Manage to survive %1 games playing on the official server, no matter if it's a draw or win."), "getused",   25},
    //{"rounds3", QT_TRANSLATE_NOOP("achievements", "Backyard Veteran"),     QT_TRANSLATE_NOOP("achievements", "Manage to survive %1 games playing on the official server, no matter if it's a draw or win."), "veteran",  100},
    //{"rounds4", QT_TRANSLATE_NOOP("achievements", "1001 Stories to tell"), QT_TRANSLATE_NOOP("achievements", "Manage to survive %1 games playing on the official server, no matter if it's a draw or win."), "stories", 1001},
    {0, 0, 0, 0, 0} // "terminator" line
};
