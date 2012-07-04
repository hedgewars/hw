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

#include "schemelist.h"

#include "../util/inihelper.h"
#include "../util/logging.h"
#include "../util/util.h"
#include "../util/refcounter.h"
#include "../util/list.h"

#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>

static void flib_schemelist_destroy(flib_schemelist *list) {
	if(list) {
		for(int i=0; i<list->schemeCount; i++) {
			flib_cfg_release(list->schemes[i]);
		}
		free(list->schemes);
		free(list);
	}
}

static char *makePrefixedName(int schemeIndex, const char *settingName) {
	return flib_asprintf("%i\\%s", schemeIndex, settingName);
}

static int readSettingsFromIni(flib_ini *ini, flib_cfg *scheme, int index) {
	flib_cfg_meta *meta = scheme->meta;
	bool error = false;
	for(int i=0; i<meta->settingCount && !error; i++) {
		char *key = makePrefixedName(index, meta->settings[i].name);
		if(!key) {
			error = true;
		} else if(flib_ini_get_int_opt(ini, &scheme->settings[i], key, meta->settings[i].def)) {
			flib_log_e("Error reading setting %s in schemes file.", key);
			error = true;
		}
		free(key);
	}
	return error;
}

static int readModsFromIni(flib_ini *ini, flib_cfg *scheme, int index) {
	flib_cfg_meta *meta = scheme->meta;
	bool error = false;
	for(int i=0; i<meta->modCount && !error; i++) {
		char *key = makePrefixedName(index, meta->mods[i].name);
		if(!key) {
			error = true;
		} else if(flib_ini_get_bool_opt(ini, &scheme->mods[i], key, false)) {
			flib_log_e("Error reading mod %s in schemes file.", key);
			error = true;
		}
		free(key);
	}
	return error;
}

static flib_cfg *readSchemeFromIni(flib_cfg_meta *meta, flib_ini *ini, int index) {
	flib_cfg *result = NULL;
	char *schemeNameKey = makePrefixedName(index+1, "name");
	if(schemeNameKey) {
		char *schemeName = NULL;
		if(!flib_ini_get_str_opt(ini, &schemeName, schemeNameKey, "Unnamed")) {
			flib_cfg *scheme = flib_cfg_create(meta, schemeName);
			if(scheme) {
				if(!readSettingsFromIni(ini, scheme, index) && !readModsFromIni(ini, scheme, index)) {
					result = flib_cfg_retain(scheme);
				}
			}
			flib_cfg_release(scheme);
		}
		free(schemeName);
	}
	free(schemeNameKey);
	return result;
}

static flib_schemelist *fromIniHandleError(flib_schemelist *result, flib_ini *ini) {
	flib_ini_destroy(ini);
	flib_schemelist_destroy(result);
	return NULL;
}

flib_schemelist *flib_schemelist_from_ini(flib_cfg_meta *meta, const char *filename) {
	if(log_badargs_if2(meta==NULL, filename==NULL)) {
		return NULL;
	}

	flib_schemelist *list = NULL;
	flib_ini *ini = flib_ini_load(filename);
	if(!ini || flib_ini_enter_section(ini, "schemes")) {
		flib_log_e("Missing file or missing section \"schemes\" in file %s.", filename);
		return fromIniHandleError(list, ini);
	}

	list = flib_schemelist_create();
	if(!list) {
		return fromIniHandleError(list, ini);
	}

	int schemeCount = 0;
	if(flib_ini_get_int(ini, &schemeCount, "size")) {
		flib_log_e("Missing or malformed scheme count in config file %s.", filename);
		return fromIniHandleError(list, ini);
	}

	for(int i=0; i<schemeCount; i++) {
		flib_cfg *scheme = readSchemeFromIni(meta, ini, i);
		if(!scheme || flib_schemelist_insert(list, scheme, i)) {
			flib_cfg_release(scheme);
			flib_log_e("Error reading scheme %i from config file %s.", i, filename);
			return fromIniHandleError(list, ini);
		}
		flib_cfg_release(scheme);
	}


	flib_ini_destroy(ini);
	return list;
}

static int writeSchemeToIni(flib_cfg *scheme, flib_ini *ini, int index) {
	flib_cfg_meta *meta = scheme->meta;
	bool error = false;

	char *key = makePrefixedName(index+1, "name");
	error |= !key || flib_ini_set_str(ini, key, scheme->name);
	free(key);

	for(int i=0; i<meta->modCount && !error; i++) {
		char *key = makePrefixedName(index+1, meta->mods[i].name);
		error |= !key || flib_ini_set_bool(ini, key, scheme->mods[i]);
		free(key);
	}

	for(int i=0; i<meta->settingCount && !error; i++) {
		char *key = makePrefixedName(index+1, meta->settings[i].name);
		error |= !key || flib_ini_set_int(ini, key, scheme->settings[i]);
		free(key);
	}
	return error;
}

int flib_schemelist_to_ini(const char *filename, const flib_schemelist *schemes) {
	int result = -1;
	if(!log_badargs_if2(filename==NULL, schemes==NULL)) {
		flib_ini *ini = flib_ini_create(NULL);
		if(ini && !flib_ini_create_section(ini, "schemes")) {
			bool error = false;
			error |= flib_ini_set_int(ini, "size", schemes->schemeCount);
			for(int i=0; i<schemes->schemeCount && !error; i++) {
				error |= writeSchemeToIni(schemes->schemes[i], ini, i);
			}

			if(!error) {
				result = flib_ini_save(ini, filename);
			}
		}
		flib_ini_destroy(ini);
	}
	return result;
}

flib_schemelist *flib_schemelist_create() {
	return flib_schemelist_retain(flib_calloc(1, sizeof(flib_schemelist)));
}

flib_schemelist *flib_schemelist_retain(flib_schemelist *list) {
	if(list) {
		flib_retain(&list->_referenceCount, "flib_schemelist");
	}
	return list;
}

void flib_schemelist_release(flib_schemelist *list) {
	if(list && flib_release(&list->_referenceCount, "flib_schemelist")) {
		flib_schemelist_destroy(list);
	}
}

flib_cfg *flib_schemelist_find(flib_schemelist *list, const char *name) {
	if(!log_badargs_if2(list==NULL, name==NULL)) {
		for(int i=0; i<list->schemeCount; i++) {
			if(!strcmp(name, list->schemes[i]->name)) {
				return list->schemes[i];
			}
		}
	}
	return NULL;
}

GENERATE_STATIC_LIST_INSERT(insertScheme, flib_cfg*)
GENERATE_STATIC_LIST_DELETE(deleteScheme, flib_cfg*)

int flib_schemelist_insert(flib_schemelist *list, flib_cfg *cfg, int pos) {
	if(!log_badargs_if2(list==NULL, cfg==NULL)
			&& !insertScheme(&list->schemes, &list->schemeCount, cfg, pos)) {
		flib_cfg_retain(cfg);
		return 0;
	}
	return -1;
}

int flib_schemelist_delete(flib_schemelist *list, int pos) {
	if(!log_badargs_if(list==NULL)) {
		flib_cfg *elem = list->schemes[pos];
		if(!deleteScheme(&list->schemes, &list->schemeCount, pos)) {
			flib_cfg_release(elem);
			return 0;
		}
	}
	return -1;
}
