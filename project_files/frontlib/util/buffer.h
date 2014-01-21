/*
 * Hedgewars, a free turn based strategy game
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#ifndef BUFFER_H_
#define BUFFER_H_

#include <stdint.h>
#include <stddef.h>

/**
 * A simple struct to hold both the pointer to an array and its size,
 * for e.g. conveniently returning it from a function.
 *
 * Convention: Size is zero iff data is a NULL pointer.
 */
typedef struct {
    void *data;
    size_t size;
} flib_buffer;

/**
 * Just like flib_buffer, but the contents are not supposed to be modified.
 */
typedef struct {
    const void *data;
    size_t size;
} flib_constbuffer;

/**
 * Simple variable-capacity data structure that can be efficiently appended to.
 */
typedef struct _flib_vector flib_vector;

/**
 * Create a new vector. Needs to be destroyed again later with flib_vector_destroy.
 * May return NULL if memory runs out.
 */
flib_vector *flib_vector_create();

/**
 * Free the memory of this vector
 */
void flib_vector_destroy(flib_vector *vec);

/**
 * Resize the vector. This changes the size, and ensures the capacity is large enough to
 * for the new size. Can also free memory if the new size is smaller. There is no guarantee
 * about the contents of extra memory.
 */
int flib_vector_resize(flib_vector *vec, size_t newSize);

/**
 * Append the provided data to the end of the vector, enlarging it as required.
 * The vector remains unchanged if appending fails.
 * Returns 0 on success.
 */
int flib_vector_append(flib_vector *vec, const void *data, size_t len);

/**
 * Append data from a format string to the buffer (without trailing 0)
 * Returns 0 on success.
 */
int flib_vector_appendf(flib_vector *vec, const char *template, ...);

/**
 * Return a pointer to the current data buffer of the vector. This pointer can
 * become invalid if the vector size or capacity is changed.
 */
void *flib_vector_data(flib_vector *vec);

/**
 * Return the current size of the vector.
 */
size_t flib_vector_size(flib_vector *vec);

/**
 * Return a buffer pointing to the current contents of the vector.
 * These will become invalid if the vector size or capacity is changed.
 */
flib_buffer flib_vector_as_buffer(flib_vector *vec);

/**
 * Return a constbuffer pointing to the current contents of the vector.
 * These will become invalid if the vector size or capacity is changed.
 */
flib_constbuffer flib_vector_as_constbuffer(flib_vector *vec);

#endif
