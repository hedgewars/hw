#include "inihelper.h"
#include "logging.h"
#include "util.h"

#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <limits.h>
#include <errno.h>
#include <stdarg.h>

static bool keychar_needs_urlencoding(char c) {
	return !isalnum(c);
}

char *inihelper_urlencode(const char *inbuf) {
	if(!inbuf) {
		return NULL;
	}
	size_t insize = strlen(inbuf);
	if(insize > SIZE_MAX/4) {
		return NULL;
	}

	char *outbuf = flib_malloc(insize*3+1);
	if(!outbuf) {
		return NULL;
	}

    size_t inpos = 0, outpos = 0;
    while(inbuf[inpos]) {
        if(!keychar_needs_urlencoding(inbuf[inpos])) {
        	outbuf[outpos++] = inbuf[inpos++];
        } else {
            if(snprintf(outbuf+outpos, 4, "%%%02X", (unsigned)((uint8_t*)inbuf)[inpos])<0) {
            	free(outbuf);
            	return NULL;
            }
            inpos++;
            outpos += 3;
        }
    }
    outbuf[outpos] = 0;
    char *shrunk = realloc(outbuf, outpos+1);
    return shrunk ? shrunk : outbuf;
}

char *inihelper_urldecode(const char *inbuf) {
	char *outbuf = flib_malloc(strlen(inbuf)+1);
	if(!outbuf) {
		return NULL;
	}

    size_t inpos = 0, outpos = 0;
    while(inbuf[inpos]) {
        if(inbuf[inpos] == '%' && isxdigit(inbuf[inpos+1]) && isxdigit(inbuf[inpos+2])) {
            char temp[3] = {inbuf[inpos+1],inbuf[inpos+2],0};
            outbuf[outpos++] = strtol(temp, NULL, 16);
            inpos += 3;
        } else {
        	outbuf[outpos++] = inbuf[inpos++];
        }
    }
    outbuf[outpos] = 0;
    char *shrunk = realloc(outbuf, outpos+1);
    return shrunk ? shrunk : outbuf;
}

char *inihelper_createDictKey(const char *sectionName, const char *keyName) {
	if(!sectionName || !keyName) {
		flib_log_e("null parameter in inihelper_createDictKey");
		return NULL;
	}
	return flib_asprintf("%s:%s", sectionName, keyName);
}

char *inihelper_getstring(dictionary *inifile, bool *error, const char *sectionName, const char *keyName) {
	if(!inifile || !sectionName || !keyName) {
		flib_log_e("null parameter in inihelper_getstring");
		*error = true;
		return NULL;
	}
	char *extendedkey = inihelper_createDictKey(sectionName, keyName);
	if(!extendedkey) {
		*error = true;
		return NULL;
	}
	char *result = iniparser_getstring(inifile, extendedkey, NULL);
	free(extendedkey);
	if(!result) {
		flib_log_d("Missing ini setting: %s/%s", sectionName, keyName);
		*error = true;
	}
	return result;
}

char *inihelper_getstringdup(dictionary *inifile, bool *error, const char *sectionName, const char *keyName) {
	return flib_strdupnull(inihelper_getstring(inifile, error, sectionName, keyName));
}

int inihelper_getint(dictionary *inifile, bool *error, const char *sectionName, const char *keyName) {
	char *value = inihelper_getstring(inifile, error, sectionName, keyName);
	if(!value) {
		return 0;
	} else {
		errno = 0;
		long val = strtol(value, NULL, 10);
		if(errno!=0) {
			flib_log_w("Cannot parse ini setting %s/%s = \"%s\" as integer.", sectionName, keyName, value);
			*error = true;
			return 0;
		}
		if(val<INT_MIN || val>INT_MAX) {
			flib_log_w("ini setting %s/%s = \"%s\" is too large or too small.", sectionName, keyName, value);
			*error = true;
			return 0;
		}
		return (int)val;
	}
}

bool inihelper_getbool(dictionary *inifile, bool *error, const char *sectionName, const char *keyName) {
	char *value = inihelper_getstring(inifile, error, sectionName, keyName);
	if(!value) {
		return false;
	} else {
		bool trueval = strchr("1tTyY", value[0]);
		bool falseval = strchr("0fFnN", value[0]);
		if(!trueval && !falseval) {
			flib_log_w("ini setting %s/%s = \"%s\" is not a recognized truth value.", sectionName, keyName, value);
			*error = true;
			return false;
		} else {
			return trueval;
		}
	}
}

int inihelper_setstr(dictionary *dict, const char *sectionName, const char *keyName, const char *value) {
	int result = -1;
	if(!dict || !sectionName || !keyName || !value) {
		flib_log_e("null parameter in inihelper_setstr");
	} else {
		char *extendedkey = inihelper_createDictKey(sectionName, keyName);
		if(extendedkey) {
			result = iniparser_set(dict, extendedkey, value);
		}
		free(extendedkey);
	}
	return result;
}

int inihelper_setint(dictionary *dict, const char *sectionName, const char *keyName, int value) {
	int result = -1;
	if(!dict || !sectionName || !keyName) {
		flib_log_e("null parameter in inihelper_setint");
	} else {
		char *strvalue = flib_asprintf("%i", value);
		if(strvalue) {
			result = inihelper_setstr(dict, sectionName, keyName, strvalue);
			free(strvalue);
		}
	}
	return result;
}

int inihelper_setbool(dictionary *dict, const char *sectionName, const char *keyName, bool value) {
	int result = -1;
	if(!dict || !sectionName || !keyName) {
		flib_log_e("null parameter in inihelper_setbool");
	} else {
		result = inihelper_setstr(dict, sectionName, keyName, value ? "true" : "false");
	}
	return result;
}
