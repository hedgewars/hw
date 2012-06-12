#include "util.h"
#include "logging.h"

#include <stddef.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>

char *flib_asprintf(const char *fmt, ...) {
	va_list argp;
	va_start(argp, fmt);
	char *result = flib_vasprintf(fmt, argp);
	va_end(argp);
	return result;
}

char *flib_vasprintf(const char *fmt, va_list args) {
	char *result = NULL;
	if(!fmt) {
		flib_log_e("null parameter in flib_vasprintf");
	} else {
		int requiredSize = vsnprintf(NULL, 0, fmt, args)+1;					// Figure out how much memory we need,
		if(requiredSize<0) {
			flib_log_e("Error formatting string with template \"%s\" in flib_vasprintf", fmt);
		} else {
			char *tmpbuf = flib_malloc(requiredSize);						// allocate it
			if(tmpbuf && vsnprintf(tmpbuf, requiredSize, fmt, args)>=0) {	// and then do the actual formatting.
				result = tmpbuf;
				tmpbuf = NULL;
			}
			free(tmpbuf);
		}
	}
	return result;
}

char *flib_strdupnull(const char *str) {
	if(!str) {
		return NULL;
	}
	return flib_asprintf("%s", str);
}

void *flib_bufdupnull(const void *buf, size_t size) {
	if(!buf || size==0) {
		return NULL;
	}
	void *result = flib_malloc(size);
	if(result) {
		memcpy(result, buf, size);
	}
	return result;
}

void *flib_malloc(size_t size) {
	void *result = malloc(size);
	if(!result) {
		flib_log_e("Out of memory trying to malloc %zu bytes.", size);
	}
	return result;
}

void *flib_calloc(size_t count, size_t elementsize) {
	void *result = calloc(count, elementsize);
	if(!result) {
		flib_log_e("Out of memory trying to calloc %zu objects of %zu bytes each.", count, elementsize);
	}
	return result;
}

static bool isAsciiAlnum(char c) {
	return (c>='0' && c<='9') || (c>='a' && c <='z') || (c>='A' && c <='Z');
}

char *flib_urlencode(const char *inbuf) {
	if(!inbuf) {
		return NULL;
	}
	size_t insize = strlen(inbuf);
	if(insize > SIZE_MAX/4) {
		flib_log_e("String too long in flib_urlencode: %zu bytes.", insize);
		return NULL;
	}

	char *outbuf = flib_malloc(insize*3+1);
	if(!outbuf) {
		return NULL;
	}

    size_t inpos = 0, outpos = 0;
    while(inbuf[inpos]) {
        if(isAsciiAlnum(inbuf[inpos])) {
        	outbuf[outpos++] = inbuf[inpos++];
        } else {
            if(snprintf(outbuf+outpos, 4, "%%%02X", (unsigned)((uint8_t*)inbuf)[inpos])<0) {
            	flib_log_e("printf error in flib_urlencode");
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

char *flib_urldecode(const char *inbuf) {
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
