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

#ifndef __OLAB_INCLUDES__
#define __OLAB_INCLUDES__

#include <stdio.h>
#include <stdlib.h>
#include "al.h"
#include "alc.h"
#include "loaders.h"
#include "wrappers.h"
#include "endianness.h"
#include "openalwrap.h"

#ifndef _WIN32
#include <pthread.h>
#include <stdint.h>
#else
#define WIN32_LEAN_AND_MEAN
#include <process.h>
#include "winstdint.h"
#endif

#ifndef _SLEEP_H
#define _SLEEP_H
/** 1.0 02/03/10 - Defines cross-platform sleep, usleep, etc. * By Wu Yongwei **/
#ifdef _WIN32
# if defined(_NEED_SLEEP_ONLY) && (defined(_MSC_VER) || defined(__MINGW32__))
#  include <stdlib.h>
#  define sleep(t) _sleep((t) * 1000)
# else
#  include <windows.h>
#  define sleep(t)  Sleep((t) * 1000)
# endif
# ifndef _NEED_SLEEP_ONLY
#  define msleep(t) Sleep(t)
#  define usleep(t) Sleep((t) / 1000)
# endif
#else
# include <unistd.h>
# ifndef _NEED_SLEEP_ONLY
#  define msleep(t) usleep((t) * 1000)
# endif
#endif
#endif /* _SLEEP_H */

#ifdef HAVE_BYTESWAP_H
/* use byteswap macros from the host system, hopefully optimized ones ;-) */
#include <byteswap.h>
#else
/* define our own version, simple, stupid, straight-forward... */

#define bswap_16(x)	((((x) & 0xFF00) >> 8) | (((x) & 0x00FF) << 8))

#define bswap_32(x)	((((x) & 0xFF000000) >> 24) | \
(((x) & 0x00FF0000) >> 8)  | \
(((x) & 0x0000FF00) << 8)  | \
(((x) & 0x000000FF) << 24) )

#endif /* HAVE_BYTESWAP_H */

#ifdef __CPLUSPLUS
extern "C" {
#endif 
	
	/*data type for WAV header*/
#pragma pack(1)
	typedef struct _WAV_header_t {
		uint32_t ChunkID;
		uint32_t ChunkSize;
		uint32_t Format;
		uint32_t Subchunk1ID;
		uint32_t Subchunk1Size;
		uint16_t AudioFormat;
		uint16_t NumChannels;
		uint32_t SampleRate;
		uint32_t ByteRate;
		uint16_t BlockAlign;
		uint16_t BitsPerSample;
		uint32_t Subchunk2ID;
		uint32_t Subchunk2Size;
	} WAV_header_t;
#pragma pack()
	
	/*data type for passing data between threads*/
	typedef struct _fade_t {
		int index;
		unsigned int quantity;
	} fade_t;
	
	/*other defines*/
#define FADE_IN		11
#define FADE_OUT	12
	
	
	/*data types for ogg and vorbis that are required to be external*/
#ifndef ogg_int64_t	
#define ogg_int64_t int64_t
#endif
	
	typedef struct {
		unsigned char *data;
		int storage;
		int fill;
		int returned;
		
		int unsynced;
		int headerbytes;
		int bodybytes;
	} ogg_sync_state;
	typedef struct vorbis_info{
		int version;
		int channels;
		long rate;
		
		/* The below bitrate declarations are *hints*.
		 Combinations of the three values carry the following implications:
		 
		 all three set to the same value:
		 implies a fixed rate bitstream
		 only nominal set:
		 implies a VBR stream that averages the nominal bitrate.  No hard
		 upper/lower limit
		 upper and or lower set:
		 implies a VBR bitstream that obeys the bitrate limits. nominal
		 may also be set to give a nominal rate.
		 none set:
		 the coder does not care to speculate.
		 */
		
		long bitrate_upper;
		long bitrate_nominal;
		long bitrate_lower;
		long bitrate_window;
		
		void *codec_setup;
	} vorbis_info;
	typedef struct vorbis_comment{
		/* unlimited user comment fields.  libvorbis writes 'libvorbis' whatever vendor is set to in encode */
		char **user_comments;
		int   *comment_lengths;
		int    comments;
		char  *vendor;
		
	} vorbis_comment;
	typedef struct {
		unsigned char   *body_data;    /* bytes from packet bodies */
		long    body_storage;          /* storage elements allocated */
		long    body_fill;             /* elements stored; fill mark */
		long    body_returned;         /* elements of fill returned */
		
		
		int     *lacing_vals;      /* The values that will go to the segment table */
		ogg_int64_t *granule_vals; 
		/* granulepos values for headers. Not compact
		 this way, but it is simple coupled to the lacing fifo */
		long    lacing_storage;
		long    lacing_fill;
		long    lacing_packet;
		long    lacing_returned;
		
		unsigned char    header[282];      /* working space for header encode */
		int              header_fill;
		
		int     e_o_s;          /* set when we have buffered the last packet in the logical bitstream */
		int     b_o_s;          /* set after we've written the initial page of a logical bitstream */
		long    serialno;
		long    pageno;
		ogg_int64_t  packetno;      
		/* sequence number for decode; the framing
		 knows where there's a hole in the data,
		 but we need coupling so that the codec
		 (which is in a seperate abstraction
		 layer) also knows about the gap */
		ogg_int64_t   granulepos;
		
	} ogg_stream_state;
	typedef struct vorbis_dsp_state{
		int analysisp;
		vorbis_info *vi;
		
		float **pcm;
		float **pcmret;
		int      pcm_storage;
		int      pcm_current;
		int      pcm_returned;
		
		int  preextrapolate;
		int  eofflag;
		
		long lW;
		long W;
		long nW;
		long centerW;
		
		ogg_int64_t granulepos;
		ogg_int64_t sequence;
		
		ogg_int64_t glue_bits;
		ogg_int64_t time_bits;
		ogg_int64_t floor_bits;
		ogg_int64_t res_bits;
		
		void       *backend_state;
	} vorbis_dsp_state;
	typedef struct {
		long endbyte;
		int  endbit;
		
		unsigned char *buffer;
		unsigned char *ptr;
		long storage;
	} oggpack_buffer;
	typedef struct vorbis_block{
		/* necessary stream state for linking to the framing abstraction */
		float  **pcm;       /* this is a pointer into local storage */
		oggpack_buffer opb;
		
		long  lW;
		long  W;
		long  nW;
		int   pcmend;
		int   mode;
		
		int         eofflag;
		ogg_int64_t granulepos;
		ogg_int64_t sequence;
		vorbis_dsp_state *vd; /* For read-only access of configuration */
		
		/* local storage to avoid remallocing; it's up to the mapping to structure it */
		void               *localstore;
		long                localtop;
		long                localalloc;
		long                totaluse;
		struct alloc_chain *reap;
		
		/* bitmetrics for the frame */
		long glue_bits;
		long time_bits;
		long floor_bits;
		long res_bits;
		
		void *internal;
		
	} vorbis_block;
	typedef struct {
		size_t (*read_func)  (void *ptr, size_t size, size_t nmemb, void *datasource);
		int    (*seek_func)  (void *datasource, ogg_int64_t offset, int whence);
		int    (*close_func) (void *datasource);
		long   (*tell_func)  (void *datasource);
	} ov_callbacks;
	typedef struct OggVorbis_File {
		void            *datasource; /* Pointer to a FILE *, etc. */
		int              seekable;
		ogg_int64_t      offset;
		ogg_int64_t      end;
		ogg_sync_state   oy;
		
		/* If the FILE handle isn't seekable (eg, a pipe), only the current stream appears */
		int              links;
		ogg_int64_t     *offsets;
		ogg_int64_t     *dataoffsets;
		long            *serialnos;
		ogg_int64_t     *pcmlengths; 
		/* overloaded to maintain binary
		 compatability; x2 size, stores both
		 beginning and end values */
		vorbis_info     *vi;
		vorbis_comment  *vc;
		
		/* Decoding working state local storage */
		ogg_int64_t      pcm_offset;
		int              ready_state;
		long             current_serialno;
		int              current_link;
		
		double           bittrack;
		double           samptrack;
		
		ogg_stream_state os; /* take physical pages, weld into a logical stream of packets */
		vorbis_dsp_state vd; /* central working state for the packet->PCM decoder */
		vorbis_block     vb; /* local working space for packet->PCM decode */
		
		ov_callbacks callbacks;
		
	} OggVorbis_File;
	
	extern int ov_open(FILE *f,OggVorbis_File *vf,char *initial,long ibytes);
	extern long ov_read(OggVorbis_File *vf,char *buffer,int length,int bigendianp,int word,int sgned,int *bitstream);
	extern ogg_int64_t ov_pcm_total(OggVorbis_File *vf,int i);
	extern long ov_read(OggVorbis_File *vf,char *buffer,int length,int bigendianp,int word,int sgned,int *bitstream);
	extern vorbis_info *ov_info(OggVorbis_File *vf,int link);
	extern vorbis_comment *ov_comment(OggVorbis_File *f, int num);
	
#ifdef __CPLUSPLUS
}
#endif

#endif /*__OLAB_INCLUDES__*/
