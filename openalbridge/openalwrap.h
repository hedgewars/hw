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
#include "alc.h"
#include "loaders.h"
#include "wrappers.h"
#include "endianness.h"

#ifndef _WIN32
#include <pthread.h>
#include <stdint.h>
#else
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include "winstdint.h"
#endif


#ifdef __CPLUSPLUS
extern "C" {
#endif 
	
#pragma once
	
	ALint	openal_init				(int memorysize);
	ALint	openal_close			(void);
	int		openal_loadfile			(const char *filename);
	ALint	openal_toggleloop		(int index);
	ALint	openal_setvolume		(int index, unsigned char percentage);
	ALint	openal_setglobalvolume	(unsigned char percentage);
	ALint	openal_togglemute		(void);
	ALint	openal_fadeout			(int index, unsigned int quantity);
	ALint	openal_fadein			(int index, unsigned int quantity);
	ALint	openal_playsound		(int index);	
	ALint	openal_pausesound		(int index);
	ALint	openal_stopsound		(int index);
	
#ifdef __CPLUSPLUS
}
#endif