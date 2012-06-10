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

static void flib_vflog(const char *prefix, int level, const char *fmt, va_list args) {
	FILE *logfile = flib_log_getfile();
	if(level >= flib_loglevel) {
		fprintf(logfile, "%s ", prefix);
		log_time(logfile);
		fprintf(logfile, "  ", prefix);
		vfprintf(logfile, fmt, args);
		fprintf(logfile, "\n");
		fflush(logfile);
	}
}

void flib_log_e(const char *fmt, ...) {
	va_list argp;
	va_start(argp, fmt);
	flib_vflog("E", FLIB_LOGLEVEL_ERROR, fmt, argp);
	va_end(argp);
}

void flib_log_w(const char *fmt, ...) {
	va_list argp;
	va_start(argp, fmt);
	flib_vflog("W", FLIB_LOGLEVEL_WARNING, fmt, argp);
	va_end(argp);
}

void flib_log_i(const char *fmt, ...) {
	va_list argp;
	va_start(argp, fmt);
	flib_vflog("I", FLIB_LOGLEVEL_INFO, fmt, argp);
	va_end(argp);
}

void flib_log_d(const char *fmt, ...) {
	va_list argp;
	va_start(argp, fmt);
	flib_vflog("D", FLIB_LOGLEVEL_DEBUG, fmt, argp);
	va_end(argp);
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
