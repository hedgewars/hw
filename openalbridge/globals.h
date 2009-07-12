/*
 * OpenAL Bridge - a simple portable library for OpenAL interface
 * Copyright (c) 2009 Vittorio Giovara <vittorio.giovara@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

#ifndef _OALB_GLOBALS_H
#define _OALB_GLOBALS_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#ifndef _WIN32
#include <pthread.h>
#else
#include <process.h>
#endif

#include "al.h"

#ifndef _SLEEP_H
#define _SLEEP_H
/** 1.0 02/03/10 - Defines cross-platform sleep, usleep, etc. * By Wu Yongwei **/
#ifdef _WIN32
# if defined(_NEED_SLEEP_ONLY) && (defined(_MSC_VER) || defined(__MINGW32__))
#  include <stdlib.h>
#  define sleep(t) _sleep((t) * 1000)
# else
#  define WIN32_LEAN_AND_MEAN
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

#ifdef HAVE_BYTESWAP_H
/* use byteswap macros from the host system, hopefully optimized ones ;-) */
#include <byteswap.h>
#else
/* define our own version, simple, stupid, straight-forward... */

#define bswap_16(x)	((((x) & 0xFF00) >> 8) | (((x) & 0x00FF) << 8))

#define bswap_32(x)	((((x) & 0xFF000000) >> 24) | (((x) & 0x00FF0000) >> 8)  | \
                         (((x) & 0x0000FF00) << 8)  | (((x) & 0x000000FF) << 24) )

#endif /* HAVE_BYTESWAP_H */

#ifdef __CPLUSPLUS
extern "C" {
#endif 
    
    /*data type for WAV header*/
#pragma pack(1)
    typedef struct _WAV_header_t {
        uint32_t ChunkID;
        uint32_t ChunkSize;
        uint32_t Format;
        uint32_t Subchunk1ID;
        uint32_t Subchunk1Size;
        uint16_t AudioFormat;
        uint16_t NumChannels;
        uint32_t SampleRate;
        uint32_t ByteRate;
        uint16_t BlockAlign;
        uint16_t BitsPerSample;
        uint32_t Subchunk2ID;
        uint32_t Subchunk2Size;
    } WAV_header_t;
#pragma pack()
    
    /*data type for passing data between threads*/
#pragma pack(1)
    typedef struct _fade_t {
        uint32_t index;
        uint16_t quantity;
    } fade_t;
#pragma pack()
    
    /*other defines*/
#define FADE_IN	 true
#define FADE_OUT false
    
#ifdef __CPLUSPLUS
}
#endif

#endif /*_OALB_GLOBALS_H*/
