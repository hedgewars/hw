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

#include "openalwrap.h"

#ifdef __CPLUSPLUS
extern "C" {
#endif 
	
	// Sources are points emitting sound.
	ALuint *Sources;
	// Buffers hold sound data.
	ALuint *Buffers;
	//index for Sources and Buffers
	ALuint globalindex, globalsize;
	// Position of the source sound.
	ALfloat **SourcePos;
	// Velocity of the source sound.
	ALfloat **SourceVel;
	
	
	ALint openal_close(void) {
		/* This function stops all the sounds, deallocates all memory and closes OpenAL */
		int i;
		ALCcontext *context;
		ALCdevice  *device;
		
		alSourceStopv	(globalsize, Sources);
		alDeleteSources (globalsize, Sources);
		alDeleteBuffers (globalsize, Buffers);
		
		for (i = 0; i < globalsize; i++) {
			free(SourcePos[i]);
			free(SourceVel[i]);
		}
		free(SourcePos);
		free(SourceVel);
		free(Sources);
		free(Buffers);
		
		context = alcGetCurrentContext();
		device  = alcGetContextsDevice(context);
		
		alcMakeContextCurrent(NULL);
		alcDestroyContext(context);
		alcCloseDevice(device);
		return AL_TRUE;
	}
	
	
	ALint openal_init(int memorysize) {	
		/* This function initializes an OpenAL contex, allocates memory space for data and prepares OpenAL buffers*/
		ALCcontext *context;
		ALCdevice *device;

		const ALCchar *default_device;
		// Position of the listener.
		ALfloat ListenerPos[] = { 0.0, 0.0, 0.0 };
		// Velocity of the listener.
		ALfloat ListenerVel[] = { 0.0, 0.0, 0.0 };
		// Orientation of the listener. (first 3 elements are "at", second 3 are "up")
		ALfloat ListenerOri[] = { 0.0, 0.0, -1.0,  0.0, 1.0, 0.0 };
		
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
		
		//allocate memory space for buffers and sources
		globalsize = memorysize;
		Buffers   = (ALuint*)   Malloc(sizeof(ALuint  )*globalsize);
		Sources   = (ALuint*)   Malloc(sizeof(ALuint  )*globalsize);
		SourcePos = (ALfloat**) Malloc(sizeof(ALfloat*)*globalsize);
		SourceVel = (ALfloat**) Malloc(sizeof(ALfloat*)*globalsize);
		
		//set the listener gain, position (on xyz axes), velocity (one value for each axe) and orientation
		alListenerf (AL_GAIN,		 1.0f		);
		alListenerfv(AL_POSITION,    ListenerPos);
		alListenerfv(AL_VELOCITY,    ListenerVel);
		alListenerfv(AL_ORIENTATION, ListenerOri);
		
		if (AlGetError("ERROR %d: Setting Listener properties\n") != AL_TRUE)
			return AL_FALSE;
		
		alGetError();  /* clear any AL errors beforehand */
		return AL_TRUE;
	}
	
	
	int openal_loadfile (const char *filename){
		/* This function opens a file, loads into memory and allocates the Source buffer for playing*/
		ALenum format;
		ALsizei bitsize;
		ALsizei freq;
		uint8_t *data;
		uint32_t fileformat;
		int i, error;
		FILE *fp;
		
		
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
		
		//prepare the buffers to receive data
		alGenBuffers(1, &Buffers[globalindex]);
		
		if (AlGetError("ERROR %d: Allocating memory for buffers\n") != AL_TRUE)
			return -3;
		
		//prepare the sources to emit sound
		alGenSources(1, &Sources[globalindex]);
		
		if (AlGetError("ERROR %d: Allocating memory for sources\n") != AL_TRUE)
			return -4;
				
		
		if (fileformat == 0x5367674F) //check if ogg
			error = load_OggVorbis (filename, &format, &data, &bitsize, &freq);
		else {
			if (fileformat == 0x46464952) //check if wav
				error = load_WavPcm (filename, &format, &data, &bitsize, &freq);
			else {
				fprintf(stderr, "ERROR: File format (%08X) not supported!\n", invert_endianness(fileformat));
				return -5;
			}
		}
		
		//copy pcm data in one buffer
		alBufferData(Buffers[globalindex], format, data, bitsize, freq);
		free(data);		//deallocate data to save memory
		
		if (AlGetError("ERROR %d: Writing data to buffer\n") != AL_TRUE)
			return -6;
		
		//memory allocation for source position and velocity
		SourcePos[globalindex] = (ALfloat*) Malloc(sizeof(ALfloat)*3);
		SourceVel[globalindex] = (ALfloat*) Malloc(sizeof(ALfloat)*3);
		
		if (SourcePos[globalindex] == NULL || SourceVel[globalindex] == NULL)
			return -7;
			
		//source properties that it will use when it's in playback
		for (i = 0; i < 3; i++) {
			SourcePos[globalindex][i] = 0.0;
			SourceVel[globalindex][i] = 0.1;
		}	
		alSourcei (Sources[globalindex], AL_BUFFER,   Buffers[globalindex]  );
		alSourcef (Sources[globalindex], AL_PITCH,    1.0f					);
		alSourcef (Sources[globalindex], AL_GAIN,     1.0f					);
		alSourcefv(Sources[globalindex], AL_POSITION, SourcePos[globalindex]);
		alSourcefv(Sources[globalindex], AL_VELOCITY, SourceVel[globalindex]);
		alSourcei (Sources[globalindex], AL_LOOPING,  0						);
		
		if (AlGetError("ERROR %d: Setting source properties\n") != AL_TRUE)
			return -8;
		
		alGetError();  /* clear any AL errors beforehand */
		
		//returns the index of the source you just loaded, increments it and exits
		return globalindex++;
	}
	
	
	ALint openal_toggleloop (int index){
		/*Set or unset looping mode*/
		ALint loop;
		
		if (index >= globalsize) {
			fprintf(stderr, "ERROR: index out of bounds (got %d, max %d)", index, globalindex);
			return AL_FALSE;
		}
		
		alGetSourcei (Sources[index], AL_LOOPING, &loop);
		alSourcei (Sources[index], AL_LOOPING, !((uint8_t) loop) & 0x00000001);
		if (AlGetError("ERROR %d: Getting or setting loop property\n") != AL_TRUE)
			return AL_FALSE;
		
		alGetError();  /* clear any AL errors beforehand */

		return AL_TRUE;
	}
	
	
	ALint openal_setvolume (int index, unsigned char percentage) {
		/*Set volume for sound number index*/
		if (index >= globalindex) {
			fprintf(stderr, "ERROR: index out of bounds (got %d, max %d)", index, globalindex);
			return AL_FALSE;
		}
		
		if (percentage > 100)
			percentage = 100;
		alSourcef (Sources[index], AL_GAIN, (ALfloat) percentage/100.0f);
		if (AlGetError("ERROR %d: Setting volume for last sound\n") != AL_TRUE)
			return AL_FALSE;
		
		alGetError();  /* clear any AL errors beforehand */

		return AL_TRUE;
	}
	
	
	ALint openal_setglobalvolume (unsigned char percentage) {
		/*Set volume for all sounds*/		
		if (percentage > 100)
			percentage = 100;
		alListenerf (AL_GAIN, (ALfloat) percentage/100.0f);
		if (AlGetError("ERROR %d: Setting global volume\n") != AL_TRUE)
			return AL_FALSE;
		
		alGetError();  /* clear any AL errors beforehand */

		return AL_TRUE;
	}
	
	
	ALint openal_togglemute () {
		/*Mute or unmute sound*/
		ALfloat mute;
		
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
	

	ALint openal_fadeout(int index, unsigned int quantity) {
#ifndef _WIN32
		pthread_t thread;
#else
		HANDLE Thread;
		DWORD threadID;
#endif
		fade_t *fade; 
		
		if (index >= globalindex) {
			fprintf(stderr, "ERROR: index out of bounds (got %d, max %d)", index, globalindex);
			return AL_FALSE;
		}
		
		fade = (fade_t*) Malloc(sizeof(fade_t));
		fade->index = index;
		fade->quantity = quantity;
		
#ifndef _WIN32
		pthread_create(&thread, NULL, helper_fadeout, (void*) fade);
		pthread_detach(thread);
#else
		Thread = _beginthread(&helper_fadeout, 0, (void*) fade);
#endif
		
		alGetError();  /* clear any AL errors beforehand */

		return AL_TRUE;
	}
		
		
	ALint openal_fadein(int index, unsigned int quantity) {
#ifndef _WIN32
		pthread_t thread;
#else
		HANDLE Thread;
		DWORD threadID;
#endif
		fade_t *fade;
		
		fade = (fade_t*) Malloc(sizeof(fade_t));
		fade->index = index;
		fade->quantity = quantity;
		
		if (index >= globalindex) {
			fprintf(stderr, "ERROR: index out of bounds (got %d, max %d)", index, globalindex);
			return AL_FALSE;
		}
				
#ifndef _WIN32
		pthread_create(&thread, NULL, helper_fadein, (void*) fade);
		pthread_detach(thread);
#else
		Thread = _beginthread(&helper_fadein, 0, (void*) fade);
#endif
		
		alGetError();  /* clear any AL errors beforehand */

		return AL_TRUE;
	}
	
	
	ALint openal_playsound(int index){
		/*Play sound number index*/
		if (index >= globalindex) {
			fprintf(stderr, "ERROR: index out of bounds (got %d, max %d)", index, globalindex);
			return AL_FALSE;
		}
		alSourcePlay(Sources[index]);
		if (AlGetError("ERROR %d: Playing last sound\n") != AL_TRUE)
			return AL_FALSE;
		
		alGetError();  /* clear any AL errors beforehand */

		return AL_TRUE;
	}
	
	
	ALint openal_pausesound(int index){
		/*Pause sound number index*/
		if (index >= globalindex) {
			fprintf(stderr, "ERROR: index out of bounds (got %d, max %d)", index, globalindex);
			return AL_FALSE;
		}
		alSourcePause(Sources[index]);
		if (AlGetError("ERROR %d: Pausing last sound\n") != AL_TRUE)
			return AL_FALSE;
		
		return AL_TRUE;
	}
	
	
	ALint openal_stopsound(int index){
		/*Stop sound number index*/
		if (index >= globalindex) {
			fprintf(stderr, "ERROR: index out of bounds (got %d, max %d)", index, globalindex);
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
