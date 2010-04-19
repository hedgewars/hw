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

#include "loaders.h"
#include "wrappers.h"
#include "vorbis/vorbisfile.h"

#ifdef __CPLUSPLUS
extern "C" {
#endif 
    
    int load_wavpcm (const char *filename, ALenum *format, char ** data, ALsizei *bitsize, ALsizei *freq) {
        WAV_header_t WAVHeader;
        FILE *wavfile;
        int32_t t;
        uint32_t n = 0;
        uint8_t sub0, sub1, sub2, sub3;
        
        wavfile = Fopen(filename, "rb");
        
        fread(&WAVHeader.ChunkID, sizeof(uint32_t), 1, wavfile);                /*RIFF*/
        fread(&WAVHeader.ChunkSize, sizeof(uint32_t), 1, wavfile);
        fread(&WAVHeader.Format, sizeof(uint32_t), 1, wavfile);                 /*WAVE*/
        
#ifdef DEBUG
        fprintf(stderr, "ChunkID: %X\n", ENDIAN_BIG_32(WAVHeader.ChunkID));
        fprintf(stderr, "ChunkSize: %d\n", ENDIAN_LITTLE_32(WAVHeader.ChunkSize));
        fprintf(stderr, "Format: %X\n", ENDIAN_BIG_32(WAVHeader.Format));
#endif
        
        fread(&WAVHeader.Subchunk1ID, sizeof(uint32_t), 1, wavfile);            /*fmt */
        fread(&WAVHeader.Subchunk1Size, sizeof(uint32_t), 1, wavfile);
        fread(&WAVHeader.AudioFormat, sizeof(uint16_t), 1, wavfile);
        fread(&WAVHeader.NumChannels, sizeof(uint16_t), 1, wavfile);
        fread(&WAVHeader.SampleRate, sizeof(uint32_t), 1, wavfile);
        fread(&WAVHeader.ByteRate, sizeof(uint32_t), 1, wavfile);
        fread(&WAVHeader.BlockAlign, sizeof(uint16_t), 1, wavfile);
        fread(&WAVHeader.BitsPerSample, sizeof(uint16_t), 1, wavfile);
        
#ifdef DEBUG
        fprintf(stderr, "Subchunk1ID: %X\n", ENDIAN_BIG_32(WAVHeader.Subchunk1ID));
        fprintf(stderr, "Subchunk1Size: %d\n", ENDIAN_LITTLE_32(WAVHeader.Subchunk1Size));
        fprintf(stderr, "AudioFormat: %d\n", ENDIAN_LITTLE_16(WAVHeader.AudioFormat));
        fprintf(stderr, "NumChannels: %d\n", ENDIAN_LITTLE_16(WAVHeader.NumChannels));
        fprintf(stderr, "SampleRate: %d\n", ENDIAN_LITTLE_32(WAVHeader.SampleRate));
        fprintf(stderr, "ByteRate: %d\n", ENDIAN_LITTLE_32(WAVHeader.ByteRate));
        fprintf(stderr, "BlockAlign: %d\n", ENDIAN_LITTLE_16(WAVHeader.BlockAlign));
        fprintf(stderr, "BitsPerSample: %d\n", ENDIAN_LITTLE_16(WAVHeader.BitsPerSample));
#endif
        
        /*remove useless header chunks by looking for the WAV_HEADER_SUBCHUNK2ID integer */
        do {
            t = fread(&sub0, sizeof(uint8_t), 1, wavfile);
            if(sub0 == 0x64) {
                t = fread(&sub1, sizeof(uint8_t), 1, wavfile);
                if(sub1 == 0x61) {
                    t = fread(&sub2, sizeof(uint8_t), 1, wavfile);
                    if(sub2 == 0x74) {
                        t = fread(&sub3, sizeof(uint8_t), 1, wavfile);
                        if(sub3 == 0x61) {
                            WAVHeader.Subchunk2ID = WAV_HEADER_SUBCHUNK2ID;
                            break;                                                
                        } 
                    }       
                }
            }
            
            if (t <= 0) { 
                /*eof*/
                errno = EILSEQ;
                err_ret("(%s) ERROR - wrong WAV header", prog);
                return AL_FALSE;
            }
        } while (1);
        
        fread(&WAVHeader.Subchunk2Size, sizeof(uint32_t), 1, wavfile);
        
#ifdef DEBUG
        fprintf(stderr, "Subchunk2ID: %X\n", ENDIAN_LITTLE_32(WAVHeader.Subchunk2ID));
        fprintf(stderr, "Subchunk2Size: %d\n", ENDIAN_LITTLE_32(WAVHeader.Subchunk2Size));
#endif
        
        *data = (char*) Malloc (sizeof(char) * ENDIAN_LITTLE_32(WAVHeader.Subchunk2Size));
        
        /*read the actual sound data*/
        do {
            n += fread(&((*data)[n]), sizeof(uint8_t), 4, wavfile);
        } while (n < ENDIAN_LITTLE_32(WAVHeader.Subchunk2Size));
        
        fclose(wavfile);	
        
#ifdef DEBUG
        err_msg("(%s) INFO - WAV data loaded", prog);
#endif
        
        /*set parameters for OpenAL*/
        /*Valid formats are AL_FORMAT_MONO8, AL_FORMAT_MONO16, AL_FORMAT_STEREO8, and AL_FORMAT_STEREO16*/
        if (ENDIAN_LITTLE_16(WAVHeader.NumChannels) == 1) {
            if (ENDIAN_LITTLE_16(WAVHeader.BitsPerSample) == 8)
                *format = AL_FORMAT_MONO8;
            else {
                if (ENDIAN_LITTLE_16(WAVHeader.BitsPerSample) == 16)
                    *format = AL_FORMAT_MONO16;
                else {
                    errno = EILSEQ;
                    err_ret("(%s) ERROR - wrong WAV header [bitsample value]", prog);
                    return AL_FALSE;
                }
            } 
        } else {
            if (ENDIAN_LITTLE_16(WAVHeader.NumChannels) == 2) {
                if (ENDIAN_LITTLE_16(WAVHeader.BitsPerSample) == 8)
                    *format = AL_FORMAT_STEREO8;
                else {
                    if (ENDIAN_LITTLE_16(WAVHeader.BitsPerSample) == 16)
                        *format = AL_FORMAT_STEREO16;
                    else {
                        errno = EILSEQ;
                        err_ret("(%s) ERROR - wrong WAV header [bitsample value]", prog);
                        return AL_FALSE;
                    }				
                }
            } else {
                errno = EILSEQ;
                err_ret("(%s) ERROR - wrong WAV header [format value]", prog); 
                return AL_FALSE;
            }
        }
        
        *bitsize = ENDIAN_LITTLE_32(WAVHeader.Subchunk2Size);
        *freq    = ENDIAN_LITTLE_32(WAVHeader.SampleRate);
        return AL_TRUE;
    }
    
    
    int load_oggvorbis (const char *filename, ALenum *format, char **data, ALsizei *bitsize, ALsizei *freq) {
        /*implementation inspired from http://www.devmaster.net/forums/showthread.php?t=1153 */
        
        /*ogg handle*/
        FILE *oggFile;
        /*stream handle*/
        OggVorbis_File oggStream; 
        /*some formatting data*/
        vorbis_info *vorbisInfo; 
        /*length of the decoded data*/
        int64_t pcm_length;
        /*other vars*/
        int section, result, size, endianness;
#ifdef DEBUG
        int i;
        /*other less useful data*/
        vorbis_comment *vorbisComment;
#endif
        
        oggFile = Fopen(filename, "rb");
        result = ov_open_callbacks(oggFile, &oggStream, NULL, 0, OV_CALLBACKS_DEFAULT);
        if (result < 0) {
            errno = EINVAL;
            err_ret("(%s) ERROR - ov_fopen() failed with %X", prog, result);
            ov_clear(&oggStream);
            return -1;
        }
        
        /*load OGG header and determine the decoded data size*/
        vorbisInfo = ov_info(&oggStream, -1);
        pcm_length = ov_pcm_total(&oggStream, -1) << vorbisInfo->channels;	
        
#ifdef DEBUG
        vorbisComment = ov_comment(&oggStream, -1);
        fprintf(stderr, "Version: %d\n", vorbisInfo->version);
        fprintf(stderr, "Channels: %d\n", vorbisInfo->channels);
        fprintf(stderr, "Rate (Hz): %ld\n", vorbisInfo->rate);
        fprintf(stderr, "Bitrate Upper: %ld\n", vorbisInfo->bitrate_upper);
        fprintf(stderr, "Bitrate Nominal: %ld\n", vorbisInfo->bitrate_nominal);
        fprintf(stderr, "Bitrate Lower: %ld\n", vorbisInfo->bitrate_lower);
        fprintf(stderr, "Bitrate Windows: %ld\n", vorbisInfo->bitrate_window);
        fprintf(stderr, "Vendor: %s\n", vorbisComment->vendor);
        fprintf(stderr, "PCM data size: %lld\n", pcm_length);
        fprintf(stderr, "# comment: %d\n", vorbisComment->comments);
        for (i = 0; i < vorbisComment->comments; i++)
            fprintf(stderr, "\tComment %d: %s\n", i, vorbisComment->user_comments[i]);
#endif
        
        /*allocates enough room for the decoded data*/
        *data = (char*) Malloc (sizeof(char) * pcm_length);
        
        /*there *should* not be ogg at 8 bits*/
        if (vorbisInfo->channels == 1)
            *format = AL_FORMAT_MONO16;
        else {
            if (vorbisInfo->channels == 2)
                *format = AL_FORMAT_STEREO16;
            else {
                errno = EILSEQ;
                err_ret("(%s) ERROR - wrong OGG header [channel %d]", prog, vorbisInfo->channels);
                ov_clear(&oggStream);
                return -1;
            }
        }
        
        size = 0;
#ifdef __LITTLE_ENDIAN__
        endianness = 0;
#elif __BIG_ENDIAN__
        endianness = 1;
#endif
        while (size < pcm_length) {
            /*ov_read decodes the ogg stream and storse the pcm in data*/
            result = ov_read (&oggStream, *data + size, pcm_length - size, endianness, 2, 1, &section);
            if (result > 0) {
                size += result;
            } else {
                if (result == 0)
                    break;
                else { 
                    errno = EILSEQ;
                    err_ret("(%s) ERROR - End of file from OGG stream", prog);
                    ov_clear(&oggStream);
                    return -1;
                }
            }
        }
        
        /*set the last fields*/
        *bitsize = size;
        *freq = vorbisInfo->rate;
        
        /*cleaning time (ov_clear also closes file handler)*/
        ov_clear(&oggStream);

        return 0;
    }
    
#ifdef __CPLUSPLUS
}
#endif	
