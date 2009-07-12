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

#include "wrappers.h"

#ifdef __CPLUSPLUS
extern "C" {
#endif 
    
    extern ALint *Sources;
    
    void *Malloc (size_t nbytes) {
        void *aptr;
        if ((aptr = malloc(nbytes)) == NULL) {
            fprintf(stderr, "ERROR: not enough memory! malloc() failed\n");
            exit(-1);
        }
        return aptr;
    }
    
    
    void *Realloc (void *aptr, size_t nbytes) {
        aptr = realloc(aptr, nbytes);
        
        if (aptr == NULL) {
            fprintf(stderr, "ERROR: not enough memory! realloc() failed\n");
            free(aptr);
            exit(-1);
        }
        return aptr;
    }
    
    
    FILE *Fopen (const char *fname, char *mode)	{
        FILE *fp;
        if ((fp=fopen(fname,mode)) == NULL)
            fprintf (stderr, "ERROR: can't open file %s in mode '%s'\n", fname, mode);
        return fp;
    }
    
    
    ALint AlGetError (const char *str) {
        ALenum error;
        
        error = alGetError();
        if (error != AL_NO_ERROR) {
            fprintf(stderr, str, error);
            return -2;
        } else 
            return AL_TRUE;
    }
    
    ALint AlGetError2 (const char *str, int num) {
        ALenum error;
        
        error = alGetError();
        if (error != AL_NO_ERROR) {
            fprintf(stderr, str, error, num);
            return -2;
        } else 
            return AL_TRUE;
    }
    
#ifndef _WIN32
    void *helper_fadein(void *tmp) 
#else
    void *helper_fadein(void *tmp) 
#endif
    {
        ALfloat gain;
        ALfloat target_gain;
        fade_t *fade;
        uint32_t index; 
        uint16_t quantity; 
        
        fade = tmp;
        index = fade->index;
        quantity = fade->quantity;
        free (fade);
        
#ifdef DEBUG
        fprintf(stderr, "Fade-out: index %d quantity %d\n", index, quantity);
#endif
        
        /*save the volume desired after the fade*/
        alGetSourcef(Sources[index], AL_GAIN, &target_gain);
        if (target_gain > 1.0f || target_gain <= 0.0f)
            target_gain = 1.0f;
        
        alSourcePlay(Sources[index]);
        
        for (gain = 0.0f ; gain <= target_gain; gain += (float) quantity/10000) {
#ifdef DEBUG
            fprintf(stderr, "Fade-in: Set gain to: %f\n", gain);
#endif
            alSourcef(Sources[index], AL_GAIN, gain);
            usleep(10000);
        }
        
        AlGetError("ERROR %d: Setting fade in volume\n");
        
#ifndef _WIN32
        pthread_exit(NULL);
#else
        _endthread();
#endif
        return 0;
    }
    
    
#ifndef _WIN32
    void *helper_fadeout(void *tmp) 
#else
    void *helper_fadeout(void *tmp) 	
#endif
    {
        ALfloat gain;
        ALfloat old_gain;
        fade_t *fade;
        uint32_t index; 
        uint16_t quantity; 
        
        fade = tmp;
        index = fade->index;
        quantity = fade->quantity;
        free(fade);
        
#ifdef DEBUG
        fprintf(stderr, "Fade-out: index %d quantity %d\n", index, quantity);
#endif
        
        alGetSourcef(Sources[index], AL_GAIN, &old_gain);
        
        for (gain = old_gain; gain >= 0.00f; gain -= (float) quantity/10000) {
#ifdef DEBUG
            fprintf(stderr, "Fade-out: Set gain to %f\n", gain);
#endif
            alSourcef(Sources[index], AL_GAIN, gain);
            usleep(10000);
        }
        
        AlGetError("ERROR %d: Setting fade out volume\n");
        
        /*stop that sound and reset its volume*/
        alSourceStop (Sources[index]);
        alSourcef (Sources[index], AL_GAIN, old_gain);	
        
#ifndef _WIN32
        pthread_exit(NULL);
#else
        _endthread();
#endif
        return 0;
    }
    
    
#ifdef __CPLUSPLUS
}
#endif
