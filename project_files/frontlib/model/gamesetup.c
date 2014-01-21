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

#include "gamesetup.h"
#include "../util/util.h"

#include <stdlib.h>

void flib_gamesetup_destroy(flib_gamesetup *gamesetup) {
    if(gamesetup) {
        free(gamesetup->style);
        flib_scheme_destroy(gamesetup->gamescheme);
        flib_map_destroy(gamesetup->map);
        flib_teamlist_destroy(gamesetup->teamlist);
        free(gamesetup);
    }
}

flib_gamesetup *flib_gamesetup_copy(const flib_gamesetup *setup) {
    if(!setup) {
        return NULL;
    }

    flib_gamesetup *result = flib_calloc(1, sizeof(flib_gamesetup));
    if(result) {
        result->style = flib_strdupnull(setup->style);
        result->gamescheme = flib_scheme_copy(setup->gamescheme);
        result->map = flib_map_copy(setup->map);
        result->teamlist = flib_teamlist_copy(setup->teamlist);
        if((setup->style && !result->style)
                || (setup->gamescheme && !result->gamescheme)
                || (setup->map && !result->map)
                || (setup->teamlist && !result->teamlist)) {
            flib_gamesetup_destroy(result);
            result = NULL;
        }
    }
    return result;
}
