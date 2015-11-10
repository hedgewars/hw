/*
 * Hedgewars, a free turn based strategy game
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

/*!
 * Data structure and functions for accessing the map.cfg of named maps.
 */

#ifndef MAPCFG_H_
#define MAPCFG_H_

typedef struct {
    char theme[256];
    int hogLimit;
} flib_mapcfg;

/**
 * Read the map configuration for the map with this name.
 * The dataDirPath must end in a path separator.
 */
int flib_mapcfg_read(const char *dataDirPath, const char *mapname, flib_mapcfg *out);

#endif /* MAPCFG_H_ */
