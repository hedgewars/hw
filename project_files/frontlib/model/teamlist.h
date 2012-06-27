#ifndef TEAMLIST_H_
#define TEAMLIST_H_

#include "team.h"

typedef struct {
	int teamCount;
	flib_team **teams;
} flib_teamlist;

flib_teamlist *flib_teamlist_create();

void flib_teamlist_destroy(flib_teamlist *list);

/**
 * Insert a team into the list. Returns 0 on success.
 */
int flib_teamlist_insert(flib_teamlist *list, flib_team *team, int pos);

/**
 * Delete the item with the name [name] from the list.
 * Returns 0 on success.
 */
int flib_teamlist_delete(flib_teamlist *list, const char *name);

/**
 * Returns the team with the name [name] from the list if it exists, NULL otherwise
 */
flib_team *flib_teamlist_find(const flib_teamlist *list, const char *name);

/**
 * Removes all items from the list and frees "teams".
 */
void flib_teamlist_clear(flib_teamlist *list);

#endif
