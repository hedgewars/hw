#ifndef LOGGING_H_
#define LOGGING_H_

#include<stdint.h>
#include <stdio.h>

#define FLIB_LOGLEVEL_ALL -100
#define FLIB_LOGLEVEL_DEBUG -1
#define FLIB_LOGLEVEL_INFO 0
#define FLIB_LOGLEVEL_WARNING 1
#define FLIB_LOGLEVEL_ERROR 2
#define FLIB_LOGLEVEL_NONE 100

char* flib_format_ip(uint32_t numip);

void flib_log_e(const char *fmt, ...);
void flib_log_w(const char *fmt, ...);
void flib_log_i(const char *fmt, ...);
void flib_log_d(const char *fmt, ...);

int flib_log_getLevel();
void flib_log_setLevel(int level);
void flib_log_setFile(FILE *logfile);

#endif /* LOGGING_H_ */
