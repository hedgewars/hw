#include "util.h"
#include "logging.h"

#include <stddef.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

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
