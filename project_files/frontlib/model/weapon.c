#include "weapon.h"

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
		flib_ini *ini = flib_ini_load(filename);
		if(!ini) {
			flib_log_e("Error loading weapon scheme file %s", filename);
		} else if(!flib_ini_enter_section(ini, "weaponset")) {
			bool error = false;
			char *name = NULL, *loadout = NULL, *crateprob = NULL, *crateammo = NULL, *delay = NULL;
			error |= flib_ini_get_str(ini, &name, "name");
			error |= flib_ini_get_str(ini, &loadout, "loadout");
			error |= flib_ini_get_str(ini, &crateprob, "crateprob");
			error |= flib_ini_get_str(ini, &crateammo, "crateammo");
			error |= flib_ini_get_str(ini, &delay, "delay");

			if(error) {
				flib_log_e("Missing key in weapon scheme file %s", filename);
			} else {
				result = flib_weaponset_create_str(name, loadout, crateprob, crateammo, delay);
			}
			free(name);
			free(loadout);
			free(crateprob);
			free(crateammo);
			free(delay);
		}
		flib_ini_destroy(ini);
	}
	return result;
}

int flib_weaponset_to_ini(const char *filename, const flib_weaponset *set) {
	int result = -1;
	if(!filename || !set) {
		flib_log_e("null parameter in flib_weaponset_to_ini");
	} else {
		flib_ini *ini = flib_ini_create(filename);
		if(!flib_ini_create_section(ini, "weaponset")) {
			bool error = false;
			error |= flib_ini_set_str(ini, "name", set->name);
			error |= flib_ini_set_str(ini, "loadout", set->loadout);
			error |= flib_ini_set_str(ini, "crateprob", set->crateprob);
			error |= flib_ini_set_str(ini, "crateammo", set->crateammo);
			error |= flib_ini_set_str(ini, "delay", set->delay);
			if(!error) {
				result = flib_ini_save(ini, filename);
			}
		}
		flib_ini_destroy(ini);
	}
	return result;
}
