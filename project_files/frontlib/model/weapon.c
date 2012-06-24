#include "weapon.h"

#include "../util/inihelper.h"
#include "../util/logging.h"
#include "../util/util.h"
#include "../util/refcounter.h"
#include "../util/list.h"

#include <stdlib.h>
#include <ctype.h>
#include <string.h>

static void flib_weaponset_destroy(flib_weaponset *cfg) {
	if(cfg) {
		free(cfg->name);
		free(cfg);
	}
}

static void setField(char field[WEAPONS_COUNT+1], const char *line, int lineLen, bool no9) {
	if(lineLen>WEAPONS_COUNT) {
		lineLen = WEAPONS_COUNT;
	}

	char min = '0';
	char max = no9 ? '8' : '9';
	for(int i=0; i<lineLen; i++) {
		if(line[i] >= min && line[i] <= max) {
			field[i] = line[i];
		} else {
			flib_log_w("Invalid character in weapon config string \"%.*s\", position %i", lineLen, line, i);
			field[i] = '0';
		}
	}
	for(int i=lineLen; i<WEAPONS_COUNT; i++) {
		field[i] = '0';
	}
	field[WEAPONS_COUNT] = 0;
}

flib_weaponset *flib_weaponset_create(const char *name) {
	flib_weaponset *result = NULL;
	if(!name) {
		flib_log_e("null parameter in flib_weaponset_create_str");
	} else {
		flib_weaponset *newSet = flib_weaponset_retain(flib_calloc(1, sizeof(flib_weaponset)));
		if(newSet) {
			newSet->name = flib_strdupnull(name);
			if(newSet->name) {
				setField(newSet->loadout, "", 0, false);
				setField(newSet->crateprob, "", 0, false);
				setField(newSet->crateammo, "", 0, false);
				setField(newSet->delay, "", 0, false);
				result = flib_weaponset_retain(newSet);
			}
		}
		flib_weaponset_release(newSet);
	}
	return result;
}

flib_weaponset *flib_weaponset_retain(flib_weaponset *weaponset) {
	if(weaponset) {
		flib_retain(&weaponset->_referenceCount, "flib_weaponset");
	}
	return weaponset;
}

void flib_weaponset_release(flib_weaponset *weaponset) {
	if(weaponset && flib_release(&weaponset->_referenceCount, "flib_weaponset")) {
		flib_weaponset_destroy(weaponset);
	}
}

static void flib_weaponsetlist_destroy(flib_weaponsetlist *list) {
	if(list) {
		for(int i=0; i<list->weaponsetCount; i++) {
			flib_weaponset_release(list->weaponsets[i]);
		}
		free(list);
	}
}

flib_weaponset *flib_weaponset_from_ammostring(const char *name, const char *ammostring) {
	flib_weaponset *result = NULL;
	if(!name || !ammostring) {
		flib_log_e("null parameter in flib_weaponset_from_ammostring");
	} else {
		result = flib_weaponset_create(name);
		if(result) {
			int fieldlen = strlen(ammostring)/4;
			setField(result->loadout, ammostring, fieldlen, false);
			setField(result->crateprob, ammostring + fieldlen, fieldlen, true);
			setField(result->delay, ammostring + 2*fieldlen, fieldlen, true);
			setField(result->crateammo, ammostring + 3*fieldlen, fieldlen, true);
		}
	}
	return result;
}

static int fillWeaponsetFromIni(flib_weaponsetlist *list, flib_ini *ini, int index) {
	int result = -1;
	char *keyname = flib_ini_get_keyname(ini, index);
	char *decodedKeyname = flib_urldecode(keyname);
	char *ammostring = NULL;
	if(decodedKeyname && !flib_ini_get_str(ini, &ammostring, keyname)) {
		flib_weaponset *set = flib_weaponset_from_ammostring(decodedKeyname, ammostring);
		if(set) {
			result = flib_weaponsetlist_insert(list, set, list->weaponsetCount);
		}
		flib_weaponset_release(set);
	}
	free(ammostring);
	free(decodedKeyname);
	free(keyname);
	return result;
}

static int fillWeaponsetsFromIni(flib_weaponsetlist *list, flib_ini *ini) {
	bool error = false;
	int weaponsets = flib_ini_get_keycount(ini);

	for(int i=0; i<weaponsets && !error; i++) {
		error |= fillWeaponsetFromIni(list, ini, i);
	}
	return error;
}

flib_weaponsetlist *flib_weaponsetlist_from_ini(const char *filename) {
	flib_weaponsetlist *result = NULL;
	if(!filename) {
		flib_log_e("null parameter in flib_weaponsetlist_from_ini");
	} else {
		flib_ini *ini = flib_ini_load(filename);
		if(!ini) {
			flib_log_e("Missing file %s.", filename);
		} else if(flib_ini_enter_section(ini, "General")) {
			flib_log_e("Missing section \"General\" in file %s.", filename);
		} else {
			flib_weaponsetlist *list = flib_weaponsetlist_create();
			if(list) {
				if(!fillWeaponsetsFromIni(list, ini)) {
					result = flib_weaponsetlist_retain(list);
				}
			}
			flib_weaponsetlist_release(list);
		}
		flib_ini_destroy(ini);
	}
	return result;
}

static bool needsEscape(char c) {
	return !((c>='0' && c<='9') || (c>='a' && c <='z'));
}


static int writeWeaponsetToIni(flib_ini *ini, flib_weaponset *set) {
	int result = -1;
	char weaponstring[WEAPONS_COUNT*4+1];
	strcpy(weaponstring, set->loadout);
	strcat(weaponstring, set->crateprob);
	strcat(weaponstring, set->delay);
	strcat(weaponstring, set->crateammo);

	char *escapedname = flib_urlencode_pred(set->name, needsEscape);
	if(escapedname) {
		result = flib_ini_set_str(ini, escapedname, weaponstring);
	}
	free(escapedname);
	return result;
}

int flib_weaponsetlist_to_ini(const char *filename, const flib_weaponsetlist *list) {
	int result = -1;
	if(!filename || !list) {
		flib_log_e("null parameter in flib_weaponsetlist_to_ini");
	} else {
		flib_ini *ini = flib_ini_create(NULL);
		if(ini && !flib_ini_create_section(ini, "General")) {
			bool error = false;
			for(int i=0; i<list->weaponsetCount && !error; i++) {
				error |= writeWeaponsetToIni(ini, list->weaponsets[i]);
			}

			if(!error) {
				result = flib_ini_save(ini, filename);
			}
		}
		flib_ini_destroy(ini);
	}
	return result;
}

flib_weaponsetlist *flib_weaponsetlist_create() {
	return flib_weaponsetlist_retain(flib_calloc(1, sizeof(flib_weaponsetlist)));
}

int flib_weaponsetlist_insert(flib_weaponsetlist *list, flib_weaponset *set, int pos) {
	flib_weaponset **changedList = flib_list_insert(list->weaponsets, &list->weaponsetCount, sizeof(*list->weaponsets), &set, pos);
	if(changedList) {
		list->weaponsets = changedList;
		flib_weaponset_retain(set);
		return 0;
	} else {
		return -1;
	}
}

int flib_weaponsetlist_delete(flib_weaponsetlist *list, int pos) {
	int result = -1;
	if(!list || pos<0 || pos>=list->weaponsetCount) {
		flib_log_e("Invalid parameter in flib_weaponsetlist_delete");
	} else {
		flib_weaponset *elem = list->weaponsets[pos];
		flib_weaponset **changedList = flib_list_delete(list->weaponsets, &list->weaponsetCount, sizeof(*list->weaponsets), pos);
		if(changedList || list->weaponsetCount==0) {
			list->weaponsets = changedList;
			flib_weaponset_release(elem);
			result = 0;
		}
	}
	return result;
}

flib_weaponsetlist *flib_weaponsetlist_retain(flib_weaponsetlist *list) {
	if(list) {
		flib_retain(&list->_referenceCount, "flib_weaponsetlist");
	}
	return list;
}

void flib_weaponsetlist_release(flib_weaponsetlist *list) {
	if(list && flib_release(&list->_referenceCount, "flib_weaponsetlist")) {
		flib_weaponsetlist_destroy(list);
	}
}
