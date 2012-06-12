#include "buffer.h"
#include "logging.h"
#include "util.h"

#include <stdlib.h>
#include <limits.h>
#include <string.h>

#define MIN_VECTOR_CAPACITY 16

typedef struct _flib_vector {
	void *data;
	size_t size;
	size_t capacity;
} _flib_vector;

flib_vector *flib_vector_create() {
	flib_vector *result = NULL;
	flib_vector *tmpVector = flib_calloc(1, sizeof(_flib_vector));
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

static void try_realloc(flib_vector *vec, size_t newCapacity) {
	void *newData = realloc(vec->data, newCapacity);
	if(newData) {
		vec->data = newData;
		vec->capacity = newCapacity;
	}
}

static size_t getFreeCapacity(flib_vector *vec) {
	return vec->capacity - vec->size;
}

int flib_vector_append(flib_vector *vec, const void *data, size_t len) {
	if(!vec) {
		flib_log_e("null parameter in flib_vector_append");
		return 0;
	}

	if(getFreeCapacity(vec) < len) {
		// Resize exponentially for constant amortized time,
		// But at least by as much as we need of course,
		// and be extra careful with integer overflows...
		size_t extraCapacity = (vec->capacity)/2;

		size_t minExtraCapacity = len - getFreeCapacity(vec);
		if(extraCapacity < minExtraCapacity) {
			extraCapacity = minExtraCapacity;
		}

		if(extraCapacity <= SIZE_MAX - vec->capacity) {
			try_realloc(vec, vec->capacity+extraCapacity);
		}

		// Check if we were able to resize.
		// If not, try to allocate at least what we need.
		if(getFreeCapacity(vec) < len) {
			try_realloc(vec, vec->capacity+minExtraCapacity);

			// Still not working? Then we fail.
			if(getFreeCapacity(vec) < len) {
				return 0;
			}
		}
	}

	memmove(((uint8_t*)vec->data) + vec->size, data, len);
	vec->size += len;
	return len;
}

flib_buffer flib_vector_as_buffer(flib_vector *vec) {
	if(!vec) {
		flib_log_e("null parameter in flib_vector_as_buffer");
		flib_buffer result = {NULL, 0};
		return result;
	} else {
		flib_buffer result = {vec->data, vec->size};
		return result;
	}
}

flib_constbuffer flib_vector_as_constbuffer(flib_vector *vec) {
	if(!vec) {
		flib_log_e("null parameter in flib_vector_as_constbuffer");
		flib_constbuffer result = {NULL, 0};
		return result;
	} else {
		flib_constbuffer result = {vec->data, vec->size};
		return result;
	}
}

void *flib_vector_data(flib_vector *vec) {
	if(!vec) {
		flib_log_e("null parameter in flib_vector_data");
		return NULL;
	} else {
		return vec->data;
	}
}

size_t flib_vector_size(flib_vector *vec) {
	if(!vec) {
		flib_log_e("null parameter in flib_vector_size");
		return 0;
	} else {
		return vec->size;
	}
}
