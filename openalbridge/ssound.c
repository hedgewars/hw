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

#include "ssound.h"
#include "loaders.h"

extern ALuint sources[MAX_SOURCES];
extern const ALfloat NV[3];
extern const ALfloat LO[6];

extern char *prog;

/*SSOUND STUFF HERE*/

char SSound_load (SSound_t* pSound, const char* cFilename) {
        uint32_t magic;
        ALenum format;
        ALsizei bitsize, freq;
        char *data;
        FILE* fp;
        
        snprintf(pSound->Filename, 256, "%s", cFilename);
        pSound->source = -1;
        alGenBuffers(1, &pSound->Buffer);
        
        if(alGetError() != AL_NO_ERROR) {
                fprintf(stderr, "CSound: Couldn't create buffer.\n");
                return 0;
        }
        
        fp = fopen(pSound->Filename, "rb");
        
        if(!fp) {
                fprintf(stderr, "CSound: Couldn't open file for reading.\n");
                return 0;
        }
        
        if(fread(&magic, sizeof(uint32_t), 1, fp) < 1)
        {
                fclose(fp);
                fprintf(stderr, "CSound: Couldn't read file header.\n");
                return 0;
        }
        fclose(fp);
        
        switch (ENDIAN_BIG_32(magic)) {
                case OGG_FILE_FORMAT:
                        load_oggvorbis (pSound->Filename, &format, &data, &bitsize, &freq);
                        break;
                case WAV_FILE_FORMAT:
                        load_wavpcm (pSound->Filename, &format, &data, &bitsize, &freq);
                        break;
                default:
                        errno = EINVAL;
                        err_ret ("(%s) ERROR - File format (%08X) not supported", prog, ENDIAN_BIG_32(magic));
                        return 0;
                        break;
        }
        
        alBufferData(pSound->Buffer, format, data, bitsize, freq);
        if(alGetError() != AL_NO_ERROR)
        {
                fprintf(stderr, "CSound: Couldn't write buffer data.\n");
                return 0;
        }
        free(data);
        
        return 1;
}

void SSound_close(SSound_t* pSound)
{
        SSound_stop(pSound);
        alDeleteBuffers(1, &pSound->Buffer);
}

void SSound_play(SSound_t* pSound, const char bLoop) {
        int i;
        
        if(pSound->source == -1) // need a new source
        {
                int i;
                for(i = 0; i < MAX_SOURCES; i++)
                {
                        ALint state;
                        alGetSourcei(sources[i], AL_SOURCE_STATE, &state);
                        if(state != AL_PLAYING && state != AL_PAUSED)
                        {
#ifdef DEBUG
                                printf("using source %d (state 0x%x) for buffer.\n", i, state);
#endif
                                alSourceStop(sources[pSound->source]);
                                alGetError();
                                break;
                        }
                }
                if(i == MAX_SOURCES) // no available source found; skip
                {
#ifdef DEBUG
                        printf("no source to play buffer %d!\n", i);
#endif
                        return;
                }
                pSound->source = i;
        }
        else // reuse already playing source
        {
                alSourceStop(sources[pSound->source]);
        }
        alSourcei (sources[pSound->source], AL_BUFFER, pSound->Buffer);
        alSourcef (sources[pSound->source], AL_PITCH,            1.0f);
        alSourcef (sources[pSound->source], AL_GAIN,             1.0f);
        alSourcefv(sources[pSound->source], AL_POSITION, NV          );
        alSourcefv(sources[pSound->source], AL_VELOCITY, NV          );
        alSourcei (sources[pSound->source], AL_LOOPING,  bLoop       );
        alSourcePlay(sources[pSound->source]);
        
        if((i = alGetError()) != AL_NO_ERROR)
        {
                fprintf(stderr, "CSound: SourcePlay error 0x%4x in source %d\n", i, pSound->source);
        }
#ifdef DEBUG
        fprintf(stderr, "play %s%s [%d]\n", pSound->Filename, bLoop ? " forever" : " once", pSound->source);
#endif
}

void SSound_pause(const SSound_t* pSound) {
        if(pSound->source == -1) // not playing
                return;
        alSourcePause(sources[pSound->source]);
#ifdef DEBUG
        fprintf(stderr, "pause %s\n", pSound->Filename);
#endif
}

void SSound_continue(const SSound_t* pSound) {
        if(pSound->source == -1) // not playing
                return;
        alSourcePlay(sources[pSound->source]);
#ifdef DEBUG
        fprintf(stderr, "pause %s\n", pSound->Filename);
#endif
}

void SSound_stop(SSound_t* pSound) {
        if(pSound->source == -1) // not playing
                return;
        alSourceStop(sources[pSound->source]);
        pSound->source = -1;
#ifdef DEBUG
        fprintf(stderr, "stop %s\n", pSound->Filename);
#endif
}

void SSound_volume(const SSound_t* pSound, const float fPercentage) {
        if(pSound->source == -1) // not playing
                return;
        alSourcef(sources[pSound->source], AL_GAIN, fPercentage);
}    