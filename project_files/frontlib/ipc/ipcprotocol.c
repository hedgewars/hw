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

#include "ipcprotocol.h"
#include "../util/util.h"
#include "../util/logging.h"
#include "../md5/md5.h"

#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <inttypes.h>
#include <stdlib.h>

int flib_ipc_append_message(flib_vector *vec, const char *fmt, ...) {
    int result = -1;
    if(!log_badargs_if2(vec==NULL, fmt==NULL)) {
        // 1 byte size prefix, 255 bytes max message length, 1 0-byte for vsnprintf
        char msgbuffer[257];

        // Format the message, leaving one byte at the start for the length
        va_list argp;
        va_start(argp, fmt);
        int msgSize = vsnprintf(msgbuffer+1, 256, fmt, argp);
        va_end(argp);

        if(!log_e_if(msgSize > 255, "Message too long (%u bytes)", (unsigned)msgSize)
                && !log_e_if(msgSize < 0, "printf error")) {
            // Add the length prefix
            ((uint8_t*)msgbuffer)[0] = msgSize;

            // Append it to the vector
            result = flib_vector_append(vec, msgbuffer, msgSize+1);
        }
    }
    return result;
}

int flib_ipc_append_mapconf(flib_vector *vec, const flib_map *map, bool mappreview) {
    int result = -1;
    flib_vector *tempvector = flib_vector_create();
    if(!log_badargs_if2(vec==NULL, map==NULL)) {
        bool error = false;

        if(map->mapgen == MAPGEN_NAMED) {
            error |= log_e_if(!map->name, "Missing map name")
                    || flib_ipc_append_message(tempvector, "emap %s", map->name);
        }
        if(!mappreview) {
            error |= log_e_if(!map->theme, "Missing map theme")
                    || flib_ipc_append_message(tempvector, "etheme %s", map->theme);
        }
        error |= flib_ipc_append_seed(tempvector, map->seed);
        error |= flib_ipc_append_message(tempvector, "e$template_filter %i", map->templateFilter);
        error |= flib_ipc_append_message(tempvector, "e$mapgen %i", map->mapgen);

        if(map->mapgen == MAPGEN_MAZE) {
            error |= flib_ipc_append_message(tempvector, "e$maze_size %i", map->mazeSize);
        }
        if(map->mapgen == MAPGEN_DRAWN) {
            /*
             * We have to split the drawn map data into several edraw messages here because
             * it can be longer than the maximum message size.
             */
            const char *edraw = "edraw ";
            int edrawlen = strlen(edraw);
            for(size_t offset=0; offset<map->drawDataSize; offset+=200) {
                size_t bytesRemaining = map->drawDataSize-offset;
                int fragmentsize = bytesRemaining < 200 ? bytesRemaining : 200;
                uint8_t messagesize = edrawlen + fragmentsize;
                error |= flib_vector_append(tempvector, &messagesize, 1);
                error |= flib_vector_append(tempvector, edraw, edrawlen);
                error |= flib_vector_append(tempvector, map->drawData+offset, fragmentsize);
            }
        }

        if(!log_e_if(error, "Error generating map config")) {
            // Message created, now we can copy everything.
            flib_constbuffer constbuf = flib_vector_as_constbuffer(tempvector);
            if(!flib_vector_append(vec, constbuf.data, constbuf.size)) {
                result = 0;
            }
        }
    }
    flib_vector_destroy(tempvector);
    return result;
}

int flib_ipc_append_seed(flib_vector *vec, const char *seed) {
    if(log_badargs_if2(vec==NULL, seed==NULL)) {
        return -1;
    }
    return flib_ipc_append_message(vec, "eseed %s", seed);
}

int flib_ipc_append_script(flib_vector *vec, const char *script) {
    int result = -1;
    if(!log_badargs_if2(vec==NULL, script==NULL)) {
        result = flib_ipc_append_message(vec, "escript %s", script);
    }
    return result;
}

int flib_ipc_append_style(flib_vector *vec, const char *style) {
    int result = -1;
    char *copy = flib_strdupnull(style);
    if(!log_badargs_if(vec==NULL) && copy) {
        if(!strcmp("Normal", copy)) {
            // "Normal" means no gametype script
            // TODO if an empty script called "Normal" is added to the scripts directory this can be removed
            result = 0;
        } else {
            size_t len = strlen(copy);
            for(size_t i=0; i<len; i++) {
                if(copy[i] == ' ') {
                    copy[i] = '_';
                }
            }

            result = flib_ipc_append_message(vec, "escript %s%s.lua", MULTIPLAYER_SCRIPT_PATH, copy);
        }
    }
    free(copy);
    return result;
}

static uint32_t buildModFlags(const flib_scheme *scheme) {
    uint32_t result = 0;
    for(int i=0; i<flib_meta.modCount; i++) {
        if(scheme->mods[i]) {
            int bitmaskIndex = flib_meta.mods[i].bitmaskIndex;
            result |= (UINT32_C(1) << bitmaskIndex);
        }
    }
    return result;
}

int flib_ipc_append_gamescheme(flib_vector *vec, const flib_scheme *scheme) {
    int result = -1;
    flib_vector *tempvector = flib_vector_create();
    if(!log_badargs_if2(vec==NULL, scheme==NULL) && tempvector) {
        bool error = false;
        error |= flib_ipc_append_message(tempvector, "e$gmflags %"PRIu32, buildModFlags(scheme));
        for(int i=0; i<flib_meta.settingCount; i++) {
            if(flib_meta.settings[i].engineCommand) {
                int value = scheme->settings[i];
                if(flib_meta.settings[i].maxMeansInfinity) {
                    value = value>=flib_meta.settings[i].max ? 9999 : value;
                }
                if(flib_meta.settings[i].times1000) {
                    value *= 1000;
                }
                error |= flib_ipc_append_message(tempvector, "%s %i", flib_meta.settings[i].engineCommand, value);
            }
        }

        if(!error) {
            // Message created, now we can copy everything.
            flib_constbuffer constbuf = flib_vector_as_constbuffer(tempvector);
            if(!flib_vector_append(vec, constbuf.data, constbuf.size)) {
                result = 0;
            }
        }
    }
    flib_vector_destroy(tempvector);
    return result;
}

static int appendWeaponSet(flib_vector *vec, flib_weaponset *set) {
    return flib_ipc_append_message(vec, "eammloadt %s", set->loadout)
        || flib_ipc_append_message(vec, "eammprob %s", set->crateprob)
        || flib_ipc_append_message(vec, "eammdelay %s", set->delay)
        || flib_ipc_append_message(vec, "eammreinf %s", set->crateammo);
}

static void calculateMd5Hex(const char *in, char out[33]) {
    md5_state_t md5state;
    uint8_t md5bytes[16];
    md5_init(&md5state);
    md5_append(&md5state, (unsigned char*)in, strlen(in));
    md5_finish(&md5state, md5bytes);
    for(int i=0;i<sizeof(md5bytes); i++) {
        snprintf(out+i*2, 3, "%02x", (unsigned)md5bytes[i]);
    }
}

static int flib_ipc_append_addteam(flib_vector *vec, const flib_team *team, bool perHogAmmo, bool noAmmoStore) {
    int result = -1;
    flib_vector *tempvector = flib_vector_create();
    if(!log_badargs_if2(vec==NULL, team==NULL) && tempvector) {
        bool error = false;

        if(!perHogAmmo && !noAmmoStore) {
            error = error
                    || appendWeaponSet(tempvector, team->hogs[0].weaponset)
                    || flib_ipc_append_message(tempvector, "eammstore");
        }

        char md5Hex[33];
        calculateMd5Hex(team->ownerName ? team->ownerName : "", md5Hex);
        if(team->colorIndex<0 || team->colorIndex>=flib_teamcolor_count) {
            flib_log_e("Color index out of bounds for team %s: %i", team->name, team->colorIndex);
            error = true;
        } else {
            error |= flib_ipc_append_message(tempvector, "eaddteam %s %"PRIu32" %s", md5Hex, flib_teamcolors[team->colorIndex], team->name);
        }

        if(team->remoteDriven) {
            error |= flib_ipc_append_message(tempvector, "erdriven");
        }

        error |= flib_ipc_append_message(tempvector, "egrave %s", team->grave);
        error |= flib_ipc_append_message(tempvector, "efort %s", team->fort);
        error |= flib_ipc_append_message(tempvector, "evoicepack %s", team->voicepack);
        error |= flib_ipc_append_message(tempvector, "eflag %s", team->flag);

        for(int i=0; i<team->bindingCount; i++) {
            error |= flib_ipc_append_message(tempvector, "ebind %s %s", team->bindings[i].binding, team->bindings[i].action);
        }

        for(int i=0; i<team->hogsInGame; i++) {
            if(perHogAmmo && !noAmmoStore) {
                error |= appendWeaponSet(tempvector, team->hogs[i].weaponset);
            }
            error |= flib_ipc_append_message(tempvector, "eaddhh %i %i %s", team->hogs[i].difficulty, team->hogs[i].initialHealth, team->hogs[i].name);
            error |= flib_ipc_append_message(tempvector, "ehat %s", team->hogs[i].hat);
        }

        if(!error) {
            // Message created, now we can copy everything.
            flib_constbuffer constbuf = flib_vector_as_constbuffer(tempvector);
            if(!flib_vector_append(vec, constbuf.data, constbuf.size)) {
                result = 0;
            }
        }
    }
    flib_vector_destroy(tempvector);
    return result;
}

int flib_ipc_append_fullconfig(flib_vector *vec, const flib_gamesetup *setup, bool netgame) {
    int result = -1;
    flib_vector *tempvector = flib_vector_create();
    if(!log_badargs_if2(vec==NULL, setup==NULL) && tempvector) {
        bool error = false;
        bool perHogAmmo = false;
        bool sharedAmmo = false;

        error |= flib_ipc_append_message(vec, netgame ? "TN" : "TL");
        if(setup->map) {
            error |= flib_ipc_append_mapconf(tempvector, setup->map, false);
        }
        if(setup->style) {
            error |= flib_ipc_append_style(tempvector, setup->style);
        }
        if(setup->gamescheme) {
            error |= flib_ipc_append_gamescheme(tempvector, setup->gamescheme);
            sharedAmmo = flib_scheme_get_mod(setup->gamescheme, "sharedammo");
            // Shared ammo has priority over per-hog ammo
            perHogAmmo = !sharedAmmo && flib_scheme_get_mod(setup->gamescheme, "perhogammo");
        }
        if(setup->teamlist->teams && setup->teamlist->teamCount>0) {
            int *clanColors = flib_calloc(setup->teamlist->teamCount, sizeof(int));
            if(!clanColors) {
                error = true;
            } else {
                int clanCount = 0;
                for(int i=0; !error && i<setup->teamlist->teamCount; i++) {
                    flib_team *team = setup->teamlist->teams[i];
                    // Find the clan index of this team (clans are identified by color).
                    bool newClan = false;
                    int clan = 0;
                    while(clan<clanCount && clanColors[clan] != team->colorIndex) {
                        clan++;
                    }
                    if(clan==clanCount) {
                        newClan = true;
                        clanCount++;
                        clanColors[clan] = team->colorIndex;
                    }

                    // If shared ammo is active, only add an ammo store for the first team in each clan.
                    bool noAmmoStore = sharedAmmo&&!newClan;
                    error |= flib_ipc_append_addteam(tempvector, setup->teamlist->teams[i], perHogAmmo, noAmmoStore);
                }
            }
            free(clanColors);
        }
        error |= flib_ipc_append_message(tempvector, "!");

        if(!error) {
            // Message created, now we can copy everything.
            flib_constbuffer constbuf = flib_vector_as_constbuffer(tempvector);
            if(!flib_vector_append(vec, constbuf.data, constbuf.size)) {
                result = 0;
            }
        }
    }
    return result;
}
