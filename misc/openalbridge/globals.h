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
#include <stdarg.h>
#include <string.h>
#include <errno.h>

#ifndef _WIN32
#include <pthread.h>
#include <syslog.h>
#else
#include <process.h>
#define syslog(x,y) fprintf(stderr,y)
#define LOG_INFO 6
#define LOG_ERR 3
#endif

#include "al.h"
#include "errlib.h"


/*control debug verbosity*/
#ifdef TRACE
#ifndef DEBUG
#define DEBUG
#endif
#endif

/** 1.0 02/03/10 - Defines cross-platform sleep, usleep, etc. [Wu Yongwei] **/
#ifndef _SLEEP_H
#define _SLEEP_H
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


/* check compiler requirements */    /*FIXME*/
#if !defined(__BIG_ENDIAN__) && !defined(__LITTLE_ENDIAN__)
#warning __BIG_ENDIAN__ or __LITTLE_ENDIAN__ not found, going to set __LITTLE_ENDIAN__ as default
#define __LITTLE_ENDIAN__ 1
//#error Do not know the endianess of this architecture
#endif

/* use byteswap macros from the host system, hopefully optimized ones ;-) 
 * or define our own version, simple, stupid, straight-forward... */
#ifdef HAVE_BYTESWAP_H
#include <byteswap.h>
#else        
#define bswap_16(x)	((((x) & 0xFF00) >> 8) | (((x) & 0x00FF) << 8))
#define bswap_32(x)	((((x) & 0xFF000000) >> 24) | (((x) & 0x00FF0000) >> 8)  | \
(((x) & 0x0000FF00) << 8)  | (((x) & 0x000000FF) << 24) )
#endif /* HAVE_BYTESWAP_H */

/* swap numbers accordingly to architecture automatically */
#ifdef __LITTLE_ENDIAN__
#define ENDIAN_LITTLE_32(x) x
#define ENDIAN_BIG_32(x)    bswap_32(x)
#define ENDIAN_LITTLE_16(x) x
#define ENDIAN_BIG_16(x)    bswap_16(x)
#elif __BIG_ENDIAN__
#define ENDIAN_LITTLE_32(x) bswap_32(x)
#define ENDIAN_BIG_32(x)    x
#define ENDIAN_LITTLE_16(x) bswap_16(x)
#define ENDIAN_BIG_16(x)    x    
#endif


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
    
    
    /*file format defines*/
#define OGG_FILE_FORMAT 0x4F676753
#define WAV_FILE_FORMAT 0x52494646
#define WAV_HEADER_SUBCHUNK2ID 0x64617461
    
    char *prog;
    
#ifdef __CPLUSPLUS
}
#endif

#endif /*_OALB_GLOBALS_H*/
