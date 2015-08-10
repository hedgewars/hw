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

#ifndef ACHIEVEMENTS_H
#define ACHIEVEMENTS_H

#define MAX_ACHIEVEMENTS 128

// This is just for testing and far from being complete - everything might change so don't use it anywhere!

enum achflags
{
    ACH_FLAGS_NONE      = 0x00,
    ACH_FLAGS_HIDDEN    = 0x01,
    ACH_FLAGS_INACTIVE  = 0x02,
    // UNKNOWN          = 0x04,
    // UNKNOWN          = 0x08,
    // UNKNOWN          = 0x10,
    // UNKNOWN          = 0x20,
    // UNKNOWN          = 0x40,
    // UNKNOWN          = 0x80,
};

struct achievement
{
    const char *id;
    const char *caption;
    const char *description;
    const char *image;
    const int   goal;
    const int   flags;
};

extern const char achievements[][6][256];

#endif // ACHIEVEMENTS_H
