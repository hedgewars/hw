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

#include "weapon.h"

#include "../util/inihelper.h"
#include "../util/logging.h"
#include "../util/util.h"
#include "../util/list.h"

#include <stdlib.h>
#include <ctype.h>
#include <string.h>

static void setField(char field[WEAPONS_COUNT+1], const char *line, int lineLen, bool no9) {
    if(lineLen>WEAPONS_COUNT) {
        lineLen = WEAPONS_COUNT;
    }

    char min = '0';
    char max = no9 ? '8' : '9';
    for(int i=0; i<lineLen; i++) {
        if(line[i] >= min && line[i] <= max) {
            field[i] = line[i];
        } else {
            flib_log_w("Invalid character in weapon config string \"%.*s\", position %i", lineLen, line, i);
            field[i] = '0';
        }
    }
    for(int i=lineLen; i<WEAPONS_COUNT; i++) {
        field[i] = '0';
    }
    field[WEAPONS_COUNT] = 0;
}

flib_weaponset *flib_weaponset_create(const char *name) {
    flib_weaponset *result = NULL;
    if(!log_badargs_if(name==NULL)) {
        flib_weaponset *newSet = flib_calloc(1, sizeof(flib_weaponset));
        if(newSet) {
            newSet->name = flib_strdupnull(name);
            if(newSet->name) {
                setField(newSet->loadout, "", 0, false);
                setField(newSet->crateprob, "", 0, false);
                setField(newSet->crateammo, "", 0, false);
                setField(newSet->delay, "", 0, false);
                result = newSet;
                newSet = NULL;
            }
        }
        flib_weaponset_destroy(newSet);
    }
    return result;
}

void flib_weaponset_destroy(flib_weaponset *cfg) {
    if(cfg) {
        free(cfg->name);
        free(cfg);
    }
}

flib_weaponset *flib_weaponset_copy(const flib_weaponset *weaponset) {
    if(!weaponset) {
        return NULL;
    }

    flib_weaponset *result = flib_weaponset_create(weaponset->name);
    if(result) {
        memcpy(result->loadout, weaponset->loadout, WEAPONS_COUNT+1);
        memcpy(result->crateprob, weaponset->crateprob, WEAPONS_COUNT+1);
        memcpy(result->delay, weaponset->delay, WEAPONS_COUNT+1);
        memcpy(result->crateammo, weaponset->crateammo, WEAPONS_COUNT+1);
    }

    return result;
}

void flib_weaponsetlist_destroy(flib_weaponsetlist *list) {
    if(list) {
        for(int i=0; i<list->weaponsetCount; i++) {
            flib_weaponset_destroy(list->weaponsets[i]);
        }
        free(list->weaponsets);
        free(list);
    }
}

flib_weaponset *flib_weaponset_from_ammostring(const char *name, const char *ammostring) {
    flib_weaponset *result = NULL;
    if(!log_badargs_if2(name==NULL, ammostring==NULL)) {
        result = flib_weaponset_create(name);
        if(result) {
            int fieldlen = strlen(ammostring)/4;
            setField(result->loadout, ammostring, fieldlen, false);
            setField(result->crateprob, ammostring + fieldlen, fieldlen, true);
            setField(result->delay, ammostring + 2*fieldlen, fieldlen, true);
            setField(result->crateammo, ammostring + 3*fieldlen, fieldlen, true);
        }
    }
    return result;
}

static int fillWeaponsetFromIni(flib_weaponsetlist *list, flib_ini *ini, int index) {
    int result = -1;
    char *keyname = flib_ini_get_keyname(ini, index);
    char *decodedKeyname = flib_urldecode(keyname);
    char *ammostring = NULL;
    if(decodedKeyname && !flib_ini_get_str(ini, &ammostring, keyname)) {
        flib_weaponset *set = flib_weaponset_from_ammostring(decodedKeyname, ammostring);
        if(set) {
            result = flib_weaponsetlist_insert(list, set, list->weaponsetCount);
            if(result) {
                flib_weaponset_destroy(set);
            }
        }
    }
    free(ammostring);
    free(decodedKeyname);
    free(keyname);
    return result;
}

static int fillWeaponsetsFromIni(flib_weaponsetlist *list, flib_ini *ini) {
    bool error = false;
    int weaponsets = flib_ini_get_keycount(ini);

    for(int i=0; i<weaponsets && !error; i++) {
        error |= fillWeaponsetFromIni(list, ini, i);
    }
    return error;
}

flib_weaponsetlist *flib_weaponsetlist_from_ini(const char *filename) {
    flib_weaponsetlist *result = NULL;
    if(!log_badargs_if(filename==NULL)) {
        flib_ini *ini = flib_ini_load(filename);
        if(!ini) {
            flib_log_e("Missing file %s.", filename);
        } else if(flib_ini_enter_section(ini, "General")) {
            flib_log_e("Missing section \"General\" in file %s.", filename);
        } else {
            flib_weaponsetlist *tmpList = flib_weaponsetlist_create();
            if(tmpList && !fillWeaponsetsFromIni(tmpList, ini)) {
                result = tmpList;
                tmpList = NULL;
            }
            flib_weaponsetlist_destroy(tmpList);
        }
        flib_ini_destroy(ini);
    }
    return result;
}

static bool needsEscape(char c) {
    return !((c>='0' && c<='9') || (c>='a' && c <='z'));
}

static int writeWeaponsetToIni(flib_ini *ini, flib_weaponset *set) {
    int result = -1;
    char weaponstring[WEAPONS_COUNT*4+1];
    strcpy(weaponstring, set->loadout);
    strcat(weaponstring, set->crateprob);
    strcat(weaponstring, set->delay);
    strcat(weaponstring, set->crateammo);

    char *escapedname = flib_urlencode_pred(set->name, needsEscape);
    if(escapedname) {
        result = flib_ini_set_str(ini, escapedname, weaponstring);
    }
    free(escapedname);
    return result;
}

int flib_weaponsetlist_to_ini(const char *filename, const flib_weaponsetlist *list) {
    int result = -1;
    if(!log_badargs_if2(filename==NULL, list==NULL)) {
        flib_ini *ini = flib_ini_create(NULL);
        if(ini && !flib_ini_create_section(ini, "General")) {
            bool error = false;
            for(int i=0; i<list->weaponsetCount && !error; i++) {
                error |= writeWeaponsetToIni(ini, list->weaponsets[i]);
            }

            if(!error) {
                result = flib_ini_save(ini, filename);
            }
        }
        flib_ini_destroy(ini);
    }
    return result;
}

flib_weaponsetlist *flib_weaponsetlist_create() {
    return flib_calloc(1, sizeof(flib_weaponsetlist));
}

GENERATE_STATIC_LIST_INSERT(insertWeaponset, flib_weaponset*)
GENERATE_STATIC_LIST_DELETE(deleteWeaponset, flib_weaponset*)

int flib_weaponsetlist_insert(flib_weaponsetlist *list, flib_weaponset *set, int pos) {
    if(!log_badargs_if2(list==NULL, set==NULL)
            && !insertWeaponset(&list->weaponsets, &list->weaponsetCount, set, pos)) {
        return 0;
    }
    return -1;
}

int flib_weaponsetlist_delete(flib_weaponsetlist *list, int pos) {
    if(!log_badargs_if(list==NULL)) {
        flib_weaponset *elem = list->weaponsets[pos];
        if(!deleteWeaponset(&list->weaponsets, &list->weaponsetCount, pos)) {
            flib_weaponset_destroy(elem);
            return 0;
        }
    }
    return -1;
}
