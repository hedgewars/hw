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

#ifndef _WIN32
#include <stdint.h>
#else
#include "winstdint.h"
#endif

#ifdef __CPLUSPLUS
extern "C" {
#endif 
	
#ifdef HAVE_BYTESWAP_H
	/* use byteswap macros from the host system, hopefully optimized ones ;-) */
#include <byteswap.h>
#else
	/* define our own version, simple, stupid, straight-forward... */
	
#define bswap_16(x)	((((x) & 0xFF00) >> 8) | (((x) & 0x00FF) << 8))
	
#define bswap_32(x)	((((x) & 0xFF000000) >> 24) | \
					(((x) & 0x00FF0000) >> 8)  | \
					(((x) & 0x0000FF00) << 8)  | \
					(((x) & 0x000000FF) << 24) )
	
#endif
	
	
#pragma once
	
	int invert_endianness(int number);
	
#ifdef __CPLUSPLUS
}
#endif