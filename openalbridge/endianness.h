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

#ifndef _OALB_ENDIANNESS_H
#define _OALB_ENDIANNESS_H

#include "globals.h"


#ifdef __CPLUSPLUS
extern "C" {
#endif 


/* check compiler requirements */
#if !defined(__BIG_ENDIAN__) && !defined(__LITTLE_ENDIAN__)
#error Do not know the endianess of this architecture
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
}
#endif

#endif /*_OALB_ENDIANNESS_H*/
