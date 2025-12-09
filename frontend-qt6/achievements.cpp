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

#include <QObject>

#include "achievements.h"

// TODO: use some structs instead?
const char achievements[][6][256] =
{
    // 6 array members each: id, caption, description, image, required number, attributes
    /*
    {"rounds1",  QT_TRANSLATE_NOOP("achievements", "No complete Newbie!"),  QT_TRANSLATE_NOOP("achievements", "Manage to survive %1 games playing on the official server, no matter if it's a draw or win."), "nonewb",     "1", ""},
    {"rounds2",  QT_TRANSLATE_NOOP("achievements", "Getting used to it!"),  QT_TRANSLATE_NOOP("achievements", "Manage to survive %1 games playing on the official server, no matter if it's a draw or win."), "getused",   "25", ""},
    {"rounds3",  QT_TRANSLATE_NOOP("achievements", "Backyard Veteran"),     QT_TRANSLATE_NOOP("achievements", "Manage to survive %1 games playing on the official server, no matter if it's a draw or win."), "veteran",  "100", ""},
    {"rounds4",  QT_TRANSLATE_NOOP("achievements", "1001 Stories to tell"), QT_TRANSLATE_NOOP("achievements", "Manage to survive %1 games playing on the official server, no matter if it's a draw or win."), "stories", "1001", ""},
    {"rope1",    QT_TRANSLATE_NOOP("achievements", "Big Swing"),            QT_TRANSLATE_NOOP("achievements", "Bridge 1000 pixels while using one rope."),                                                    "bgswing",    "1", ""},
    {"rope2",    QT_TRANSLATE_NOOP("achievements", "Spider Hog"),           QT_TRANSLATE_NOOP("achievements", "Bridge 3000 pixels while using one rope."),                                                    "spider",     "1", "hidden"},
    {"skipping", QT_TRANSLATE_NOOP("achievements", "Skipped"),              QT_TRANSLATE_NOOP("achievements", "Let a single hog skip over the surface of the water for at least 5 times."),                   "skipped",    "1", "hidden"},
    {"cgunman",  QT_TRANSLATE_NOOP("achievements", "Crazy Gunman"),         QT_TRANSLATE_NOOP("achievements", "Eliminate 3 hogs with a single shot of the sniper rifle."),                                    "cgunman",    "1", ""},
    */
    { {0, 0, 0, 0, 0, 0} } // "terminator" line
};
