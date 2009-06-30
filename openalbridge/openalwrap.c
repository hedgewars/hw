/*
 * OpenAL Bridge - a simple portable library for OpenAL interface
 * Copyright (c) 2009 Vittorio Giovara <vittorio.giovara@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

#include "globals.h"
#include "wrappers.h"
#include "alc.h"
#include "loaders.h"
#include "endianness.h"

#ifdef __CPLUSPLUS
extern "C" {
#endif 
	
	/*Sources are points emitting sound*/
	ALuint *Sources;
	/*Buffers hold sound data*/
	ALuint *Buffers;
	/*index for Sources and Buffers*/
	ALuint globalindex, globalsize, increment;
	/*Position of the source sound*/
	ALfloat SourcePos[] = { 0.0, 0.0, 0.0 };
	/*Velocity of the source sound*/
	ALfloat SourceVel[] = { 0.0, 0.0, 0.0 };
	
	ALint openalReady = AL_FALSE;
	
	ALint openal_close(void) {
		/*Stop all sounds, deallocate all memory and close OpenAL */
		ALCcontext *context;
		ALCdevice  *device;
		
		if(openalReady == AL_FALSE)
		{
			fprintf(stderr, "ERROR: OpenAL not initialized\n");
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
	
	ALint openal_ready(void) {
		return openalReady;
	}
	
	ALint openal_init(uint32_t memorysize) {	
		/*Initialize an OpenAL contex and allocate memory space for data and buffers*/
		ALCcontext *context;
		ALCdevice *device;
		const ALCchar *default_device;

		/*Position of the listener*/
		ALfloat ListenerPos[] = { 0.0, 0.0, 0.0 };
		/*Velocity of the listener*/
		ALfloat ListenerVel[] = { 0.0, 0.0, 0.0 };
		/*Orientation of the listener. (first 3 elements are "at", second 3 are "up")*/
		ALfloat ListenerOri[] = { 0.0, 0.0, -1.0,  0.0, 1.0, 0.0 };

		if(openalReady == AL_TRUE)
		{
			fprintf(stderr, "ERROR: OpenAL already initialized\n");
			return AL_FALSE;
		}

		default_device = alcGetString(NULL, ALC_DEFAULT_DEVICE_SPECIFIER);
		fprintf(stderr, "Using default device: %s\n", default_device);
		
		if ((device = alcOpenDevice(default_device)) == NULL) {
			fprintf(stderr, "ERROR: Failed to open sound device\n");
			return AL_FALSE;
		}
		
		context = alcCreateContext(device, NULL);
		alcMakeContextCurrent(context);
		alcProcessContext(context);
		
		if (AlGetError("ERROR %d: Creating a new contex\n") != AL_TRUE)
			return AL_FALSE;
		
		/*allocate memory space for buffers and sources*/
		globalsize = memorysize;
		increment = memorysize;
		Buffers = (ALuint*) Malloc(sizeof(ALuint)*globalsize);
		Sources = (ALuint*) Malloc(sizeof(ALuint)*globalsize);
		
		/*set the listener gain, position (on xyz axes), velocity (one value for each axe) and orientation*/
		alListenerf (AL_GAIN,		 1.0f		);
		alListenerfv(AL_POSITION,    ListenerPos);
		alListenerfv(AL_VELOCITY,    ListenerVel);
		alListenerfv(AL_ORIENTATION, ListenerOri);
		
		if (AlGetError("ERROR %d: Setting Listener properties\n") != AL_TRUE)
			return AL_FALSE;
		
		openalReady = AL_TRUE;

		alGetError();  /* clear any AL errors beforehand */
		return AL_TRUE;
	}
	
	
	uint8_t helper_realloc (void) {
		/*expands allocated memory when loading more sound files than expected*/
		globalsize += increment;
#ifdef DEBUG
		fprintf(stderr, "OpenAL: Realloc in process %d\n", globalsize);
#endif
		Buffers = (ALuint*) Realloc(Buffers, sizeof(ALuint)*globalsize);
		Sources = (ALuint*) Realloc(Sources, sizeof(ALuint)*globalsize);
		
		return 0;
	}
	
	
	int openal_loadfile (const char *filename){
		/*Open a file, load into memory and allocate the Source buffer for playing*/
		ALenum format;
		ALsizei bitsize;
		ALsizei freq;
		char *data;
		uint32_t fileformat;
		ALenum error;
		FILE *fp;
		
		if(openalReady == AL_FALSE)
		{
			fprintf(stderr, "ERROR: OpenAL not initialized\n");
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
			fprintf(stderr, "ERROR: file %s is too short \n", filename);
			return -2;
		}
		
		/*prepare the buffer to receive data*/
		alGenBuffers(1, &Buffers[globalindex]);
		
		if (AlGetError("ERROR %d: Allocating memory for buffers\n") != AL_TRUE)
			return -3;
		
		/*prepare the source to emit sound*/
		alGenSources(1, &Sources[globalindex]);
		
		if (AlGetError("ERROR %d: Allocating memory for sources\n") != AL_TRUE)
			return -4;
				
		
		if (fileformat == 0x5367674F) /*check if ogg*/
			error = load_OggVorbis (filename, &format, &data, &bitsize, &freq);
		else {
			if (fileformat == 0x46464952) /*check if wav*/
				error = load_WavPcm (filename, &format, &data, &bitsize, &freq);
			else {
				fprintf(stderr, "ERROR: File format (%08X) not supported!\n", invert_endianness(fileformat));
				return -5;
			}
		}
		
		/*copy pcm data in one buffer*/
		alBufferData(Buffers[globalindex], format, data, bitsize, freq);
		free(data);		/*deallocate data to save memory*/
		
		if (AlGetError("ERROR %d: Writing data to buffer\n") != AL_TRUE)
			return -6;
			
		/*set source properties that it will use when it's in playback*/
		alSourcei (Sources[globalindex], AL_BUFFER,   Buffers[globalindex]  );
		alSourcef (Sources[globalindex], AL_PITCH,    1.0f					);
		alSourcef (Sources[globalindex], AL_GAIN,     1.0f					);
		alSourcefv(Sources[globalindex], AL_POSITION, SourcePos				);
		alSourcefv(Sources[globalindex], AL_VELOCITY, SourceVel				);
		alSourcei (Sources[globalindex], AL_LOOPING,  0						);
		
		if (AlGetError("ERROR %d: Setting source properties\n") != AL_TRUE)
			return -7;
		
		alGetError();  /* clear any AL errors beforehand */
		
		/*returns the index of the source you just loaded, increments it and exits*/
		return globalindex++;
	}
	
	
	ALint openal_toggleloop (uint32_t index){
		/*Set or unset looping mode*/
		ALint loop;
		
		if(openalReady == AL_FALSE)
		{
			fprintf(stderr, "ERROR: OpenAL not initialized\n");
			return AL_FALSE;
		}

		if (index >= globalsize) {
			fprintf(stderr, "ERROR: index out of bounds (got %d, max %d)\n", index, globalindex);
			return AL_FALSE;
		}
		
		alGetSourcei (Sources[index], AL_LOOPING, &loop);
		alSourcei (Sources[index], AL_LOOPING, !((uint8_t) loop) & 0x00000001);
		if (AlGetError("ERROR %d: Getting or setting loop property\n") != AL_TRUE)
			return AL_FALSE;
		
		alGetError();  /* clear any AL errors beforehand */

		return AL_TRUE;
	}
	
	
	ALint openal_setvolume (uint32_t index, uint8_t percentage) {
		if(openalReady == AL_FALSE)
		{
			fprintf(stderr, "ERROR: OpenAL not initialized\n");
			return AL_FALSE;
		}

		/*Set volume for sound number index*/
		if (index >= globalindex) {
			fprintf(stderr, "ERROR: index out of bounds (got %d, max %d)\n", index, globalindex);
			return AL_FALSE;
		}
		
		if (percentage > 100)
			percentage = 100;
		alSourcef (Sources[index], AL_GAIN, (float) percentage/100.0f);
		if (AlGetError("ERROR %d: Setting volume for last sound\n") != AL_TRUE)
			return AL_FALSE;
		
		alGetError();  /* clear any AL errors beforehand */

		return AL_TRUE;
	}
	
	
	ALint openal_setglobalvolume (uint8_t percentage) {
		if(openalReady == AL_FALSE)
		{
			fprintf(stderr, "ERROR: OpenAL not initialized\n");
			return AL_FALSE;
		}

		/*Set volume for all sounds*/		
		if (percentage > 100)
			percentage = 100;
		alListenerf (AL_GAIN, (float) percentage/100.0f);
		if (AlGetError("ERROR %d: Setting global volume\n") != AL_TRUE)
			return AL_FALSE;
		
		alGetError();  /* clear any AL errors beforehand */

		return AL_TRUE;
	}
	
	
	ALint openal_togglemute () {
		/*Mute or unmute sound*/
		ALfloat mute;
		
		if(openalReady == AL_FALSE)
		{
			fprintf(stderr, "ERROR: OpenAL not initialized\n");
			return AL_FALSE;
		}

		alGetListenerf (AL_GAIN, &mute);
		if (mute > 0) 
			mute = 0;
		else
			mute = 1.0;
		alListenerf (AL_GAIN, mute);
		if (AlGetError("ERROR %d: Setting mute property\n") != AL_TRUE)
			return AL_FALSE;
		
		alGetError();  /* clear any AL errors beforehand */

		return AL_TRUE;
	}
	
	
	ALint openal_fade(uint32_t index, uint16_t quantity, uint8_t direction) {
		/*Fade in or out by calling a helper thread*/
#ifndef _WIN32
		pthread_t thread;
#else
		HANDLE Thread;
		DWORD threadID;
#endif
		fade_t *fade;
		
		if(openalReady == AL_FALSE)
		{
			fprintf(stderr, "ERROR: OpenAL not initialized\n");
			return AL_FALSE;
		}

		fade = (fade_t*) Malloc(sizeof(fade_t));
		fade->index = index;
		fade->quantity = quantity;
		
		if (index >= globalindex) {
			fprintf(stderr, "ERROR: index out of bounds (got %d, max %d)\n", index, globalindex);
			return AL_FALSE;
		}
		
		if (direction == FADE_IN)
#ifndef _WIN32
			pthread_create(&thread, NULL, helper_fadein, (void*) fade);
#else
			Thread = _beginthread(&helper_fadein, 0, (void*) fade);
#endif
		else {
			if (direction == FADE_OUT)
#ifndef _WIN32
				pthread_create(&thread, NULL, helper_fadeout, (void*) fade);
#else
				Thread = _beginthread(&helper_fadeout, 0, (void*) fade);
#endif	
			else {
				fprintf(stderr, "ERROR: unknown direction for fade (%d)\n", direction);
				free(fade);
				return AL_FALSE;
			}
		}
		
#ifndef _WIN32
		pthread_detach(thread);
#endif
		
		alGetError();  /* clear any AL errors beforehand */
		
		return AL_TRUE;
	}

	
	ALint openal_fadeout(uint32_t index, uint16_t quantity) {
		/*wrapper for fadeout*/
		return openal_fade(index, quantity, FADE_OUT);
	}
		
		
	ALint openal_fadein(uint32_t index, uint16_t quantity) {
		/*wrapper for fadein*/
		return openal_fade(index, quantity, FADE_IN);
	}

	
	ALint openal_playsound(uint32_t index){
		if(openalReady == AL_FALSE)
		{
			fprintf(stderr, "ERROR: OpenAL not initialized\n");
			return AL_FALSE;
		}

		/*Play sound number index*/
		if (index >= globalindex) {
			fprintf(stderr, "ERROR: index out of bounds (got %d, max %d)\n", index, globalindex);
			return AL_FALSE;
		}
		alSourcePlay(Sources[index]);
		if (AlGetError("ERROR %d: Playing last sound\n") != AL_TRUE)
			return AL_FALSE;
		
		alGetError();  /* clear any AL errors beforehand */

		return AL_TRUE;
	}
	
	
	ALint openal_pausesound(uint32_t index){
		if(openalReady == AL_FALSE)
		{
			fprintf(stderr, "ERROR: OpenAL not initialized\n");
			return AL_FALSE;
		}

		/*Pause sound number index*/
		if (index >= globalindex) {
			fprintf(stderr, "ERROR: index out of bounds (got %d, max %d)\n", index, globalindex);
			return AL_FALSE;
		}
		alSourcePause(Sources[index]);
		if (AlGetError("ERROR %d: Pausing last sound\n") != AL_TRUE)
			return AL_FALSE;
		
		return AL_TRUE;
	}
	
	
	ALint openal_stopsound(uint32_t index){
		if(openalReady == AL_FALSE)
		{
			fprintf(stderr, "ERROR: OpenAL not initialized\n");
			return AL_FALSE;
		}

		/*Stop sound number index*/
		if (index >= globalindex) {
			fprintf(stderr, "ERROR: index out of bounds (got %d, max %d)\n", index, globalindex);
			return AL_FALSE;
		}
		alSourceStop(Sources[index]);
		if (AlGetError("ERROR %d: Stopping last sound\n") != AL_TRUE)
			return AL_FALSE;
		
		alGetError();  /* clear any AL errors beforehand */

		return AL_TRUE;
	}
	
#ifdef __CPLUSPLUS
}
#endif
