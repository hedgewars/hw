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

#include "teamlist.h"

#include "../util/util.h"
#include "../util/list.h"
#include "../util/logging.h"

#include <stdlib.h>
#include <string.h>

flib_teamlist *flib_teamlist_create() {
    return flib_calloc(1, sizeof(flib_teamlist));
}

void flib_teamlist_destroy(flib_teamlist *list) {
    if(list) {
        for(int i=0; i<list->teamCount; i++) {
            flib_team_destroy(list->teams[i]);
        }
        free(list->teams);
        free(list);
    }
}

GENERATE_STATIC_LIST_INSERT(insertTeam, flib_team*)
GENERATE_STATIC_LIST_DELETE(deleteTeam, flib_team*)

static int findTeam(const flib_teamlist *list, const char *name) {
    for(int i=0; i<list->teamCount; i++) {
        if(!strcmp(name, list->teams[i]->name)) {
            return i;
        }
    }
    return -1;
}

int flib_teamlist_insert(flib_teamlist *list, flib_team *team, int pos) {
    if(!log_badargs_if2(list==NULL, team==NULL)
            && !insertTeam(&list->teams, &list->teamCount, team, pos)) {
        return 0;
    }
    return -1;
}

int flib_teamlist_delete(flib_teamlist *list, const char *name) {
    int result = -1;
    if(!log_badargs_if2(list==NULL, name==NULL)) {
        int itemid = findTeam(list, name);
        if(itemid>=0) {
            flib_team *team = list->teams[itemid];
            if(!deleteTeam(&list->teams, &list->teamCount, itemid)) {
                flib_team_destroy(team);
                result = 0;
            }
        }
    }
    return result;
}

flib_team *flib_teamlist_find(const flib_teamlist *list, const char *name) {
    flib_team *result = NULL;
    if(!log_badargs_if2(list==NULL, name==NULL)) {
        int itemid = findTeam(list, name);
        if(itemid>=0) {
            result = list->teams[itemid];
        }
    }
    return result;
}

void flib_teamlist_clear(flib_teamlist *list) {
    if(!log_badargs_if(list==NULL)) {
        for(int i=0; i<list->teamCount; i++) {
            flib_team_destroy(list->teams[i]);
        }
        free(list->teams);
        list->teams = NULL;
        list->teamCount = 0;
    }
}

flib_teamlist *flib_teamlist_copy(flib_teamlist *list) {
    if(!list) {
        return NULL;
    }
    flib_teamlist *result = flib_teamlist_create();
    if(result) {
        bool error = false;
        for(int i=0; !error && i<list->teamCount; i++) {
            flib_team *teamcopy = flib_team_copy(list->teams[i]);
            if(!teamcopy || flib_teamlist_insert(result, teamcopy, i)) {
                flib_team_destroy(teamcopy);
                error = true;
            }
        }
        if(error) {
            flib_teamlist_destroy(result);
            result = NULL;
        }
    }
    return result;
}
