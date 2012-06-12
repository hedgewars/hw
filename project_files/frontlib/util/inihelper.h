/**
 * Convenience interface for ini reading/writing.
 *
 * We currently use iniparser in the background, but using its interface directly is a bit verbose.
 * This module is supposed to 1. make ini reading and writing a bit more convenient, and 2. hide
 * the iniparser dependency so it can at need be easily replaced.
 */

#ifndef INIHELPER_H_
#define INIHELPER_H_

#include "../iniparser/iniparser.h"

#include <stdbool.h>

struct _flib_ini;
typedef struct _flib_inihelper flib_ini;

/**
 * Returned buffer must be free()d
 */
char *inihelper_urlencode(const char *inbuf);

/**
 * Returned buffer must be free()d
 */
char *inihelper_urldecode(const char *inbuf);

/**
 * Create a key in the format "sectionName:keyName"
 * Returned buffer must be free()d
 */
char *inihelper_createDictKey(const char *sectionName, const char *keyName);

/**
 * Returns an internal buffer, don't modify or free
 * Sets error to true if something goes wrong, leaves it unchanged otherwise.
 */
char *inihelper_getstring(dictionary *inifile, bool *error, const char *sectionName, const char *keyName);

/**
 * Returned buffer must be free()d
 * Sets error to true if something goes wrong, leaves it unchanged otherwise.
 */
char *inihelper_getstringdup(dictionary *inifile, bool *error, const char *sectionName, const char *keyName);

/**
 * Sets error to true if something goes wrong, leaves it unchanged otherwise.
 */
int inihelper_getint(dictionary *inifile, bool *error, const char *sectionName, const char *keyName);

/**
 * Sets error to true if something goes wrong, leaves it unchanged otherwise.
 */
bool inihelper_getbool(dictionary *inifile, bool *error, const char *sectionName, const char *keyName);

/**
 * Returns a nonzero value on error.
 */
int inihelper_setstr(dictionary *dict, const char *sectionName, const char *keyName, const char *value);

/**
 * Returns a nonzero value on error.
 */
int inihelper_setint(dictionary *dict, const char *sectionName, const char *keyName, int value);

/**
 * Set an ini setting to "true" or "false".
 * Returns a nonzero value on error.
 */
int inihelper_setbool(dictionary *dict, const char *sectionName, const char *keyName, bool value);

#endif /* INIHELPER_H_ */
