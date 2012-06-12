#include "cfg.h"

#include "../util/inihelper.h"
#include "../util/logging.h"
#include "../util/util.h"

#include <stdio.h>
#include <stdlib.h>

static flib_cfg_meta *flib_cfg_meta_from_ini_handleError(flib_cfg_meta *result, flib_ini *settingfile, flib_ini *modfile) {
	flib_cfg_meta_destroy(result);
	flib_ini_destroy(settingfile);
	flib_ini_destroy(modfile);
	return NULL;
}

flib_cfg_meta *flib_cfg_meta_from_ini(const char *settingpath, const char *modpath) {
	if(!settingpath || !modpath) {
		flib_log_e("null parameter in flib_cfg_meta_from_ini");
		return NULL;
	}
	flib_cfg_meta *result = flib_calloc(1, sizeof(flib_cfg_meta));
	flib_ini *settingfile = flib_ini_load(settingpath);
	flib_ini *modfile = flib_ini_load(modpath);

	if(!result || !settingfile || !modfile) {
		return flib_cfg_meta_from_ini_handleError(result, settingfile, modfile);
	}

	result->settingCount = flib_ini_get_sectioncount(settingfile);
	result->modCount = flib_ini_get_sectioncount(modfile);
	result->settings = flib_calloc(result->settingCount, sizeof(flib_cfg_setting_meta));
	result->mods = flib_calloc(result->modCount, sizeof(flib_cfg_mod_meta));

	if(!result->settings || !result->mods) {
		return flib_cfg_meta_from_ini_handleError(result, settingfile, modfile);
	}

	for(int i=0; i<result->settingCount; i++) {
		result->settings[i].iniName = flib_ini_get_sectionname(settingfile, i);
		if(!result->settings[i].iniName) {
			return flib_cfg_meta_from_ini_handleError(result, settingfile, modfile);
		}

		bool error = false;
		error |= flib_ini_enter_section(settingfile, result->settings[i].iniName);
		error |= flib_ini_get_str(settingfile, &result->settings[i].title, "title");
		error |= flib_ini_get_str(settingfile, &result->settings[i].engineCommand, "command");
		error |= flib_ini_get_str(settingfile, &result->settings[i].image, "image");
		error |= flib_ini_get_bool(settingfile, &result->settings[i].checkOverMax, "checkOverMax");
		error |= flib_ini_get_bool(settingfile, &result->settings[i].times1000, "times1000");
		error |= flib_ini_get_int(settingfile, &result->settings[i].min, "min");
		error |= flib_ini_get_int(settingfile, &result->settings[i].max, "max");
		error |= flib_ini_get_int(settingfile, &result->settings[i].def, "default");

		if(error) {
			flib_log_e("Missing or malformed ini parameter in file %s, section %s", settingpath, result->settings[i].iniName);
			return flib_cfg_meta_from_ini_handleError(result, settingfile, modfile);
		}
	}

	for(int i=0; i<result->modCount; i++) {
		result->mods[i].iniName = flib_ini_get_sectionname(modfile, i);
		if(!result->mods[i].iniName) {
			return flib_cfg_meta_from_ini_handleError(result, settingfile, modfile);
		}

		bool error = false;
		error |= flib_ini_enter_section(modfile, result->mods[i].iniName);
		error |= flib_ini_get_int(modfile, &result->mods[i].bitmaskIndex, "bitmaskIndex");
		if(error) {
			flib_log_e("Missing or malformed ini parameter in file %s, section %s", modpath, result->mods[i].iniName);
			return flib_cfg_meta_from_ini_handleError(result, settingfile, modfile);
		}
	}

	flib_ini_destroy(settingfile);
	flib_ini_destroy(modfile);
	return result;
}

void flib_cfg_meta_destroy(flib_cfg_meta *cfg) {
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

flib_cfg *flib_cfg_create(const flib_cfg_meta *meta, const char *schemeName) {
	flib_cfg *result = flib_calloc(1, sizeof(flib_cfg));
	if(!meta || !result || !schemeName) {
		flib_log_e("null parameter in flib_cfg_create");
		return NULL;
	}

	result->modCount = meta->modCount;
	result->settingCount = meta->settingCount;
	result->schemeName = flib_strdupnull(schemeName);
	result->mods = flib_calloc(meta->modCount, sizeof(*result->mods));
	result->settings = flib_calloc(meta->settingCount, sizeof(*result->settings));

	if(!result->mods || !result->settings || !result->schemeName) {
		flib_cfg_destroy(result);
		return NULL;
	}

	for(int i=0; i<meta->settingCount; i++) {
		result->settings[i] = meta->settings[i].def;
	}
	return result;
}

flib_cfg *flib_cfg_from_ini_handleError(flib_cfg *result, flib_ini *settingfile) {
	flib_ini_destroy(settingfile);
	flib_cfg_destroy(result);
	return NULL;
}

flib_cfg *flib_cfg_from_ini(const flib_cfg_meta *meta, const char *filename) {
	if(!meta || !filename) {
		flib_log_e("null parameter in flib_cfg_from_ini");
		return NULL;
	}
	flib_ini *settingfile = flib_ini_load(filename);
	if(!settingfile) {
		return NULL;
	}

	char *schemename = NULL;
	if(flib_ini_enter_section(settingfile, "Scheme")) {
		flib_log_e("Missing section \"Scheme\" in config file %s.", filename);
		return flib_cfg_from_ini_handleError(NULL, settingfile);
	}
	if(flib_ini_get_str(settingfile, &schemename, "name")) {
		flib_log_e("Missing scheme name in config file %s.", filename);
		return flib_cfg_from_ini_handleError(NULL, settingfile);
	}

	flib_cfg *result = flib_cfg_create(meta, schemename);

	if(flib_ini_enter_section(settingfile, "BasicSettings")) {
		flib_log_w("Missing section \"BasicSettings\" in config file %s, using defaults.", filename);
	} else {
		for(int i=0; i<meta->settingCount; i++) {
			if(flib_ini_get_int_opt(settingfile, &result->settings[i], meta->settings[i].iniName, meta->settings[i].def)) {
				flib_log_e("Error reading BasicSetting %s in config file %s.", meta->settings[i].iniName, filename);
				return flib_cfg_from_ini_handleError(result, settingfile);
			}
		}
	}

	if(flib_ini_enter_section(settingfile, "GameMods")) {
		flib_log_w("Missing section \"GameMods\" in config file %s, using defaults.", filename);
	} else {
		for(int i=0; i<meta->modCount; i++) {
			if(flib_ini_get_bool_opt(settingfile, &result->mods[i], meta->mods[i].iniName, false)) {
				flib_log_e("Error reading GameMod %s in config file %s.", meta->mods[i].iniName, filename);
				return flib_cfg_from_ini_handleError(result, settingfile);
			}
		}
	}
	flib_ini_destroy(settingfile);
	return result;
}

int flib_cfg_to_ini(const flib_cfg_meta *meta, const char *filename, const flib_cfg *config) {
	int result = -1;
	if(!meta || !filename || !config || config->modCount!=meta->modCount || config->settingCount!=meta->settingCount) {
		flib_log_e("Invalid parameter in flib_cfg_to_ini");
	} else {
		flib_ini *ini = flib_ini_create(filename);
		if(ini) {
			bool error = false;

			// Add the values
			error |= flib_ini_create_section(ini, "Scheme");
			if(!error) {
				error |= flib_ini_set_str(ini, "name", config->schemeName);
			}


			error |= flib_ini_create_section(ini, "BasicSettings");
			if(!error) {
				for(int i=0; i<config->settingCount; i++) {
					error |= flib_ini_set_int(ini, meta->settings[i].iniName, config->settings[i]);
				}
			}

			error |= flib_ini_create_section(ini, "GameMods");
			if(!error) {
				for(int i=0; i<config->modCount; i++) {
					error |= flib_ini_set_bool(ini, meta->mods[i].iniName, config->mods[i]);
				}
			}

			if(!error) {
				result = flib_ini_save(ini, filename);
			}
		}
		flib_ini_destroy(ini);
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
