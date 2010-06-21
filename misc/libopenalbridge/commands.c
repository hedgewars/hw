/*
 *  commands.c
 *  Hedgewars
 *
 *  Created by Vittorio on 13/06/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "commands.h"
#include "wrappers.h"

ALfloat old_gain;
extern ALuint *Sources;
extern ALuint cache_size, cache_index, sources_number;
extern ALboolean instances_number;
extern al_sound_t *the_sounds;

void openal_pausesound (uint32_t index) {
    if (openal_ready() == AL_TRUE && index < cache_size)
        alSourcePause(Sources[the_sounds[index].source_index]);
}


void openal_stopsound (uint32_t index) {
    if (openal_ready() == AL_TRUE && index < cache_size)
        alSourceStop(Sources[the_sounds[index].source_index]);
}


void openal_playsound (unsigned int index) {
    ALboolean needsSource = AL_TRUE;
    ALfloat SourcePosition[] = { 0.0, 0.0, 0.0 };
    ALfloat SourceVelocity[] = { 0.0, 0.0, 0.0 };
    ALint state;
    int i, j;
    
    if (openal_ready() == AL_TRUE && index < cache_size) {
        // check if sound has already a source
        if (the_sounds[index].source_index != -1) {
            // it has a source, check it's not playing
            alGetSourcei(Sources[the_sounds[index].source_index], AL_SOURCE_STATE, &state);
            if (state != AL_PLAYING && state != AL_PAUSED) { 	 
                // it is not being played, so we can use it safely
	            needsSource = AL_FALSE; 		 
            }
            // else it is being played, so we have to allocate a new source for this buffer
        }
        
        if (needsSource) {
#ifdef DEBUG
            fprintf(stderr,"(Bridge Debug) - looking for a source for sound %d\n", index);
#endif
            for (i = 0; i < sources_number; i++) {
                // let's iterate on Sources until we find a source that is not playing
                alGetSourcei(Sources[i], AL_SOURCE_STATE, &state); 	 
                if (state != AL_PLAYING && state != AL_PAUSED) {
                    // let's iterate on the_sounds until we find the sound using that source
                    for (j = 0; j < cache_size; j++) {
                        if (the_sounds[j].source_index == i) {
                            the_sounds[j].source_index = -1;
                            break;
                        }
                    }
                    // here we know that no-one is using that source so we can use it
                    break;
                }
            }
            
            if (i == sources_number) {
                // this means all sources are busy
            }
            
            // set source properties that it will use when it's in playback
            alSourcei (Sources[i], AL_BUFFER,   the_sounds[index].buffer);
            alSourcef (Sources[i], AL_PITCH,    1.0f);
            alSourcef (Sources[i], AL_GAIN,     1.0f);
            alSourcefv(Sources[i], AL_POSITION, SourcePosition);
            alSourcefv(Sources[i], AL_VELOCITY, SourceVelocity);
            alSourcei (Sources[i], AL_LOOPING,  0);
            
            if (AL_NO_ERROR != alGetError()) {
                fprintf(stderr,"(Bridge ERROR) - failed to set Source properties\n");
                return;
            }
            the_sounds[index].source_index = i;
        }
        
        alSourcePlay(Sources[the_sounds[index].source_index]);
        
        if (AL_NO_ERROR != alGetError()) {
            fprintf(stderr,"(Bridge Warning) - failed to play sound %d\n", index);
            return;
        }
    }
}

void openal_toggleloop (uint32_t index) {
    ALint loop;

    if (openal_ready() == AL_TRUE && index < cache_size) {
        alGetSourcei (Sources[the_sounds[index].source_index], AL_LOOPING, &loop);
        alSourcei (Sources[the_sounds[index].source_index], AL_LOOPING, !((uint8_t) loop) & 0x00000001);
    }
}


void openal_setvolume (uint32_t index, float gain) {
    if (openal_ready() == AL_TRUE && index < cache_size)
        alSourcef (Sources[the_sounds[index].source_index], AL_GAIN, gain);
}


void openal_setglobalvolume (float gain) {
    if (openal_ready() == AL_TRUE)
        alListenerf (AL_GAIN, gain);
}

void openal_togglemute () {
    ALfloat gain;

    if (openal_ready() == AL_TRUE) {
        alGetListenerf (AL_GAIN, &gain);
        if (gain > 0) {
            old_gain = gain;
            gain = 0;
        } else
            gain = old_gain;

        alListenerf (AL_GAIN, gain);
    }
}

// Fade in or out by calling a helper thread
void openal_fade (uint32_t index, uint16_t quantity, al_fade_t direction) {
#ifndef _WIN32
    pthread_t thread;
#else
    HANDLE Thread;
#endif
    fade_t *fade;

    if (openal_ready() == AL_TRUE && index < cache_size) {
        fade = (fade_t*) Malloc(sizeof(fade_t));
        fade->index = index;
        fade->quantity = quantity;
        fade->type = direction;

#ifndef _WIN32
        pthread_create(&thread, NULL, (void *)helper_fade, (void *)fade);
        pthread_detach(thread);
#else
        Thread = (HANDLE) _beginthread((void *)helper_fade, 0, (void *)fade);
#endif
    }
}

void openal_setposition (uint32_t index, float x, float y, float z) {
    if (openal_ready() == AL_TRUE && index < cache_size)
        alSource3f(Sources[the_sounds[index].source_index], AL_POSITION, x, y, z);;
}

void helper_fade(void *tmp) {
    ALfloat gain;
    ALfloat target_gain;
    fade_t *fade;
    uint32_t index;
    uint16_t quantity;
    al_fade_t type;

    fade = tmp;
    index = fade->index;
    quantity = fade->quantity;
    type = fade->type;
    free (fade);

    if (type == AL_FADE_IN) {
#ifdef DEBUG
        fprintf(stderr,"(Bridge Info) - Fade-in in progress [index %d quantity %d]", index, quantity);
#endif

        // save the volume desired after the fade
        alGetSourcef(Sources[the_sounds[index].source_index], AL_GAIN, &target_gain);
        if (target_gain > 1.0f || target_gain <= 0.0f)
            target_gain = 1.0f;

        for (gain = 0.0f ; gain <= target_gain; gain += (float) quantity/10000) {
#ifdef TRACE
            fprintf(stderr,"(Bridge Debug) - Fade-in set gain to %f\n", gain);
#endif
            alSourcef(Sources[the_sounds[index].source_index], AL_GAIN, gain);
            usleep(10000);
        }
    } else {
        alGetSourcef(Sources[the_sounds[index].source_index], AL_GAIN, &target_gain);

        for (gain = target_gain; gain >= 0.00f; gain -= (float) quantity/10000) {
#ifdef TRACE
            fprintf(stderr,"(Bridge Debug) - Fade-out set gain to %f\n", gain);
#endif
            alSourcef(Sources[the_sounds[index].source_index], AL_GAIN, gain);
            usleep(10000);
        }

        if (AL_NO_ERROR != alGetError())
            fprintf(stderr,"(Bridge Warning) - Failed to set fade-out effect\n");

        // stop that sound and reset its volume
        alSourceStop (Sources[the_sounds[index].source_index]);
        alSourcef (Sources[the_sounds[index].source_index], AL_GAIN, target_gain);
    }

    if (AL_NO_ERROR != alGetError())
        fprintf(stderr,"(Bridge Warning) - Failed to set fade effect\n");

#ifndef _WIN32
    pthread_exit(NULL);
#else
    _endthread();
#endif
}

