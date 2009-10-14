/*
 * OpenAL Bridge - a simple portable library for OpenAL interface
 * Copyright (c) 2009 Vittorio Giovara <vittorio.giovara@gmail.com>,
 *                    Mario Liebisch <mario.liebisch+hw@googlemail.com>
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

#include "openalbridge.h"


char *prog;

/*Buffers hold sound data*/
ALuint *Buffers;
/*index for Sources and Buffers*/
ALuint globalindex, globalsize, increment;

//null vector
const ALfloat NV[] = {0.0f, 0.0f, 0.0f};
//listener orientation
const ALfloat LO[] = {0.0f, 0.0f, -1.0f, 0.0f, 1.0f, 0.0f};

SSound_t aSounds[MAX_SOUNDS];
int iNumSounds = 0;
char oalbReady = 0;

ALCcontext *context;
ALCdevice *device;
ALuint sources[MAX_SOURCES];




/**
 * const char oalb_init (const char* programname, const char usehardware) 
 *
 *  ARGUMENTS
 * programname [const char*]: name of the program invoking OpenAL
 * usehardware [const char] : flag to enable audio hardware acceleration
 *  DESCRIPTION
 *
 *  RETURN
 * 1 success
 * 2 error
 */

const char oalb_init (const char* programname, const char usehardware) {                
        prog = (char *) programname;
        
        if (oalbReady == AL_TRUE) {
                errno = EPERM;                
                err_ret("(%s) WARN - OpenAL already initialized", prog);
                return AL_FALSE;
        }
        
#ifdef _WIN32
        /* Hardware acceleration is broken on some windows card*/
        if (usehardware != 0)
                device = alcOpenDevice(NULL);
        else
        {
                device = alcOpenDevice("Generic Software");
                if(!device)
                {
                        err_msg("(%s) WARN - Failed to open software device", prog);
                        device = alcOpenDevice(NULL);
                }
        }
#else
        /*always hardware for UNIX systems*/
        device = alcOpenDevice(NULL);
#endif
        
        if (device == NULL) {
                errno = ENODEV;                
                err_ret("(%s) WARN - Failed to open sound device", prog);
                return AL_FALSE;
        }
        
        err_msg("(%s) INFO - Using OpenAL device: %s", prog, alcGetString(device, ALC_DEVICE_SPECIFIER));
        
        context = alcCreateContext(device, NULL);
        alcMakeContextCurrent(context);
        
        if (AlGetError("(%s) WARN - Failed to create a new contex") != AL_TRUE)
                return AL_FALSE;
        
        /*set the listener gain, position (on xyz axes), velocity (one value for each axe) and orientation*/
        alListenerf (AL_GAIN,        1.0f);
        alListenerfv(AL_POSITION,    NV);
        alListenerfv(AL_VELOCITY,    NV);
        alListenerfv(AL_ORIENTATION, LO);
        
        alcProcessContext(context);
        
        if (AlGetError("(%s) WARN - Failed to set Listener properties") != AL_TRUE)
                return AL_FALSE;
        
        alGenSources(MAX_SOURCES, sources);
        
        oalbReady = AL_TRUE;
        
        alGetError();  /* clear any AL errors beforehand */
        return AL_TRUE;
}


/**
 * void oalb_close (void) 
 *
 *  ARGUMENTS
 * -
 *  DESCRIPTION
 * Stop all sounds, deallocate all memory and close OpenAL
 *  RETURN
 * -
 */

void oalb_close (void) {
        int i;
        
        if (oalbReady == 0) {
                errno = EPERM;
                err_ret("(%s) WARN - OpenAL not initialized", prog);
                return;
        }
        
        for(i = 0; i < iNumSounds; i++) {
                SSound_stop(&aSounds[i]);
                SSound_close(&aSounds[i]);
        }
        
        alSourceStopv (MAX_SOURCES, sources);
        alDeleteSources (MAX_SOURCES, sources);
        
        alcMakeContextCurrent(NULL);
        alcDestroyContext(context);
        alcCloseDevice(device);
        
        oalbReady = 0;
        
        return;
}

/**
 * char oalb_ready (void)  
 *
 *  ARGUMENTS
 * -
 *  DESCRIPTION
 *
 *  RETURN
 * -
 */

char oalb_ready (void) {
        return oalbReady;
}

/**
 * const int32_t oalb_loadfile (const char *filename) 
 *
 *  ARGUMENTS
 * -
 *  DESCRIPTION
 *
 *  RETURN
 * -
 */

const int32_t oalb_loadfile (const char *filename) {
        int i;
        
        if (oalbReady == 0) {
                errno = EPERM;                
                err_ret("(%s) WARN - OpenAL not initialized", prog);
                return -1;
        }
        
        if(iNumSounds == MAX_SOUNDS) {
                err_msg("(%s) WARN - Maximum number of sound samples reached", prog);
                return -3;
        }
        
        
        for(i = 0; i < iNumSounds; i++)
                if(strcmp(aSounds[i].Filename, filename) == 0)
                        return i;
        
        if(SSound_load(&aSounds[iNumSounds], filename))
                return iNumSounds++;
        else
                return -2;
        
}


void oalb_setvolume (const uint32_t iIndex,  const char cPercentage) {
        if (oalbReady == 0) {
                errno = EPERM;                
                err_ret("(%s) WARN - OpenAL not initialized", prog);
                return;
        }
        
        /*Set volume for sound number index*/
        if(iIndex < 0 || iIndex >= iNumSounds) {
                errno = EINVAL;
                err_ret("(%s) ERROR - Index (%d) out of bounds", prog, iIndex);
                return;
        }
        
        if(cPercentage > 100)
                SSound_volume(&aSounds[iIndex], 1.0f);
        else
                SSound_volume(&aSounds[iIndex], cPercentage / 100.0f);
        
        if (AlGetError2("(%s) ERROR -  Failed to set volume for sound %d\n", iIndex) != AL_TRUE)
                return;
        
        alGetError();  /* clear any AL errors beforehand */
        
        return;
}


void oalb_setglobalvolume (const char cPercentage) {
        if (oalbReady == 0) {
                errno = EPERM;                
                err_ret("(%s) WARN - OpenAL not initialized", prog);
                return;
        }
        
        /*Set volume for all sounds*/		
        if(cPercentage > 100)
                alListenerf (AL_GAIN, 1.0f);
        else
                alListenerf (AL_GAIN, cPercentage / 100.0f);
        
        if (AlGetError("(%s) ERROR -  Failed to set global volume") != AL_TRUE)
                return;
        
        alGetError();  /* clear any AL errors beforehand */
        
        return;
}

    
void oalb_togglemute (void) {
        /*Mute or unmute sound*/
        ALfloat mute;
        
        if (oalbReady == AL_FALSE) {
                errno = EPERM;                
                err_ret("(%s) WARN - OpenAL not initialized", prog);
                return;
        }
        
        alGetListenerf (AL_GAIN, &mute);
        if (mute > 0) 
                mute = 0;
        else
                mute = 1.0;
        
        alListenerf (AL_GAIN, mute);
        
        if (AlGetError("(%s) ERROR -  Failed to set mute property") != AL_TRUE)
                return;
        
        alGetError();  /* clear any AL errors beforehand */
        
        return;
}
 /*
 
 ALboolean openal_fade (uint32_t index, uint16_t quantity, ALboolean direction) {
 /*Fade in or out by calling a helper thread
 #ifndef _WIN32
 pthread_t thread;
 #else
 HANDLE Thread;
 DWORD threadID;
 #endif
 fade_t *fade;
 
 if (oalbReady == AL_FALSE) {
 errno = EPERM;                
 err_ret("(%s) WARN - OpenAL not initialized", prog);
 return AL_FALSE;
 }
 
 fade = (fade_t*) Malloc(sizeof(fade_t));
 fade->index = index;
 fade->quantity = quantity;
 
 if (index >= globalsize) {
 errno = EINVAL;
 err_ret("(%s) ERROR - Index out of bounds (got %d, max %d)", prog, index, globalindex);
 return AL_FALSE;
 }
 
 switch (direction) {
 case FADE_IN:
 #ifndef _WIN32
 pthread_create(&thread, NULL, helper_fadein, (void*) fade);
 #else
 Thread = _beginthread(&helper_fadein, 0, (void*) fade);
 #endif
 break;
 case FADE_OUT:
 #ifndef _WIN32
 pthread_create(&thread, NULL, helper_fadeout, (void*) fade);
 #else
 Thread = _beginthread(&helper_fadeout, 0, (void*) fade);
 #endif	
 break;
 default:
 errno = EINVAL;
 err_ret("(%s) ERROR - Unknown direction for fading", prog, index, globalindex);
 free(fade);
 return AL_FALSE;
 break;
 }
 
 #ifndef _WIN32
 pthread_detach(thread);
 #endif
 
 alGetError();  /* clear any AL errors beforehand 
 
 return AL_TRUE;
 }
 
 
 ALboolean openal_fadeout (uint32_t index, uint16_t quantity) {
 /*wrapper for fadeout
 return openal_fade(index, quantity, FADE_OUT);
 }
 
 
 ALboolean openal_fadein (uint32_t index, uint16_t quantity) {
 /*wrapper for fadein
 return openal_fade(index, quantity, FADE_IN);
 }
 
 
 ALboolean openal_setposition (uint32_t index, float x, float y, float z) {
 if (oalbReady == AL_FALSE) {
 errno = EPERM;                
 err_ret("(%s) WARN - OpenAL not initialized", prog);
 return AL_FALSE;
 }
 
 if (index >= globalsize) {
 errno = EINVAL;
 err_ret("(%s) ERROR - Index out of bounds (got %d, max %d)", prog, index, globalindex);
 return AL_FALSE;
 }
 
 alSource3f(Sources[index], AL_POSITION, x, y, z);
 if (AlGetError2("(%s) ERROR - Failed to set position for sound %d)", index) != AL_TRUE)
 return AL_FALSE;
 
 return AL_TRUE;
 }
 
 */

void oalb_playsound (const uint32_t iIndex, const char bLoop) {
        if (oalbReady == AL_FALSE) {
                errno = EPERM;                
                err_ret("(%s) WARN - OpenAL not initialized", prog);
                return;
        }
        
        /*Play sound number index*/
        if(iIndex < 0 || iIndex >= iNumSounds) {
                errno = EINVAL;
                err_ret("(%s) ERROR - Index (%d) out of bounds", prog, iIndex);
                return;
        }
        SSound_play(&aSounds[iIndex], bLoop);
        
        
        
        alGetError();  /* clear any AL errors beforehand */
        
        return;
}


void oalb_pausesound (const uint32_t iIndex) {
        if (oalbReady == AL_FALSE) {
                errno = EPERM;                
                err_ret("(%s) WARN - OpenAL not initialized", prog);
                return;
        }
        
        /*Pause sound number index*/
        if(iIndex < 0 || iIndex >= iNumSounds) {
                errno = EINVAL;
                err_ret("(%s) ERROR - Index (%d) out of bounds", prog, iIndex);
                return;
        }
        SSound_pause(&aSounds[iIndex]);
        
        if (AlGetError2("(%s) ERROR - Failed to pause sound %d)", iIndex) != AL_TRUE)
                return;
        
        return;
}


void oalb_stopsound (const uint32_t iIndex) {
        if (oalbReady == AL_FALSE) {
                errno = EPERM;                
                err_ret("(%s) WARN - OpenAL not initialized", prog);
                return;
        }
        
        /*Stop sound number index*/
        if(iIndex < 0 || iIndex >= iNumSounds) {
                errno = EINVAL;
                err_ret("(%s) ERROR - Index (%d) out of bounds", prog, iIndex);
                return;
        }
        SSound_stop(&aSounds[iIndex]);
        
        if (AlGetError2("(%s) ERROR - Failed to stop sound %d)", iIndex) != AL_TRUE)
                return;
        
        alGetError();  /* clear any AL errors beforehand */
        
        return;
}
