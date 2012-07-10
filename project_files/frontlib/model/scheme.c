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
#include "../util/refcounter.h"

#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>

static void flib_metascheme_destroy(flib_metascheme *meta) {
	if(meta) {
		if(meta->settings) {
			for(int i=0; i<meta->settingCount; i++) {
				free(meta->settings[i].name);
				free(meta->settings[i].engineCommand);
			}
			free(meta->settings);
		}
		if(meta->mods) {
			for(int i=0; i<meta->modCount; i++) {
				free(meta->mods[i].name);
			}
			free(meta->mods);
		}
		free(meta);
	}
}

static void flib_scheme_destroy(flib_scheme* scheme) {
	if(scheme) {
		flib_metascheme_release(scheme->meta);
		free(scheme->mods);
		free(scheme->settings);
		free(scheme->name);
		free(scheme);
	}
}

static flib_metascheme *flib_metascheme_from_ini_handleError(flib_metascheme *result, flib_ini *ini) {
	flib_metascheme_destroy(result);
	flib_ini_destroy(ini);
	return NULL;
}

static int readMetaSettingSections(flib_ini *ini, flib_metascheme *result, int limit) {
	while(result->settingCount<limit) {
		char sectionName[32];
		if(snprintf(sectionName, sizeof(sectionName), "setting%i", result->settingCount) <= 0) {
			return -1;
		}
		if(!flib_ini_enter_section(ini, sectionName)) {
			flib_metascheme_setting *metasetting = &result->settings[result->settingCount];
			result->settingCount++;

			bool error = false;
			error |= flib_ini_get_str(ini, &metasetting->name, "name");
			error |= flib_ini_get_str_opt(ini, &metasetting->engineCommand, "command", NULL);
			error |= flib_ini_get_bool(ini, &metasetting->times1000, "times1000");
			error |= flib_ini_get_bool(ini, &metasetting->maxMeansInfinity, "maxmeansinfinity");
			error |= flib_ini_get_int(ini, &metasetting->min, "min");
			error |= flib_ini_get_int(ini, &metasetting->max, "max");
			error |= flib_ini_get_int(ini, &metasetting->def, "default");
			if(error) {
				flib_log_e("Missing or malformed ini parameter in metaconfig, section %s", sectionName);
				return -1;
			}
		} else {
			return 0;
		}
	}
	return 0;
}

static int readMetaModSections(flib_ini *ini, flib_metascheme *result, int limit) {
	while(result->modCount<limit) {
		char sectionName[32];
		if(snprintf(sectionName, sizeof(sectionName), "mod%i", result->modCount) <= 0) {
			return -1;
		}
		if(!flib_ini_enter_section(ini, sectionName)) {
			flib_metascheme_mod *metamod = &result->mods[result->modCount];
			result->modCount++;

			bool error = false;
			error |= flib_ini_get_str(ini, &metamod->name, "name");
			error |= flib_ini_get_int(ini, &metamod->bitmaskIndex, "bitmaskIndex");
			if(error) {
				flib_log_e("Missing or malformed ini parameter in metaconfig, section %s", sectionName);
				return -1;
			}
		} else {
			return 0;
		}
	}
	return 0;
}

flib_metascheme *flib_metascheme_from_ini(const char *filename) {
	if(log_badargs_if(filename==NULL)) {
		return NULL;
	}
	flib_metascheme *result = flib_metascheme_retain(flib_calloc(1, sizeof(flib_metascheme)));
	flib_ini *ini = flib_ini_load(filename);

	if(!result || !ini) {
		return flib_metascheme_from_ini_handleError(result, ini);
	}

	// We're overallocating here for simplicity
	int sectionCount = flib_ini_get_sectioncount(ini);
	result->settingCount = 0;
	result->modCount = 0;
	result->settings = flib_calloc(sectionCount, sizeof(flib_metascheme_setting));
	result->mods = flib_calloc(sectionCount, sizeof(flib_metascheme_mod));

	if(!result->settings || !result->mods) {
		return flib_metascheme_from_ini_handleError(result, ini);
	}

	if(readMetaSettingSections(ini, result, sectionCount) || readMetaModSections(ini, result, sectionCount)) {
		return flib_metascheme_from_ini_handleError(result, ini);
	}

	if(result->settingCount+result->modCount != sectionCount) {
		flib_log_e("Unknown or non-contiguous sections headers in metaconfig.");
		return flib_metascheme_from_ini_handleError(result, ini);
	}

	flib_ini_destroy(ini);
	return result;
}

flib_metascheme *flib_metascheme_retain(flib_metascheme *metainfo) {
	if(metainfo) {
		flib_retain(&metainfo->_referenceCount, "flib_metascheme");
	}
	return metainfo;
}

void flib_metascheme_release(flib_metascheme *meta) {
	if(meta && flib_release(&meta->_referenceCount, "flib_metascheme")) {
		flib_metascheme_destroy(meta);
	}
}

flib_scheme *flib_scheme_create(flib_metascheme *meta, const char *schemeName) {
	flib_scheme *result = flib_scheme_retain(flib_calloc(1, sizeof(flib_scheme)));
	if(log_badargs_if2(meta==NULL, schemeName==NULL) || result==NULL) {
		return NULL;
	}

	result->meta = flib_metascheme_retain(meta);
	result->name = flib_strdupnull(schemeName);
	result->mods = flib_calloc(meta->modCount, sizeof(*result->mods));
	result->settings = flib_calloc(meta->settingCount, sizeof(*result->settings));

	if(!result->mods || !result->settings || !result->name) {
		flib_scheme_destroy(result);
		return NULL;
	}

	for(int i=0; i<meta->settingCount; i++) {
		result->settings[i] = meta->settings[i].def;
	}
	return result;
}

flib_scheme *flib_scheme_copy(const flib_scheme *scheme) {
	flib_scheme *result = NULL;
	if(scheme) {
		result = flib_scheme_create(scheme->meta, scheme->name);
		if(result) {
			memcpy(result->mods, scheme->mods, scheme->meta->modCount * sizeof(*scheme->mods));
			memcpy(result->settings, scheme->settings, scheme->meta->settingCount * sizeof(*scheme->settings));
		}
	}
	return result;
}

flib_scheme *flib_scheme_retain(flib_scheme *scheme) {
	if(scheme) {
		flib_retain(&scheme->_referenceCount, "flib_scheme");
	}
	return scheme;
}

void flib_scheme_release(flib_scheme *scheme) {
	if(scheme && flib_release(&scheme->_referenceCount, "flib_scheme")) {
		flib_scheme_destroy(scheme);
	}
}

bool flib_scheme_get_mod(flib_scheme *scheme, const char *name) {
	if(!log_badargs_if2(scheme==NULL, name==NULL)) {
		for(int i=0; i<scheme->meta->modCount; i++) {
			if(!strcmp(scheme->meta->mods[i].name, name)) {
				return scheme->mods[i];
			}
		}
		flib_log_e("Unable to find game mod %s", name);
	}
	return false;
}

int flib_scheme_get_setting(flib_scheme *scheme, const char *name, int def) {
	if(!log_badargs_if2(scheme==NULL, name==NULL)) {
		for(int i=0; i<scheme->meta->settingCount; i++) {
			if(!strcmp(scheme->meta->settings[i].name, name)) {
				return scheme->settings[i];
			}
		}
		flib_log_e("Unable to find game setting %s", name);
	}
	return def;
}
