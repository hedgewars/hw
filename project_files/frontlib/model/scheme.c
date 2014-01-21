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

#include "scheme.h"

#include "../util/inihelper.h"
#include "../util/logging.h"
#include "../util/util.h"

#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>

flib_scheme *flib_scheme_create(const char *schemeName) {
    flib_scheme *result = flib_calloc(1, sizeof(flib_scheme));
    if(log_badargs_if(schemeName==NULL) || result==NULL) {
        return NULL;
    }

    result->name = flib_strdupnull(schemeName);
    result->mods = flib_calloc(flib_meta.modCount, sizeof(*result->mods));
    result->settings = flib_calloc(flib_meta.settingCount, sizeof(*result->settings));

    if(!result->mods || !result->settings || !result->name) {
        flib_scheme_destroy(result);
        return NULL;
    }

    for(int i=0; i<flib_meta.settingCount; i++) {
        result->settings[i] = flib_meta.settings[i].def;
    }
    return result;
}

flib_scheme *flib_scheme_copy(const flib_scheme *scheme) {
    flib_scheme *result = NULL;
    if(scheme) {
        result = flib_scheme_create(scheme->name);
        if(result) {
            memcpy(result->mods, scheme->mods, flib_meta.modCount * sizeof(*scheme->mods));
            memcpy(result->settings, scheme->settings, flib_meta.settingCount * sizeof(*scheme->settings));
        }
    }
    return result;
}

void flib_scheme_destroy(flib_scheme* scheme) {
    if(scheme) {
        free(scheme->mods);
        free(scheme->settings);
        free(scheme->name);
        free(scheme);
    }
}

bool flib_scheme_get_mod(const flib_scheme *scheme, const char *name) {
    if(!log_badargs_if2(scheme==NULL, name==NULL)) {
        for(int i=0; i<flib_meta.modCount; i++) {
            if(!strcmp(flib_meta.mods[i].name, name)) {
                return scheme->mods[i];
            }
        }
        flib_log_e("Unable to find game mod %s", name);
    }
    return false;
}

int flib_scheme_get_setting(const flib_scheme *scheme, const char *name, int def) {
    if(!log_badargs_if2(scheme==NULL, name==NULL)) {
        for(int i=0; i<flib_meta.settingCount; i++) {
            if(!strcmp(flib_meta.settings[i].name, name)) {
                return scheme->settings[i];
            }
        }
        flib_log_e("Unable to find game setting %s", name);
    }
    return def;
}
