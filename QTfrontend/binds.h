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

#ifndef BINDS_H
#define BINDS_H

#include <QString>

#ifdef VIDEOREC
#define BINDS_NUMBER 63
#else
#define BINDS_NUMBER 62
#endif

struct BindAction
{
    QString action;
    QString strbind;
    const char * name;
    const char * category;
    const char * description;
};

extern const BindAction cbinds[BINDS_NUMBER];

#endif // BINDS_H
