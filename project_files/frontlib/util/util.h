#ifndef FLIB_UTIL_H_
#define FLIB_UTIL_H_

#include <stddef.h>
#include <stdarg.h>

/**
 * Prints a format string to a newly allocated buffer of the required size.
 * Parameters are like those for printf. Returns NULL on error.
 *
 * Returned buffer must be free()d
 */
char *flib_asprintf(const char *fmt, ...);

/**
 * Exactly as flib_asprintf, but accepts a va_list.
 */
char *flib_vasprintf(const char *fmt, va_list args);

/**
 * Return a duplicate of the provided string, or NULL if an error
 * occurs or if str is already NULL.
 *
 * Returned buffer must be free()d
 */
char *flib_strdupnull(const char *str);

/**
 * Return a duplicate of the provided buffer, or NULL if an error
 * occurs or if buf is already NULL or if size is 0.
 *
 * Returned buffer must be free()d
 */
void *flib_bufdupnull(const void *buf, size_t size);

/**
 * Simple malloc wrapper that automatically logs an error if no memory
 * is available. Otherwise behaves exactly like malloc.
 */
void *flib_malloc(size_t size);

/**
 * Simple calloc wrapper that automatically logs an error if no memory
 * is available. Otherwise behaves exactly like calloc.
 */
void *flib_calloc(size_t count, size_t elementsize);

#endif
