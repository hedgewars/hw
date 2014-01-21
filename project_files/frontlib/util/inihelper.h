/*
 * Hedgewars, a free turn based strategy game
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

/**
 * Convenience interface for ini reading/writing.
 *
 * We currently use iniparser in the background, but using its interface directly is a bit verbose.
 * This module is supposed to 1. make ini reading and writing a bit more convenient, and 2. hide
 * the iniparser dependency so it can at need be easily replaced.
 */

#ifndef INIHELPER_H_
#define INIHELPER_H_

#include <stdbool.h>

#define INI_ERROR_NOTFOUND -1
#define INI_ERROR_FORMAT -2
#define INI_ERROR_OTHER -100

typedef struct _flib_ini flib_ini;

/**
 * Create a new ini data structure, pre-filled with the contents of
 * the file "filename" if it exists. If filename is null, or the file
 * is not found, an empty ini will be created. However, if an error
 * occurs while reading the ini file (or any other error), null
 * is returned.
 *
 * This behavior is useful for modifying an existing ini file without
 * discarding unknown keys.
 */
flib_ini *flib_ini_create(const char *filename);

/**
 * Similar to flib_ini_create, but fails if the file is not found
 * or if filename is null.
 */
flib_ini *flib_ini_load(const char *filename);

/**
 * Store the ini to the file "filename", overwriting
 * the previous contents. Returns 0 on success.
 */
int flib_ini_save(flib_ini *ini, const char *filename);

void flib_ini_destroy(flib_ini *ini);

/**
 * Enter the section with the specified name. Returns 0 on
 * success, INI_ERROR_NOTFOUND if the section does not exist
 * and a different value if another error occurs.
 * If an error occurs, there is no current section.
 *
 * The section name should only consist of letters and
 * numbers.
 */
int flib_ini_enter_section(flib_ini *ini, const char *section);

/**
 * Creates and enters the section with the specified name. Simply
 * enters the section if it exists already. Returns 0 on success
 * and a different value if another error occurs.
 * If an error occurs, there is no current section.
 */
int flib_ini_create_section(flib_ini *ini, const char *section);

/**
 * Find a key in the current section and store the value in outVar
 * as a newly allocated string. Returns 0 on success, INI_ERROR_NOTFOUND
 * if the key was not found and a different value for other errors,
 * e.g. if there is no current section.
 */
int flib_ini_get_str(flib_ini *ini, char **outVar, const char *key);

/**
 * Find a key in the current section and store the value in outVar
 * as a newly allocated string. If the key is not found, the default
 * value will be used instead. Returns 0 on success.
 */
int flib_ini_get_str_opt(flib_ini *ini, char **outVar, const char *key, const char *def);

/**
 * Find a key in the current section and store the value in outVar
 * as an int. Returns 0 on success, INI_ERROR_NOTFOUND
 * if the key was not found, INI_ERROR_FORMAT if it was found but
 * could not be converted to an int, and a different value for other
 * errors, e.g. if there is no current section.
 */
int flib_ini_get_int(flib_ini *ini, int *outVar, const char *key);

/**
 * Find a key in the current section and store the value in outVar
 * as an int. If the key is not found, the default value will be used instead.
 * Returns 0 on success, INI_ERROR_FORMAT if the value was found but
 * could not be converted to int, and another value otherwise.
 */
int flib_ini_get_int_opt(flib_ini *ini, int *outVar, const char *key, int def);

/**
 * Find a key in the current section and store the value in outVar
 * as a bool. Treats everything beginning with "Y", "T" or "1" as true,
 * everything starting with "N", "F" or "1" as false.
 *
 * Returns 0 on success, INI_ERROR_NOTFOUND if the key was not found,
 * INI_ERROR_FORMAT if the value could not be interpreted as boolean,
 * and another value otherwise.
 */
int flib_ini_get_bool(flib_ini *ini, bool *outVar, const char *key);

/**
 * Find a key in the current section and store the value in outVar
 * as a bool. If the key is not found, the default value will be
 * used instead. Returns 0 on success, INI_ERROR_FORMAT if the
 * value could not be interpreted as boolean, and another value otherwise.
 */
int flib_ini_get_bool_opt(flib_ini *ini, bool *outVar, const char *key, bool def);

/**
 * In the current section, associate key with value. Returns 0 on success.
 */
int flib_ini_set_str(flib_ini *ini, const char *key, const char *value);

/**
 * In the current section, associate key with value. Returns 0 on success.
 */
int flib_ini_set_int(flib_ini *ini, const char *key, int value);

/**
 * In the current section, associate key with value. Returns 0 on success.
 */
int flib_ini_set_bool(flib_ini *ini, const char *key, bool value);

/**
 * Returns the number of sections in the ini file, or a negative value on error.
 */
int flib_ini_get_sectioncount(flib_ini *ini);

/**
 * Returns the name of the section, or NULL on error. The returned string must
 * be free()d.
 *
 * Note: There is no guarantee that the order of the sections
 * will remain stable if the ini is modified.
 */
char *flib_ini_get_sectionname(flib_ini *ini, int number);

/**
 * Returns the number of keys in the current section, or -1 on error.
 */
int flib_ini_get_keycount(flib_ini *ini);

/**
 * Returns the name of the key in the current section, or NULL on error.
 * The returned string must be free()d.
 *
 * Note: There is no guarantee that the order of the keys in a section
 * will remain stable if the ini is modified.
 */
char *flib_ini_get_keyname(flib_ini *ini, int number);

#endif /* INIHELPER_H_ */
