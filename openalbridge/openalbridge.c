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

#include "openalbridge.h"

char oalbReady = 0;
int iNumSounds = 0;
char *prog;
/*Sources are points emitting sound*/
ALuint Sources[MAX_SOURCES];

/*structure that holds information about sounds*/
SSound_t *theSounds;

ALfloat SourcePos[] = { 0.0, 0.0, 0.0 }; /*Position of the source sound*/
ALfloat SourceVel[] = { 0.0, 0.0, 0.0 }; /*Velocity of the source sound*/

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
        /*Initialize an OpenAL contex and allocate memory space for data and buffers*/
        ALCcontext *context;
        ALCdevice *device;
        const ALCchar *default_device;
        int i;
        
        prog = (char *) programname;
        
        /*Position of the listener*/
        ALfloat ListenerPos[] = {0.0, 0.0, 0.0};
        /*Velocity of the listener*/
        ALfloat ListenerVel[] = {0.0, 0.0, 0.0};
        /*Orientation of the listener. (first 3 elements are "at", second 3 are "up")*/
        ALfloat ListenerOri[] = {0.0, 0.0, -1.0, 0.0, 1.0, 0.0};
        
        if (oalbReady == 1) {
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
        err_msg("(%s) INFO - Output device: %s", prog, alcGetString(device, ALC_DEVICE_SPECIFIER));
        
        context = alcCreateContext(device, NULL);
        alcMakeContextCurrent(context);
        alcProcessContext(context);
        
        if (AlGetError("(%s) ERROR - Failed to create a new contex") != AL_TRUE)
                return AL_FALSE;
        
        /*set the listener gain, position (on xyz axes), velocity (one value for each axe) and orientation*/
        alListenerf (AL_GAIN,        1.0f       );
        alListenerfv(AL_POSITION,    ListenerPos);
        alListenerfv(AL_VELOCITY,    ListenerVel);
        alListenerfv(AL_ORIENTATION, ListenerOri);
        
        if (AlGetError("(%s) WARN - Failed to set Listener properties") != AL_TRUE)
                return AL_FALSE;
        
        theSounds = (SSound_t*) Malloc(sizeof(SSound_t)*MAX_SOUNDS);
        for (i = 0; i < MAX_SOUNDS; i++) {
                theSounds->isLoaded = 0;
                theSounds->sourceIndex = -1;
        }
        
        alGenSources(MAX_SOURCES, Sources);
        oalbReady = 1;
        
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
        /*Stop all sounds, deallocate all memory and close OpenAL */
        ALCcontext *context;
        ALCdevice  *device;
        int i;
        
        if (oalbReady == 0) {
                errno = EPERM;
                err_ret("(%s) WARN - OpenAL not initialized", prog);
                return;
        }
        
        alSourceStopv	(MAX_SOURCES, Sources);
        alDeleteSources (MAX_SOURCES, Sources);
        
        for (i = 0; i < MAX_SOUNDS; i++) {
                free(theSounds[i].filename);
                alDeleteBuffers (1, &theSounds[i].Buffer);
        }
        free(theSounds);
        
        context = alcGetCurrentContext();
        device  = alcGetContextsDevice(context);
        
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
/*
 ALboolean helper_realloc (void) {
 expands allocated memory when loading more sound files than expected
 int oldsize = globalsize;
 globalsize += increment;
 
 #ifdef DEBUG
 err_msg("(%s) INFO - Realloc in process from %d to %d\n", prog, oldsize, globalsize);
 #endif
 
 Buffers = (ALuint*) Realloc(Buffers, sizeof(ALuint)*globalsize);
 Sources = (ALuint*) Realloc(Sources, sizeof(ALuint)*globalsize);
 
 return AL_TRUE;
 }*/

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

const int32_t oalb_loadfile (const char *filename){
        /*Open a file, load into memory and allocate the Source buffer for playing*/
        
        ALenum format, error;
        ALsizei bitsize, freq;
        char *data;
        int namelength, i;
        uint32_t magic;
        FILE *fp;
        
        if (oalbReady == 0) {
                errno = EPERM;                
                err_ret("(%s) WARN - OpenAL not initialized", prog);
                return -1;
        }
        
        /*when the buffers are all used, we can expand memory to accept new files*/
        //     if (globalindex == globalsize)
        //            helper_realloc();
        
        namelength=strlen(filename);
        /*if this sound is already loaded return the index from theSounds*/
        for (i = 0; i < iNumSounds; i++){
                if (theSounds[iNumSounds].isLoaded == 1) {
                        if (strncmp(theSounds[iNumSounds].filename, filename, namelength) == 0)
                                return i;
                }
        }
        
        /*else load it and store it into a theSounds cell*/
        
        /*detect the file format, as written in the first 4 bytes of the header*/
        fp = Fopen (filename, "rb");
        
        if (fp == NULL)
                return -1;
        
        error = fread (&magic, sizeof(uint32_t), 1, fp);
        fclose (fp);
        
        if (error < 0) {
                errno = EIO;
                err_ret("(%s) ERROR - File %s is too short", prog, filename);
                return -2;
        }
        
        switch (ENDIAN_BIG_32(magic)) {
                case OGG_FILE_FORMAT:
                        error = load_oggvorbis (filename, &format, &data, &bitsize, &freq);
                        break;
                case WAV_FILE_FORMAT:
                        error = load_wavpcm (filename, &format, &data, &bitsize, &freq);
                        break;
                default:
                        errno = EINVAL;
                        err_ret ("(%s) ERROR - File format (%08X) not supported", prog, ENDIAN_BIG_32(magic));
                        return -5;
                        break;
        }
        
        theSounds[iNumSounds].filename = (char*) Malloc(sizeof(char) * namelength);
        strncpy(theSounds[iNumSounds].filename, filename, namelength);
        theSounds[iNumSounds].isLoaded = 1;
        
        /*prepare the buffer to receive data*/
        alGenBuffers(1, &theSounds[iNumSounds].Buffer);
        
        if (AlGetError("(%s) ERROR - Failed to allocate memory for buffers") != AL_TRUE)
                return -3;
        
        /*copy pcm data in one buffer*/
        alBufferData(theSounds[iNumSounds].Buffer, format, data, bitsize, freq);
        /*deallocate data to save memory*/
        free(data);		
        
        if (AlGetError("(%s) ERROR - Failed to write data to buffers") != AL_TRUE)
                return -6;
        
        alGetError();  /* clear any AL errors beforehand */
        
        /*returns the index of the source you just loaded, increments it and exits*/
        return iNumSounds++;
}



void oalb_setvolume (const uint32_t iIndex,  const char cPercentage) {
        float percentage;
        
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
                percentage = 1.0f;
        else
                percentage = cPercentage / 100.0f;
        
        alSourcef(Sources[theSounds[iIndex].sourceIndex], AL_GAIN, percentage);
        
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


void oalb_fade (uint32_t iIndex, uint16_t quantity, ALboolean direction) {
        /*Fade in or out by calling a helper thread*/
#ifndef _WIN32
        pthread_t thread;
#else
        HANDLE Thread;
        DWORD threadID;
#endif
        fade_t *fade;
        
        if (oalbReady == 0) {
                errno = EPERM;                
                err_ret("(%s) WARN - OpenAL not initialized", prog);
                return ;
        }
        
        fade = (fade_t*) Malloc(sizeof(fade_t));
        fade->index = iIndex;
        fade->quantity = quantity;
        
        if(iIndex < 0 || iIndex >= iNumSounds) {
                errno = EINVAL;
                err_ret("(%s) ERROR - Index (%d) out of bounds", prog, iIndex);
                return;
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
                        err_ret("(%s) ERROR - Unknown direction for fading", prog, index);
                        free(fade);
                        return;
                        break;
        }
        
#ifndef _WIN32
        pthread_detach(thread);
#endif
        
        alGetError();  /* clear any AL errors beforehand */
        
        return;
}


void oalb_fadeout (uint32_t index, uint16_t quantity) {
        /*wrapper for fadeout*/
        oalb_fade(index, quantity, FADE_OUT);
        return;
}


void oalb_fadein (uint32_t index, uint16_t quantity) {
        /*wrapper for fadein*/
        oalb_fade(index, quantity, FADE_IN);
        return;
}
 

/*      ALboolean openal_setposition (uint32_t index, float x, float y, float z) {
 if (openalReady == AL_FALSE) {
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
 }*/


void oalb_playsound (const uint32_t iIndex, const char bLoop){
        int findNewSource;
        int i, j, state;
        
        if (oalbReady == 0) {
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
        
        /*check if sound has already a source*/
        if (theSounds[iIndex].sourceIndex == -1) {
                /*needs a new source*/
                findNewSource = 1;
        } else {
                /*already has a source -- check it's not playing*/
                alGetSourcei(Sources[theSounds[iIndex].sourceIndex], AL_SOURCE_STATE, &state);
                if(state == AL_PLAYING || state == AL_PAUSED) {
                        /*it is being played, so we have to allocate a new source*/
                        findNewSource = 1;
                } else {
                        /*it is not being played, so we can use it safely*/
                        findNewSource = 0;
                }
        }
        
        if (findNewSource == 1) {
#ifdef DEBUG
             err_msg("(%s) DEBUG - Looking for a source for sound %d", prog, iIndex);   
#endif
                for (i = 0; i < MAX_SOURCES; i++) {
                        alGetSourcei(Sources[i], AL_SOURCE_STATE, &state);
                        if(state != AL_PLAYING && state != AL_PAUSED) {
                              //  alSourceStop(Sources[i]);
                              //  alGetError();
                                for(j = 0; j < iNumSounds; j++)
                                        if(theSounds[j].isLoaded && theSounds[j].sourceIndex == i)
                                                theSounds[j].sourceIndex = -1;
                                break;
                        } else {
                                //TODO: what happens when all 16 sources are busy?
                        }
                }
                theSounds[iIndex].sourceIndex = i;
        }
        
        alSourcei (Sources[theSounds[iIndex].sourceIndex], AL_BUFFER,   theSounds[iIndex].Buffer);
        alSourcef (Sources[theSounds[iIndex].sourceIndex], AL_PITCH,    1.0f        );
        alSourcef (Sources[theSounds[iIndex].sourceIndex], AL_GAIN,     1.0f        );
        alSourcefv(Sources[theSounds[iIndex].sourceIndex], AL_POSITION, SourcePos   );
        alSourcefv(Sources[theSounds[iIndex].sourceIndex], AL_VELOCITY, SourceVel   );
        alSourcei (Sources[theSounds[iIndex].sourceIndex], AL_LOOPING,  bLoop       );
        if (AlGetError("(%s) ERROR - Failed to set Source properties") != AL_TRUE)
                return;
        
        alSourcePlay(Sources[theSounds[iIndex].sourceIndex]);
        if (AlGetError2("(%s) ERROR - Failed to play sound %d)", iIndex) != AL_TRUE)
                return;
        
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
        alSourcePause(Sources[theSounds[iIndex].sourceIndex]);                             
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
        alSourceStop(Sources[theSounds[iIndex].sourceIndex]);                             
        
        if (AlGetError2("(%s) ERROR - Failed to stop sound %d)", iIndex) != AL_TRUE)
                return;
        
        alGetError();  /* clear any AL errors beforehand */
        
        return;
}
