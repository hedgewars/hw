#include "logging.h"

#include <time.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>

static int flib_loglevel = FLIB_LOGLEVEL_INFO;
static FILE *flib_logfile = NULL;

char* flib_format_ip(uint32_t numip) {
	static char ip[16];
	snprintf(ip, 16, "%u.%u.%u.%u", (unsigned)(numip>>24), (unsigned)((numip>>16)&0xff), (unsigned)((numip>>8)&0xff), (unsigned)(numip&0xff));
	return ip;
}

static inline FILE *flib_log_getfile() {
	if(flib_logfile==NULL) {
		return stdout;
	} else {
		return flib_logfile;
	}
}

static void log_time() {
    time_t timer;
    char buffer[25];
    struct tm* tm_info;

    time(&timer);
    tm_info = localtime(&timer);

    strftime(buffer, 25, "%Y-%m-%d %H:%M:%S", tm_info);
    fprintf(flib_log_getfile(), "%s", buffer);
}

static const char *getPrefix(int level) {
	switch(level) {
	case FLIB_LOGLEVEL_ERROR: return "E";
	case FLIB_LOGLEVEL_WARNING: return "W";
	case FLIB_LOGLEVEL_INFO: return "I";
	case FLIB_LOGLEVEL_DEBUG: return "D";
	default: return "?";
	}
}

static void _flib_vflog(const char *func, int level, const char *fmt, va_list args) {
	FILE *logfile = flib_log_getfile();
	if(level >= flib_loglevel) {
		fprintf(logfile, "%s ", getPrefix(level));
		log_time(logfile);
		fprintf(logfile, " [%-30s] ", func);
		vfprintf(logfile, fmt, args);
		fprintf(logfile, "\n");
		fflush(logfile);
	}
}

void _flib_flog(const char *func, int level, const char *fmt, ...) {
	va_list argp;
	va_start(argp, fmt);
	_flib_vflog(func, level, fmt, argp);
	va_end(argp);
}

bool _flib_fassert(const char *func, int level, bool cond, const char *fmt, ...) {
	if(!cond) {
		va_list argp;
		va_start(argp, fmt);
		_flib_vflog(func, level, fmt, argp);
		va_end(argp);
	}
	return !cond;
}

bool _flib_assert_params(const char *func, bool cond) {
	return _flib_fassert(func, FLIB_LOGLEVEL_ERROR, cond, "Invalid parameter to function");
}

int flib_log_getLevel() {
	return flib_loglevel;
}

void flib_log_setLevel(int level) {
	flib_loglevel = level;
}

void flib_log_setFile(FILE *file) {
	flib_logfile = file;
}

bool flib_log_isActive(int level) {
	return level >= flib_log_getLevel();
}
