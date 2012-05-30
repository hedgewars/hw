/*
 * frontlib_internals.h
 *
 *  Created on: 30.05.2012
 *      Author: simmax
 */

#ifndef LOGGING_H_
#define LOGGING_H_

#include<stdio.h>
#include<stdint.h>

char* flib_format_ip(uint32_t numip);

#define flib_log_e(...) fprintf (stderr, __VA_ARGS__)
#define flib_log_w(...) printf(__VA_ARGS__)
#define flib_log_i(...) printf(__VA_ARGS__)

#endif /* LOGGING_H_ */
