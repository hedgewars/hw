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

#include <stdint.h>
#include "al.h"

#ifndef _OALB_INTERFACE_TYPES_H
#define _OALB_INTERFACE_TYPES_H

enum al_fade_enum {AL_FADE_IN, AL_FADE_OUT};
typedef enum al_fade_enum al_fade_t;


// data type to handle which source source is playing what
#pragma pack(1)
typedef struct _al_sound_t {
    const char *filename;       // name of the sound file
    ALuint buffer;              // actual sound content
    uint32_t source_index;      // index of the associated source
    ALboolean is_used;          // tells if the element can be overwritten
} al_sound_t;
#pragma pack()


// data type for passing data between threads
#pragma pack(1)
typedef struct _fade_t {
    uint32_t index;
    uint16_t quantity;
    al_fade_t type;
} fade_t;
#pragma pack()


// data type for WAV header
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


#ifdef __CPLUSPLUS
}
#endif

#endif /*_OALB_INTERFACE_TYPES_H*/
