/*
 * OpenAL Bridge - a simple portable library for OpenAL interface
 * Copyright (c) 2009 Vittorio Giovara <vittorio.giovara@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

#include <stdio.h>
#include <stdlib.h>
#include "al.h"

#ifndef _WIN32
#include <pthread.h>
#include <stdint.h>
#else
#define WIN32_LEAN_AND_MEAN
#include <process.h>
#include "winstdint.h"
#endif

#ifndef _SLEEP_H
#define _SLEEP_H
/** 1.0 02/03/10 - Defines cross-platform sleep, usleep, etc. * By Wu Yongwei **/
#ifdef _WIN32
# if defined(_NEED_SLEEP_ONLY) && (defined(_MSC_VER) || defined(__MINGW32__))
#  include <stdlib.h>
#  define sleep(t) _sleep((t) * 1000)
# else
#  include <windows.h>
#  define sleep(t)  Sleep((t) * 1000)
# endif
# ifndef _NEED_SLEEP_ONLY
#  define msleep(t) Sleep(t)
#  define usleep(t) Sleep((t) / 1000)
# endif
#else
# include <unistd.h>
# ifndef _NEED_SLEEP_ONLY
#  define msleep(t) usleep((t) * 1000)
# endif
#endif
#endif /* _SLEEP_H */

#pragma once

typedef struct _fade_t {
	int index;
	unsigned int quantity;
} fade_t;

void *Malloc (size_t nbytes);
FILE *Fopen (const char *fname, char *mode);
ALint AlGetError (const char *str);
#ifndef _WIN32
void *helper_fadein (void *tmp);
void *helper_fadeout (void *tmp); 
#else
void WINAPI helper_fadein (void *tmp); 
void WINAPI helper_fadeout (void *tmp); 	
#endif