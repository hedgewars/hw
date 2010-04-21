/*

 module: errlib.h

 purpose: definitions of function sin errlib.c

 reference: Stevens, Unix network programming (2ed), p.922

 */

#ifndef _ERRLIB_H
#define _ERRLIB_H

#include "globals.h"

extern int daemon_proc;

void err_msg (const char *fmt, ...);
void err_quit (const char *fmt, ...);
void err_ret (const char *fmt, ...);
void err_sys (const char *fmt, ...);
void err_dump (const char *fmt, ...);

#endif /*_ERRLIB_H*/

/*
 suggested error string ( PROG ) LEVEL - TEXT : ERRNO

 errno?  closeprog? log level
 err_msg      no       no       LOG_INFO
 err_quit     no     exit(1)    LOG_ERR
 err_ret      si       no       LOG_INFO
 err_sys      si     exit(1)    LOG_ERR
 err_dump     si    abort( )    LOG_ERR
 */
