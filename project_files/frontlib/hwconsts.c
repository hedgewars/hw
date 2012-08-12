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

#include "hwconsts.h"

const uint32_t flib_teamcolors[] = HW_TEAMCOLOR_ARRAY;
const size_t flib_teamcolor_count = sizeof(flib_teamcolors)/sizeof(uint32_t)-1;


uint32_t flib_get_teamcolor(int colorIndex) {
	if(colorIndex>=0 && colorIndex < flib_teamcolor_count) {
		return flib_teamcolors[colorIndex];
	} else {
		return 0;
	}
}

int flib_get_teamcolor_count() {
	return flib_teamcolor_count;
}

int flib_get_hedgehogs_per_team() {
	return HEDGEHOGS_PER_TEAM;
}

int flib_get_weapons_count() {
	return WEAPONS_COUNT;
}
