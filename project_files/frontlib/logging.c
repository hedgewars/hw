#include "logging.h"

#include <time.h>
#include <stdio.h>
#include <stdarg.h>

char* flib_format_ip(uint32_t numip) {
	static char ip[16];
	snprintf(ip, 16, "%u.%u.%u.%u", numip>>24, (numip>>16)&0xff, (numip>>8)&0xff, numip&0xff);
	return ip;
}

static void log_time(FILE *file) {
    time_t timer;
    char buffer[25];
    struct tm* tm_info;

    time(&timer);
    tm_info = localtime(&timer);

    strftime(buffer, 25, "%Y-%m-%d %H:%M:%S", tm_info);
    fprintf(file, "%s", buffer);
}

static void flib_vflog(FILE *file, const char *prefix, const char *fmt, va_list args) {
	log_time(file);
	fprintf(file, " [%s]", prefix);
	vfprintf(file, fmt, args);
	fprintf(file, "\n");
}

void flib_log_e(const char *fmt, ...) {
	va_list argp;
	va_start(argp, fmt);
	flib_vflog(stderr, "E", fmt, argp);
	va_end(argp);
}

void flib_log_w(const char *fmt, ...) {
	va_list argp;
	va_start(argp, fmt);
	flib_vflog(stdout, "W", fmt, argp);
	va_end(argp);
}

void flib_log_i(const char *fmt, ...) {
	va_list argp;
	va_start(argp, fmt);
	flib_vflog(stdout, "I", fmt, argp);
	va_end(argp);
}
