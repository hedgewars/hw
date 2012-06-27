/**
 * Simple dynamic array manipulation functions.
 */

#ifndef LIST_H_
#define LIST_H_

#include <stddef.h>
#include <string.h>
#include <stdlib.h>
#include "util.h"
#include "logging.h"

/**
 * Generate a static function that inserts a new value into a heap array of the given type,
 * using realloc and memmove to increase the capacity and shift existing values.
 * The function takes a pointer to the array variable and a pointer to the size variable
 * because both can be changed by this operation (realloc / increment).
 * The function returns 0 on success and leaves the array unchanged on error.
 */
#define GENERATE_STATIC_LIST_INSERT(fname, type) \
	static int fname(type **listptr, int *listSizePtr, type element, int pos) { \
		int result = -1; \
		if(!listptr || !listSizePtr || pos < 0 || pos > *listSizePtr) { \
			flib_log_e("Invalid parameter in "#fname); \
		} else { \
			type *newList = flib_realloc(*listptr, ((*listSizePtr)+1)*sizeof(type)); \
			if(newList) { \
				memmove(newList + (pos+1), newList + pos, ((*listSizePtr)-pos)*sizeof(type)); \
				newList[pos] = element; \
				(*listSizePtr)++; \
				*listptr = newList; \
				result = 0; \
			} \
		} \
		return result; \
	}

/**
 * Generate a static function that deletes a value from a heap array of the given type,
 * using realloc and memmove to decrease the capacity and shift existing values.
 * The function takes a pointer to the array variable and a pointer to the size variable
 * because both can be changed by this operation (realloc / decrement).
 * The function returns 0 on success and leaves the array unchanged on error.
 */
#define GENERATE_STATIC_LIST_DELETE(fname, type) \
	static int fname(type **listPtr, int *listSizePtr, int pos) { \
		int result = -1; \
		if(!listPtr || !listSizePtr || pos < 0 || pos >= *listSizePtr) { \
			flib_log_e("Invalid parameter in "#fname); \
		} else { \
			memmove((*listPtr) + pos, (*listPtr) + (pos+1), ((*listSizePtr)-(pos+1))*sizeof(type)); \
			(*listSizePtr)--; \
			\
			size_t newCharSize = (*listSizePtr)*sizeof(type); \
			type *newList = flib_realloc((*listPtr), newCharSize); \
			if(newList || newCharSize==0) { \
				(*listPtr) = newList; \
			} /* If the realloc fails, just keep using the old buffer...*/ \
			result = 0; \
		} \
		return result; \
	}

#endif /* LIST_H_ */
