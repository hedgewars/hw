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

#include "wrappers.h"

#ifdef __CPLUSPLUS
extern "C" {
#endif 
	
	void *Malloc (size_t nbytes)
	{
		void *aptr;
		if ( (aptr = malloc(nbytes)) == NULL) {
			fprintf(stderr, "ERROR: not enough memory! malloc() failed");
			exit(-1);
		}
		return aptr;
	}
	
	FILE *Fopen (const char *fname, char *mode)
	{
		FILE *fp;
		if ((fp=fopen(fname,mode)) == NULL)
			fprintf (stderr, "ERROR: can't open file %s in mode '%s'", fname, mode);
		return fp;
	}
	
	ALint AlGetError (const char *str) {
		ALenum error;
		
		error = alGetError();
		if (error != AL_NO_ERROR) {
			fprintf(stderr, str, error);
			return -2;
		} else 
			return AL_TRUE;
	}
	
#ifdef __CPLUSPLUS
}
#endif