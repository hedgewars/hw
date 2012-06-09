#ifndef TEAM_H_
#define TEAM_H_

#include "weapon.h"
#include "../hwconsts.h"

#include <stdbool.h>
#include <stdint.h>

#define TEAM_DEFAULT_HOGNAME "Hog"
#define TEAM_DEFAULT_HAT "NoHat"
#define TEAM_DEFAULT_DIFFICULTY 0
#define TEAM_DEFAULT_HEALTH 100

typedef struct {
	char *name;
	char *hat;

	// Statistics. They are irrelevant for the engine or server,
	// but provided for ini reading/writing by the frontend.
	int rounds;
	int deaths;
	int kills;
	int suicides;

	// These settings are sometimes used on a per-team basis.
	int difficulty;
	int initialHealth;
} flib_hog;

typedef struct {
	flib_hog hogs[HEDGEHOGS_PER_TEAM];
	char *name;
	char *grave;
	char *fort;
	char *voicepack;
	char *flag;

	// TODO binds

	// Transient settings used in game setup
	uint32_t color;
	int hogsInGame;
	bool remoteDriven;
	char *hash;

	// This setting is sometimes used on a per-game basis.
	flib_weaponset *weaponset;
} flib_team;

#endif /* TEAM_H_ */
