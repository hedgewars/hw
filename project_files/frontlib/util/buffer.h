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
struct _flib_vector;
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
 * Append the provided data to the end of the vector, enlarging it as required.
 * Returns the ammount of data appended, which is either len (success) or 0 (out of memory).
 * The vector remains unchanged if appending fails.
 */
int flib_vector_append(flib_vector *vec, const void *data, size_t len);

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
