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

#ifndef LOGGING_H_
#define LOGGING_H_

#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>

#define FLIB_LOGLEVEL_ALL -100
#define FLIB_LOGLEVEL_DEBUG -1
#define FLIB_LOGLEVEL_INFO 0
#define FLIB_LOGLEVEL_WARNING 1
#define FLIB_LOGLEVEL_ERROR 2
#define FLIB_LOGLEVEL_NONE 100

/**
 * Returns a pointer to a static buffer, don't free or store.
 */
char* flib_format_ip(uint32_t numip);

/**
 * Evaluates the expression cond. If it is true, a formatted error will be logged.
 * Returns true if an error is logged, false otherwise (i.e. the boolean value of the argument)
 * Usage: log_e_if(errorHasHappened, "Format string", formatArg, ...);
 */
#define log_e_if(cond, ...) _flib_fassert(__func__, FLIB_LOGLEVEL_ERROR, !(bool)(cond), __VA_ARGS__)
#define log_w_if(cond, ...) _flib_fassert(__func__, FLIB_LOGLEVEL_WARNING, !(bool)(cond), __VA_ARGS__)

/**
 * Helper macros for log_badargs_if
 * The t parameters are the textual representation of the c parameters. They need to be passed
 * explicitly, to prevent them from being expanded in prescan.
 */
#define _flib_lbi(c1,t1) log_e_if(c1, "Invalid Argument (%s)", t1)
#define _flib_lbi2(c1,t1,c2,t2) (_flib_lbi(c1,t1) || _flib_lbi(c2,t2))
#define _flib_lbi3(c1,t1,c2,t2,c3,t3) (_flib_lbi(c1,t1) || _flib_lbi2(c2,t2,c3,t3))
#define _flib_lbi4(c1,t1,c2,t2,c3,t3,c4,t4) (_flib_lbi(c1,t1) || _flib_lbi3(c2,t2,c3,t3,c4,t4))
#define _flib_lbi5(c1,t1,c2,t2,c3,t3,c4,t4,c5,t5) (_flib_lbi(c1,t1) || _flib_lbi4(c2,t2,c3,t3,c4,t4,c5,t5))
#define _flib_lbi6(c1,t1,c2,t2,c3,t3,c4,t4,c5,t5,c6,t6) (_flib_lbi(c1,t1) || _flib_lbi5(c2,t2,c3,t3,c4,t4,c5,t5,c6,t6))

/**
 * These macros log an "Invalid Argument" error for the first of their arguments that evaluates to true.
 * The text of the argument is included in the log message.
 * The expression returns true if any of its arguments is true (i.e. if an argument error was logged).
 *
 * For example, log_badargs_if(x==NULL) will log "Invalid Argument (x==NULL)" and return true if x is NULL.
 */
#define log_badargs_if(c1) _flib_lbi(c1,#c1)
#define log_badargs_if2(c1, c2) _flib_lbi2(c1,#c1,c2,#c2)
#define log_badargs_if3(c1, c2, c3) _flib_lbi3(c1,#c1,c2,#c2,c3,#c3)
#define log_badargs_if4(c1, c2, c3, c4) _flib_lbi4(c1,#c1,c2,#c2,c3,#c3,c4,#c4)
#define log_badargs_if5(c1, c2, c3, c4, c5) _flib_lbi5(c1,#c1,c2,#c2,c3,#c3,c4,#c4,c5,#c5)
#define log_badargs_if6(c1, c2, c3, c4, c5, c6) _flib_lbi6(c1,#c1,c2,#c2,c3,#c3,c4,#c4,c5,#c5,c6,#c6)

#define log_oom_if(cond) log_e_if(cond, "Out of Memory")

#define flib_log_e(...) _flib_flog(__func__, FLIB_LOGLEVEL_ERROR, __VA_ARGS__)
#define flib_log_w(...) _flib_flog(__func__, FLIB_LOGLEVEL_WARNING, __VA_ARGS__)
#define flib_log_i(...) _flib_flog(__func__, FLIB_LOGLEVEL_INFO, __VA_ARGS__)
#define flib_log_d(...) _flib_flog(__func__, FLIB_LOGLEVEL_DEBUG, __VA_ARGS__)

bool _flib_fassert(const char *func, int level, bool cond, const char *fmt, ...);
void _flib_flog(const char *func, int level, const char *fmt, ...);

/**
 * Only log messages that are at least the indicated level
 */
void flib_log_setLevel(int level);
int flib_log_getLevel();

/**
 * Log to the indicated file. You can pass NULL to log to stdout.
 * This overrides setCallback and vice versa.
 */
void flib_log_setFile(FILE *logfile);

/**
 * Returns whether messages of this level are logged at the moment.
 */
bool flib_log_isActive(int level);

/**
 * Allows logging through an arbitrary callback function. Useful for integrating into an
 * existing logging system. This overrides setFile and vice versa.
 */
void flib_log_setCallback(void (*logCallback)(int level, const char *msg));

#endif /* LOGGING_H_ */
