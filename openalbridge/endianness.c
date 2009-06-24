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
#include <stdint.h>
#include "endianness.h"

#ifdef __CPLUSPLUS
extern "C" {
#endif 
	
	//from big endian to little endian
	int invert_endianness(int number){
		uint8_t n1,n2,n3,n4;
		uint32_t a1,a2,a3,a4;
		uint32_t done = 0;
		
		n1 = number;
		n2 = number >> 8;
		n3 = number >> 16;
		n4 = number >> 24;
		
		//printf("%X, %X, %X, %X\n", n1, n2, n3, n4);
		a1 = (uint32_t) n1 << 24;
		a2 = (uint32_t) n2 << 16;
		a3 = (uint32_t) n3 << 8;
		a4 = (uint32_t) n4;
		done = a1 + a2 + a3 + a4;
		//printf("%08X %08X %08X %08X = %08X\n", a1, a2, a3, a4, done);
		return done;
	}
	
#ifdef __CPLUSPLUS
}
#endif