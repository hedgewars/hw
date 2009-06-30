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

#include "loaders.h"

#ifdef __CPLUSPLUS
extern "C" {
#endif 
	
	int load_WavPcm (const char *filename, ALenum *format, char ** data, ALsizei *bitsize, ALsizei *freq) {
		WAV_header_t WAVHeader;
		FILE *wavfile;
		int32_t t;
		uint32_t n = 0;
		
		wavfile = Fopen(filename, "rb");
		
		fread(&WAVHeader.ChunkID, sizeof(uint32_t), 1, wavfile);
		fread(&WAVHeader.ChunkSize, sizeof(uint32_t), 1, wavfile);
		fread(&WAVHeader.Format, sizeof(uint32_t), 1, wavfile);
		
#ifdef DEBUG
		fprintf(stderr, "ChunkID: %X\n", invert_endianness(WAVHeader.ChunkID));
		fprintf(stderr, "ChunkSize: %d\n", WAVHeader.ChunkSize);
		fprintf(stderr, "Format: %X\n", invert_endianness(WAVHeader.Format));
#endif
		
		fread(&WAVHeader.Subchunk1ID, sizeof(uint32_t), 1, wavfile);
		fread(&WAVHeader.Subchunk1Size, sizeof(uint32_t), 1, wavfile);
		fread(&WAVHeader.AudioFormat, sizeof(uint16_t), 1, wavfile);
		fread(&WAVHeader.NumChannels, sizeof(uint16_t), 1, wavfile);
		fread(&WAVHeader.SampleRate, sizeof(uint32_t), 1, wavfile);
		fread(&WAVHeader.ByteRate, sizeof(uint32_t), 1, wavfile);
		fread(&WAVHeader.BlockAlign, sizeof(uint16_t), 1, wavfile);
		fread(&WAVHeader.BitsPerSample, sizeof(uint16_t), 1, wavfile);
		
#ifdef DEBUG
		fprintf(stderr, "Subchunk1ID: %X\n", invert_endianness(WAVHeader.Subchunk1ID));
		fprintf(stderr, "Subchunk1Size: %d\n", WAVHeader.Subchunk1Size);
		fprintf(stderr, "AudioFormat: %d\n", WAVHeader.AudioFormat);
		fprintf(stderr, "NumChannels: %d\n", WAVHeader.NumChannels);
		fprintf(stderr, "SampleRate: %d\n", WAVHeader.SampleRate);
		fprintf(stderr, "ByteRate: %d\n", WAVHeader.ByteRate);
		fprintf(stderr, "BlockAlign: %d\n", WAVHeader.BlockAlign);
		fprintf(stderr, "BitsPerSample: %d\n", WAVHeader.BitsPerSample);
#endif
		
		do { /*remove useless header chunks (plenty room for improvements)*/
			t = fread(&WAVHeader.Subchunk2ID, sizeof(uint32_t), 1, wavfile);
			if (invert_endianness(WAVHeader.Subchunk2ID) == 0x64617461)
				break;
			if (t <= 0) { /*eof*/
				fprintf(stderr, "ERROR: wrong WAV header\n");
				return AL_FALSE;
			}
		} while (1);
		fread(&WAVHeader.Subchunk2Size, sizeof(uint32_t), 1, wavfile);
		
#ifdef DEBUG
		fprintf(stderr, "Subchunk2ID: %X\n", invert_endianness(WAVHeader.Subchunk2ID));
		fprintf(stderr, "Subchunk2Size: %d\n", WAVHeader.Subchunk2Size);
#endif
		
		*data = (char*) Malloc (sizeof(char) * WAVHeader.Subchunk2Size);
		
		/*this could be improved*/
		do {
			n += fread(&((*data)[n]), sizeof(uint8_t), 1, wavfile);
		} while (n < WAVHeader.Subchunk2Size);
		
		fclose(wavfile);	
		
#ifdef DEBUG
		fprintf(stderr, "Last two bytes of data: %X%X\n", (*data)[n-2], (*data)[n-1]);
#endif
		
		/*remaining parameters*/
		/*Valid formats are AL_FORMAT_MONO8, AL_FORMAT_MONO16, AL_FORMAT_STEREO8, and AL_FORMAT_STEREO16*/
		if (WAVHeader.NumChannels == 1) {
			if (WAVHeader.BitsPerSample == 8)
				*format = AL_FORMAT_MONO8;
			else {
				if (WAVHeader.BitsPerSample == 16)
					*format = AL_FORMAT_MONO16;
				else {
					fprintf(stderr, "ERROR: wrong WAV header - bitsample value\n");
					return AL_FALSE;
				}
			} 
		} else {
			if (WAVHeader.NumChannels == 2) {
				if (WAVHeader.BitsPerSample == 8)
					*format = AL_FORMAT_STEREO8;
				else {
					if (WAVHeader.BitsPerSample == 16)
						*format = AL_FORMAT_STEREO16;
					else {
						fprintf(stderr, "ERROR: wrong WAV header - bitsample value\n");
						return AL_FALSE;
					}				
				}
			} else {
				fprintf(stderr, "ERROR: wrong WAV header - format value\n");
				return AL_FALSE;
			}
		}
		
		*bitsize = WAVHeader.Subchunk2Size;
		*freq = WAVHeader.SampleRate;
		return AL_TRUE;
	}
	
	int load_OggVorbis (const char *filename, ALenum *format, char **data, ALsizei *bitsize, ALsizei *freq) {
		/*implementation inspired from http://www.devmaster.net/forums/showthread.php?t=1153 */
		FILE			*oggFile;		/*ogg handle*/
		OggVorbis_File  oggStream;		/*stream handle*/
		vorbis_info		*vorbisInfo;	/*some formatting data*/
		int64_t			pcm_length;		/*length of the decoded data*/
		int size = 0;
		int section, result;
#ifdef DEBUG
		int i;
		vorbis_comment	*vorbisComment;	/*other less useful data*/
#endif
		
		oggFile = Fopen(filename, "rb");
		result = ov_open(oggFile, &oggStream, NULL, 0);
		/*TODO: check returning value of result*/
		
		vorbisInfo = ov_info(&oggStream, -1);
		pcm_length = ov_pcm_total(&oggStream,-1) << vorbisInfo->channels;	
		
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
		fprintf(stderr, "PCM data size: %ld\n", pcm_length);
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
				fprintf(stderr, "ERROR: wrong OGG header - channel value (%d)\n", vorbisInfo->channels);
				return AL_FALSE;
			}
		}
		
		while(size < pcm_length)	{
			/*ov_read decodes the ogg stream and storse the pcm in data*/
			result = ov_read (&oggStream, *data + size, pcm_length - size, 0, 2, 1, &section);
			if(result > 0) {
				size += result;
			} else {
				if (result == 0)
					break;
				else { 
					fprintf(stderr, "ERROR: end of file from OGG stream\n");
					return AL_FALSE;
				}
			}
		}
		
		/*records the last fields*/
		*bitsize = size;
		*freq = vorbisInfo->rate;
		return AL_TRUE;
	}
	
#ifdef __CPLUSPLUS
}
#endif	
