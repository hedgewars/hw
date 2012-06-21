/**
 * Simple dynamic array manipulation functions.
 */

#ifndef LIST_H_
#define LIST_H_

#include <stddef.h>

/**
 * Insert element into the list and increase listSize.
 * Returns a pointer to the modified list on success, NULL on failure. On success, the old
 * pointer is no longer valid, and on failure the list remains unchanged (similar to realloc)
 */
void *flib_list_insert(void *list, int *listSizePtr, size_t elementSize, void *elementPtr, int pos);

/**
 * Remove an element from the list and decrease listSize.
 * Returns a pointer to the modified list on success, NULL on failure. On success, the old
 * pointer is no longer valid, and on failure the list remains unchanged (similar to realloc)
 */
void *flib_list_delete(void *list, int *listSizePtr, size_t elementSize, int pos);

#endif /* LIST_H_ */
