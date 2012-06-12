#include "team.h"

#include "../util/inihelper.h"
#include "../util/util.h"
#include "../util/logging.h"

static flib_team *from_ini_handleError(flib_team *result, dictionary *settingfile, char **bindingKeys) {
	if(settingfile) {
		iniparser_freedict(settingfile);
	}
	flib_team_destroy(result);
	free(bindingKeys);
	return NULL;
}

flib_team *flib_team_from_ini(const char *filename) {
	flib_team *result = flib_calloc(1, sizeof(flib_team));
	dictionary *settingfile = NULL;
	char **bindingKeys = NULL;

	if(!filename) {
		flib_log_e("null parameter in flib_team_from_ini");
		return from_ini_handleError(result, settingfile, bindingKeys);
	}

	if(!result) {
		return from_ini_handleError(result, settingfile, bindingKeys);
	}

	settingfile = iniparser_load(filename);
	if(!settingfile) {
		flib_log_e("Error loading team file %s", filename);
		return from_ini_handleError(result, settingfile, bindingKeys);
	}

	bool error = false;
	result->name = inihelper_getstringdup(settingfile, &error, "team", "name");
	result->grave = inihelper_getstringdup(settingfile, &error, "team", "grave");
	result->fort = inihelper_getstringdup(settingfile, &error, "team", "fort");
	result->voicepack = inihelper_getstringdup(settingfile, &error, "team", "voicepack");
	result->flag = inihelper_getstringdup(settingfile, &error, "team", "flag");
	result->rounds = inihelper_getint(settingfile, &error, "team", "rounds");
	result->wins = inihelper_getint(settingfile, &error, "team", "wins");
	result->campaignProgress = inihelper_getint(settingfile, &error, "team", "campaignprogress");
	int difficulty = inihelper_getint(settingfile, &error, "team", "difficulty");

	char sectionName[10];
	strcpy(sectionName, "hedgehog0");
	for(int i=0; i<HEDGEHOGS_PER_TEAM; i++) {
		sectionName[8] = '0'+i;
		result->hogs[i].name = inihelper_getstringdup(settingfile, &error, sectionName, "name");
		result->hogs[i].hat = inihelper_getstringdup(settingfile, &error, sectionName, "hat");
		result->hogs[i].rounds = inihelper_getint(settingfile, &error, sectionName, "rounds");
		result->hogs[i].kills = inihelper_getint(settingfile, &error, sectionName, "kills");
		result->hogs[i].deaths = inihelper_getint(settingfile, &error, sectionName, "deaths");
		result->hogs[i].suicides = inihelper_getint(settingfile, &error, sectionName, "suicides");
		result->hogs[i].difficulty = difficulty;
		result->hogs[i].initialHealth = TEAM_DEFAULT_HEALTH;
	}

	result->bindingCount = iniparser_getsecnkeys(settingfile, "binds");
	result->bindings = flib_calloc(result->bindingCount, sizeof(flib_binding));
	bindingKeys = iniparser_getseckeys(settingfile, "binds");
	if(!result->bindings || !bindingKeys) {
		return from_ini_handleError(result, settingfile, bindingKeys);
	}

	for(int i=0; i<result->bindingCount; i++) {
		result->bindings[i].binding = flib_strdupnull(iniparser_getstring(settingfile, bindingKeys[i], NULL));
		// The key names all start with "binds:", so we skip that.
		result->bindings[i].action = inihelper_urldecode(bindingKeys[i]+strlen("binds:"));
		if(!result->bindings[i].action || !result->bindings[i].binding) {
			error = true;
		}
	}

	if(error) {
		flib_log_e("Error reading team file %s", filename);
		return from_ini_handleError(result, settingfile, bindingKeys);
	}

	iniparser_freedict(settingfile);
	free(bindingKeys);
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
