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
#include "globals.h"
#include "al.h"
#include "alc.h"
#include "wrappers.h"
#include "loaders.h"


/*Sources are points emitting sound*/
ALuint *Sources;
/*Buffers hold sound data*/
ALuint *Buffers;
/*index for Sources and Buffers*/
ALuint globalindex, globalsize, increment;

ALboolean isBridgeReady = AL_FALSE;
ALfloat old_gain;

int openal_init (int memorysize) {
    /*Initialize an OpenAL contex and allocate memory space for data and buffers*/
    ALCcontext *context;
    ALCdevice *device;
    
    // set the memory dimentsion and the increment width when reallocating
    if (memorysize <= 0)
        globalsize = 50;
    else
        globalsize = memorysize;
    increment = globalsize;
    
    // reuse old context but keep the new value for increment
    if (isBridgeReady == AL_TRUE) {
        fprintf(stderr,"(Bridge Warning) - already initialized");
        return 0;
    }
    
    // open hardware device if present
    device = alcOpenDevice(NULL);
    
    if (device == NULL) {
        fprintf(stderr,"(Bridge Warning) - failed to open sound device, using software renderer");
        device = alcOpenDevice("Generic Software");
        if (device == NULL) {
            fprintf(stderr,"(Bridge Error) - failed to open sound software device, sound will be disabled");
            return -1;
        }
    }
    
    fprintf(stderr,"(Bridge Info) - Output device: %s", alcGetString(device, ALC_DEVICE_SPECIFIER));
    
    context = alcCreateContext(device, NULL);
    alcMakeContextCurrent(context);
    alcProcessContext(context);
    
    if (AL_NO_ERROR != alGetError()) {
        fprintf(stderr,"(Bridge Error) - Failed to create a new contex");
        alcMakeContextCurrent(NULL);
        alcDestroyContext(context);
        alcCloseDevice(device);
        return -2;
    }
    
    // allocate memory space for buffers and sources
    Buffers = (ALuint*) Malloc(sizeof(ALuint)*globalsize);
    Sources = (ALuint*) Malloc(sizeof(ALuint)*globalsize);
    
    // set the listener gain, position (on xyz axes), velocity (one value for each axe) and orientation
    // Position, Velocity and Orientation of the listener
    ALfloat ListenerPos[] = {0.0, 0.0, 0.0};
    ALfloat ListenerVel[] = {0.0, 0.0, 0.0};
    ALfloat ListenerOri[] = {0.0, 0.0, -1.0,  0.0, 1.0, 0.0};
    
    alListenerf (AL_GAIN,        1.0f       );
    alListenerfv(AL_POSITION,    ListenerPos);
    alListenerfv(AL_VELOCITY,    ListenerVel);
    alListenerfv(AL_ORIENTATION, ListenerOri);
    
    if (AL_NO_ERROR != alGetError()) {
        fprintf(stderr,"(Bridge Error) - Failed to set Listener properties");
        return -3;
    }
    isBridgeReady = AL_TRUE;
    
    alGetError();  // clear any AL errors beforehand
    return AL_TRUE;
}

void openal_close (void) {
    /*Stop all sounds, deallocate all memory and close OpenAL */
    ALCcontext *context;
    ALCdevice  *device;
    
    if (isBridgeReady == AL_FALSE) {
        fprintf(stderr,"(Bridge Warning) - OpenAL not initialized");
        return;
    }
    
    alSourceStopv	(globalsize, Sources);
    alDeleteSources (globalsize, Sources);
    alDeleteBuffers (globalsize, Buffers);
    
    free(Sources);
    free(Buffers);
    
    context = alcGetCurrentContext();
    device  = alcGetContextsDevice(context);
    
    alcMakeContextCurrent(NULL);
    alcDestroyContext(context);
    alcCloseDevice(device);
    
    isBridgeReady = AL_FALSE;
    
    fprintf(stderr,"(Bridge Info) - closed");
    
    return;
}

ALboolean openal_ready (void) {
    return isBridgeReady;
}


void helper_realloc (void) {
    /*expands allocated memory when loading more sound files than expected*/
    int oldsize = globalsize;
    globalsize += increment;
    
    fprintf(stderr,"(Bridge Info) - Realloc in process from %d to %d\n", oldsize, globalsize);
    
    Buffers = (ALuint*) Realloc(Buffers, sizeof(ALuint)*globalsize);
    Sources = (ALuint*) Realloc(Sources, sizeof(ALuint)*globalsize);
    
    return;
}


int openal_loadfile (const char *filename){
    /*Open a file, load into memory and allocate the Source buffer for playing*/
    ALfloat SourcePos[] = { 0.0, 0.0, 0.0 }; /*Position of the source sound*/
    ALfloat SourceVel[] = { 0.0, 0.0, 0.0 }; /*Velocity of the source sound*/
    ALenum format;
    ALsizei bitsize, freq;
    char *data;
    uint32_t fileformat;
    ALenum error;
    FILE *fp;
    
    if (isBridgeReady == AL_FALSE) {
        fprintf(stderr,"(Bridge Warning) - not initialized");
        return -1;
    }
    
    /*when the buffers are all used, we can expand memory to accept new files*/
    if (globalindex == globalsize)
        helper_realloc();
    
    /*detect the file format, as written in the first 4 bytes of the header*/
    fp = Fopen (filename, "rb");
    
    if (fp == NULL)
        return -2;
    
    error = fread (&fileformat, sizeof(uint32_t), 1, fp);
    fclose (fp);
    
    if (error < 0) {
        fprintf(stderr,"(Bridge Error) - File %s is too short", filename);
        return -3;
    }
    
    /*prepare the buffer to receive data*/
    alGenBuffers(1, &Buffers[globalindex]);
    
    if (AL_NO_ERROR != alGetError()) {
        fprintf(stderr,"(Bridge Error) - Failed to allocate memory for buffers");
        return -4;
    }
    
    /*prepare the source to emit sound*/
    alGenSources(1, &Sources[globalindex]);
    
    if (AL_NO_ERROR != alGetError()) {
        fprintf(stderr,"(Bridge Error) - Failed to allocate memory for sources");
        return -5;
    }
    
    switch (ENDIAN_BIG_32(fileformat)) {
        case OGG_FILE_FORMAT:
            error = load_oggvorbis (filename, &format, &data, &bitsize, &freq);
            break;
        case WAV_FILE_FORMAT:
            error = load_wavpcm (filename, &format, &data, &bitsize, &freq);
            break;
        default:
            fprintf(stderr,"(Bridge Error) - File format (%08X) not supported", ENDIAN_BIG_32(fileformat));
            return -6;
            break;
    }
    
    if (error != 0) {
        fprintf(stderr,"(Bridge Error) - error loading file %s", filename);
        free(data);
        return -7;
    }
    
    //copy pcm data in one buffer and free it
    alBufferData(Buffers[globalindex], format, data, bitsize, freq);
    free(data);
    
    if (AL_NO_ERROR != alGetError()) {
        fprintf(stderr,"(Bridge Error) - Failed to write data to buffers");
        return -8;
    }
    
    /*set source properties that it will use when it's in playback*/
    alSourcei (Sources[globalindex], AL_BUFFER,   Buffers[globalindex]  );
    alSourcef (Sources[globalindex], AL_PITCH,    1.0f                  );
    alSourcef (Sources[globalindex], AL_GAIN,     1.0f                  );
    alSourcefv(Sources[globalindex], AL_POSITION, SourcePos             );
    alSourcefv(Sources[globalindex], AL_VELOCITY, SourceVel             );
    alSourcei (Sources[globalindex], AL_LOOPING,  0                     );
    
    if (AL_NO_ERROR != alGetError()) {
        fprintf(stderr,"(Bridge Error) - Failed to set Source properties");
        return -9;
    }
    
    alGetError();  /* clear any AL errors beforehand */
    
    /*returns the index of the source you just loaded, increments it and exits*/
    return globalindex++;
}


void openal_playsound (uint32_t index) {
    openal_playsound_loop (index, 0);
}


void openal_pausesound (uint32_t index) {
    if (isBridgeReady == AL_TRUE && index < globalsize)
        alSourcePause(Sources[index]);
}


void openal_stopsound (uint32_t index) {
    openal_stopsound_free(index, 0);
}


void openal_freesound (uint32_t index){
    if (isBridgeReady == AL_TRUE && index < globalsize)
        alSourceStop(Sources[index]);
    // STUB
}


void openal_playsound_loop (unsigned int index, char loops) {
    if (isBridgeReady == AL_TRUE && index < globalsize) {
        alSourcePlay(Sources[index]);
        if (loops != 0)
            openal_toggleloop(index);
    }
}

void openal_stopsound_free (unsigned int index, char freesource) {
    if (isBridgeReady == AL_TRUE && index < globalsize) {
        alSourceStop(Sources[index]);
        if (freesource != 0)
            openal_freesound(index);
    }
}

void openal_toggleloop (uint32_t index) {
    ALint loop;
    
    if (isBridgeReady == AL_TRUE && index < globalsize) {
        alGetSourcei (Sources[index], AL_LOOPING, &loop);
        alSourcei (Sources[index], AL_LOOPING, !((uint8_t) loop) & 0x00000001);
    }
    
}


void openal_setvolume (uint32_t index, float gain) {
    if (isBridgeReady == AL_TRUE && index < globalsize)
        alSourcef (Sources[index], AL_GAIN, gain);
}


void openal_setglobalvolume (float gain) {
    if (isBridgeReady == AL_TRUE)
        alListenerf (AL_GAIN, gain);
}

void openal_togglemute () {
    ALfloat gain;
    
    if (isBridgeReady == AL_TRUE) {
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
    
    if (isBridgeReady == AL_TRUE && index < globalsize) {
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

void openal_fadein (uint32_t index, uint16_t quantity) {
    openal_fade(index, quantity, AL_FADE_IN);
}

void openal_fadeout (uint32_t index, uint16_t quantity) {
    openal_fade(index, quantity, AL_FADE_OUT);
}


void openal_setposition (uint32_t index, float x, float y, float z) {
    if (isBridgeReady == AL_TRUE && index < globalsize)
        alSource3f(Sources[index], AL_POSITION, x, y, z);;
}
