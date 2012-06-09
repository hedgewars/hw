#include "cfg.h"

#include "../iniparser/iniparser.h"
#include "../iniparser/dictionary.h"
#include "../util/inihelper.h"
#include "../util/logging.h"
#include "../util/util.h"

#include <stdio.h>

static void freeCfgMeta(flib_cfg_meta *cfg) {
	if(cfg) {
		if(cfg->settings) {
			for(int i=0; i<cfg->settingCount; i++) {
				free(cfg->settings[i].iniName);
				free(cfg->settings[i].title);
				free(cfg->settings[i].engineCommand);
				free(cfg->settings[i].image);
			}
			free(cfg->settings);
		}
		if(cfg->mods) {
			for(int i=0; i<cfg->modCount; i++) {
				free(cfg->mods[i].iniName);
			}
			free(cfg->mods);
		}
		free(cfg);
	}
}

flib_cfg_meta *flib_cfg_meta_from_ini(const char *settingpath, const char *modpath) {
	if(!settingpath || !modpath) {
		return NULL;
	}
	flib_cfg_meta *result = calloc(1, sizeof(flib_cfg_meta));
	dictionary *settingfile = iniparser_load(settingpath);
	dictionary *modfile = iniparser_load(modpath);

	if(!result || !settingfile || !modfile) {
		goto handleError;
	}

	result->settingCount = iniparser_getnsec(settingfile);
	result->modCount = iniparser_getnsec(modfile);
	result->settings = calloc(result->settingCount, sizeof(flib_cfg_setting_meta));
	result->mods = calloc(result->modCount, sizeof(flib_cfg_mod_meta));

	if(!result->settings || !result->mods) {
		goto handleError;
	}

	for(int i=0; i<result->settingCount; i++) {
		char *sectionName = iniparser_getsecname(settingfile, i);
		if(!sectionName) {
			goto handleError;
		}

		bool error = false;
		result->settings[i].iniName = flib_strdupnull(sectionName);
		result->settings[i].title = inihelper_getstringdup(settingfile, &error, sectionName, "title");
		result->settings[i].engineCommand = inihelper_getstringdup(settingfile, &error, sectionName, "command");
		result->settings[i].image = inihelper_getstringdup(settingfile, &error, sectionName, "image");
		result->settings[i].checkOverMax = inihelper_getbool(settingfile, &error, sectionName, "checkOverMax");
		result->settings[i].times1000 = inihelper_getbool(settingfile, &error, sectionName, "times1000");
		result->settings[i].min = inihelper_getint(settingfile, &error, sectionName, "min");
		result->settings[i].max = inihelper_getint(settingfile, &error, sectionName, "max");
		result->settings[i].def = inihelper_getint(settingfile, &error, sectionName, "default");
		if(error) {
			flib_log_e("Missing or malformed ini parameter in file %s, section %s", settingpath, sectionName);
			goto handleError;
		}
	}

	for(int i=0; i<result->modCount; i++) {
		char *sectionName = iniparser_getsecname(modfile, i);
		if(!sectionName) {
			goto handleError;
		}

		bool error = false;
		result->mods[i].iniName = flib_strdupnull(sectionName);
		result->mods[i].bitmaskIndex = inihelper_getint(modfile, &error, sectionName, "bitmaskIndex");
		if(error) {
			flib_log_e("Missing or malformed ini parameter in file %s, section %s", modpath, sectionName);
			goto handleError;
		}
	}

	iniparser_freedict(settingfile);
	iniparser_freedict(modfile);
	return result;

	handleError:
	freeCfgMeta(result);
	iniparser_freedict(settingfile);
	iniparser_freedict(modfile);
	return NULL;
}

void flib_cfg_meta_destroy(flib_cfg_meta *metainfo) {
	freeCfgMeta(metainfo);
}

flib_cfg *flib_cfg_create(const flib_cfg_meta *meta, const char *schemeName) {
	flib_cfg *result = calloc(1, sizeof(flib_cfg));
	if(!meta || !result || !schemeName) {
		return NULL;
	}

	result->modCount = meta->modCount;
	result->settingCount = meta->settingCount;
	result->schemeName = flib_strdupnull(schemeName);
	result->mods = calloc(meta->modCount, sizeof(*result->mods));
	result->settings = calloc(meta->settingCount, sizeof(*result->settings));

	if(!result->mods || !result->settings || !result->schemeName) {
		flib_cfg_destroy(result);
		return NULL;
	}

	for(int i=0; i<meta->settingCount; i++) {
		result->settings[i] = meta->settings[i].def;
	}
	return result;
}

flib_cfg *flib_cfg_from_ini_handleError(flib_cfg *result, dictionary *settingfile) {
	iniparser_freedict(settingfile);
	flib_cfg_destroy(result);
	return NULL;
}

flib_cfg *flib_cfg_from_ini(const flib_cfg_meta *meta, const char *filename) {
	if(!meta || !filename) {
		return NULL;
	}
	dictionary *settingfile = iniparser_load(filename);
	if(!settingfile) {
		return NULL;
	}

	bool error = false;
	char *schemename = inihelper_getstring(settingfile, &error, "Scheme", "name");
	if(!schemename) {
		return flib_cfg_from_ini_handleError(NULL, settingfile);
	}

	flib_cfg *result = flib_cfg_create(meta, schemename);

	for(int i=0; i<meta->settingCount; i++) {
		char *key = inihelper_createDictKey("BasicSettings", meta->settings[i].iniName);
		if(!key) {
			return flib_cfg_from_ini_handleError(result, settingfile);
		}
		result->settings[i] = iniparser_getint(settingfile, key, meta->settings[i].def);
		free(key);
	}
	for(int i=0; i<meta->modCount; i++) {
		char *key = inihelper_createDictKey("GameMods", meta->mods[i].iniName);
		if(!key) {
			return flib_cfg_from_ini_handleError(result, settingfile);
		}
		result->mods[i] = iniparser_getboolean(settingfile, key, false);
		free(key);
	}
	iniparser_freedict(settingfile);
	return result;
}

int flib_cfg_to_ini(const flib_cfg_meta *meta, const char *filename, const flib_cfg *config) {
	int result = -1;
	if(meta && filename && config && config->modCount==meta->modCount && config->settingCount==meta->settingCount) {
		dictionary *dict = dictionary_new(0);
		if(dict) {
			bool error = false;
			// Add the sections
			error |= iniparser_set(dict, "Scheme", NULL);
			error |= iniparser_set(dict, "BasicSettings", NULL);
			error |= iniparser_set(dict, "GameMods", NULL);

			// Add the values
			error |= inihelper_setstr(dict, "Scheme", "name", config->schemeName);
			for(int i=0; i<config->settingCount; i++) {
				error |= inihelper_setint(dict, "BasicSettings", meta->settings[i].iniName, config->settings[i]);
			}
			for(int i=0; i<config->modCount; i++) {
				error |= inihelper_setbool(dict, "GameMods", meta->mods[i].iniName, config->mods[i]);
			}
			if(!error) {
				FILE *inifile = fopen(filename, "wb");
				if(inifile) {
					iniparser_dump_ini(dict, inifile);
					fclose(inifile);
					result = 0;
				}
			}
			dictionary_del(dict);
		}
	}
	return result;
}

void flib_cfg_destroy(flib_cfg* cfg) {
	if(cfg) {
		free(cfg->mods);
		free(cfg->settings);
		free(cfg->schemeName);
		free(cfg);
	}
}
