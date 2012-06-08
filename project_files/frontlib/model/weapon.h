#ifndef MODEL_WEAPON_H_
#define MODEL_WEAPON_H_

#include "../hwconsts.h"

/**
 * These values are all in the range 0..9
 *
 * For loadout, 9 means inifinite ammo.
 * For the other setting, 9 might actually be invalid, it's not possible to set more than 8 in the QtFrontend. (TODO)
 */
typedef struct {
	char loadout[WEAPONS_COUNT+1];
	char crateprob[WEAPONS_COUNT+1];
	char crateammo[WEAPONS_COUNT+1];
	char delay[WEAPONS_COUNT+1];
	char *name;
} flib_weaponset;

/**
 * Returns a new weapon set, or NULL on error.
 * name must not be NULL.
 *
 * The new weapon set is pre-filled with default
 * settings (see hwconsts.h)
 */
flib_weaponset *flib_weaponset_create(const char *name);
flib_weaponset *flib_weaponset_from_ini(const char *filename);
int flib_weaponset_to_ini(const char *filename, const flib_weaponset *set);
void flib_weaponset_destroy(flib_weaponset *set);

#endif
