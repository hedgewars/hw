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

#ifndef _OALB_INTERFACE_H
#define _OALB_INTERFACE_H


#ifdef __CPLUSPLUS
extern "C" {
#endif 
		
	int openal_init				(unsigned int memorysize);
	int openal_close			(void);
	int openal_loadfile			(const char *filename);
	int openal_toggleloop		(unsigned int index);
	int openal_setposition		(unsigned int index, float x, float y, float z);
	int openal_setvolume		(unsigned int index, unsigned char percentage);
	int openal_setglobalvolume	(unsigned char percentage);
	int openal_togglemute		(void);
	int openal_fadeout			(unsigned int index, unsigned short int quantity);
	int openal_fadein			(unsigned int index, unsigned short int quantity);
	int openal_fade				(unsigned int index, unsigned short int quantity, unsigned char direction);
	int openal_playsound		(unsigned int index);	
	int openal_pausesound		(unsigned int index);
	int openal_stopsound		(unsigned int index);
	
#ifdef __CPLUSPLUS
}
#endif

#endif /*_OALB_INTERFACE_H*/
