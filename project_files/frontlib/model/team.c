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
	flib_team *result = flib_calloc(1, sizeof(flib_team));
	flib_ini *ini = NULL;

	if(!filename) {
		flib_log_e("null parameter in flib_team_from_ini");
		return from_ini_handleError(result, ini);
	}

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
	if(!filename || !team) {
		flib_log_e("null parameter in flib_team_to_ini");
	} else {
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

void flib_team_destroy(flib_team *team) {
	if(team) {
		for(int i=0; i<HEDGEHOGS_PER_TEAM; i++) {
			free(team->hogs[i].name);
			free(team->hogs[i].hat);
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
		free(team->hash);
		flib_weaponset_destroy(team->weaponset);
		free(team);
	}
}
