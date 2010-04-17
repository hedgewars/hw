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
        
        if ((aptr = malloc(nbytes)) == NULL)
            err_dump("(%s) FATAL - not enough memory");
        
        return aptr;
    }
    
    
    void *Realloc (void *aptr, size_t nbytes) {
        aptr = realloc(aptr, nbytes);
        
        if (aptr == NULL) 
            err_dump("(%s) FATAL - not enough memory");
        
        return aptr;
    }
    
    
    FILE *Fopen (const char *fname, char *mode)	{
        FILE *fp;
        
        fp = fopen(fname,mode);
        if (fp == NULL)
            err_ret("(%s) ERROR - can't open file %s in mode '%s'", prog, fname, mode);
        
        return fp;
    }
    
    /*TODO make a proper error reporting routine*/
    ALint AlGetError (const char *str) {
        ALenum error;
        
        error = alGetError();
        if (error != AL_NO_ERROR) {
            err_msg(str, prog);
            return error;
        } else 
            return AL_TRUE;
    }
    
    ALint AlGetError2 (const char *str, int num) {
        ALenum error;
        
        error = alGetError();
        if (error != AL_NO_ERROR) {
            err_msg(str, prog, num);
            return error;
        } else 
            return AL_TRUE;
    }
    
    void *helper_fadein(void *tmp) {
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
        err_msg("(%s) INFO - Fade-in in progress [index %d quantity %d]", prog, index, quantity);
#endif
        
        /*save the volume desired after the fade*/
        alGetSourcef(Sources[index], AL_GAIN, &target_gain);
        if (target_gain > 1.0f || target_gain <= 0.0f)
            target_gain = 1.0f;
        
        alSourcePlay(Sources[index]);
        
        for (gain = 0.0f ; gain <= target_gain; gain += (float) quantity/10000) {
#ifdef TRACE
            err_msg("(%s) DEBUG - Fade-in set gain to %f", gain);
#endif
            alSourcef(Sources[index], AL_GAIN, gain);
            usleep(10000);
        }
        
        AlGetError("(%s) WARN - Failed to set fade-in volume level");
        
#ifndef _WIN32
        pthread_exit(NULL);
#else
        _endthread();
#endif
        return 0;
    }
    
    void *helper_fadeout(void *tmp) {
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
        err_msg("(%s) INFO - Fade-out in progress [index %d quantity %d]", prog, index, quantity);
#endif
        
        alGetSourcef(Sources[index], AL_GAIN, &old_gain);
        
        for (gain = old_gain; gain >= 0.00f; gain -= (float) quantity/10000) {
#ifdef TRACE
            err_msg("(%s) DEBUG - Fade-out set gain to %f", gain);
#endif
            alSourcef(Sources[index], AL_GAIN, gain);
            usleep(10000);
        }
        
        AlGetError("(%s) WARN - Failed to set fade-out volume level");
        
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
