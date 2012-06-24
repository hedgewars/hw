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
	if(!vec) {
		flib_log_e("null parameter in flib_vector_resize");
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
	if(!vec) {
		flib_log_e("null parameter in flib_vector_append");
		return 0;
	}

	if(len > SIZE_MAX-vec->size) {
		return 0;
	}

	size_t oldSize = vec->size;
	if(flib_vector_resize(vec, vec->size+len)) {
		return 0;
	}

	memmove(((uint8_t*)vec->data) + oldSize, data, len);
	return len;
}

int flib_vector_appendf(flib_vector *vec, const char *fmt, ...) {
	int result = -1;
	if(!vec || !fmt) {
		flib_log_e("null parameter in flib_vector_appendf");
	} else {
		va_list argp;
		va_start(argp, fmt);
		char *formatted = flib_vasprintf(fmt, argp);
		va_end(argp);


		if(formatted) {
			size_t len = strlen(formatted);
			if(flib_vector_append(vec, formatted, len) == len) {
				result = 0;
			}
		}
	}
	return result;
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
