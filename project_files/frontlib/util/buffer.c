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

#include "buffer.h"
#include "logging.h"
#include "util.h"

#include <stdlib.h>
#include <limits.h>
#include <string.h>

#define MIN_VECTOR_CAPACITY 16

struct _flib_vector {
    void *data;
    size_t size;
    size_t capacity;
};

flib_vector *flib_vector_create() {
    flib_vector *result = NULL;
    flib_vector *tmpVector = flib_calloc(1, sizeof(flib_vector));
    if(tmpVector) {
        tmpVector->data = flib_malloc(MIN_VECTOR_CAPACITY);
        if(tmpVector->data) {
            tmpVector->size = 0;
            tmpVector->capacity = MIN_VECTOR_CAPACITY;
            result = tmpVector;
            tmpVector = NULL;
        }
    }
    flib_vector_destroy(tmpVector);
    return result;
}

void flib_vector_destroy(flib_vector *vec) {
    if(vec) {
        free(vec->data);
        free(vec);
    }
}

static int setCapacity(flib_vector *vec, size_t newCapacity) {
    if(newCapacity == vec->capacity) {
        return 0;
    }
    void *newData = realloc(vec->data, newCapacity);
    if(newData) {
        vec->data = newData;
        vec->capacity = newCapacity;
        return 0;
    } else {
        return -1;
    }
}

static int allocateExtraCapacity(flib_vector *vec, size_t extraCapacity) {
    if(extraCapacity <= SIZE_MAX - vec->capacity) {
        return setCapacity(vec, vec->capacity + extraCapacity);
    } else {
        return -1;
    }
}

int flib_vector_resize(flib_vector *vec, size_t newSize) {
    if(log_badargs_if(vec==NULL)) {
        return -1;
    }

    if(vec->capacity < newSize) {
        // Resize exponentially for constant amortized time,
        // But at least by as much as we need of course
        size_t extraCapacity = (vec->capacity)/2;
        size_t minExtraCapacity = newSize - vec->capacity;
        if(extraCapacity < minExtraCapacity) {
            extraCapacity = minExtraCapacity;
        }

        if(allocateExtraCapacity(vec, extraCapacity)) {
            allocateExtraCapacity(vec, minExtraCapacity);
        }
    } else if(vec->capacity/2 > newSize) {
        size_t newCapacity = newSize+newSize/4;
        if(newCapacity < MIN_VECTOR_CAPACITY) {
            newCapacity = MIN_VECTOR_CAPACITY;
        }
        setCapacity(vec, newCapacity);
    }

    if(vec->capacity >= newSize) {
        vec->size = newSize;
        return 0;
    } else {
        return -1;
    }
}

int flib_vector_append(flib_vector *vec, const void *data, size_t len) {
    if(!log_badargs_if2(vec==NULL, data==NULL && len>0)
            && !log_oom_if(len > SIZE_MAX-vec->size)) {
        size_t oldSize = vec->size;
        if(!log_oom_if(flib_vector_resize(vec, vec->size+len))) {
            memmove(((uint8_t*)vec->data) + oldSize, data, len);
            return 0;
        }
    }
    return -1;
}

int flib_vector_appendf(flib_vector *vec, const char *fmt, ...) {
    int result = -1;
    if(!log_badargs_if2(vec==NULL, fmt==NULL)) {
        va_list argp;
        va_start(argp, fmt);
        char *formatted = flib_vasprintf(fmt, argp);
        va_end(argp);


        if(formatted) {
            size_t len = strlen(formatted);
            result = flib_vector_append(vec, formatted, len);
        }
    }
    return result;
}

flib_buffer flib_vector_as_buffer(flib_vector *vec) {
    if(log_badargs_if(vec==NULL)) {
        flib_buffer result = {NULL, 0};
        return result;
    } else {
        flib_buffer result = {vec->data, vec->size};
        return result;
    }
}

flib_constbuffer flib_vector_as_constbuffer(flib_vector *vec) {
    if(log_badargs_if(vec==NULL)) {
        flib_constbuffer result = {NULL, 0};
        return result;
    } else {
        flib_constbuffer result = {vec->data, vec->size};
        return result;
    }
}

void *flib_vector_data(flib_vector *vec) {
    if(log_badargs_if(vec==NULL)) {
        return NULL;
    } else {
        return vec->data;
    }
}

size_t flib_vector_size(flib_vector *vec) {
    if(log_badargs_if(vec==NULL)) {
        return 0;
    } else {
        return vec->size;
    }
}
