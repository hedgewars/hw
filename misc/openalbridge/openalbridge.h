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

#include "openalbridge_t.h"

#ifdef __CPLUSPLUS
extern "C" {
#endif

    // init audio context and allocate memory
    int openal_init               (int memorysize);

    // close audio subsytem and free memory
    void openal_close             (void);

    // check if openal_init has been called
    char openal_ready             (void);

    // load an audio file into memory and map it to abuffer
    int  openal_loadfile          (const char *filename);

    // play, pause, stop a single sound source
    void openal_playsound         (unsigned int index);
    void openal_pausesound        (unsigned int index);
    void openal_stopsound         (unsigned int index);

    // play a sound and set whether it should loop or not (0/1)
    void openal_playsound_loop    (unsigned int index, char loops);

    // stop a sound and free the associated buffer
    void openal_stopsound_free    (unsigned int index, char freesource);

    void openal_freesound         (unsigned int index);

    // set or unset the looping property for a sound source
    void openal_toggleloop        (unsigned int index);

    // set position and volume of a sound source
    void openal_setposition       (unsigned int index, float x, float y, float z);
    void openal_setvolume         (unsigned int index, float gain);

    // set volume for all sounds (gain interval is [0-1])
    void openal_setglobalvolume   (float gain);

    // mute or unmute all sounds
    void openal_togglemute        (void);

    // fade effect,
    void openal_fade              (unsigned int index, unsigned short int quantity, al_fade_t direction);
    void openal_fadein            (unsigned int index, unsigned short int quantity);
    void openal_fadeout           (unsigned int index, unsigned short int quantity);


#ifdef __CPLUSPLUS
}
#endif

#endif /*_OALB_INTERFACE_H*/
