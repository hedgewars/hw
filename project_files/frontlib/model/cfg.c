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

#include "cfg.h"

#include "../util/inihelper.h"
#include "../util/logging.h"
#include "../util/util.h"
#include "../util/refcounter.h"

#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>

static void flib_cfg_meta_destroy(flib_cfg_meta *cfg) {
	if(cfg) {
		if(cfg->settings) {
			for(int i=0; i<cfg->settingCount; i++) {
				free(cfg->settings[i].name);
				free(cfg->settings[i].engineCommand);
			}
			free(cfg->settings);
		}
		if(cfg->mods) {
			for(int i=0; i<cfg->modCount; i++) {
				free(cfg->mods[i].name);
			}
			free(cfg->mods);
		}
		free(cfg);
	}
}

static void flib_cfg_destroy(flib_cfg* cfg) {
	if(cfg) {
		flib_cfg_meta_release(cfg->meta);
		free(cfg->mods);
		free(cfg->settings);
		free(cfg->name);
		free(cfg);
	}
}

static flib_cfg_meta *flib_cfg_meta_from_ini_handleError(flib_cfg_meta *result, flib_ini *ini) {
	flib_cfg_meta_destroy(result);
	flib_ini_destroy(ini);
	return NULL;
}

static int readMetaSettingSections(flib_ini *ini, flib_cfg_meta *result, int limit) {
	while(result->settingCount<limit) {
		char sectionName[32];
		if(snprintf(sectionName, sizeof(sectionName), "setting%i", result->settingCount) <= 0) {
			return -1;
		}
		if(!flib_ini_enter_section(ini, sectionName)) {
			flib_cfg_setting_meta *metasetting = &result->settings[result->settingCount];
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

static int readMetaModSections(flib_ini *ini, flib_cfg_meta *result, int limit) {
	while(result->modCount<limit) {
		char sectionName[32];
		if(snprintf(sectionName, sizeof(sectionName), "mod%i", result->modCount) <= 0) {
			return -1;
		}
		if(!flib_ini_enter_section(ini, sectionName)) {
			flib_cfg_mod_meta *metamod = &result->mods[result->modCount];
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

flib_cfg_meta *flib_cfg_meta_from_ini(const char *filename) {
	if(log_badargs_if(filename==NULL)) {
		return NULL;
	}
	flib_cfg_meta *result = flib_cfg_meta_retain(flib_calloc(1, sizeof(flib_cfg_meta)));
	flib_ini *ini = flib_ini_load(filename);

	if(!result || !ini) {
		return flib_cfg_meta_from_ini_handleError(result, ini);
	}

	// We're overallocating here for simplicity
	int sectionCount = flib_ini_get_sectioncount(ini);
	result->settingCount = 0;
	result->modCount = 0;
	result->settings = flib_calloc(sectionCount, sizeof(flib_cfg_setting_meta));
	result->mods = flib_calloc(sectionCount, sizeof(flib_cfg_mod_meta));

	if(!result->settings || !result->mods) {
		return flib_cfg_meta_from_ini_handleError(result, ini);
	}

	if(readMetaSettingSections(ini, result, sectionCount) || readMetaModSections(ini, result, sectionCount)) {
		return flib_cfg_meta_from_ini_handleError(result, ini);
	}

	if(result->settingCount+result->modCount != sectionCount) {
		flib_log_e("Unknown or non-contiguous sections headers in metaconfig.");
		return flib_cfg_meta_from_ini_handleError(result, ini);
	}

	flib_ini_destroy(ini);
	return result;
}

flib_cfg_meta *flib_cfg_meta_retain(flib_cfg_meta *metainfo) {
	if(metainfo) {
		flib_retain(&metainfo->_referenceCount, "flib_cfg_meta");
	}
	return metainfo;
}

void flib_cfg_meta_release(flib_cfg_meta *cfg) {
	if(cfg && flib_release(&cfg->_referenceCount, "flib_cfg_meta")) {
		flib_cfg_meta_destroy(cfg);
	}
}

flib_cfg *flib_cfg_create(flib_cfg_meta *meta, const char *schemeName) {
	flib_cfg *result = flib_cfg_retain(flib_calloc(1, sizeof(flib_cfg)));
	if(log_badargs_if2(meta==NULL, schemeName==NULL) || result==NULL) {
		return NULL;
	}

	result->meta = flib_cfg_meta_retain(meta);
	result->name = flib_strdupnull(schemeName);
	result->mods = flib_calloc(meta->modCount, sizeof(*result->mods));
	result->settings = flib_calloc(meta->settingCount, sizeof(*result->settings));

	if(!result->mods || !result->settings || !result->name) {
		flib_cfg_destroy(result);
		return NULL;
	}

	for(int i=0; i<meta->settingCount; i++) {
		result->settings[i] = meta->settings[i].def;
	}
	return result;
}

flib_cfg *flib_cfg_copy(const flib_cfg *cfg) {
	flib_cfg *result = NULL;
	if(cfg) {
		result = flib_cfg_create(cfg->meta, cfg->name);
		if(result) {
			memcpy(result->mods, cfg->mods, cfg->meta->modCount * sizeof(*cfg->mods));
			memcpy(result->settings, cfg->settings, cfg->meta->settingCount * sizeof(*cfg->settings));
		}
	}
	return result;
}

flib_cfg *flib_cfg_retain(flib_cfg *cfg) {
	if(cfg) {
		flib_retain(&cfg->_referenceCount, "flib_cfg");
	}
	return cfg;
}

void flib_cfg_release(flib_cfg *cfg) {
	if(cfg && flib_release(&cfg->_referenceCount, "flib_cfg")) {
		flib_cfg_destroy(cfg);
	}
}

bool flib_cfg_get_mod(flib_cfg *cfg, const char *name) {
	if(!log_badargs_if2(cfg==NULL, name==NULL)) {
		for(int i=0; i<cfg->meta->modCount; i++) {
			if(!strcmp(cfg->meta->mods[i].name, name)) {
				return cfg->mods[i];
			}
		}
		flib_log_e("Unable to find game mod %s", name);
	}
	return false;
}

int flib_cfg_get_setting(flib_cfg *cfg, const char *name, int def) {
	if(!log_badargs_if2(cfg==NULL, name==NULL)) {
		for(int i=0; i<cfg->meta->settingCount; i++) {
			if(!strcmp(cfg->meta->settings[i].name, name)) {
				return cfg->settings[i];
			}
		}
		flib_log_e("Unable to find game setting %s", name);
	}
	return def;
}
