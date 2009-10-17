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


#ifdef __CPLUSPLUS
extern "C" {
#endif 
        
        /*Sources are points emitting sound*/
        ALuint *Sources;
        /*Buffers hold sound data*/
        ALuint *Buffers;
        /*index for Sources and Buffers*/
        ALuint globalindex, globalsize, increment;
        
        ALboolean openalReady = AL_FALSE;
        
        ALboolean openal_close (void) {
                /*Stop all sounds, deallocate all memory and close OpenAL */
                ALCcontext *context;
                ALCdevice  *device;
                
                if (openalReady == AL_FALSE) {
                        errno = EPERM;
                        err_ret("(%s) WARN - OpenAL not initialized", prog);
                        return AL_FALSE;
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
                
                openalReady = AL_FALSE;
                
                return AL_TRUE;
        }
        
        ALboolean openal_ready(void) {
                return openalReady;
        }
        
        ALboolean openal_init(char* programname, ALboolean usehardware, uint32_t memorysize) {	
                /*Initialize an OpenAL contex and allocate memory space for data and buffers*/
                ALCcontext *context;
                ALCdevice *device;
                const ALCchar *default_device;
                
                prog = programname;
                
                /*Position of the listener*/
                ALfloat ListenerPos[] = { 0.0, 0.0, 0.0 };
                /*Velocity of the listener*/
                ALfloat ListenerVel[] = { 0.0, 0.0, 0.0 };
                /*Orientation of the listener. (first 3 elements are "at", second 3 are "up")*/
                ALfloat ListenerOri[] = { 0.0, 0.0, -1.0,  0.0, 1.0, 0.0 };
                
                if (openalReady == AL_TRUE) {
                        errno = EPERM;                
                        err_ret("(%s) WARN - OpenAL already initialized", prog);
                        return AL_FALSE;
                }
                
                if (usehardware == AL_TRUE)
                        device = alcOpenDevice(NULL);
                else
                        device = alcOpenDevice("Generic Software");
                
                if (device == NULL) {
                        errno = ENODEV;                
                        err_ret("(%s) WARN - Failed to open sound device", prog);
                        return AL_FALSE;
                }
                err_msg("(%s) INFO - Output device: %s", prog, alcGetString(device, ALC_DEVICE_SPECIFIER));
                
                context = alcCreateContext(device, NULL);
                alcMakeContextCurrent(context);
                alcProcessContext(context);
                
                if (AlGetError("(%s) WARN - Failed to create a new contex") != AL_TRUE)
                        return AL_FALSE;
                
                /*allocate memory space for buffers and sources*/
                if (memorysize == 0)
                        globalsize = 50;
                else
                        globalsize = memorysize;
                increment  = globalsize;
                
                Buffers = (ALuint*) Malloc(sizeof(ALuint)*globalsize);
                Sources = (ALuint*) Malloc(sizeof(ALuint)*globalsize);
                
                /*set the listener gain, position (on xyz axes), velocity (one value for each axe) and orientation*/
                alListenerf (AL_GAIN,        1.0f       );
                alListenerfv(AL_POSITION,    ListenerPos);
                alListenerfv(AL_VELOCITY,    ListenerVel);
                alListenerfv(AL_ORIENTATION, ListenerOri);
                
                if (AlGetError("(%s) WARN - Failed to set Listener properties") != AL_TRUE)
                        return AL_FALSE;
                
                openalReady = AL_TRUE;
                
                alGetError();  /* clear any AL errors beforehand */
                return AL_TRUE;
        }
        
        
        ALboolean helper_realloc (void) {
                /*expands allocated memory when loading more sound files than expected*/
                int oldsize = globalsize;
                globalsize += increment;
                
#ifdef DEBUG
                err_msg("(%s) INFO - Realloc in process from %d to %d\n", prog, oldsize, globalsize);
#endif
                
                Buffers = (ALuint*) Realloc(Buffers, sizeof(ALuint)*globalsize);
                Sources = (ALuint*) Realloc(Sources, sizeof(ALuint)*globalsize);
                
                return AL_TRUE;
        }
        
        
        ALint openal_loadfile (const char *filename){
                /*Open a file, load into memory and allocate the Source buffer for playing*/
                ALfloat SourcePos[] = { 0.0, 0.0, 0.0 }; /*Position of the source sound*/
                ALfloat SourceVel[] = { 0.0, 0.0, 0.0 }; /*Velocity of the source sound*/
                ALenum format;
                ALsizei bitsize, freq;
                char *data;
                uint32_t fileformat;
                ALenum error;
                FILE *fp;
                
                if (openalReady == AL_FALSE) {
                        errno = EPERM;                
                        err_ret("(%s) WARN - OpenAL not initialized", prog);
                        return AL_FALSE;
                }
                
                /*when the buffers are all used, we can expand memory to accept new files*/
                if (globalindex == globalsize)
                        helper_realloc();
                
                /*detect the file format, as written in the first 4 bytes of the header*/
                fp = Fopen (filename, "rb");
                
                if (fp == NULL)
                        return -1;
                
                error = fread (&fileformat, sizeof(uint32_t), 1, fp);
                fclose (fp);
                
                if (error < 0) {
                        errno = EIO;
                        err_ret("(%s) ERROR - File %s is too short", prog, filename);
                        return -2;
                }
                
                /*prepare the buffer to receive data*/
                alGenBuffers(1, &Buffers[globalindex]);
                
                if (AlGetError("(%s) ERROR - Failed to allocate memory for buffers") != AL_TRUE)
                        return -3;
                
                /*prepare the source to emit sound*/
                alGenSources(1, &Sources[globalindex]);
                
                if (AlGetError("(%s) ERROR - Failed to allocate memory for sources") != AL_TRUE)
                        return -4;
                
                
                switch (ENDIAN_BIG_32(fileformat)) {
                        case OGG_FILE_FORMAT:
                                error = load_oggvorbis (filename, &format, &data, &bitsize, &freq);
                                break;
                        case WAV_FILE_FORMAT:
                                error = load_wavpcm (filename, &format, &data, &bitsize, &freq);
                                break;
                        default:
                                errno = EINVAL;
                                err_ret ("(%s) ERROR - File format (%08X) not supported", prog, ENDIAN_BIG_32(fileformat));
                                return -5;
                                break;
                }
                
                
                /*copy pcm data in one buffer*/
                alBufferData(Buffers[globalindex], format, data, bitsize, freq);
                free(data);		/*deallocate data to save memory*/
                
                if (AlGetError("(%s) ERROR - Failed to write data to buffers") != AL_TRUE)
                        return -6;
                
                /*set source properties that it will use when it's in playback*/
                alSourcei (Sources[globalindex], AL_BUFFER,   Buffers[globalindex]  );
                alSourcef (Sources[globalindex], AL_PITCH,    1.0f                  );
                alSourcef (Sources[globalindex], AL_GAIN,     1.0f                  );
                alSourcefv(Sources[globalindex], AL_POSITION, SourcePos             );
                alSourcefv(Sources[globalindex], AL_VELOCITY, SourceVel             );
                alSourcei (Sources[globalindex], AL_LOOPING,  0                     );
                
                if (AlGetError("(%s) ERROR - Failed to set Source properties") != AL_TRUE)
                        return -7;
                
                alGetError();  /* clear any AL errors beforehand */
                
                /*returns the index of the source you just loaded, increments it and exits*/
                return globalindex++;
        }
        
        
        ALboolean openal_toggleloop (uint32_t index){
                /*Set or unset looping mode*/
                ALint loop;
                
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
                
                alGetSourcei (Sources[index], AL_LOOPING, &loop);
                alSourcei (Sources[index], AL_LOOPING, !((uint8_t) loop) & 0x00000001);
                if (AlGetError("(%s) ERROR - Failed to get or set loop property") != AL_TRUE)
                        return AL_FALSE;
                
                alGetError();  /* clear any AL errors beforehand */
                
                return AL_TRUE;
        }
        
        
        ALboolean openal_setvolume (uint32_t index, uint8_t percentage) {
                if (openalReady == AL_FALSE) {
                        errno = EPERM;                
                        err_ret("(%s) WARN - OpenAL not initialized", prog);
                        return AL_FALSE;
                }
                
                /*Set volume for sound number index*/
                if (index >= globalsize) {
                        errno = EINVAL;
                        err_ret("(%s) ERROR - Index out of bounds (got %d, max %d)", prog, index, globalindex);
                        return AL_FALSE;
                }
                
                if (percentage > 100)
                        percentage = 100;
                alSourcef (Sources[index], AL_GAIN, (float) percentage/100.0f);
                if (AlGetError2("(%s) ERROR -  Failed to set volume for sound %d\n", index) != AL_TRUE)
                        return AL_FALSE;
                
                alGetError();  /* clear any AL errors beforehand */
                
                return AL_TRUE;
        }
        
        
        ALboolean openal_setglobalvolume (uint8_t percentage) {
                if (openalReady == AL_FALSE) {
                        errno = EPERM;                
                        err_ret("(%s) WARN - OpenAL not initialized", prog);
                        return AL_FALSE;
                }
                
                /*Set volume for all sounds*/		
                if (percentage > 100)
                        percentage = 100;
                alListenerf (AL_GAIN, (float) percentage/100.0f);
                if (AlGetError("(%s) ERROR -  Failed to set global volume") != AL_TRUE)
                        return AL_FALSE;
                
                alGetError();  /* clear any AL errors beforehand */
                
                return AL_TRUE;
        }
        
        
        ALboolean openal_togglemute () {
                /*Mute or unmute sound*/
                ALfloat mute;
                
                if (openalReady == AL_FALSE) {
                        errno = EPERM;                
                        err_ret("(%s) WARN - OpenAL not initialized", prog);
                        return AL_FALSE;
                }
                
                alGetListenerf (AL_GAIN, &mute);
                if (mute > 0) 
                        mute = 0;
                else
                        mute = 1.0;
                alListenerf (AL_GAIN, mute);
                if (AlGetError("(%s) ERROR -  Failed to set mute property") != AL_TRUE)
                        return AL_FALSE;
                
                alGetError();  /* clear any AL errors beforehand */
                
                return AL_TRUE;
        }
        
        
        ALboolean openal_fade (uint32_t index, uint16_t quantity, ALboolean direction) {
                /*Fade in or out by calling a helper thread*/
#ifndef _WIN32
                pthread_t thread;
#else
                HANDLE Thread;
                DWORD threadID;
#endif
                fade_t *fade;
                
                if (openalReady == AL_FALSE) {
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
                
                alGetError();  /* clear any AL errors beforehand */
                
                return AL_TRUE;
        }
        
        
        ALboolean openal_fadeout (uint32_t index, uint16_t quantity) {
                /*wrapper for fadeout*/
                return openal_fade(index, quantity, FADE_OUT);
        }
        
        
        ALboolean openal_fadein (uint32_t index, uint16_t quantity) {
                /*wrapper for fadein*/
                return openal_fade(index, quantity, FADE_IN);
        }
        
        
        ALboolean openal_setposition (uint32_t index, float x, float y, float z) {
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
        }
        
        
        ALboolean openal_playsound (uint32_t index){
                if (openalReady == AL_FALSE) {
                        errno = EPERM;                
                        err_ret("(%s) WARN - OpenAL not initialized", prog);
                        return AL_FALSE;
                }
                
                /*Play sound number index*/
                if (index >= globalsize) {
                        errno = EINVAL;
                        err_ret("(%s) ERROR - Index out of bounds (got %d, max %d)", prog, index, globalindex);
                        return AL_FALSE;
                }
                alSourcePlay(Sources[index]);
                if (AlGetError2("(%s) ERROR - Failed to play sound %d)", index) != AL_TRUE)
                        return AL_FALSE;
                
                alGetError();  /* clear any AL errors beforehand */
                
                return AL_TRUE;
        }
        
        
        ALboolean openal_pausesound(uint32_t index){
                if (openalReady == AL_FALSE) {
                        errno = EPERM;                
                        err_ret("(%s) WARN - OpenAL not initialized", prog);
                        return AL_FALSE;
                }
                
                /*Pause sound number index*/
                if (index >= globalsize) {
                        errno = EINVAL;
                        err_ret("(%s) ERROR - Index out of bounds (got %d, max %d)", prog, index, globalindex);
                        return AL_FALSE;
                }
                alSourcePause(Sources[index]);
                if (AlGetError2("(%s) ERROR - Failed to pause sound %d)", index) != AL_TRUE)
                        return AL_FALSE;
                
                return AL_TRUE;
        }
        
        
        ALboolean openal_stopsound(uint32_t index){
                if (openalReady == AL_FALSE) {
                        errno = EPERM;                
                        err_ret("(%s) WARN - OpenAL not initialized", prog);
                        return AL_FALSE;
                }
                
                /*Stop sound number index*/
                if (index >= globalsize) {
                        errno = EINVAL;
                        err_ret("(%s) ERROR - Index out of bounds (got %d, max %d)", prog, index, globalindex);
                        return AL_FALSE;
                }
                alSourceStop(Sources[index]);
                if (AlGetError2("(%s) ERROR - Failed to stop sound %d)", index) != AL_TRUE)
                        return AL_FALSE;
                
                alGetError();  /* clear any AL errors beforehand */
                
                return AL_TRUE;
        }
        
#ifdef __CPLUSPLUS
}
#endif
