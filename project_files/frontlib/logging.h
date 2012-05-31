/*
 *
 */

#ifndef LOGGING_H_
#define LOGGING_H_

#include<stdint.h>

char* flib_format_ip(uint32_t numip);

void flib_log_e(const char *fmt, ...);
void flib_log_w(const char *fmt, ...);
void flib_log_i(const char *fmt, ...);

#endif /* LOGGING_H_ */
