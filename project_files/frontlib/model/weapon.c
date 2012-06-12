#include "weapon.h"

#include "../iniparser/iniparser.h"
#include "../util/inihelper.h"
#include "../util/logging.h"
#include "../util/util.h"

#include <stdlib.h>
#include <ctype.h>

int set_field(char field[WEAPONS_COUNT+1], const char *line, bool no9) {
	// Validate the new string
	for(int i=0; i<WEAPONS_COUNT && line[i]; i++) {
		if(line[i] < '0' || line[i] > '9' || (no9 && line[i] == '9')) {
			flib_log_e("Invalid character in weapon config string \"%.*s\", position %i", WEAPONS_COUNT, line, i);
			return -1;
		}
	}

	bool lineEnded = false;
	for(int i=0; i<WEAPONS_COUNT; i++) {
		if(!lineEnded && !line[i]) {
			flib_log_w("Incomplete weapon config line \"%s\", filling with zeroes.", line);
			lineEnded = true;
		}
		if(lineEnded) {
			field[i] = '0';
		} else {
			field[i] = line[i];
		}
	}
	field[WEAPONS_COUNT] = 0;
	return 0;
}

static flib_weaponset *flib_weaponset_create_str(const char *name, const char *loadoutStr, const char *crateProbStr, const char *crateAmmoStr, const char *delayStr) {
	flib_weaponset *result = NULL;
	if(!name || !loadoutStr || !crateProbStr || !crateAmmoStr || !delayStr) {
		flib_log_e("null parameter in flib_weaponset_create_str");
	} else {
		flib_weaponset *newSet = flib_calloc(1, sizeof(flib_weaponset));
		char *nameCopy = flib_strdupnull(name);
		if(newSet && nameCopy) {
			newSet->name = nameCopy;
			nameCopy = NULL;
			bool error = false;
			error |= set_field(newSet->loadout, loadoutStr, false);
			error |= set_field(newSet->crateprob, crateProbStr, false);
			error |= set_field(newSet->crateammo, crateAmmoStr, false);
			error |= set_field(newSet->delay, delayStr, false);
			if(!error) {
				result = newSet;
				newSet = NULL;
			}
		}
		free(nameCopy);
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

flib_weaponset *flib_weaponset_create(const char *name) {
	return flib_weaponset_create_str(name, AMMOLINE_DEFAULT_QT, AMMOLINE_DEFAULT_PROB, AMMOLINE_DEFAULT_CRATE, AMMOLINE_DEFAULT_DELAY);
}

flib_weaponset *flib_weaponset_from_ini(const char *filename) {
	flib_weaponset *result = NULL;
	if(!filename) {
		flib_log_e("null parameter in flib_weaponset_from_ini");
	} else {
		dictionary *settingfile = iniparser_load(filename);
		if(!settingfile) {
			flib_log_e("Error loading weapon scheme file %s", filename);
		} else {
			bool error = false;
			char *name = inihelper_getstring(settingfile, &error, "weaponset", "name");
			char *loadout = inihelper_getstring(settingfile, &error, "weaponset", "loadout");
			char *crateprob = inihelper_getstring(settingfile, &error, "weaponset", "crateprob");
			char *crateammo = inihelper_getstring(settingfile, &error, "weaponset", "crateammo");
			char *delay = inihelper_getstring(settingfile, &error, "weaponset", "delay");
			if(error) {
				flib_log_e("Missing key in weapon scheme file %s", filename);
			} else {
				result = flib_weaponset_create_str(name, loadout, crateprob, crateammo, delay);
			}
		}
		iniparser_freedict(settingfile);
	}
	return result;
}

int flib_weaponset_to_ini(const char *filename, const flib_weaponset *set) {
	int result = -1;
	if(!filename || !set) {
		flib_log_e("null parameter in flib_weaponset_to_ini");
	} else {
		dictionary *dict = iniparser_load(filename);
		if(!dict) {
			dict = dictionary_new(0);
		}
		if(dict) {
			bool error = false;
			// Add the sections
			error |= iniparser_set(dict, "weaponset", NULL);

			// Add the values
			error |= inihelper_setstr(dict, "weaponset", "name", set->name);
			error |= inihelper_setstr(dict, "weaponset", "loadout", set->loadout);
			error |= inihelper_setstr(dict, "weaponset", "crateprob", set->crateprob);
			error |= inihelper_setstr(dict, "weaponset", "crateammo", set->crateammo);
			error |= inihelper_setstr(dict, "weaponset", "delay", set->delay);
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
