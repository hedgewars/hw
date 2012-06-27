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
 */
#define log_e_if(cond, ...) _flib_fassert(__func__, FLIB_LOGLEVEL_ERROR, !(bool)(cond), __VA_ARGS__)
#define log_w_if(cond, ...) _flib_fassert(__func__, FLIB_LOGLEVEL_WARNING, !(bool)(cond), __VA_ARGS__)

/**
 * Shorthand for some common error types
 */
#define log_badparams_if(cond) log_e_if(cond, "Invalid Parameters")
#define log_oom_if(cond) log_e_if(cond, "Out of Memory")

#define flib_log_e(...) _flib_flog(__func__, FLIB_LOGLEVEL_ERROR, __VA_ARGS__)
#define flib_log_w(...) _flib_flog(__func__, FLIB_LOGLEVEL_WARNING, __VA_ARGS__)
#define flib_log_i(...) _flib_flog(__func__, FLIB_LOGLEVEL_INFO, __VA_ARGS__)
#define flib_log_d(...) _flib_flog(__func__, FLIB_LOGLEVEL_DEBUG, __VA_ARGS__)

bool _flib_assert_params(const char *func, bool cond);
bool _flib_fassert(const char *func, int level, bool cond, const char *fmt, ...);
void _flib_flog(const char *func, int level, const char *fmt, ...);

int flib_log_getLevel();
void flib_log_setLevel(int level);
void flib_log_setFile(FILE *logfile);
bool flib_log_isActive(int level);

#endif /* LOGGING_H_ */
