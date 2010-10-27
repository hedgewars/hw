/*
 *  commands.h
 *  Hedgewars
 *
 *  Created by Vittorio on 13/06/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef _OALB_COMMANDS_H
#define _OALB_COMMANDS_H

#include "openalbridge_t.h"
#include "openalbridge.h"


#define openal_fadein(x,y)          openal_fade(x,y,AL_FADE_IN)
#define openal_fadeout(x,y)         openal_fade(x,y,AL_FADE_OUT)
#define openal_playsound_loop(x,y)  openal_playsound(x)  \
                                        if (y != 0)  \
                                        openal_toggleloop(x);
#ifdef __CPLUSPLUS
extern "C" {
#endif

    // play, pause, stop a single sound source
    void openal_pausesound        (unsigned int index);
    void openal_stopsound         (unsigned int index);

    // play a sound and set whether it should loop or not (0/1)
    void openal_playsound         (unsigned int index);

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

#ifdef __CPLUSPLUS
}
#endif

#endif /*_OALB_COMMANDS_H*/
