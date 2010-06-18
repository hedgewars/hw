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

#include "wrappers.h"
#include "openalbridge_t.h"


void *Malloc (size_t nbytes) {
    void *aptr;

    if ((aptr = malloc(nbytes)) == NULL) {
        fprintf(stderr,"(Bridge FATAL) - not enough memory\n");
        abort();
    }

    return aptr;
}


void *Realloc (void *aptr, size_t nbytes) {
    aptr = realloc(aptr, nbytes);

    if (aptr == NULL) {
        fprintf(stderr,"(Bridge FATAL) - not enough memory\n");
        abort();
    }

    return aptr;
}


FILE *Fopen (const char *fname, char *mode)	{
    FILE *fp;

    fp = fopen(fname,mode);
    if (fp == NULL)
        fprintf(stderr,"(Bridge Error) - can't open file %s in mode '%s'\n", fname, mode);

    return fp;
}


