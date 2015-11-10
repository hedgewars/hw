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

#include "team.h"

#include "../util/inihelper.h"
#include "../util/util.h"
#include "../util/logging.h"

#include <string.h>
#include <stdlib.h>

static flib_team *from_ini_handleError(flib_team *result, flib_ini *settingfile) {
    flib_ini_destroy(settingfile);
    flib_team_destroy(result);
    return NULL;
}

flib_team *flib_team_from_ini(const char *filename) {
    if(log_badargs_if(filename==NULL)) {
        return NULL;
    }

    flib_team *result = flib_calloc(1, sizeof(flib_team));
    flib_ini *ini = NULL;

    if(!result) {
        return from_ini_handleError(result, ini);
    }

    ini = flib_ini_load(filename);
    if(!ini) {
        flib_log_e("Error loading team file %s", filename);
        return from_ini_handleError(result, ini);
    }

    if(flib_ini_enter_section(ini, "team")) {
        flib_log_e("Missing section \"Team\" in team file %s", filename);
        return from_ini_handleError(result, ini);
    }
    bool error = false;
    error |= flib_ini_get_str(ini, &result->name, "name");
    error |= flib_ini_get_str(ini, &result->grave, "grave");
    error |= flib_ini_get_str(ini, &result->fort, "fort");
    error |= flib_ini_get_str(ini, &result->voicepack, "voicepack");
    error |= flib_ini_get_str(ini, &result->flag, "flag");
    error |= flib_ini_get_int(ini, &result->rounds, "rounds");
    error |= flib_ini_get_int(ini, &result->wins, "wins");
    error |= flib_ini_get_int(ini, &result->campaignProgress, "campaignprogress");

    int difficulty = 0;
    error |= flib_ini_get_int(ini, &difficulty, "difficulty");

    if(error) {
        flib_log_e("Missing or malformed entry in section \"Team\" in file %s", filename);
        return from_ini_handleError(result, ini);
    }

    for(int i=0; i<HEDGEHOGS_PER_TEAM; i++) {
        char sectionName[32];
        if(snprintf(sectionName, sizeof(sectionName), "hedgehog%i", i) <= 0) {
            return from_ini_handleError(result, ini);
        }
        if(flib_ini_enter_section(ini, sectionName)) {
            flib_log_e("Missing section \"%s\" in team file %s", sectionName, filename);
            return from_ini_handleError(result, ini);
        }
        flib_hog *hog = &result->hogs[i];
        error |= flib_ini_get_str(ini, &hog->name, "name");
        error |= flib_ini_get_str(ini, &hog->hat, "hat");
        error |= flib_ini_get_int(ini, &hog->rounds, "rounds");
        error |= flib_ini_get_int(ini, &hog->kills, "kills");
        error |= flib_ini_get_int(ini, &hog->deaths, "deaths");
        error |= flib_ini_get_int(ini, &hog->suicides, "suicides");
        result->hogs[i].difficulty = difficulty;
        result->hogs[i].initialHealth = TEAM_DEFAULT_HEALTH;

        if(error) {
            flib_log_e("Missing or malformed entry in section \"%s\" in file %s", sectionName, filename);
            return from_ini_handleError(result, ini);
        }
    }

    if(!flib_ini_enter_section(ini, "binds")) {
        result->bindingCount = flib_ini_get_keycount(ini);
        if(result->bindingCount<0) {
            flib_log_e("Error reading bindings from file %s", filename);
            result->bindingCount = 0;
        }
        result->bindings = flib_calloc(result->bindingCount, sizeof(flib_binding));
        if(!result->bindings) {
            return from_ini_handleError(result, ini);
        }
        for(int i=0; i<result->bindingCount; i++) {
            char *keyname = flib_ini_get_keyname(ini, i);
            if(!keyname) {
                error = true;
            } else {
                result->bindings[i].action = flib_urldecode(keyname);
                error |= !result->bindings[i].action;
                error |= flib_ini_get_str(ini, &result->bindings[i].binding, keyname);
            }
            free(keyname);
        }
    }

    if(error) {
        flib_log_e("Error reading team file %s", filename);
        return from_ini_handleError(result, ini);
    }

    flib_ini_destroy(ini);
    return result;
}

void flib_team_destroy(flib_team *team) {
    if(team) {
        for(int i=0; i<HEDGEHOGS_PER_TEAM; i++) {
            free(team->hogs[i].name);
            free(team->hogs[i].hat);
            flib_weaponset_destroy(team->hogs[i].weaponset);
        }
        free(team->name);
        free(team->grave);
        free(team->fort);
        free(team->voicepack);
        free(team->flag);
        if(team->bindings) {
            for(int i=0; i<team->bindingCount; i++) {
                free(team->bindings[i].action);
                free(team->bindings[i].binding);
            }
        }
        free(team->bindings);
        free(team->ownerName);
        free(team);
    }
}

static int writeTeamSection(const flib_team *team, flib_ini *ini) {
    if(flib_ini_create_section(ini, "team")) {
        return -1;
    }
    bool error = false;
    error |= flib_ini_set_str(ini, "name",  team->name);
    error |= flib_ini_set_str(ini, "grave", team->grave);
    error |= flib_ini_set_str(ini, "fort", team->fort);
    error |= flib_ini_set_str(ini, "voicepack", team->voicepack);
    error |= flib_ini_set_str(ini, "flag", team->flag);
    error |= flib_ini_set_int(ini, "rounds", team->rounds);
    error |= flib_ini_set_int(ini, "wins", team->wins);
    error |= flib_ini_set_int(ini, "campaignprogress", team->campaignProgress);
    error |= flib_ini_set_int(ini, "difficulty", team->hogs[0].difficulty);
    return error;
}

static int writeHogSections(const flib_team *team, flib_ini *ini) {
    for(int i=0; i<HEDGEHOGS_PER_TEAM; i++) {
        const flib_hog *hog = &team->hogs[i];
        char sectionName[32];
        if(snprintf(sectionName, sizeof(sectionName), "hedgehog%i", i) <= 0) {
            return -1;
        }
        if(flib_ini_create_section(ini, sectionName)) {
            return -1;
        }
        bool error = false;
        error |= flib_ini_set_str(ini, "name", hog->name);
        error |= flib_ini_set_str(ini, "hat", hog->hat);
        error |= flib_ini_set_int(ini, "rounds", hog->rounds);
        error |= flib_ini_set_int(ini, "kills", hog->kills);
        error |= flib_ini_set_int(ini, "deaths", hog->deaths);
        error |= flib_ini_set_int(ini, "suicides", hog->suicides);
        if(error) {
            return error;
        }
    }
    return 0;
}

static int writeBindingSection(const flib_team *team, flib_ini *ini) {
    if(team->bindingCount == 0) {
        return 0;
    }
    if(flib_ini_create_section(ini, "binds")) {
        return -1;
    }
    for(int i=0; i<team->bindingCount; i++) {
        bool error = false;
        char *action = flib_urlencode(team->bindings[i].action);
        if(action) {
            error |= flib_ini_set_str(ini, action, team->bindings[i].binding);
            free(action);
        } else {
            error = true;
        }
        if(error) {
            return error;
        }
    }
    return 0;
}

int flib_team_to_ini(const char *filename, const flib_team *team) {
    int result = -1;
    if(!log_badargs_if2(filename==NULL, team==NULL)) {
        flib_ini *ini = flib_ini_create(filename);
        bool error = false;
        error |= writeTeamSection(team, ini);
        error |= writeHogSections(team, ini);
        error |= writeBindingSection(team, ini);
        if(!error) {
            result = flib_ini_save(ini, filename);
        }
        flib_ini_destroy(ini);
    }
    return result;
}

int flib_team_set_weaponset(flib_team *team, const flib_weaponset *set) {
    if(team) {
        for(int i=0; i<HEDGEHOGS_PER_TEAM; i++) {
            flib_weaponset_destroy(team->hogs[i].weaponset);
            team->hogs[i].weaponset = flib_weaponset_copy(set);
            if(set && !team->hogs[i].weaponset) {
                return -1;
            }
        }
    }
    return 0;
}

void flib_team_set_health(flib_team *team, int health) {
    if(team) {
        for(int i=0; i<HEDGEHOGS_PER_TEAM; i++) {
            team->hogs[i].initialHealth = health;
        }
    }
}

static char *strdupWithError(const char *in, bool *error) {
    char *out = flib_strdupnull(in);
    if(in && !out) {
        *error = true;
    }
    return out;
}

flib_team *flib_team_copy(const flib_team *team) {
    flib_team *result = NULL;
    if(team) {
        flib_team *tmpTeam = flib_calloc(1, sizeof(flib_team));
        if(tmpTeam) {
            bool error = false;

            for(int i=0; i<HEDGEHOGS_PER_TEAM; i++) {
                tmpTeam->hogs[i].name = strdupWithError(team->hogs[i].name, &error);
                tmpTeam->hogs[i].hat = strdupWithError(team->hogs[i].hat, &error);
                tmpTeam->hogs[i].rounds = team->hogs[i].rounds;
                tmpTeam->hogs[i].kills = team->hogs[i].kills;
                tmpTeam->hogs[i].deaths = team->hogs[i].deaths;
                tmpTeam->hogs[i].suicides = team->hogs[i].suicides;
                tmpTeam->hogs[i].difficulty = team->hogs[i].difficulty;
                tmpTeam->hogs[i].initialHealth = team->hogs[i].initialHealth;
                tmpTeam->hogs[i].weaponset = flib_weaponset_copy(team->hogs[i].weaponset);
                if(team->hogs[i].weaponset && !tmpTeam->hogs[i].weaponset) {
                    error = true;
                }
            }

            tmpTeam->name = strdupWithError(team->name, &error);
            tmpTeam->grave = strdupWithError(team->grave, &error);
            tmpTeam->fort = strdupWithError(team->fort, &error);
            tmpTeam->voicepack = strdupWithError(team->voicepack, &error);
            tmpTeam->flag = strdupWithError(team->flag, &error);
            tmpTeam->ownerName = strdupWithError(team->ownerName, &error);

            tmpTeam->bindingCount = team->bindingCount;
            if(team->bindings) {
                tmpTeam->bindings = flib_calloc(team->bindingCount, sizeof(flib_binding));
                if(tmpTeam->bindings) {
                    for(int i=0; i<tmpTeam->bindingCount; i++) {
                        tmpTeam->bindings[i].action = strdupWithError(team->bindings[i].action, &error);
                        tmpTeam->bindings[i].binding = strdupWithError(team->bindings[i].binding, &error);
                    }
                } else {
                    error = true;
                }
            }

            tmpTeam->rounds = team->rounds;
            tmpTeam->wins = team->wins;
            tmpTeam->campaignProgress = team->campaignProgress;

            tmpTeam->colorIndex = team->colorIndex;
            tmpTeam->hogsInGame = team->hogsInGame;
            tmpTeam->remoteDriven = team->remoteDriven;

            if(!error) {
                result = tmpTeam;
                tmpTeam = 0;
            }
        }
        flib_team_destroy(tmpTeam);
    }
    return result;
}
