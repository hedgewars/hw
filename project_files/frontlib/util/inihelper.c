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

#include "inihelper.h"
#include "../iniparser/dictionary.h"
#include "../iniparser/iniparser.h"

#include "logging.h"
#include "util.h"

#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <limits.h>
#include <errno.h>
#include <stdarg.h>

struct _flib_ini {
    dictionary *inidict;
    char *currentSection;
};

static char *createDictKey(const char *sectionName, const char *keyName) {
    return flib_asprintf("%s:%s", sectionName, keyName);
}

/**
 * Turns a string into a lowercase string, in-place.
 */
static void strToLower(char *str) {
    if(str) {
        while(*str) {
            *str = tolower(*str);
            str++;
        }
    }
}

flib_ini *flib_ini_create(const char *filename) {
    flib_ini *result = NULL;
    flib_ini *tmpIni = flib_calloc(1, sizeof(flib_ini));
    if(tmpIni) {
        if(filename) {
            tmpIni->inidict = iniparser_load(filename);
        }
        if(!tmpIni->inidict) {
            tmpIni->inidict = dictionary_new(0);
        }
        if(tmpIni->inidict) {
            result = tmpIni;
            tmpIni = NULL;
        }
    }
    flib_ini_destroy(tmpIni);
    return result;
}

flib_ini *flib_ini_load(const char *filename) {
    flib_ini *result = NULL;
    if(!log_badargs_if(filename==NULL)) {
        flib_ini *tmpIni = flib_calloc(1, sizeof(flib_ini));
        if(tmpIni) {
            tmpIni->inidict = iniparser_load(filename);
            if(tmpIni->inidict) {
                result = tmpIni;
                tmpIni = NULL;
            }
        }
        flib_ini_destroy(tmpIni);
    }
    return result;
}

int flib_ini_save(flib_ini *ini, const char *filename) {
    int result = INI_ERROR_OTHER;
    if(!log_badargs_if2(ini==NULL, filename==NULL)) {
        FILE *file = fopen(filename, "wb");
        if(!file) {
            flib_log_e("Error opening file \"%s\" for writing.", filename);
        } else {
            iniparser_dump_ini(ini->inidict, file);
            if(fclose(file)) {
                flib_log_e("Write error on ini file \"%s\"", filename);
            } else {
                result = 0;
            }
        }
    }
    return result;
}

void flib_ini_destroy(flib_ini *ini) {
    if(ini) {
        if(ini->inidict) {
            iniparser_freedict(ini->inidict);
        }
        free(ini->currentSection);
        free(ini);
    }
}

int flib_ini_enter_section(flib_ini *ini, const char *section) {
    int result = INI_ERROR_OTHER;
    if(ini) {
        free(ini->currentSection);
        ini->currentSection = NULL;
    }
    if(!log_badargs_if2(ini==NULL, section==NULL)) {
        if(!iniparser_find_entry(ini->inidict, section)) {
            flib_log_d("Ini section %s not found", section);
            result = INI_ERROR_NOTFOUND;
        } else {
            ini->currentSection = flib_strdupnull(section);
            if(ini->currentSection) {
                // Usually iniparser ignores case, but some section-handling functions don't,
                // so we set it to lowercase manually
                strToLower(ini->currentSection);
                result = 0;
            }
        }
    }
    return result;
}

int flib_ini_create_section(flib_ini *ini, const char *section) {
    int result = INI_ERROR_OTHER;
    if(!log_badargs_if2(ini==NULL, section==NULL)) {
        result = flib_ini_enter_section(ini, section);
        if(result == INI_ERROR_NOTFOUND) {
            if(iniparser_set(ini->inidict, section, NULL)) {
                flib_log_e("Error creating ini section %s", section);
                result = INI_ERROR_OTHER;
            } else {
                result = flib_ini_enter_section(ini, section);
            }
        }
    }
    return result;
}

/**
 * The result is an internal string of the iniparser, don't free it.
 */
static char *findValue(dictionary *dict, const char *section, const char *key) {
    char *result = NULL;
    char *dictKey = createDictKey(section, key);
    if(dictKey) {
        result = iniparser_getstring(dict, dictKey, NULL);
    }
    free(dictKey);
    return result;
}

int flib_ini_get_str(flib_ini *ini, char **outVar, const char *key) {
    char *tmpValue = NULL;
    int result = flib_ini_get_str_opt(ini, &tmpValue, key, NULL);
    if(result==0) {
        if(tmpValue == NULL) {
            result = INI_ERROR_NOTFOUND;
        } else {
            *outVar = tmpValue;
            tmpValue = NULL;
        }
    }
    free(tmpValue);
    return result;
}

int flib_ini_get_str_opt(flib_ini *ini, char **outVar, const char *key, const char *def) {
    int result = INI_ERROR_OTHER;
    if(!log_badargs_if4(ini==NULL, ini->currentSection==NULL, outVar==NULL, key==NULL)) {
        const char *value = findValue(ini->inidict, ini->currentSection, key);
        if(!value) {
            value = def;
        }
        char *valueDup = flib_strdupnull(value);
        if(valueDup || !def) {
            *outVar = valueDup;
            result = 0;
        }
    }
    return result;
}

int flib_ini_get_int(flib_ini *ini, int *outVar, const char *key) {
    char *tmpValue = NULL;
    int result = flib_ini_get_str(ini, &tmpValue, key);
    if(result==0) {
        errno = 0;
        long val = strtol(tmpValue, NULL, 10);
        if(errno!=0 || val<INT_MIN || val>INT_MAX) {
            flib_log_w("Cannot parse ini setting %s/%s = \"%s\" as integer.", ini->currentSection, key, tmpValue);
            result = INI_ERROR_FORMAT;
        } else {
            *outVar = val;
        }
    }
    free(tmpValue);
    return result;
}

int flib_ini_get_int_opt(flib_ini *ini, int *outVar, const char *key, int def) {
    int tmpValue;
    int result = flib_ini_get_int(ini, &tmpValue, key);
    if(result == 0) {
        *outVar = tmpValue;
    } else if(result == INI_ERROR_NOTFOUND || result == INI_ERROR_FORMAT) {
        *outVar = def;
        result = 0;
    }
    return result;
}

int flib_ini_get_bool(flib_ini *ini, bool *outVar, const char *key) {
    char *tmpValue = NULL;
    int result = flib_ini_get_str(ini, &tmpValue, key);
    if(result==0) {
        bool trueval = strchr("1tTyY", tmpValue[0]);
        bool falseval = strchr("0fFnN", tmpValue[0]);
        if(!trueval && !falseval) {
            flib_log_w("ini setting %s/%s = \"%s\" is not a recognized truth value.", ini->currentSection, key, tmpValue);
            result = INI_ERROR_FORMAT;
        } else {
            *outVar = trueval;
        }
    }
    free(tmpValue);
    return result;
}

int flib_ini_get_bool_opt(flib_ini *ini, bool *outVar, const char *key, bool def) {
    bool tmpValue;
    int result = flib_ini_get_bool(ini, &tmpValue, key);
    if(result == 0) {
        *outVar = tmpValue;
    } else if(result == INI_ERROR_NOTFOUND || result == INI_ERROR_FORMAT) {
        *outVar = def;
        result = 0;
    }
    return result;
}

int flib_ini_set_str(flib_ini *ini, const char *key, const char *value) {
    int result = INI_ERROR_OTHER;
    if(!log_badargs_if4(ini==NULL, ini->currentSection==NULL, key==NULL, value==NULL)) {
        char *dictKey = createDictKey(ini->currentSection, key);
        if(dictKey) {
            result = iniparser_set(ini->inidict, dictKey, value);
            if(result) {
                flib_log_e("Error setting ini entry %s to %s", dictKey, value);
            }
        }
        free(dictKey);
    }
    return result;
}

int flib_ini_set_int(flib_ini *ini, const char *key, int value) {
    int result = INI_ERROR_OTHER;
    char *strvalue = flib_asprintf("%i", value);
    if(strvalue) {
        result = flib_ini_set_str(ini, key, strvalue);
    }
    free(strvalue);
    return result;
}

int flib_ini_set_bool(flib_ini *ini, const char *key, bool value) {
    return flib_ini_set_str(ini, key, value ? "true" : "false");
}

int flib_ini_get_sectioncount(flib_ini *ini) {
    if(!log_badargs_if(ini==NULL)) {
        return iniparser_getnsec(ini->inidict);
    }
    return INI_ERROR_OTHER;
}

char *flib_ini_get_sectionname(flib_ini *ini, int number) {
    if(!log_badargs_if2(ini==NULL, number<0)) {
        return flib_strdupnull(iniparser_getsecname(ini->inidict, number));
    }
    return NULL;
}

int flib_ini_get_keycount(flib_ini *ini) {
    if(!log_badargs_if2(ini==NULL, ini->currentSection==NULL)) {
        return iniparser_getsecnkeys(ini->inidict, ini->currentSection);
    }
    return INI_ERROR_OTHER;
}

char *flib_ini_get_keyname(flib_ini *ini, int number) {
    char *result = NULL;
    if(!log_badargs_if3(ini==NULL, ini->currentSection==NULL, number<0)) {
        int keyCount = iniparser_getsecnkeys(ini->inidict, ini->currentSection);
        char **keys = iniparser_getseckeys(ini->inidict, ini->currentSection);
        if(keys && keyCount>number) {
            // The keys are in the format section:key, so we have to skip the section and colon.
            result = flib_strdupnull(keys[number]+strlen(ini->currentSection)+1);
        }
        free(keys);
    }
    return result;
}
