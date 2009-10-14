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

#include "common.h"
#include "wrappers.h"
#include "loaders.h"
#include "alc.h"


#ifdef __cplusplus
extern "C" {
#endif 
        
        const char      oalb_init               (const char* programname, const char usehardware);
        void            oalb_close              (void);
        char            oalb_ready              (void);
        const int32_t   oalb_loadfile           (const char* cFilename);
        void            oalb_playsound          (const uint32_t iIndex, const char bLoop);
        void            oalb_pausesound         (const uint32_t iIndex);
        void            oalb_stopsound          (const uint32_t iIndex);
        void            oalb_setvolume          (const uint32_t iIndex, const char cPercentage);
        void            oalb_setglobalvolume    (const char cPercentage);
        void            oalb_togglemute         (void);
       /*
        ALboolean   openal_setposition       (unsigned int index, float x, float y, float z);
        ALboolean   openal_fadeout           (unsigned int index, unsigned short int quantity);
        ALboolean   openal_fadein            (unsigned int index, unsigned short int quantity);
        ALboolean   openal_fade              (unsigned int index, unsigned short int quantity, ALboolean direction);
        ALboolean   openal_pausesound        (unsigned int index);
        */
        

        
#ifdef __cplusplus
}
#endif

#endif /*_OALB_INTERFACE_H*/
